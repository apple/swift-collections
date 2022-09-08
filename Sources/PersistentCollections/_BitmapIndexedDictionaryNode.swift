//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

fileprivate let initialDataCapacity: Capacity = 4
fileprivate let initialTrieCapacity: Capacity = 1

final class BitmapIndexedDictionaryNode<Key: Hashable, Value>: _DictionaryNode {

  typealias ReturnPayload = (key: Key, value: Value)
  typealias ReturnBitmapIndexedNode = BitmapIndexedDictionaryNode<Key, Value>

  typealias DataBufferElement = ReturnPayload
  typealias TrieBufferElement = ReturnBitmapIndexedNode

  var header: Header
  var count: Int


  var collisionFree: Bool {
    !hashCollision
  }

  var hashCollision: Bool {
    header.hashCollision
  }

  let dataCapacity: Capacity
  let trieCapacity: Capacity

  let dataBaseAddress: UnsafeMutablePointer<DataBufferElement>
  let trieBaseAddress: UnsafeMutablePointer<TrieBufferElement>

  private var rootBaseAddress: UnsafeMutableRawPointer {
    UnsafeMutableRawPointer(trieBaseAddress)
  }

  deinit {
    dataBaseAddress.deinitialize(count: header.dataCount)
    trieBaseAddress.deinitialize(count: header.trieCount)

    rootBaseAddress.deallocate()
  }

  @inline(__always)
  var dataMap: Bitmap {
    header.dataMap
  }

  @inline(__always)
  var trieMap: Bitmap {
    header.trieMap
  }

  @inlinable
  static func _allocate(
    dataCapacity: Capacity, trieCapacity: Capacity
  ) -> (
    dataBaseAddress: UnsafeMutablePointer<DataBufferElement>,
    trieBaseAddress: UnsafeMutablePointer<TrieBufferElement>
  ) {
    let dataCapacityInBytes = Int(dataCapacity) * MemoryLayout<DataBufferElement>.stride
    let trieCapacityInBytes = Int(trieCapacity) * MemoryLayout<TrieBufferElement>.stride

    let alignment = Swift.max(
      MemoryLayout<DataBufferElement>.alignment,
      MemoryLayout<TrieBufferElement>.alignment)
    let memory = UnsafeMutableRawPointer.allocate(
      byteCount: dataCapacityInBytes + trieCapacityInBytes,
      alignment: alignment)

    let dataBaseAddress = memory
      .advanced(by: trieCapacityInBytes)
      .bindMemory(to: DataBufferElement.self, capacity: Int(dataCapacity))
    let trieBaseAddress = memory
      .bindMemory(to: TrieBufferElement.self, capacity: Int(trieCapacity))

    return (dataBaseAddress, trieBaseAddress)
  }

