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

internal struct _NodeHeader {
  internal var dataMap: _Bitmap
  internal var trieMap: _Bitmap

  init(dataMap: _Bitmap, trieMap: _Bitmap) {
    self.dataMap = dataMap
    self.trieMap = trieMap
  }
}

extension _NodeHeader {
  internal var isCollisionNode: Bool {
    !dataMap.intersection(trieMap).isEmpty
  }

  internal var dataCount: Int {
    isCollisionNode ? Int(dataMap._value) : dataMap.count
  }

  internal var trieCount: Int {
    isCollisionNode ? 0 : trieMap.count
  }
}

extension _NodeHeader: Equatable {
  internal static func == (lhs: _NodeHeader, rhs: _NodeHeader) -> Bool {
    lhs.dataMap == rhs.dataMap && lhs.trieMap == rhs.trieMap
  }
}

extension PersistentDictionary {
  internal final class _Node {
    typealias Element = (key: Key, value: Value)
    typealias Index = PersistentDictionary.Index

    // TODO: restore type to `UInt8` after reworking hash-collisions to grow in
    // depth instead of width
    internal typealias Capacity = UInt32

    var header: _NodeHeader
    var count: Int

    let dataCapacity: Capacity
    let trieCapacity: Capacity

    let dataBaseAddress: UnsafeMutablePointer<Element>
    let trieBaseAddress: UnsafeMutablePointer<_Node>

    deinit {
      dataBaseAddress.deinitialize(count: header.dataCount)
      trieBaseAddress.deinitialize(count: header.trieCount)

      rootBaseAddress.deallocate()
    }

    init(dataCapacity: Capacity, trieCapacity: Capacity) {
      let (dataBaseAddress, trieBaseAddress) = _Node._allocate(
        dataCapacity: dataCapacity,
        trieCapacity: trieCapacity)

      self.header = _NodeHeader(dataMap: .empty, trieMap: .empty)
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
    dataBaseAddress: UnsafeMutablePointer<Element>,
    trieBaseAddress: UnsafeMutablePointer<_Node>
  ) {
    let dataCapacityInBytes = Int(dataCapacity) * MemoryLayout<Element>.stride
    let trieCapacityInBytes = Int(trieCapacity) * MemoryLayout<_Node>.stride

    let alignment = Swift.max(
      MemoryLayout<Element>.alignment,
      MemoryLayout<_Node>.alignment)
    let memory = UnsafeMutableRawPointer.allocate(
      byteCount: dataCapacityInBytes + trieCapacityInBytes,
      alignment: alignment)

    let dataBaseAddress = memory
      .advanced(by: trieCapacityInBytes)
      .bindMemory(to: Element.self, capacity: Int(dataCapacity))
    let trieBaseAddress = memory
      .bindMemory(to: _Node.self, capacity: Int(trieCapacity))

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

    self.header = _NodeHeader(dataMap: .empty, trieMap: .empty)

    assert(self.invariant)
  }

  convenience init(dataMap: _Bitmap, _ item: Element) {
    assert(dataMap.count == 1)
    self.init()
    self.header = _NodeHeader(dataMap: dataMap, trieMap: .empty)
    self.count = 1
    self.dataBaseAddress.initialize(to: item)
    assert(self.invariant)
  }

  convenience init(_ item: Element, at bucket: _Bucket) {
    self.init(dataMap: _Bitmap(bucket), item)
  }

  convenience init(
    _ item0: Element, at bucket0: _Bucket,
    _ item1: Element, at bucket1: _Bucket
  ) {
    assert(bucket0 != bucket1)
    self.init()

    self.header = _NodeHeader(
      dataMap: _Bitmap(bucket0, bucket1),
      trieMap: .empty)
    self.count = 2

    if bucket0 < bucket1 {
      self.dataBaseAddress.initialize(to: item0)
      self.dataBaseAddress.successor().initialize(to: item1)
    } else {
      self.dataBaseAddress.initialize(to: item1)
      self.dataBaseAddress.successor().initialize(to: item0)
    }
    assert(self.invariant)
  }

