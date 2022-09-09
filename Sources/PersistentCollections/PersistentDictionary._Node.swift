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
  internal var itemMap: _Bitmap
  internal var childMap: _Bitmap

  init(itemMap: _Bitmap, childMap: _Bitmap) {
    self.itemMap = itemMap
    self.childMap = childMap
  }
}

extension _NodeHeader {
  internal var isCollisionNode: Bool {
    !itemMap.intersection(childMap).isEmpty
  }

  internal var itemCount: Int {
    isCollisionNode ? Int(itemMap._value) : itemMap.count
  }

  internal var childCount: Int {
    isCollisionNode ? 0 : childMap.count
  }
}

extension _NodeHeader: Equatable {
  internal static func == (lhs: _NodeHeader, rhs: _NodeHeader) -> Bool {
    lhs.itemMap == rhs.itemMap && lhs.childMap == rhs.childMap
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

    let itemCapacity: Capacity
    let childCapacity: Capacity

    let itemBaseAddress: UnsafeMutablePointer<Element>
    let childBaseAddress: UnsafeMutablePointer<_Node>

    deinit {
      itemBaseAddress.deinitialize(count: header.itemCount)
      childBaseAddress.deinitialize(count: header.childCount)

      rootBaseAddress.deallocate()
    }

    init(itemCapacity: Capacity, childCapacity: Capacity) {
      let (itemBaseAddress, childBaseAddress) = _Node._allocate(
        itemCapacity: itemCapacity,
        childCapacity: childCapacity)

      self.header = _NodeHeader(itemMap: .empty, childMap: .empty)
      self.count = 0

      self.itemBaseAddress = itemBaseAddress
      self.childBaseAddress = childBaseAddress

      self.itemCapacity = itemCapacity
      self.childCapacity = childCapacity

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
    itemCapacity: Capacity, childCapacity: Capacity
  ) -> (
    itemBaseAddress: UnsafeMutablePointer<Element>,
    childBaseAddress: UnsafeMutablePointer<_Node>
  ) {
    let itemBytes = Int(itemCapacity) * MemoryLayout<Element>.stride
    let childBytes = Int(childCapacity) * MemoryLayout<_Node>.stride

    let alignment = Swift.max(
      MemoryLayout<Element>.alignment,
      MemoryLayout<_Node>.alignment)
    let memory = UnsafeMutableRawPointer.allocate(
      byteCount: itemBytes + childBytes,
      alignment: alignment)

    let itemBaseAddress = memory
      .advanced(by: childBytes)
      .bindMemory(to: Element.self, capacity: Int(itemCapacity))
    let childBaseAddress = memory
      .bindMemory(to: _Node.self, capacity: Int(childCapacity))

    return (itemBaseAddress, childBaseAddress)
  }

  func copy(
    itemCapacityGrowthFactor itemGrowthFactor: Capacity = 1,
    itemCapacityShrinkFactor itemShrinkFactor: Capacity = 1,
    childCapacityGrowthFactor childGrowthFactor: Capacity = 1,
    childCapacityShrinkFactor childShrinkFactor: Capacity = 1
  ) -> _Node {
    let src = self
    let dc = src.itemCapacity &* itemGrowthFactor / itemShrinkFactor
    let tc = src.childCapacity &* childGrowthFactor / childShrinkFactor
    let dst = _Node(itemCapacity: dc, childCapacity: tc)

    dst.header = src.header
    dst.count = src.count

    dst.itemBaseAddress.initialize(
      from: src.itemBaseAddress,
      count: src.header.itemCount)
    dst.childBaseAddress.initialize(
      from: src.childBaseAddress,
      count: src.header.childCount)

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }
}

extension PersistentDictionary._Node {
  convenience init() {
    self.init(
      itemCapacity: _Node.initialDataCapacity,
      childCapacity: _Node.initialTrieCapacity)

    self.header = _NodeHeader(itemMap: .empty, childMap: .empty)

    assert(self.invariant)
  }

  convenience init(itemMap: _Bitmap, _ item: Element) {
    assert(itemMap.count == 1)
    self.init()
    self.header = _NodeHeader(itemMap: itemMap, childMap: .empty)
    self.count = 1
    self.itemBaseAddress.initialize(to: item)
    assert(self.invariant)
  }

  convenience init(_ item: Element, at bucket: _Bucket) {
    self.init(itemMap: _Bitmap(bucket), item)
  }