  func copy(
    withDataCapacityFactor dataCapacityFactor: Capacity = 1,
    withDataCapacityShrinkFactor dataCapacityShrinkFactor: Capacity = 1,
    withTrieCapacityFactor trieCapacityFactor: Capacity = 1,
    withTrieCapacityShrinkFactor trieCapacityShrinkFactor: Capacity = 1
  ) -> Self {
    let src = self
    let dc = src.dataCapacity &* dataCapacityFactor / dataCapacityShrinkFactor
    let tc = src.trieCapacity &* trieCapacityFactor / trieCapacityShrinkFactor
    let dst = Self(dataCapacity: dc, trieCapacity: tc)

    dst.header = src.header
    dst.count = src.count

    dst.dataBaseAddress.initialize(
      from: src.dataBaseAddress,
      count: src.header.dataCount)
    dst.trieBaseAddress.initialize(
      from: src.trieBaseAddress,
      count: src.header.trieCount)

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  var invariant: Bool {
    guard headerInvariant else {
      return false
    }

    //        let recursiveCount = self.reduce(0, { count, _ in count + 1 })
    //
    //        guard recursiveCount == count else {
    //            return false
    //        }

    guard count - payloadArity >= 2 * nodeArity else {
      return false
    }

    if hashCollision {
      let hash = computeHash(_dataSlice.first!.key)

      guard _dataSlice.allSatisfy({ computeHash($0.key) == hash }) else {
        return false
      }
    }

    return true
  }

  var headerInvariant: Bool {
    (header.dataMap & header.trieMap) == 0 || (header.dataMap == header.trieMap)
  }

  var _dataSlice: UnsafeBufferPointer<DataBufferElement> {
    UnsafeBufferPointer(start: dataBaseAddress, count: header.dataCount)
  }

  var _trieSlice: UnsafeMutableBufferPointer<TrieBufferElement> {
    UnsafeMutableBufferPointer(start: trieBaseAddress, count: header.trieCount)
  }

  init(dataCapacity: Capacity, trieCapacity: Capacity) {
    let (dataBaseAddress, trieBaseAddress) = Self._allocate(
      dataCapacity: dataCapacity,
      trieCapacity: trieCapacity)

    self.header = Header(dataMap: 0, trieMap: 0)
    self.count = 0

    self.dataBaseAddress = dataBaseAddress
    self.trieBaseAddress = trieBaseAddress

    self.dataCapacity = dataCapacity
    self.trieCapacity = trieCapacity

    assert(self.invariant)
  }

  convenience init() {
    self.init(
      dataCapacity: initialDataCapacity,
      trieCapacity: initialTrieCapacity)

    self.header = Header(dataMap: 0, trieMap: 0)

    assert(self.invariant)
  }

  convenience init(dataMap: Bitmap, firstKey: Key, firstValue: Value) {
    self.init()

    self.header = Header(dataMap: dataMap, trieMap: 0)
    self.count = 1

    self.dataBaseAddress.initialize(to: (firstKey, firstValue))

    assert(self.invariant)
  }

  convenience init(
    dataMap: Bitmap,
    firstKey: Key,
    firstValue: Value,
    secondKey: Key,
    secondValue: Value
  ) {
    self.init()

    self.header = Header(dataMap: dataMap, trieMap: 0)
    self.count = 2

    self.dataBaseAddress.initialize(to: (firstKey, firstValue))
    self.dataBaseAddress.successor().initialize(to: (secondKey, secondValue))

    assert(self.invariant)
  }

  convenience init(
    trieMap: Bitmap,
    firstNode: BitmapIndexedDictionaryNode<Key, Value>
  ) {
    self.init()

    self.header = Header(dataMap: 0, trieMap: trieMap)
    self.count = firstNode.count

    self.trieBaseAddress.initialize(to: firstNode)

    assert(self.invariant)
  }

  convenience init(
    dataMap: Bitmap,
    trieMap: Bitmap,
    firstKey: Key,
    firstValue: Value,
    firstNode: BitmapIndexedDictionaryNode<Key, Value>
  ) {
    self.init()

    self.header = Header(dataMap: dataMap, trieMap: trieMap)
    self.count = 1 + firstNode.count

    self.dataBaseAddress.initialize(to: (firstKey, firstValue))
    self.trieBaseAddress.initialize(to: firstNode)

    assert(self.invariant)
  }

  convenience init(collisions: [ReturnPayload]) {
    self.init(dataCapacity: Capacity(collisions.count), trieCapacity: 0)

    self.header = Header(
      dataMap: Bitmap(collisions.count),
      trieMap: Bitmap(collisions.count))
    self.count = collisions.count

    self.dataBaseAddress.initialize(from: collisions, count: collisions.count)

    assert(self.invariant)
  }

  func get(_ key: Key, _ keyHash: Int, _ shift: Int) -> Value? {
    let mask = maskFrom(keyHash, shift)
    let bitpos = bitposFrom(mask)

    guard collisionFree else {
      let content: [ReturnPayload] = Array(self)
      let hash = computeHash(content.first!.key)

      guard keyHash == hash else {
        return nil
      }

      return content.first(where: { key == $0.key }).map { $0.value }
    }

    guard (dataMap & bitpos) == 0 else {
      let index = indexFrom(dataMap, mask, bitpos)
      let payload = self.getPayload(index)
      return key == payload.key ? payload.value : nil
    }

    guard (trieMap & bitpos) == 0 else {
      let index = indexFrom(trieMap, mask, bitpos)
      return self.getNode(index).get(key, keyHash, shift + bitPartitionSize)
    }

    return nil
  }

  func containsKey(_ key: Key, _ keyHash: Int, _ shift: Int) -> Bool {
    let mask = maskFrom(keyHash, shift)
    let bitpos = bitposFrom(mask)

    guard collisionFree else {
      let content: [ReturnPayload] = Array(self)
      let hash = computeHash(content.first!.key)

      guard keyHash == hash else {
        return false
      }

      return content.contains(where: { key == $0.key })
    }

    guard (dataMap & bitpos) == 0 else {
      let index = indexFrom(dataMap, mask, bitpos)
      let payload = self.getPayload(index)
      return key == payload.key
    }

    guard (trieMap & bitpos) == 0 else {
      let index = indexFrom(trieMap, mask, bitpos)
      return self
        .getNode(index)
        .containsKey(key, keyHash, shift + bitPartitionSize)
    }

    return false
  }

  func index(
    _ key: Key,
    _ keyHash: Int,
    _ shift: Int,
    _ skippedBefore: Int
  ) -> PersistentDictionaryIndex? {
    guard collisionFree else {
      let content: [ReturnPayload] = Array(self)
      let hash = computeHash(content.first!.key)

      assert(keyHash == hash)
      return content
        .firstIndex(where: { _key, _ in _key == key })
        .map { PersistentDictionaryIndex(value: $0) }
    }

    let mask = maskFrom(keyHash, shift)
    let bitpos = bitposFrom(mask)

    let skipped = self.counts.prefix(upTo: mask).reduce(0, +)

    guard (dataMap & bitpos) == 0 else {
      let index = indexFrom(dataMap, mask, bitpos)
      let payload = self.getPayload(index)
      guard key == payload.key else { return nil }

      return PersistentDictionaryIndex(value: skippedBefore + skipped)
    }

    guard (trieMap & bitpos) == 0 else {
      let index = indexFrom(trieMap, mask, bitpos)
      return self
        .getNode(index)
        .index(key, keyHash, shift + bitPartitionSize, skippedBefore + skipped)
    }

    return nil
  }

  func get(
    position: PersistentDictionaryIndex,
    _ shift: Int,
    _ stillToSkip: Int
  ) -> ReturnPayload {
    var cumulativeCounts = self.counts

    for i in 1 ..< cumulativeCounts.count {
      cumulativeCounts[i] += cumulativeCounts[i - 1]
    }

    var mask = 0

    for i in 0 ..< cumulativeCounts.count {
      if cumulativeCounts[i] <= stillToSkip {
        mask = i
      } else {
        mask = i
        break
      }
    }

    let skipped = (mask == 0) ? 0 : cumulativeCounts[mask - 1]

    let bitpos = bitposFrom(mask)

    guard (dataMap & bitpos) == 0 else {
      let index = indexFrom(dataMap, mask, bitpos)
      return self.getPayload(index)
    }

    guard (trieMap & bitpos) == 0 else {
      let index = indexFrom(trieMap, mask, bitpos)
      return self
        .getNode(index)
        .get(position: position, shift + bitPartitionSize, stillToSkip - skipped)
    }

    fatalError("Should not reach here.")
  }

  final func updateOrUpdating(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ key: Key,
    _ value: Value,
    _ keyHash: Int,
    _ shift: Int,
    _ effect: inout _DictionaryEffect<Value>
  ) -> BitmapIndexedDictionaryNode<Key, Value> {

    guard collisionFree else {
      return updateOrUpdatingCollision(
        isStorageKnownUniquelyReferenced, key, value, keyHash, shift, &effect)
    }

    let mask = maskFrom(keyHash, shift)
    let bitpos = bitposFrom(mask)

    guard (dataMap & bitpos) == 0 else {
      let index = indexFrom(dataMap, mask, bitpos)
      let (key0, value0) = self.getPayload(index)

      if key0 == key {
        effect.setReplacedValue(previousValue: value0)
        return copyAndSetValue(isStorageKnownUniquelyReferenced, bitpos, value)
      } else {
        let keyHash0 = computeHash(key0)

        if keyHash0 == keyHash {
          let subNodeNew = Self(
            /* hash, */ collisions: [(key0, value0), (key, value)])

          effect.setModified()
          if self.count == 1 {
            return subNodeNew
          } else {
            return copyAndMigrateFromInlineToNode(
              isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
          }
        } else {
          let subNodeNew = mergeTwoKeyValPairs(
            key0, value0, keyHash0,
            key, value, keyHash,
            shift + bitPartitionSize)

          effect.setModified()
          return copyAndMigrateFromInlineToNode(
            isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
        }
      }
    }

    guard (trieMap & bitpos) == 0 else {
      let index = indexFrom(trieMap, mask, bitpos)
      let subNodeModifyInPlace = self.isTrieNodeKnownUniquelyReferenced(
        index, isStorageKnownUniquelyReferenced)

      let subNode = self.getNode(index)

      let subNodeNew = subNode.updateOrUpdating(
        subNodeModifyInPlace,
        key, value, keyHash,
        shift + bitPartitionSize,
        &effect)
      guard effect.modified, subNode !== subNodeNew else {
        if effect.previousValue == nil { count += 1 }
        assert(self.invariant)
        return self
      }

      return copyAndSetTrieNode(
        isStorageKnownUniquelyReferenced,
        bitpos,
        index,
        subNodeNew,
        updateCount: { $0 -= subNode.count ; $0 += subNodeNew.count })
    }

    effect.setModified()
    return copyAndInsertValue(
      isStorageKnownUniquelyReferenced, bitpos, key, value)
  }

  @inline(never)
  final func updateOrUpdatingCollision(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ key: Key,
    _ value: Value,
    _ keyHash: Int,
    _ shift: Int,
    _ effect: inout _DictionaryEffect<Value>
  ) -> BitmapIndexedDictionaryNode<Key, Value> {
    assert(hashCollision)

    let content: [ReturnPayload] = Array(self)
    let hash = computeHash(content.first!.key)

    guard keyHash == hash else {
      effect.setModified()
      return mergeKeyValPairAndCollisionNode(
        key, value, keyHash, self, hash, shift)
    }

    if let index = content.firstIndex(where: { key == $0.key }) {
      let updatedContent: [ReturnPayload] = (
        content[0..<index] + [(key, value)] + content[index+1..<content.count])

      effect.setReplacedValue(previousValue: content[index].value)
      return Self(/* hash, */ collisions: updatedContent)
    } else {
      effect.setModified()
      return Self(/* hash, */ collisions: content + [(key, value)])
    }
  }

  final func removeOrRemoving(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ key: Key,
    _ keyHash: Int,
    _ shift: Int,
    _ effect: inout _DictionaryEffect<Value>
  ) -> BitmapIndexedDictionaryNode<Key, Value> {

    guard collisionFree else {
      return removeOrRemovingCollision(
        isStorageKnownUniquelyReferenced,
        key, keyHash,
        shift,
        &effect)
    }

    let mask = maskFrom(keyHash, shift)
    let bitpos = bitposFrom(mask)

    guard (dataMap & bitpos) == 0 else {
      let index = indexFrom(dataMap, mask, bitpos)
      let (key0, value0) = self.getPayload(index)
      guard key0 == key else {
        assert(self.invariant)
        return self
      }

      effect.setModified(previousValue: value0)
      if self.payloadArity == 2, self.nodeArity == 0 {
        if shift == 0 {
          // keep remaining pair on root level
          let newDataMap = (dataMap ^ bitpos)
          let (remainingKey, remainingValue) = getPayload(1 - index)
          return Self(
            dataMap: newDataMap,
            firstKey: remainingKey,
            firstValue: remainingValue)
        } else {
          // create potential new root: will a) become new root, or b) inlined
          // on another level
          let newDataMap = bitposFrom(maskFrom(keyHash, 0))
          let (remainingKey, remainingValue) = getPayload(1 - index)
          return Self(
            dataMap: newDataMap,
            firstKey: remainingKey,
            firstValue: remainingValue)
        }
      } else if
        self.payloadArity == 1,
        self.nodeArity == 1,
        self.getNode(0).hashCollision
      {
        // escalate hash-collision node
        return getNode(0)
      } else {
        return copyAndRemoveValue(isStorageKnownUniquelyReferenced, bitpos)
      }
    }

    guard (trieMap & bitpos) == 0 else {
      let index = indexFrom(trieMap, mask, bitpos)
      let subNodeModifyInPlace = self.isTrieNodeKnownUniquelyReferenced(
        index, isStorageKnownUniquelyReferenced)

      let subNode = self.getNode(index)

      let subNodeNew = subNode.removeOrRemoving(
        subNodeModifyInPlace, key, keyHash, shift + bitPartitionSize, &effect)
      guard effect.modified, subNode !== subNodeNew else {
        if effect.modified { count -= 1 }
        assert(self.invariant)
        return self
      }

      assert(subNodeNew.count > 0, "Sub-node must have at least one element.")
      switch subNodeNew.count {
      case 1:
        if self.isCandiateForCompaction {
          // escalate singleton
          return subNodeNew
        } else {
          // inline singleton
          return copyAndMigrateFromNodeToInline(
            isStorageKnownUniquelyReferenced, bitpos, subNodeNew.getPayload(0))
        }

      case _:
        if subNodeNew.hashCollision, self.isCandiateForCompaction {
          // escalate singleton
          return subNodeNew
        } else {
          // modify current node (set replacement node)
          return copyAndSetTrieNode(
            isStorageKnownUniquelyReferenced,
            bitpos,
            index,
            subNodeNew,
            updateCount: { $0 -= 1 })
        }
      }
    }

    return self
  }

  @inline(never)
  final func removeOrRemovingCollision(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ key: Key,
    _ keyHash: Int,
    _ shift: Int,
    _ effect: inout _DictionaryEffect<Value>
  ) -> BitmapIndexedDictionaryNode<Key, Value> {
    assert(hashCollision)

    let content: [ReturnPayload] = Array(self)
    let _ = computeHash(content.first!.key)

    if let index = content.firstIndex(where: { key == $0.key }) {
      effect.setModified(previousValue: content[index].value)
      var updatedContent = content; updatedContent.remove(at: index)
      assert(updatedContent.count == content.count - 1)

      if updatedContent.count == 1 {
        // create potential new root: will a) become new root, or b) inlined
        // on another level
        let newDataMap = bitposFrom(maskFrom(keyHash, 0))
        let (remainingKey, remainingValue) = updatedContent.first!
        return Self(
          dataMap: newDataMap,
          firstKey: remainingKey,
          firstValue: remainingValue)
      } else {
        return Self(/* hash, */ collisions: updatedContent)
      }
    } else {
      return self
    }
  }

  var isCandiateForCompaction: Bool { payloadArity == 0 && nodeArity == 1 }

  func mergeTwoKeyValPairs(
    _ key0: Key, _ value0: Value, _ keyHash0: Int,
    _ key1: Key, _ value1: Value, _ keyHash1: Int,
    _ shift: Int
  ) -> BitmapIndexedDictionaryNode<Key, Value> {
    assert(keyHash0 != keyHash1)

    let mask0 = maskFrom(keyHash0, shift)
    let mask1 = maskFrom(keyHash1, shift)

    if mask0 != mask1 {
      // unique prefixes, payload fits on same level
      if mask0 < mask1 {
        return Self(
          dataMap: bitposFrom(mask0) | bitposFrom(mask1),
          firstKey: key0,
          firstValue: value0,
          secondKey: key1,
          secondValue: value1)
      } else {
        return Self(
          dataMap: bitposFrom(mask1) | bitposFrom(mask0),
          firstKey: key1,
          firstValue: value1,
          secondKey: key0,
          secondValue: value0)
      }
    } else {
      // recurse: identical prefixes, payload must be disambiguated deeper
      // in the trie
      let node = mergeTwoKeyValPairs(
        key0, value0, keyHash0,
        key1, value1, keyHash1,
        shift + bitPartitionSize)

      return Self(trieMap: bitposFrom(mask0), firstNode: node)
    }
  }

  func mergeKeyValPairAndCollisionNode(
    _ key0: Key, _ value0: Value, _ keyHash0: Int,
    _ node1: BitmapIndexedDictionaryNode<Key, Value>,
    _ nodeHash1: Int,
    _ shift: Int
  ) -> BitmapIndexedDictionaryNode<Key, Value> {
    assert(keyHash0 != nodeHash1)

    let mask0 = maskFrom(keyHash0, shift)
    let mask1 = maskFrom(nodeHash1, shift)

    if mask0 != mask1 {
      // unique prefixes, payload and collision node fit on same level
      return Self(
        dataMap: bitposFrom(mask0),
        trieMap: bitposFrom(mask1),
        firstKey: key0,
        firstValue: value0,
        firstNode: node1)
    } else {
      // recurse: identical prefixes, payload must be disambiguated deeper in the trie
      let node = mergeKeyValPairAndCollisionNode(
        key0,
        value0,
        keyHash0,
        node1,
        nodeHash1,
        shift + bitPartitionSize)

      return Self(trieMap: bitposFrom(mask0), firstNode: node)
    }
  }

  private func isTrieNodeKnownUniquelyReferenced(
    _ slotIndex: Int,
    _ isParentNodeKnownUniquelyReferenced: Bool
  ) -> Bool {
    let isUnique = Swift.isKnownUniquelyReferenced(&trieBaseAddress[slotIndex])

    return isParentNodeKnownUniquelyReferenced && isUnique
  }

  var hasNodes: Bool { header.trieMap != 0 }

  var nodeArity: Int { header.trieCount }

  func getNode(_ index: Int) -> BitmapIndexedDictionaryNode<Key, Value> {
    trieBaseAddress[index]
  }

  var hasPayload: Bool { header.dataMap != 0 }

  var payloadArity: Int { header.dataCount }

  func getPayload(_ index: Int) -> (key: Key, value: Value) {
    dataBaseAddress[index]
  }

  private final var counts: [Int] {
    var counts = Array(repeating: 0, count: Bitmap.bitWidth)

    zip(header.dataMap._nonzeroBits(), _dataSlice).forEach { (index, _) in
      counts[index] = 1
    }

    zip(header.trieMap._nonzeroBits(), _trieSlice).forEach { (index, trieNode) in
      counts[index] = trieNode.count
    }

    return counts
  }

  private final func count(upTo mask: Int) -> Int {
    let bitpos = bitposFrom(mask)

    let dataIndex = indexFrom(dataMap, mask, bitpos)
    let trieIndex = indexFrom(trieMap, mask, bitpos)

    let buffer = UnsafeMutableBufferPointer(
      start: trieBaseAddress, count: header.trieCount)
    let children = buffer.prefix(upTo: trieIndex).map { $0.count }.reduce(0, +)
    let count = dataIndex + children

    assert(count == counts.prefix(upTo: mask).reduce(0, +))
    return count
  }

  func dataIndex(_ bitpos: Bitmap) -> Int {
    (dataMap & (bitpos &- 1)).nonzeroBitCount
  }

  func trieIndex(_ bitpos: Bitmap) -> Int {
    (trieMap & (bitpos &- 1)).nonzeroBitCount
  }

  func copyAndSetValue(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: Bitmap,
    _ newValue: Value
  ) -> BitmapIndexedDictionaryNode<Key, Value> {
    let src: ReturnBitmapIndexedNode = self
    let dst: ReturnBitmapIndexedNode

    if isStorageKnownUniquelyReferenced {
      dst = src
    } else {
      dst = src.copy()
    }

    let idx = dataIndex(bitpos)

    dst.dataBaseAddress[idx].value = newValue

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  private func copyAndSetTrieNode(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: Bitmap,
    _ idx: Int,
    _ newNode: TrieBufferElement,
    updateCount: (inout Int) -> Void
  ) -> BitmapIndexedDictionaryNode<Key, Value> {
    let src: ReturnBitmapIndexedNode = self
    let dst: ReturnBitmapIndexedNode

    if isStorageKnownUniquelyReferenced {
      dst = src
    } else {
      dst = src.copy()
    }

    dst.trieBaseAddress[idx] = newNode

    // update metadata: `dataMap, nodeMap, collMap`
    updateCount(&dst.count)

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func copyAndInsertValue(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: Bitmap,
    _ key: Key,
    _ value: Value
  ) -> BitmapIndexedDictionaryNode<Key, Value> {
    let src: ReturnBitmapIndexedNode = self
    let dst: ReturnBitmapIndexedNode

    let hasRoomForData = header.dataCount < dataCapacity

    if isStorageKnownUniquelyReferenced && hasRoomForData {
      dst = src
    } else {
      dst = src.copy(withDataCapacityFactor: hasRoomForData ? 1 : 2)
    }

    let dataIdx = indexFrom(dataMap, bitpos)
    rangeInsert(
      (key, value),
      at: dataIdx,
      into: dst.dataBaseAddress,
      count: dst.header.dataCount)

    // update metadata: `dataMap | bitpos, nodeMap, collMap`
    dst.header.dataMap |= bitpos
    dst.count += 1

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func copyAndRemoveValue(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: Bitmap
  ) -> BitmapIndexedDictionaryNode<Key, Value> {
    let src: ReturnBitmapIndexedNode = self
    let dst: ReturnBitmapIndexedNode

    if isStorageKnownUniquelyReferenced {
      dst = src
    } else {
      dst = src.copy()
    }

    let dataIdx = indexFrom(dataMap, bitpos)
    rangeRemove(
      at: dataIdx, from: dst.dataBaseAddress, count: dst.header.dataCount)

    // update metadata: `dataMap ^ bitpos, nodeMap, collMap`
    dst.header.dataMap ^= bitpos
    dst.count -= 1

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func copyAndMigrateFromInlineToNode(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: Bitmap,
    _ node: TrieBufferElement
  ) -> BitmapIndexedDictionaryNode<Key, Value> {
    let src: ReturnBitmapIndexedNode = self
    let dst: ReturnBitmapIndexedNode

    let hasRoomForTrie = header.trieCount < trieCapacity

    if isStorageKnownUniquelyReferenced && hasRoomForTrie {
      dst = src
    } else {
      // TODO reconsider the details of the heuristic
      //
      // Since copying is necessary, check if the data section can be reduced.
      // Keep at mininum the initial capacity.
      //
      // Notes currently can grow to a maximum size of 48 (tuple and sub-node)
      // slots.
      let tooMuchForData = Swift.max(header.dataCount * 2 - 1, 4) < dataCapacity

      dst = src.copy(
        withDataCapacityShrinkFactor: tooMuchForData ? 2 : 1,
        withTrieCapacityFactor: hasRoomForTrie ? 1 : 2)
    }

    let dataIdx = indexFrom(dataMap, bitpos)
    rangeRemove(
      at: dataIdx, from: dst.dataBaseAddress, count: dst.header.dataCount)

    let trieIdx = indexFrom(trieMap, bitpos)
    rangeInsert(
      node, at: trieIdx, into: dst.trieBaseAddress, count: dst.header.trieCount)

    // update metadata: `dataMap ^ bitpos, nodeMap | bitpos, collMap`
    dst.header.dataMap ^= bitpos
    dst.header.trieMap |= bitpos
    dst.count += 1 // assuming that `node.count == 2`

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func copyAndMigrateFromNodeToInline(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: Bitmap,
    _ tuple: (key: Key, value: Value)
  ) -> BitmapIndexedDictionaryNode<Key, Value> {
    let src: ReturnBitmapIndexedNode = self
    let dst: ReturnBitmapIndexedNode

    let hasRoomForData = header.dataCount < dataCapacity

    if isStorageKnownUniquelyReferenced && hasRoomForData {
      dst = src
    } else {
      dst = src.copy(withDataCapacityFactor: hasRoomForData ? 1 : 2)
    }

    let nodeIdx = indexFrom(trieMap, bitpos)
    rangeRemove(
      at: nodeIdx, from: dst.trieBaseAddress, count: dst.header.trieCount)

    let dataIdx = indexFrom(dataMap, bitpos)
    rangeInsert(
      tuple, at: dataIdx, into: dst.dataBaseAddress, count: dst.header.dataCount)

    // update metadata: `dataMap | bitpos, nodeMap ^ bitpos, collMap`
    dst.header.dataMap |= bitpos
    dst.header.trieMap ^= bitpos
    dst.count -= 1 // assuming that updated `node.count == 1`

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }
}

// TODO: `Equatable` needs more test coverage, apart from hash-collision smoke test
extension BitmapIndexedDictionaryNode: Equatable where Value: Equatable {
  static func == (
    lhs: BitmapIndexedDictionaryNode,
    rhs: BitmapIndexedDictionaryNode
  ) -> Bool {
    if lhs.hashCollision && rhs.hashCollision {
      let l = Dictionary(uniqueKeysWithValues: Array(lhs))
      let r = Dictionary(uniqueKeysWithValues: Array(rhs))
      return l == r
    }

    return (
      lhs === rhs ||
      lhs.header == rhs.header &&
      lhs.count == rhs.count &&
      deepContentEquality(lhs, rhs))
  }

  private static func deepContentEquality(
    _ lhs: BitmapIndexedDictionaryNode,
    _ rhs: BitmapIndexedDictionaryNode
  ) -> Bool {
    guard lhs.header == rhs.header else { return false }

    for index in 0..<lhs.payloadArity {
      if lhs.getPayload(index) != rhs.getPayload(index) {
        return false
      }
    }

    for index in 0..<lhs.nodeArity {
      if lhs.getNode(index) != rhs.getNode(index) {
        return false
      }
    }

    return true
  }
}

extension BitmapIndexedDictionaryNode: Sequence {
  typealias Iterator = DictionaryKeyValueTupleIterator<Key, Value>

  public __consuming func makeIterator() -> Iterator {
    DictionaryKeyValueTupleIterator(rootNode: self)
  }
}

struct Header: Equatable {
  var dataMap: Bitmap
  var trieMap: Bitmap

  var dataCount: Int { hashCollision ? Int(dataMap) : dataMap.nonzeroBitCount }
  var trieCount: Int { hashCollision ? 0            : trieMap.nonzeroBitCount }

  var hashCollision: Bool {
    (dataMap & trieMap) != 0
  }

  static func == (lhs: Header, rhs: Header) -> Bool {
    lhs.dataMap == rhs.dataMap && lhs.trieMap == rhs.trieMap
  }
}