  convenience init(_ child: _Node, at bucket: _Bucket) {
    self.init()

    self.header = _NodeHeader(
      dataMap: .empty,
      trieMap: _Bitmap(bucket))
    self.count = child.count

    self.trieBaseAddress.initialize(to: child)

    assert(self.invariant)
  }

  convenience init(
    _ item: Element, at bucket0: _Bucket,
    _ child: _Node, at bucket1: _Bucket
  ) {
    assert(bucket0 != bucket1)
    self.init()

    self.header = _NodeHeader(
      dataMap: _Bitmap(bucket0),
      trieMap: _Bitmap(bucket1))
    self.count = 1 + child.count

    self.dataBaseAddress.initialize(to: item)
    self.trieBaseAddress.initialize(to: child)

    assert(self.invariant)
  }

  convenience init(collisions: [Element]) {
    self.init(dataCapacity: Capacity(collisions.count), trieCapacity: 0)

    self.header = _NodeHeader(
      dataMap: _Bitmap(bitPattern: collisions.count),
      trieMap: _Bitmap(bitPattern: collisions.count))
    self.count = collisions.count

    self.dataBaseAddress.initialize(from: collisions, count: collisions.count)

    assert(self.invariant)
  }
}

extension PersistentDictionary._Node {
  var isRegularNode: Bool {
    !isCollisionNode
  }

  var isCollisionNode: Bool {
    header.isCollisionNode
  }

  private var rootBaseAddress: UnsafeMutableRawPointer {
    UnsafeMutableRawPointer(trieBaseAddress)
  }

  @inline(__always)
  var dataMap: _Bitmap {
    header.dataMap
  }

  @inline(__always)
  var trieMap: _Bitmap {
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

    if isCollisionNode {
      let hash = _HashValue(_dataSlice.first!.key)

      guard _dataSlice.allSatisfy({ _HashValue($0.key) == hash }) else {
        return false
      }
    }

    return true
  }

  var headerInvariant: Bool {
    header.dataMap.intersection(header.trieMap).isEmpty
    || (header.dataMap == header.trieMap)
  }

  var _dataSlice: UnsafeBufferPointer<Element> {
    UnsafeBufferPointer(start: dataBaseAddress, count: header.dataCount)
  }

  var _trieSlice: UnsafeMutableBufferPointer<_Node> {
    UnsafeMutableBufferPointer(start: trieBaseAddress, count: header.trieCount)
  }

  var isCandiateForCompaction: Bool { payloadArity == 0 && nodeArity == 1 }

  func isTrieNodeKnownUniquelyReferenced(
    _ slotIndex: Int,
    _ isParentNodeKnownUniquelyReferenced: Bool
  ) -> Bool {
    let isUnique = Swift.isKnownUniquelyReferenced(&trieBaseAddress[slotIndex])

    return isParentNodeKnownUniquelyReferenced && isUnique
  }
}

extension PersistentDictionary._Node: _NodeProtocol {
  var hasNodes: Bool { !header.trieMap.isEmpty }

  var nodeArity: Int { header.trieCount }

  func getNode(_ index: Int) -> _Node {
    trieBaseAddress[index]
  }

  var hasPayload: Bool { !header.dataMap.isEmpty }

  var payloadArity: Int { header.dataCount }

  func getPayload(_ index: Int) -> (key: Key, value: Value) {
    dataBaseAddress[index]
  }
}

extension PersistentDictionary._Node: _DictionaryNodeProtocol {
  func get(_ key: Key, _ path: _HashPath) -> Value? {
    guard isRegularNode else {
      let content: [Element] = Array(self)
      let hash = _HashValue(content.first!.key)
      guard path._hash == hash else { return nil }
      return content.first(where: { key == $0.key }).map { $0.value }
    }

    let bucket = path.currentBucket

    if dataMap.contains(bucket) {
      let offset = dataMap.offset(of: bucket)
      let payload = self.getPayload(offset)
      return key == payload.key ? payload.value : nil
    }

    if trieMap.contains(bucket) {
      let offset = trieMap.offset(of: bucket)
      return self.getNode(offset).get(key, path.descend())
    }

    return nil
  }