  convenience init(
    _ item0: Element, at bucket0: _Bucket,
    _ item1: Element, at bucket1: _Bucket
  ) {
    assert(bucket0 != bucket1)
    self.init()

    self.header = _NodeHeader(
      itemMap: _Bitmap(bucket0, bucket1),
      childMap: .empty)
    self.count = 2

    if bucket0 < bucket1 {
      self.itemBaseAddress.initialize(to: item0)
      self.itemBaseAddress.successor().initialize(to: item1)
    } else {
      self.itemBaseAddress.initialize(to: item1)
      self.itemBaseAddress.successor().initialize(to: item0)
    }
    assert(self.invariant)
  }

  convenience init(_ child: _Node, at bucket: _Bucket) {
    self.init()

    self.header = _NodeHeader(
      itemMap: .empty,
      childMap: _Bitmap(bucket))
    self.count = child.count

    self.childBaseAddress.initialize(to: child)

    assert(self.invariant)
  }

  convenience init(
    _ item: Element, at bucket0: _Bucket,
    _ child: _Node, at bucket1: _Bucket
  ) {
    assert(bucket0 != bucket1)
    self.init()

    self.header = _NodeHeader(
      itemMap: _Bitmap(bucket0),
      childMap: _Bitmap(bucket1))
    self.count = 1 + child.count

    self.itemBaseAddress.initialize(to: item)
    self.childBaseAddress.initialize(to: child)

    assert(self.invariant)
  }

  convenience init(collisions: [Element]) {
    self.init(itemCapacity: Capacity(collisions.count), childCapacity: 0)

    self.header = _NodeHeader(
      itemMap: _Bitmap(bitPattern: collisions.count),
      childMap: _Bitmap(bitPattern: collisions.count))
    self.count = collisions.count

    self.itemBaseAddress.initialize(from: collisions, count: collisions.count)

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
    UnsafeMutableRawPointer(childBaseAddress)
  }

  @inline(__always)
  var itemMap: _Bitmap {
    header.itemMap
  }

  @inline(__always)
  var childMap: _Bitmap {
    header.childMap
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

    guard count - itemCount >= 2 * childCount else {
      return false
    }

    if isCollisionNode {
      let hash = _HashValue(_items.first!.key)

      guard _items.allSatisfy({ _HashValue($0.key) == hash }) else {
        return false
      }
    }

    return true
  }

  var headerInvariant: Bool {
    header.itemMap.intersection(header.childMap).isEmpty
    || (header.itemMap == header.childMap)
  }

  var _items: UnsafeBufferPointer<Element> {
    UnsafeBufferPointer(start: itemBaseAddress, count: header.itemCount)
  }

  var _children: UnsafeMutableBufferPointer<_Node> {
    UnsafeMutableBufferPointer(start: childBaseAddress, count: header.childCount)
  }

  var isCandidateForCompaction: Bool { itemCount == 0 && childCount == 1 }

  func isChildUnique(
    at offset: Int, uniqueParent isParentUnique: Bool
  ) -> Bool {
    guard isParentUnique else { return false }
    return isKnownUniquelyReferenced(&_children[offset])
  }
}

extension PersistentDictionary._Node: _NodeProtocol {
  var hasChildren: Bool { !header.childMap.isEmpty }

  var childCount: Int { header.childCount }

  func child(at index: Int) -> _Node {
    childBaseAddress[index]
  }

  var hasItems: Bool { !header.itemMap.isEmpty }

  var itemCount: Int { header.itemCount }

