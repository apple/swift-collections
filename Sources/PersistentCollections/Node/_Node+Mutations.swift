//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// MARK: Node-level mutation operations

extension _Node.UnsafeHandle {
  /// Insert `item` at `slot` corresponding to `bucket`.
  /// There must be enough free space in the node to fit the new item.
  ///
  /// `itemMap` must not already reflect the insertion at the time this
  /// function is called. This method does not update `itemMap`.
  @inlinable
  internal func _insertItem(_ item: __owned Element, at slot: _Slot) {
    assertMutable()
    let c = itemCount
    assert(slot.value <= c)

    let stride = MemoryLayout<Element>.stride
    assert(bytesFree >= stride)
    bytesFree &-= stride

    let start = _memory
      .advanced(by: byteCapacity &- (c &+ 1) &* stride)
      .bindMemory(to: Element.self, capacity: 1)

    let prefix = c &- slot.value
    start.moveInitialize(from: start + 1, count: prefix)
    (start + prefix).initialize(to: item)
  }

  /// Insert `child` at `slot`. There must be enough free space in the node
  /// to fit the new child.
  ///
  /// `childMap` must not yet reflect the insertion at the time this
  /// function is called. This method does not update `childMap`.
 @inlinable
  internal func _insertChild(_ child: __owned _Node, at slot: _Slot) {
    assertMutable()
    assert(!isCollisionNode)

    let c = childMap.count
    assert(slot.value <= c)

    let stride = MemoryLayout<_Node>.stride
    assert(bytesFree >= stride)
    bytesFree &-= stride

    _memory.bindMemory(to: _Node.self, capacity: c &+ 1)
    let q = _childrenStart + slot.value
    (q + 1).moveInitialize(from: q, count: c &- slot.value)
    q.initialize(to: child)
  }

  /// Remove and return the item at `slot`, increasing the amount of free
  /// space available in the node.
  ///
  /// `itemMap` must not yet reflect the removal at the time this
  /// function is called. This method does not update `itemMap`.
  @inlinable
  internal func _removeItem(at slot: _Slot) -> Element {
    assertMutable()
    let c = itemCount
    assert(slot.value < c)
    let stride = MemoryLayout<Element>.stride
    bytesFree &+= stride

    let start = _memory
      .advanced(by: byteCapacity &- stride &* c)
      .assumingMemoryBound(to: Element.self)

    let prefix = c &- 1 &- slot.value
    let q = start + prefix
    let item = q.move()
    (start + 1).moveInitialize(from: start, count: prefix)
    return item
  }

  /// Remove and return the child at `slot`, increasing the amount of free
  /// space available in the node.
  ///
  /// `childMap` must not yet reflect the removal at the time this
  /// function is called. This method does not update `childMap`.
  @inlinable
  internal func _removeChild(at slot: _Slot) -> _Node {
    assertMutable()
    assert(!isCollisionNode)
    let count = childCount
    assert(slot.value < count)

    bytesFree &+= MemoryLayout<_Node>.stride

    let q = _childrenStart + slot.value
    let child = q.move()
    q.moveInitialize(from: q + 1, count: count &- 1 &- slot.value)
    return child
  }
}

extension _Node {
  @inlinable
  internal mutating func insertItem(
    _ item: __owned Element, _ bucket: _Bucket
  ) {
    let slot = read { $0.itemMap.slot(of: bucket) }
    self.insertItem(item, at: slot, bucket)
  }

  /// Insert `item` at `slot` corresponding to `bucket`.
  /// There must be enough free space in the node to fit the new item.
  @inlinable
  internal mutating func insertItem(
    _ item: __owned Element, at slot: _Slot, _ bucket: _Bucket
  ) {
    self.count &+= 1
    update {
      $0._insertItem(item, at: slot)
      if $0.isCollisionNode {
        assert(bucket.isInvalid)
        $0.collisionCount &+= 1
      } else {
        assert(!$0.itemMap.contains(bucket))
        assert(!$0.childMap.contains(bucket))
        $0.itemMap.insert(bucket)
        assert($0.itemMap.slot(of: bucket) == slot)
      }
    }
  }