  func containsKey(_ key: Key, _ path: _HashPath) -> Bool {
    guard isRegularNode else {
      let content: [Element] = Array(self)
      let hash = _HashValue(content.first!.key)
      guard path._hash == hash else { return false }
      return content.contains(where: { key == $0.key })
    }

    let bucket = path.currentBucket

    if dataMap.contains(bucket) {
      let offset = dataMap.offset(of: bucket)
      let payload = self.getPayload(offset)
      return key == payload.key
    }

    if trieMap.contains(bucket) {
      let offset = trieMap.offset(of: bucket)
      return self
        .getNode(offset)
        .containsKey(key, path.descend())
    }

    return false
  }

  func index(
    forKey key: Key,
    _ path: _HashPath,
    _ skippedBefore: Int
  ) -> Index? {
    guard isRegularNode else {
      let content: [Element] = Array(self)
      let hash = _HashValue(content.first!.key)
      assert(path._hash == hash)
      return content
        .firstIndex(where: { _key, _ in _key == key })
        .map { Index(_value: $0) }
    }

    let bucket = path.currentBucket

    if dataMap.contains(bucket) {
      let offset = dataMap.offset(of: bucket)
      let payload = self.getPayload(offset)
      guard key == payload.key else { return nil }
      return Index(_value: skippedBefore + _count(upTo: bucket))
    }

    if trieMap.contains(bucket) {
      let offset = trieMap.offset(of: bucket)
      let skipped = skippedBefore + _count(upTo: bucket)
      return self
        .getNode(offset)
        .index(forKey: key, path.descend(), skipped)
    }

    return nil
  }

  final func updateOrUpdating(
    _ isUnique: Bool,
    _ item: Element,
    _ path: _HashPath,
    _ effect: inout _DictionaryEffect<Value>
  ) -> _Node {

    guard isRegularNode else {
      return _updateOrUpdatingCollision(isUnique, item, path, &effect)
    }

    let bucket = path.currentBucket
    if dataMap.contains(bucket) {
      let offset = dataMap.offset(of: bucket)
      let item0 = self.getPayload(offset)

      if item0.key == item.key {
        effect.setReplacedValue(previousValue: item0.value)
        return _copyAndSetValue(isUnique, bucket, item.value)
      }
      let hash0 = _HashValue(item0.key)
      if hash0 == path._hash {
        let subNodeNew = _Node(collisions: [item0, item])
        effect.setModified()
        if self.count == 1 { return subNodeNew }
        return _copyAndMigrateFromInlineToNode(isUnique, bucket, subNodeNew)
      }
      let subNodeNew = _mergeTwoKeyValPairs(
        item, path.descend(),
        item0, hash0)
      effect.setModified()
      return _copyAndMigrateFromInlineToNode(isUnique, bucket, subNodeNew)
    }

    if trieMap.contains(bucket) {
      let offset = trieMap.offset(of: bucket)
      let isUniqueChild = self.isTrieNodeKnownUniquelyReferenced(
        offset, isUnique)

      let subNode = self.getNode(offset)

      let subNodeNew = subNode.updateOrUpdating(
        isUniqueChild, item, path.descend(), &effect)
      guard effect.modified, subNode !== subNodeNew else {
        if effect.previousValue == nil { count += 1 }
        assert(self.invariant)
        return self
      }

      return _copyAndSetTrieNode(
        isUnique,
        bucket,
        offset,
        subNodeNew,
        updateCount: { $0 -= subNode.count ; $0 += subNodeNew.count })
    }

    effect.setModified()
    return _copyAndInsertValue(isUnique, bucket, item)
  }

