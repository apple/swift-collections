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

internal struct _NodeHeader: Equatable {
  internal typealias Bitmap = UInt32

  // TODO: restore type to `UInt8` after reworking hash-collisions to grow in
  // depth instead of width
  internal typealias Capacity = UInt32

  internal var dataMap: Bitmap
  internal var trieMap: Bitmap

  init(dataMap: Bitmap, trieMap: Bitmap) {
    self.dataMap = dataMap
    self.trieMap = trieMap
  }
}

extension _NodeHeader {
  internal var hashCollision: Bool {
    (dataMap & trieMap) != 0
  }

  internal var dataCount: Int {
    hashCollision ? Int(dataMap) : dataMap.nonzeroBitCount
  }

  internal var trieCount: Int {
    hashCollision ? 0 : trieMap.nonzeroBitCount
  }

  internal static func == (lhs: _NodeHeader, rhs: _NodeHeader) -> Bool {
    lhs.dataMap == rhs.dataMap && lhs.trieMap == rhs.trieMap
  }
}

extension PersistentDictionary {
  internal final class _Node {
    typealias Index = PersistentDictionary.Index
    typealias Capacity = _NodeHeader.Capacity

    typealias DataBufferElement = ReturnPayload
    typealias TrieBufferElement = ReturnBitmapIndexedNode

    var header: _NodeHeader
    var count: Int

    let dataCapacity: Capacity
    let trieCapacity: Capacity

    let dataBaseAddress: UnsafeMutablePointer<DataBufferElement>
    let trieBaseAddress: UnsafeMutablePointer<TrieBufferElement>

    deinit {
      dataBaseAddress.deinitialize(count: header.dataCount)
      trieBaseAddress.deinitialize(count: header.trieCount)

      rootBaseAddress.deallocate()
    }

    init(dataCapacity: Capacity, trieCapacity: Capacity) {
      let (dataBaseAddress, trieBaseAddress) = _Node._allocate(
        dataCapacity: dataCapacity,
        trieCapacity: trieCapacity)

      self.header = _NodeHeader(dataMap: 0, trieMap: 0)
      self.count = 0

      self.dataBaseAddress = dataBaseAddress
      self.trieBaseAddress = trieBaseAddress

      self.dataCapacity = dataCapacity
      self.trieCapacity = trieCapacity

      assert(self.invariant)
    }
  }
}

extension PersistentDictionary._Node {
  typealias _Node = PersistentDictionary._Node

  static var initialDataCapacity: Capacity { 4 }
  static var initialTrieCapacity: Capacity { 1 }
}

extension PersistentDictionary._Node {
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
  ) -> _Node {
    let src = self
    let dc = src.dataCapacity &* dataCapacityFactor / dataCapacityShrinkFactor
    let tc = src.trieCapacity &* trieCapacityFactor / trieCapacityShrinkFactor
    let dst = _Node(dataCapacity: dc, trieCapacity: tc)

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
}

extension PersistentDictionary._Node {
  convenience init() {
    self.init(
      dataCapacity: _Node.initialDataCapacity,
      trieCapacity: _Node.initialTrieCapacity)

    self.header = _NodeHeader(dataMap: 0, trieMap: 0)

    assert(self.invariant)
  }

  convenience init(
    dataMap: _NodeHeader.Bitmap, firstKey: Key, firstValue: Value) {
    self.init()

    self.header = _NodeHeader(dataMap: dataMap, trieMap: 0)
    self.count = 1

    self.dataBaseAddress.initialize(to: (firstKey, firstValue))

    assert(self.invariant)
  }

  convenience init(
    dataMap: _NodeHeader.Bitmap,
    firstKey: Key,
    firstValue: Value,
    secondKey: Key,
    secondValue: Value
  ) {
    self.init()

    self.header = _NodeHeader(dataMap: dataMap, trieMap: 0)
    self.count = 2

    self.dataBaseAddress.initialize(to: (firstKey, firstValue))
    self.dataBaseAddress.successor().initialize(to: (secondKey, secondValue))

    assert(self.invariant)
  }