  /// Insert `child` in `bucket`. There must be enough free space in the
  /// node to fit the new child.
  @inlinable
  internal mutating func insertChild(
    _ child: __owned _Node, _ bucket: _Bucket
  ) {
    count &+= child.count
    update {
      assert(!$0.isCollisionNode)
      assert(!$0.itemMap.contains(bucket))
      assert(!$0.childMap.contains(bucket))

      let slot = $0.childMap.slot(of: bucket)
      $0._insertChild(child, at: slot)
      $0.childMap.insert(bucket)
    }
  }

  /// Remove and return the item at `slot`, increasing the amount of free
  /// space available in the node.
  @inlinable
  internal mutating func removeItem(
    at slot: _Slot, _ bucket: _Bucket
  ) -> Element {
    defer { _invariantCheck() }
    assert(count > 0)
    count &-= 1
    return update {
      let old = $0._removeItem(at: slot)
      if $0.isCollisionNode {
        assert(bucket.isInvalid)
        assert(slot.value < $0.collisionCount)
        $0.collisionCount &-= 1
      } else {
        assert($0.itemMap.contains(bucket))
        assert($0.itemMap.slot(of: bucket) == slot)
        $0.itemMap.remove(bucket)
      }
      return old
    }
  }

  @inlinable
  internal mutating func removeChild(
    at slot: _Slot, _ bucket: _Bucket
  ) -> _Node {
    defer { _invariantCheck() }
    assert(!isCollisionNode)
    let child = update {
      assert($0.childMap.contains(bucket))
      assert($0.childMap.slot(of: bucket) == slot)
      let child = $0._removeChild(at: slot)
      $0.childMap.remove(bucket)
      return child
    }
    assert(self.count >= child.count)
    self.count &-= child.count
    return child
  }

  @inlinable
  internal mutating func removeSingletonItem() -> Element {
    defer { _invariantCheck() }
    assert(count == 1)
    count = 0
    return update {
      assert($0.itemCount == 1 && $0.childCount == 0)
      let old = $0._removeItem(at: .zero)
      $0.itemMap = .empty
      $0.childMap = .empty
      return old
    }
  }

  @inlinable
  internal mutating func removeSingletonChild() -> _Node {
    defer { _invariantCheck() }
    let child = update {
      assert($0.itemCount == 0 && $0.childCount == 1)
      let child = $0._removeChild(at: .zero)
      $0.childMap = .empty
      return child
    }
    assert(self.count == child.count)
    self.count = 0
    return child
  }
}

// MARK: Subtree-level mutation operations

extension _Node {
  @inlinable
  internal mutating func updateValue(
    _ value: __owned Value,
    forKey key: Key,
    _ level: _Level,
    _ hash: _Hash
  ) -> Value? {
    defer { _invariantCheck() }
    let isUnique = self.isUnique()
    let r = find(level, key, hash, forInsert: true)
    switch r {
    case .found(_, let slot):
      ensureUnique(isUnique: isUnique)
      _invariantCheck() // FIXME
      return update {
        let p = $0.itemPtr(at: slot)
        let old = p.pointee.value
        p.pointee.value = value
        return old
      }
    case .notFound(let bucket, let slot):
      ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewItem)
      insertItem((key, value), at: slot, bucket)
      return nil
    case .newCollision(let bucket, let slot):
      let existingHash = read { _Hash($0[item: slot].key) }
      if hash == existingHash, hasSingletonItem {
        // Convert current node to a collision node.
        ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewItem)
        update { $0.collisionCount = 1 }
        insertItem((key, value), at: _Slot(1), .invalid)
      } else {
        ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewCollision)
        let existing = removeItem(at: slot, bucket)
        let node = _Node(
          level: level.descend(),
          item1: existing, existingHash,
          item2: (key, value), hash)
        insertChild(node, bucket)
      }
      return nil
    case .expansion(let collisionHash):
      self = Self(
        level: level,
        item1: (key, value), hash,
        child2: self, collisionHash)
      return nil
    case .descend(_, let slot):
      ensureUnique(isUnique: isUnique)
      let old = update {
        $0[child: slot].updateValue(value, forKey: key, level.descend(), hash)
      }
      if old == nil { count &+= 1 }
      return old
    }
  }
}