  @inline(never)
  final func _updateOrUpdatingCollision(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ item: Element,
    _ path: _HashPath,
    _ effect: inout _DictionaryEffect<Value>
  ) -> _Node {
    assert(isCollisionNode)

    let content: [Element] = Array(self)
    let hash = _HashValue(content.first!.key)

    guard path._hash == hash else {
      effect.setModified()
      return _mergeKeyValPairAndCollisionNode(item, path, self, hash)
    }

    if let offset = content.firstIndex(where: { item.key == $0.key }) {
      var updatedContent: [Element] = []
      updatedContent.reserveCapacity(content.count + 1)
      updatedContent.append(contentsOf: content[0..<offset])
      updatedContent.append(item)
      updatedContent.append(contentsOf: content[(offset+1)...])
      effect.setReplacedValue(previousValue: content[offset].value)
      return _Node(/* hash, */ collisions: updatedContent)
    } else {
      effect.setModified()
      return _Node(/* hash, */ collisions: content + [item])
    }
  }

  final func removeOrRemoving(
    _ isUnique: Bool,
    _ key: Key,
    _ path: _HashPath,
    _ effect: inout _DictionaryEffect<Value>
  ) -> _Node {

    guard isRegularNode else {
      return _removeOrRemovingCollision(isUnique, key, path, &effect)
    }

    let bucket = path.currentBucket

    if dataMap.contains(bucket) {
      let offset = dataMap.offset(of: bucket)
      let item0 = self.getPayload(offset)
      guard item0.key == key else {
        assert(self.invariant)
        return self
      }

      effect.setModified(previousValue: item0.value)
      if self.payloadArity == 2, self.nodeArity == 0 {
        if path.isAtRoot {
          // keep remaining item on root level
          var newDataMap = dataMap
          newDataMap.remove(bucket)
          let remaining = getPayload(1 - offset)
          return _Node(dataMap: newDataMap, remaining)
        }
        // create potential new root: will a) become new root, or b) inlined
        // on another level
        let remaining = getPayload(1 - offset)
        return _Node(remaining, at: path.top().currentBucket)
      }

      if
        self.payloadArity == 1,
        self.nodeArity == 1,
        self.getNode(0).isCollisionNode
      {
        // escalate hash-collision node
        return getNode(0)
      }
      return _copyAndRemoveValue(isUnique, bucket)
    }

    if trieMap.contains(bucket) {
      let offset = trieMap.offset(of: bucket)
      let isChildUnique = self.isTrieNodeKnownUniquelyReferenced(offset, isUnique)

      let subNode = self.getNode(offset)

      let subNodeNew = subNode.removeOrRemoving(
        isChildUnique, key, path.descend(), &effect)
      guard effect.modified, subNode !== subNodeNew else {
        if effect.modified { count -= 1 }
        assert(self.invariant)
        return self
      }

      assert(subNodeNew.count > 0, "Sub-node must have at least one element.")
      if subNodeNew.count == 1 {
        if self.isCandiateForCompaction {
          // escalate singleton
          return subNodeNew
        }
        // inline singleton
        return _copyAndMigrateFromNodeToInline(
          isUnique, bucket, subNodeNew.getPayload(0))
      }

      if subNodeNew.isCollisionNode, self.isCandiateForCompaction {
        // escalate singleton
        return subNodeNew
      }
      // modify current node (set replacement node)
      return _copyAndSetTrieNode(
        isUnique,
        bucket,
        offset,
        subNodeNew,
        updateCount: { $0 -= 1 })
    }

    return self
  }

  @inline(never)
  final func _removeOrRemovingCollision(
    _ isUnique: Bool,
    _ key: Key,
    _ path: _HashPath,
    _ effect: inout _DictionaryEffect<Value>
  ) -> _Node {
    assert(isCollisionNode)

    let content: [Element] = Array(self)

    guard let index = content.firstIndex(where: { key == $0.key }) else {
      return self
    }
    effect.setModified(previousValue: content[index].value)
    var updatedContent = content
    updatedContent.remove(at: index)

    if updatedContent.count == 1 {
      // create potential new root: will a) become new root, or b) inlined
      // on another level
      let remaining = updatedContent.first!
      return _Node(remaining, at: path.top().currentBucket)
    }
    return _Node(/* hash, */ collisions: updatedContent)
  }
}

extension PersistentDictionary._Node {
  func item(position: Int) -> Element {
    assert(position >= 0 && position < count)
    let counts = self._counts

    var b = 0
    var skipped = 0
    while b < counts.count {
      let c = skipped + counts[b]
      if c > position { break }
      skipped = c
      b += 1
    }
    let bucket = _Bucket(UInt(bitPattern: b))

    if dataMap.contains(bucket) {
      assert(skipped == position)
      let offset = dataMap.offset(of: bucket)
      return self.getPayload(offset)
    }

    precondition(trieMap.contains(bucket))
    assert(skipped <= position && skipped + counts[b] > position)
    return self
      .getNode(trieMap.offset(of: bucket))
      .item(position: position - skipped)
  }
}

extension PersistentDictionary._Node {
  func _mergeTwoKeyValPairs(
    _ item0: Element, _ path0: _HashPath,
    _ item1: Element, _ hash1: _HashValue
  ) -> _Node {
    let path1 = _HashPath(_hash: hash1, shift: path0._shift)
    return _mergeTwoKeyValPairs(item0, path0, item1, path1)
  }