  convenience init(trieMap: _NodeHeader.Bitmap, firstNode: _Node) {
    self.init()

    self.header = _NodeHeader(dataMap: 0, trieMap: trieMap)
    self.count = firstNode.count

    self.trieBaseAddress.initialize(to: firstNode)

    assert(self.invariant)
  }

  convenience init(
    dataMap: _NodeHeader.Bitmap,
    trieMap: _NodeHeader.Bitmap,
    firstKey: Key,
    firstValue: Value,
    firstNode: _Node
  ) {
    self.init()

    self.header = _NodeHeader(dataMap: dataMap, trieMap: trieMap)
    self.count = 1 + firstNode.count

    self.dataBaseAddress.initialize(to: (firstKey, firstValue))
    self.trieBaseAddress.initialize(to: firstNode)

    assert(self.invariant)
  }

  convenience init(collisions: [ReturnPayload]) {
    self.init(dataCapacity: Capacity(collisions.count), trieCapacity: 0)

    self.header = _NodeHeader(
      dataMap: _NodeHeader.Bitmap(collisions.count),
      trieMap: _NodeHeader.Bitmap(collisions.count))
    self.count = collisions.count

    self.dataBaseAddress.initialize(from: collisions, count: collisions.count)

    assert(self.invariant)
  }
}

extension PersistentDictionary._Node {
  var collisionFree: Bool {
    !hashCollision
  }

  var hashCollision: Bool {
    header.hashCollision
  }

  private var rootBaseAddress: UnsafeMutableRawPointer {
    UnsafeMutableRawPointer(trieBaseAddress)
  }

  @inline(__always)
  var dataMap: _NodeHeader.Bitmap {
    header.dataMap
  }

  @inline(__always)
  var trieMap: _NodeHeader.Bitmap {
    header.trieMap
  }