  func item(at offset: Int) -> Element {
    _items[offset]
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

    if itemMap.contains(bucket) {
      let offset = itemMap.offset(of: bucket)
      let payload = self.item(at: offset)
      return key == payload.key ? payload.value : nil
    }

    if childMap.contains(bucket) {
      let offset = childMap.offset(of: bucket)
      return self.child(at: offset).get(key, path.descend())
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

    if itemMap.contains(bucket) {
      let offset = itemMap.offset(of: bucket)
      return key == self._items[offset].key
    }

    if childMap.contains(bucket) {
      let offset = childMap.offset(of: bucket)
      return self
        .child(at: offset)
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
        .firstIndex(where: { $0.key == key })
        .map { Index(_value: $0) }
    }

    let bucket = path.currentBucket

    if itemMap.contains(bucket) {
      let offset = itemMap.offset(of: bucket)
      let item = self.item(at: offset)
      guard key == item.key else { return nil }
      return Index(_value: skippedBefore + _count(upTo: bucket))
    }

    if childMap.contains(bucket) {
      let offset = childMap.offset(of: bucket)
      let skipped = skippedBefore + _count(upTo: bucket)
      return self
        .child(at: offset)
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
    if itemMap.contains(bucket) {
      let offset = itemMap.offset(of: bucket)
      let item0 = self.item(at: offset)

      if item0.key == item.key {
        effect.setReplacedValue(previousValue: item0.value)
        return _copyAndSetValue(isUnique, bucket, item.value)
      }
      let hash0 = _HashValue(item0.key)
      if hash0 == path._hash {
        let newChild = _Node(collisions: [item0, item])
        effect.setModified()
        if self.count == 1 { return newChild }
        return _copyAndMigrateFromInlineToNode(isUnique, bucket, newChild)
      }
      let newChild = _mergeTwoKeyValPairs(
        item, path.descend(),
        item0, hash0)
      effect.setModified()
      return _copyAndMigrateFromInlineToNode(isUnique, bucket, newChild)
    }

    if childMap.contains(bucket) {
      let offset = childMap.offset(of: bucket)
      let isUniqueChild = self.isChildUnique(at: offset, uniqueParent: isUnique)

      let oldChild = self.child(at: offset)

      let newChild = oldChild.updateOrUpdating(
        isUniqueChild, item, path.descend(), &effect)
      guard effect.modified, oldChild !== newChild else {
        if effect.previousValue == nil { count += 1 }
        assert(self.invariant)
        return self
      }

      return _copyAndSetTrieNode(
        isUnique,
        bucket,
        offset,
        newChild,
        updateCount: { $0 -= oldChild.count ; $0 += newChild.count })
    }

    effect.setModified()
    return _copyAndInsertValue(isUnique, bucket, item)
  }

  @inline(never)
  final func _updateOrUpdatingCollision(
    _ isUnique: Bool,
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
      updatedContent.append(contentsOf: content[0 ..< offset])
      updatedContent.append(item)
      updatedContent.append(contentsOf: content[(offset + 1)...])
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

    if itemMap.contains(bucket) {
      let offset = itemMap.offset(of: bucket)
      let item0 = self.item(at: offset)
      guard item0.key == key else {
        assert(self.invariant)
        return self
      }

      effect.setModified(previousValue: item0.value)
      if self.itemCount == 2, self.childCount == 0 {
        if path.isAtRoot {
          // keep remaining item on root level
          var newItemMap = itemMap
          newItemMap.remove(bucket)
          let remaining = item(at: 1 - offset)
          return _Node(itemMap: newItemMap, remaining)
        }
        // create potential new root: will a) become new root, or b) inlined
        // on another level
        let remaining = item(at: 1 - offset)
        return _Node(remaining, at: path.top().currentBucket)
      }

      if
        self.itemCount == 1,
        self.childCount == 1,
        self.child(at: 0).isCollisionNode
      {
        // escalate hash-collision node
        return child(at: 0)
      }
      return _copyAndRemoveValue(isUnique, bucket)
    }

    if childMap.contains(bucket) {
      let offset = childMap.offset(of: bucket)
      let isChildUnique = self.isChildUnique(at: offset, uniqueParent: isUnique)

      let oldChild = self.child(at: offset)

      let newChild = oldChild.removeOrRemoving(
        isChildUnique, key, path.descend(), &effect)
      guard effect.modified, oldChild !== newChild else {
        if effect.modified { count -= 1 }
        assert(self.invariant)
        return self
      }

      assert(newChild.count > 0, "Sub-node must have at least one element.")
      if newChild.count == 1 {
        if self.isCandidateForCompaction {
          // escalate singleton
          return newChild
        }
        // inline singleton
        return _copyAndMigrateFromNodeToInline(
          isUnique, bucket, newChild.item(at: 0))
      }

      if newChild.isCollisionNode, self.isCandidateForCompaction {
        // escalate singleton
        return newChild
      }
      // modify current node (set replacement node)
      return _copyAndSetTrieNode(
        isUnique, bucket, offset, newChild, updateCount: { $0 -= 1 })
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

    guard let offset = content.firstIndex(where: { key == $0.key }) else {
      return self
    }
    effect.setModified(previousValue: content[offset].value)
    var updatedContent = content
    updatedContent.remove(at: offset)

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

    if itemMap.contains(bucket) {
      assert(skipped == position)
      let offset = itemMap.offset(of: bucket)
      return self.item(at: offset)
    }

    precondition(childMap.contains(bucket))
    assert(skipped <= position && skipped + counts[b] > position)
    return self
      .child(at: childMap.offset(of: bucket))
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
    // in the prefix tree
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

    // recurse: identical prefixes, payload must be disambiguated deeper in the
    // prefix trie
    let node = _mergeKeyValPairAndCollisionNode(
      item0, path0.descend(),
      node1, path1.descend())

    return _Node(node, at: bucket0)
  }

  final func _count(upTo bucket: _Bucket) -> Int {
    let itemCount = itemMap.intersection(_Bitmap(upTo: bucket)).count
    let childCount = childMap.intersection(_Bitmap(upTo: bucket)).count

    let buffer = UnsafeMutableBufferPointer(
      start: childBaseAddress, count: header.childCount)
    let children = buffer.prefix(upTo: childCount).map { $0.count }.reduce(0, +)

    return itemCount + children
  }

  final var _counts: [Int] {
    var counts = Array(repeating: 0, count: _Bitmap.capacity)

    for bucket in itemMap {
      counts[Int(bitPattern: bucket.value)] = 1
    }

    for (bucket, trieNode) in zip(childMap, _children) {
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

    let offset = itemMap.offset(of: bucket)

    dst.itemBaseAddress[offset].value = newValue

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

    dst.childBaseAddress[offset] = newNode

    // update metadata: `itemMap, nodeMap, collMap`
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

    let hasRoomForItem = header.itemCount < itemCapacity

    if isUnique && hasRoomForItem {
      dst = src
    } else {
      dst = src.copy(itemCapacityGrowthFactor: hasRoomForItem ? 1 : 2)
    }

    let offset = dst.itemMap.offset(of: bucket)
    _rangeInsert(
      item,
      at: offset,
      into: dst.itemBaseAddress,
      count: dst.header.itemCount)

    dst.header.itemMap.insert(bucket)
    dst.count += 1

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func _copyAndRemoveValue(_ isUnique: Bool, _ bucket: _Bucket) -> _Node {
    assert(itemMap.contains(bucket))
    let src: _Node = self
    let dst: _Node

    if isUnique {
      dst = src
    } else {
      dst = src.copy()
    }

    let dataOffset = dst.itemMap.offset(of: bucket)
    _rangeRemove(
      at: dataOffset, from: dst.itemBaseAddress, count: dst.header.itemCount)

    // update metadata: `itemMap ^ bitpos, nodeMap, collMap`
    dst.header.itemMap.remove(bucket)
    dst.count -= 1

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func _copyAndMigrateFromInlineToNode(
    _ isUnique: Bool, _ bucket: _Bucket, _ node: _Node
  ) -> _Node {
    assert(itemMap.contains(bucket))
    let src: _Node = self
    let dst: _Node

    let hasRoomForChild = header.childCount < childCapacity

    if isUnique && hasRoomForChild {
      dst = src
    } else {
      // TODO reconsider the details of the heuristic
      //
      // Since copying is necessary, check if the data section can be reduced.
      // Keep at mininum the initial capacity.
      //
      // Notes currently can grow to a maximum size of 48 (tuple and sub-node)
      // slots.
      let itemsNeedShrinking = Swift.max(header.itemCount * 2 - 1, 4) < itemCapacity

      dst = src.copy(
        itemCapacityShrinkFactor: itemsNeedShrinking ? 2 : 1,
        childCapacityGrowthFactor: hasRoomForChild ? 1 : 2)
    }

    let itemOffset = dst.itemMap.offset(of: bucket)
    _rangeRemove(
      at: itemOffset, from: dst.itemBaseAddress, count: dst.header.itemCount)

    let childOffset = dst.childMap.offset(of: bucket)
    _rangeInsert(
      node, at: childOffset,
      into: dst.childBaseAddress, count: dst.header.childCount)

    // update metadata: `itemMap ^ bitpos, nodeMap | bitpos, collMap`
    dst.header.itemMap.remove(bucket)
    dst.header.childMap.insert(bucket)
    dst.count += 1 // assuming that `node.count == 2`

    assert(src.invariant)
    assert(dst.invariant)
    return dst
  }

  func _copyAndMigrateFromNodeToInline(
    _ isUnique: Bool, _ bucket: _Bucket, _ item: Element
  ) -> _Node {
    assert(childMap.contains(bucket))
    let src: _Node = self
    let dst: _Node

    let hasRoomForItem = header.itemCount < itemCapacity

    if isUnique && hasRoomForItem {
      dst = src
    } else {
      dst = src.copy(itemCapacityGrowthFactor: hasRoomForItem ? 1 : 2)
    }

    let childOffset = dst.childMap.offset(of: bucket)
    _rangeRemove(
      at: childOffset, from: dst.childBaseAddress, count: dst.header.childCount)

    let itemOffset = dst.itemMap.offset(of: bucket)
    _rangeInsert(
      item, at: itemOffset,
      into: dst.itemBaseAddress, count: dst.header.itemCount)

    // update metadata: `itemMap | bitpos, nodeMap ^ bitpos, collMap`
    dst.header.itemMap.insert(bucket)
    dst.header.childMap.remove(bucket)
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

    for index in 0..<lhs.itemCount {
      if lhs.item(at: index) != rhs.item(at: index) {
        return false
      }
    }

    for index in 0..<lhs.childCount {
      if lhs.child(at: index) != rhs.child(at: index) {
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