  func _mergeTwoKeyValPairs(
    _ item0: Element, _ path0: _HashPath,
    _ item1: Element, _ path1: _HashPath
  ) -> _Node {
    assert(path0._hash != path1._hash)
    assert(path0._shift == path1._shift)

    let bucket0 = path0.currentBucket
    let bucket1 = path1.currentBucket

    if bucket0 != bucket1 {
      // unique prefixes, payload fits on same level
      return _Node(
        item0, at: bucket0,
        item1, at: bucket1)
    }
    // recurse: identical prefixes, payload must be disambiguated deeper
    // in the trie
    let node = _mergeTwoKeyValPairs(
      item0, path0.descend(),
      item1, path1.descend())

    return _Node(node, at: bucket0)
  }

  final func _mergeKeyValPairAndCollisionNode(
    _ item0: Element, _ path0: _HashPath,
    _ node1: _Node, _ hash1: _HashValue
  ) -> _Node {
    let path1 = _HashPath(_hash: hash1, shift: path0._shift)
    return _mergeKeyValPairAndCollisionNode(item0, path0, node1, path1)
  }

  final func _mergeKeyValPairAndCollisionNode(
    _ item0: Element, _ path0: _HashPath,
    _ node1: _Node, _ path1: _HashPath
  ) -> _Node {
    assert(path0._hash != path1._hash)
    assert(path0._shift == path1._shift)

    let bucket0 = path0.currentBucket
    let bucket1 = path1.currentBucket

    if bucket0 != bucket1 {
      // unique prefixes, payload and collision node fit on same level
      return _Node(item0, at: bucket0, node1, at: bucket1)
    }

    // recurse: identical prefixes, payload must be disambiguated deeper in the trie
    let node = _mergeKeyValPairAndCollisionNode(
      item0, path0.descend(),
      node1, path1.descend())

    return _Node(node, at: bucket0)
  }

  final func _count(upTo bucket: _Bucket) -> Int {
    let dataCount = dataMap.intersection(_Bitmap(upTo: bucket)).count
    let trieCount = trieMap.intersection(_Bitmap(upTo: bucket)).count

    let buffer = UnsafeMutableBufferPointer(
      start: trieBaseAddress, count: header.trieCount)
    let children = buffer.prefix(upTo: trieCount).map { $0.count }.reduce(0, +)

    return dataCount + children
  }

  final var _counts: [Int] {
    var counts = Array(repeating: 0, count: _Bitmap.capacity)

    for bucket in dataMap {
      counts[Int(bitPattern: bucket.value)] = 1
    }

    for (bucket, trieNode) in zip(trieMap, _trieSlice) {
      counts[Int(bitPattern: bucket.value)] = trieNode.count
    }

    return counts
  }