  var invariant: Bool {
    guard headerInvariant else {
      return false
    }

    //    let recursiveCount = self.reduce(0, { count, _ in count + 1 })
    //
    //    guard recursiveCount == count else {
    //      return false
    //    }

    guard count - payloadArity >= 2 * nodeArity else {
      return false
    }

    if hashCollision {
      let hash = _computeHash(_dataSlice.first!.key)

      guard _dataSlice.allSatisfy({ _computeHash($0.key) == hash }) else {
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

  var isCandiateForCompaction: Bool { payloadArity == 0 && nodeArity == 1 }

  func dataIndex(_ bitpos: _NodeHeader.Bitmap) -> Int {
    (dataMap & (bitpos &- 1)).nonzeroBitCount
  }

  func trieIndex(_ bitpos: _NodeHeader.Bitmap) -> Int {
    (trieMap & (bitpos &- 1)).nonzeroBitCount
  }

  func isTrieNodeKnownUniquelyReferenced(
    _ slotIndex: Int,
    _ isParentNodeKnownUniquelyReferenced: Bool
  ) -> Bool {
    let isUnique = Swift.isKnownUniquelyReferenced(&trieBaseAddress[slotIndex])

    return isParentNodeKnownUniquelyReferenced && isUnique
  }
}

extension PersistentDictionary._Node: _NodeProtocol {
  typealias ReturnPayload = (key: Key, value: Value)
  typealias ReturnBitmapIndexedNode = _Node

  var hasNodes: Bool { header.trieMap != 0 }

  var nodeArity: Int { header.trieCount }

  func getNode(_ index: Int) -> _Node {
    trieBaseAddress[index]
  }

  var hasPayload: Bool { header.dataMap != 0 }

  var payloadArity: Int { header.dataCount }

  func getPayload(_ index: Int) -> (key: Key, value: Value) {
    dataBaseAddress[index]
  }

}

extension PersistentDictionary._Node: _DictionaryNodeProtocol {
  func get(_ key: Key, _ keyHash: Int, _ shift: Int) -> Value? {
    let mask = _maskFrom(keyHash, shift)
    let bitpos = _bitposFrom(mask)

    guard collisionFree else {
      let content: [ReturnPayload] = Array(self)
      let hash = _computeHash(content.first!.key)

      guard keyHash == hash else {
        return nil
      }

      return content.first(where: { key == $0.key }).map { $0.value }
    }

    guard (dataMap & bitpos) == 0 else {
      let index = _indexFrom(dataMap, mask, bitpos)
      let payload = self.getPayload(index)
      return key == payload.key ? payload.value : nil
    }

    guard (trieMap & bitpos) == 0 else {
      let index = _indexFrom(trieMap, mask, bitpos)
      return self.getNode(index).get(key, keyHash, shift + _bitPartitionSize)
    }

    return nil
  }

  func containsKey(_ key: Key, _ keyHash: Int, _ shift: Int) -> Bool {
    let mask = _maskFrom(keyHash, shift)
    let bitpos = _bitposFrom(mask)

    guard collisionFree else {
      let content: [ReturnPayload] = Array(self)
      let hash = _computeHash(content.first!.key)

      guard keyHash == hash else {
        return false
      }

      return content.contains(where: { key == $0.key })
    }

    guard (dataMap & bitpos) == 0 else {
      let index = _indexFrom(dataMap, mask, bitpos)
      let payload = self.getPayload(index)
      return key == payload.key
    }

    guard (trieMap & bitpos) == 0 else {
      let index = _indexFrom(trieMap, mask, bitpos)
      return self
        .getNode(index)
        .containsKey(key, keyHash, shift + _bitPartitionSize)
    }

    return false
  }

  func index(
    _ key: Key,
    _ keyHash: Int,
    _ shift: Int,
    _ skippedBefore: Int
  ) -> Index? {
    guard collisionFree else {
      let content: [ReturnPayload] = Array(self)
      let hash = _computeHash(content.first!.key)

      assert(keyHash == hash)
      return content
        .firstIndex(where: { _key, _ in _key == key })
        .map { Index(_value: $0) }
    }

    let mask = _maskFrom(keyHash, shift)
    let bitpos = _bitposFrom(mask)

    let skipped = self._counts.prefix(upTo: mask).reduce(0, +)

    guard (dataMap & bitpos) == 0 else {
      let index = _indexFrom(dataMap, mask, bitpos)
      let payload = self.getPayload(index)
      guard key == payload.key else { return nil }

      return Index(_value: skippedBefore + skipped)
    }

    guard (trieMap & bitpos) == 0 else {
      let index = _indexFrom(trieMap, mask, bitpos)
      return self
        .getNode(index)
        .index(key, keyHash, shift + _bitPartitionSize, skippedBefore + skipped)
    }

    return nil
  }

  final func updateOrUpdating(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ key: Key,
    _ value: Value,
    _ keyHash: Int,
    _ shift: Int,
    _ effect: inout _DictionaryEffect<Value>
  ) -> _Node {

    guard collisionFree else {
      return _updateOrUpdatingCollision(
        isStorageKnownUniquelyReferenced, key, value, keyHash, shift, &effect)
    }

    let mask = _maskFrom(keyHash, shift)
    let bitpos = _bitposFrom(mask)

    guard (dataMap & bitpos) == 0 else {
      let index = _indexFrom(dataMap, mask, bitpos)
      let (key0, value0) = self.getPayload(index)

      if key0 == key {
        effect.setReplacedValue(previousValue: value0)
        return _copyAndSetValue(isStorageKnownUniquelyReferenced, bitpos, value)
      } else {
        let keyHash0 = _computeHash(key0)

        if keyHash0 == keyHash {
          let subNodeNew = _Node(
            /* hash, */ collisions: [(key0, value0), (key, value)])

          effect.setModified()
          if self.count == 1 {
            return subNodeNew
          } else {
            return _copyAndMigrateFromInlineToNode(
              isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
          }
        } else {
          let subNodeNew = _mergeTwoKeyValPairs(
            key0, value0, keyHash0,
            key, value, keyHash,
            shift + _bitPartitionSize)

          effect.setModified()
          return _copyAndMigrateFromInlineToNode(
            isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
        }
      }
    }

    guard (trieMap & bitpos) == 0 else {
      let index = _indexFrom(trieMap, mask, bitpos)
      let subNodeModifyInPlace = self.isTrieNodeKnownUniquelyReferenced(
        index, isStorageKnownUniquelyReferenced)

      let subNode = self.getNode(index)

      let subNodeNew = subNode.updateOrUpdating(
        subNodeModifyInPlace,
        key, value, keyHash,
        shift + _bitPartitionSize,
        &effect)
      guard effect.modified, subNode !== subNodeNew else {
        if effect.previousValue == nil { count += 1 }
        assert(self.invariant)
        return self
      }

      return _copyAndSetTrieNode(
        isStorageKnownUniquelyReferenced,
        bitpos,
        index,
        subNodeNew,
        updateCount: { $0 -= subNode.count ; $0 += subNodeNew.count })
    }

    effect.setModified()
    return _copyAndInsertValue(
      isStorageKnownUniquelyReferenced, bitpos, key, value)
  }

  @inline(never)
  final func _updateOrUpdatingCollision(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ key: Key,
    _ value: Value,
    _ keyHash: Int,
    _ shift: Int,
    _ effect: inout _DictionaryEffect<Value>
  ) -> _Node {
    assert(hashCollision)

    let content: [ReturnPayload] = Array(self)
    let hash = _computeHash(content.first!.key)

    guard keyHash == hash else {
      effect.setModified()
      return _mergeKeyValPairAndCollisionNode(
        key, value, keyHash, self, hash, shift)
    }

    if let index = content.firstIndex(where: { key == $0.key }) {
      let updatedContent: [ReturnPayload] = (
        content[0..<index] + [(key, value)] + content[index+1..<content.count])

      effect.setReplacedValue(previousValue: content[index].value)
      return _Node(/* hash, */ collisions: updatedContent)
    } else {
      effect.setModified()
      return _Node(/* hash, */ collisions: content + [(key, value)])
    }
  }

  final func removeOrRemoving(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ key: Key,
    _ keyHash: Int,
    _ shift: Int,
    _ effect: inout _DictionaryEffect<Value>
  ) -> _Node {

    guard collisionFree else {
      return _removeOrRemovingCollision(
        isStorageKnownUniquelyReferenced,
        key, keyHash,
        shift,
        &effect)
    }

    let mask = _maskFrom(keyHash, shift)
    let bitpos = _bitposFrom(mask)

    guard (dataMap & bitpos) == 0 else {
      let index = _indexFrom(dataMap, mask, bitpos)
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
          return _Node(
            dataMap: newDataMap,
            firstKey: remainingKey,
            firstValue: remainingValue)
        } else {
          // create potential new root: will a) become new root, or b) inlined
          // on another level
          let newDataMap = _bitposFrom(_maskFrom(keyHash, 0))
          let (remainingKey, remainingValue) = getPayload(1 - index)
          return _Node(
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
        return _copyAndRemoveValue(isStorageKnownUniquelyReferenced, bitpos)
      }
    }

    guard (trieMap & bitpos) == 0 else {
      let index = _indexFrom(trieMap, mask, bitpos)
      let subNodeModifyInPlace = self.isTrieNodeKnownUniquelyReferenced(
        index, isStorageKnownUniquelyReferenced)

      let subNode = self.getNode(index)

      let subNodeNew = subNode.removeOrRemoving(
        subNodeModifyInPlace, key, keyHash, shift + _bitPartitionSize, &effect)
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
          return _copyAndMigrateFromNodeToInline(
            isStorageKnownUniquelyReferenced, bitpos, subNodeNew.getPayload(0))
        }

      case _:
        if subNodeNew.hashCollision, self.isCandiateForCompaction {
          // escalate singleton
          return subNodeNew
        } else {
          // modify current node (set replacement node)
          return _copyAndSetTrieNode(
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
  final func _removeOrRemovingCollision(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ key: Key,
    _ keyHash: Int,
    _ shift: Int,
    _ effect: inout _DictionaryEffect<Value>
  ) -> _Node {
    assert(hashCollision)

    let content: [ReturnPayload] = Array(self)
    let _ = _computeHash(content.first!.key)

    if let index = content.firstIndex(where: { key == $0.key }) {
      effect.setModified(previousValue: content[index].value)
      var updatedContent = content; updatedContent.remove(at: index)
      assert(updatedContent.count == content.count - 1)

      if updatedContent.count == 1 {
        // create potential new root: will a) become new root, or b) inlined
        // on another level
        let newDataMap = _bitposFrom(_maskFrom(keyHash, 0))
        let (remainingKey, remainingValue) = updatedContent.first!
        return _Node(
          dataMap: newDataMap,
          firstKey: remainingKey,
          firstValue: remainingValue)
      } else {
        return _Node(/* hash, */ collisions: updatedContent)
      }
    } else {
      return self
    }
  }
}

extension PersistentDictionary._Node {
  func get(position: Index, _ shift: Int, _ stillToSkip: Int) -> ReturnPayload {
    var cumulativeCounts = self._counts

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

    let bitpos = _bitposFrom(mask)

    guard (dataMap & bitpos) == 0 else {
      let index = _indexFrom(dataMap, mask, bitpos)
      return self.getPayload(index)
    }

    guard (trieMap & bitpos) == 0 else {
      let index = _indexFrom(trieMap, mask, bitpos)
      return self
        .getNode(index)
        .get(position: position, shift + _bitPartitionSize, stillToSkip - skipped)
    }

    fatalError("Should not reach here.")
  }
}

extension PersistentDictionary._Node {
  func _mergeTwoKeyValPairs(
    _ key0: Key, _ value0: Value, _ keyHash0: Int,
    _ key1: Key, _ value1: Value, _ keyHash1: Int,
    _ shift: Int
  ) -> _Node {
    assert(keyHash0 != keyHash1)

    let mask0 = _maskFrom(keyHash0, shift)
    let mask1 = _maskFrom(keyHash1, shift)

    if mask0 != mask1 {
      // unique prefixes, payload fits on same level
      if mask0 < mask1 {
        return _Node(
          dataMap: _bitposFrom(mask0) | _bitposFrom(mask1),
          firstKey: key0,
          firstValue: value0,
          secondKey: key1,
          secondValue: value1)
      } else {
        return Self(
          dataMap: _bitposFrom(mask1) | _bitposFrom(mask0),
          firstKey: key1,
          firstValue: value1,
          secondKey: key0,
          secondValue: value0)
      }
    } else {
      // recurse: identical prefixes, payload must be disambiguated deeper
      // in the trie
      let node = _mergeTwoKeyValPairs(
        key0, value0, keyHash0,
        key1, value1, keyHash1,
        shift + _bitPartitionSize)

      return _Node(trieMap: _bitposFrom(mask0), firstNode: node)
    }
  }

  final func _mergeKeyValPairAndCollisionNode(
    _ key0: Key, _ value0: Value, _ keyHash0: Int,
    _ node1: _Node,
    _ nodeHash1: Int,
    _ shift: Int
  ) -> _Node {
    assert(keyHash0 != nodeHash1)

    let mask0 = _maskFrom(keyHash0, shift)
    let mask1 = _maskFrom(nodeHash1, shift)

    if mask0 != mask1 {
      // unique prefixes, payload and collision node fit on same level
      return _Node(
        dataMap: _bitposFrom(mask0),
        trieMap: _bitposFrom(mask1),
        firstKey: key0,
        firstValue: value0,
        firstNode: node1)
    } else {
      // recurse: identical prefixes, payload must be disambiguated deeper in the trie
      let node = _mergeKeyValPairAndCollisionNode(
        key0,
        value0,
        keyHash0,
        node1,
        nodeHash1,
        shift + _bitPartitionSize)

      return _Node(trieMap: _bitposFrom(mask0), firstNode: node)
    }
  }

  final var _counts: [Int] {
    var counts = Array(repeating: 0, count: _NodeHeader.Bitmap.bitWidth)

    zip(header.dataMap._nonzeroBits(), _dataSlice).forEach { (index, _) in
      counts[index] = 1
    }

    zip(header.trieMap._nonzeroBits(), _trieSlice).forEach { (index, trieNode) in
      counts[index] = trieNode.count
    }

    return counts
  }

  func _copyAndSetValue(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: _NodeHeader.Bitmap,
    _ newValue: Value
  ) -> _Node {
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

  private func _copyAndSetTrieNode(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: _NodeHeader.Bitmap,
    _ idx: Int,
    _ newNode: TrieBufferElement,
    updateCount: (inout Int) -> Void
  ) -> _Node {
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

  func _copyAndInsertValue(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: _NodeHeader.Bitmap,
    _ key: Key,
    _ value: Value
  ) -> _Node {
    let src: ReturnBitmapIndexedNode = self
    let dst: ReturnBitmapIndexedNode

    let hasRoomForData = header.dataCount < dataCapacity

    if isStorageKnownUniquelyReferenced && hasRoomForData {
      dst = src
    } else {
      dst = src.copy(withDataCapacityFactor: hasRoomForData ? 1 : 2)
    }

    let dataIdx = _indexFrom(dataMap, bitpos)
    _rangeInsert(
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

  func _copyAndRemoveValue(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: _NodeHeader.Bitmap
  ) -> _Node {
    let src: ReturnBitmapIndexedNode = self
    let dst: ReturnBitmapIndexedNode

    if isStorageKnownUniquelyReferenced {
      dst = src
    } else {
      dst = src.copy()
    }

    let dataIdx = _indexFrom(dataMap, bitpos)
    _rangeRemove(
      at: dataIdx, from: dst.dataBaseAddress, count: dst.header.dataCount)

    // update metadata: `dataMap ^ bitpos, nodeMap, collMap`
    dst.header.dataMap ^= bitpos
    dst.count -= 1

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func _copyAndMigrateFromInlineToNode(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: _NodeHeader.Bitmap,
    _ node: TrieBufferElement
  ) -> _Node {
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

    let dataIdx = _indexFrom(dataMap, bitpos)
    _rangeRemove(
      at: dataIdx, from: dst.dataBaseAddress, count: dst.header.dataCount)

    let trieIdx = _indexFrom(trieMap, bitpos)
    _rangeInsert(
      node, at: trieIdx, into: dst.trieBaseAddress, count: dst.header.trieCount)

    // update metadata: `dataMap ^ bitpos, nodeMap | bitpos, collMap`
    dst.header.dataMap ^= bitpos
    dst.header.trieMap |= bitpos
    dst.count += 1 // assuming that `node.count == 2`

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func _copyAndMigrateFromNodeToInline(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ bitpos: _NodeHeader.Bitmap,
    _ tuple: (key: Key, value: Value)
  ) -> _Node {
    let src: ReturnBitmapIndexedNode = self
    let dst: ReturnBitmapIndexedNode

    let hasRoomForData = header.dataCount < dataCapacity

    if isStorageKnownUniquelyReferenced && hasRoomForData {
      dst = src
    } else {
      dst = src.copy(withDataCapacityFactor: hasRoomForData ? 1 : 2)
    }

    let nodeIdx = _indexFrom(trieMap, bitpos)
    _rangeRemove(
      at: nodeIdx, from: dst.trieBaseAddress, count: dst.header.trieCount)

    let dataIdx = _indexFrom(dataMap, bitpos)
    _rangeInsert(
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
extension PersistentDictionary._Node: Equatable where Value: Equatable {
  static func == (lhs: _Node, rhs: _Node) -> Bool {
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

  private static func deepContentEquality(_ lhs: _Node, _ rhs: _Node) -> Bool {
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

extension PersistentDictionary._Node: Sequence {
  typealias Iterator = PersistentDictionary<Key, Value>.Iterator

  public __consuming func makeIterator() -> Iterator {
    Iterator(_root: self)
  }
}