extension _Node {
  /// Remove the item with the specified key from this subtree and return it.
  ///
  /// This function may leave `self` containing a singleton item.
  /// It is up to the caller to detect this situation & correct it when needed,
  /// by inlining the remaining item into the parent node.
  @inlinable
  internal mutating func remove(
    _ key: Key, _ level: _Level, _ hash: _Hash
  ) -> Element? {
    defer { _invariantCheck() }
    guard self.isUnique() else {
      guard let r = removing(key, level, hash) else { return nil }
      self = r.replacement
      return r.old
    }
    let r = find(level, key, hash, forInsert: false)
    switch r {
    case .found(let bucket, let slot):
      let old = removeItem(at: slot, bucket)
      if isAtrophied {
        self = removeSingletonChild()
      }
      if level.isAtRoot, isCollisionNode, hasSingletonItem {
        self._convertToRegularNode()
      }
      return old
    case .notFound, .newCollision, .expansion:
      return nil
    case .descend(let bucket, let slot):
      let (old, needsInlining) = update {
        let child = $0.childPtr(at: slot)
        let old = child.pointee.remove(key, level.descend(), hash)
        guard old != nil else { return (old, false) }
        let needsInlining = child.pointee.hasSingletonItem
        return (old, needsInlining)
      }
      guard old != nil else { return nil }
      count &-= 1
      if needsInlining {
        ensureUnique(isUnique: true, withFreeSpace: Self.spaceForInlinedChild)
        var child = self.removeChild(at: slot, bucket)
        let item = child.removeSingletonItem()
        insertItem(item, bucket)
      }
      if isAtrophied {
        self = removeSingletonChild()
      }
      return old
    }
  }

  @inlinable
  internal mutating func _convertToRegularNode() {
    assert(isCollisionNode && hasSingletonItem)
    assert(isUnique())
    update {
      let hash = _Hash($0[item: .zero].key)
      $0.itemMap = _Bitmap(hash[.top])
      $0.childMap = .empty
    }
  }

  @inlinable
  internal func removing(
    _ key: Key, _ level: _Level, _ hash: _Hash
  ) -> (replacement: _Node, old: Element)? {
    let r = find(level, key, hash, forInsert: false)
    switch r {
    case .found(let bucket, let slot):
      // Don't copy the node if we'd immediately discard it.
      let willAtrophy = read {
        $0.itemCount == 1
        && $0.childCount == 1
        && $0[child: .zero].isCollisionNode
      }
      if willAtrophy {
        return read { ($0[child: .zero], $0[item: .zero]) }
      }
      var node = self.copy()
      let old = node.removeItem(at: slot, bucket)
      if level.isAtRoot, node.isCollisionNode, node.hasSingletonItem {
        node._convertToRegularNode()
      }
      node._invariantCheck()
      return (node, old)
    case .notFound, .newCollision, .expansion:
      return nil
    case .descend(let bucket, let slot):
      let r = read { $0[child: slot].removing(key, level.descend(), hash) }
      guard var r = r else { return nil }
      if r.replacement.hasSingletonItem {
        var node = copy(withFreeSpace: Self.spaceForInlinedChild)
        _ = node.removeChild(at: slot, bucket)
        let item = r.replacement.removeSingletonItem()
        node.insertItem(item, bucket)
        node._invariantCheck()
        return (node, r.old)
      }
      if r.replacement.isCollisionNode && self.hasSingletonChild {
        // Don't return an atrophied node.
        return (r.replacement, r.old)
      }
      var node = copy()
      node.update { $0[child: slot] = r.replacement }
      node.count &-= 1
      node._invariantCheck()
      return (node, r.old)
    }
  }
}