  func _copyAndSetValue(
    _ isUnique: Bool, _ bucket: _Bucket, _ newValue: Value
  ) -> _Node {
    let src: _Node = self
    let dst: _Node

    if isUnique {
      dst = src
    } else {
      dst = src.copy()
    }

    let offset = dataMap.offset(of: bucket)

    dst.dataBaseAddress[offset].value = newValue

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  private func _copyAndSetTrieNode(
    _ isUnique: Bool,
    _ bucket: _Bucket,
    _ offset: Int,
    _ newNode: _Node,
    updateCount: (inout Int) -> Void
  ) -> _Node {
    let src: _Node = self
    let dst: _Node

    if isUnique {
      dst = src
    } else {
      dst = src.copy()
    }

    dst.trieBaseAddress[offset] = newNode

    // update metadata: `dataMap, nodeMap, collMap`
    updateCount(&dst.count)

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func _copyAndInsertValue(
    _ isUnique: Bool,
    _ bucket: _Bucket,
    _ item: Element
  ) -> _Node {
    let src: _Node = self
    let dst: _Node

    let hasRoomForData = header.dataCount < dataCapacity

    if isUnique && hasRoomForData {
      dst = src
    } else {
      dst = src.copy(withDataCapacityFactor: hasRoomForData ? 1 : 2)
    }

    let offset = dst.dataMap.offset(of: bucket)
    _rangeInsert(
      item,
      at: offset,
      into: dst.dataBaseAddress,
      count: dst.header.dataCount)

    dst.header.dataMap.insert(bucket)
    dst.count += 1

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func _copyAndRemoveValue(_ isUnique: Bool, _ bucket: _Bucket) -> _Node {
    assert(dataMap.contains(bucket))
    let src: _Node = self
    let dst: _Node

    if isUnique {
      dst = src
    } else {
      dst = src.copy()
    }

    let dataOffset = dst.dataMap.offset(of: bucket)
    _rangeRemove(
      at: dataOffset, from: dst.dataBaseAddress, count: dst.header.dataCount)

    // update metadata: `dataMap ^ bitpos, nodeMap, collMap`
    dst.header.dataMap.remove(bucket)
    dst.count -= 1

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func _copyAndMigrateFromInlineToNode(
    _ isUnique: Bool, _ bucket: _Bucket, _ node: _Node
  ) -> _Node {
    assert(dataMap.contains(bucket))
    let src: _Node = self
    let dst: _Node

    let hasRoomForTrie = header.trieCount < trieCapacity

    if isUnique && hasRoomForTrie {
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

    let dataOffset = dst.dataMap.offset(of: bucket)
    _rangeRemove(
      at: dataOffset, from: dst.dataBaseAddress, count: dst.header.dataCount)

    let trieOffset = dst.trieMap.offset(of: bucket)
    _rangeInsert(
      node, at: trieOffset,
      into: dst.trieBaseAddress, count: dst.header.trieCount)

    // update metadata: `dataMap ^ bitpos, nodeMap | bitpos, collMap`
    dst.header.dataMap.remove(bucket)
    dst.header.trieMap.insert(bucket)
    dst.count += 1 // assuming that `node.count == 2`

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func _copyAndMigrateFromNodeToInline(
    _ isUnique: Bool, _ bucket: _Bucket, _ item: Element
  ) -> _Node {
    assert(trieMap.contains(bucket))
    let src: _Node = self
    let dst: _Node

    let hasRoomForData = header.dataCount < dataCapacity

    if isUnique && hasRoomForData {
      dst = src
    } else {
      dst = src.copy(withDataCapacityFactor: hasRoomForData ? 1 : 2)
    }

    let nodeOffset = dst.trieMap.offset(of: bucket)
    _rangeRemove(
      at: nodeOffset, from: dst.trieBaseAddress, count: dst.header.trieCount)

    let dataOffset = dst.dataMap.offset(of: bucket)
    _rangeInsert(
      item, at: dataOffset,
      into: dst.dataBaseAddress, count: dst.header.dataCount)

    // update metadata: `dataMap | bitpos, nodeMap ^ bitpos, collMap`
    dst.header.dataMap.insert(bucket)
    dst.header.trieMap.remove(bucket)
    dst.count -= 1 // assuming that updated `node.count == 1`

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }
}

// TODO: `Equatable` needs more test coverage, apart from hash-collision smoke test
extension PersistentDictionary._Node: Equatable where Value: Equatable {
  static func == (lhs: _Node, rhs: _Node) -> Bool {
    if lhs.isCollisionNode && rhs.isCollisionNode {
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
