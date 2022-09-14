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
  /// Insert `item` at `offset` corresponding to `bucket`.
  /// There must be enough free space in the node to fit the new item.
  ///
  /// `itemMap` must not already reflect the insertion at the time this
  /// function is called. This method does not update `itemMap`.
  @inlinable
  internal func _insertItem(_ item: __owned Element, at offset: Int) {
    assertMutable()
    let count = itemCount
    assert(offset >= 0 && offset <= count)

    let stride = MemoryLayout<Element>.stride
    assert(bytesFree >= stride)
    bytesFree &-= stride

    let start = _memory
      .advanced(by: byteCapacity &- (count &+ 1) &* stride)
      .bindMemory(to: Element.self, capacity: count &+ 1)

    start.moveInitialize(from: start + 1, count: offset)
    (start + offset).initialize(to: item)
  }

  /// Insert `child` at `offset`. There must be enough free space in the node
  /// to fit the new child.
  ///
  /// `childMap` must not yet reflect the insertion at the time this
  /// function is called. This method does not update `childMap`.
 @inlinable
  internal func _insertChild(_ child: __owned _Node, at offset: Int) {
    assertMutable()
    assert(!isCollisionNode)

    let c = childMap.count
    assert(offset >= 0 && offset <= c)

    let stride = MemoryLayout<_Node>.stride
    assert(bytesFree >= stride)
    bytesFree &-= stride

    _memory.bindMemory(to: _Node.self, capacity: c &+ 1)
    let q = _childrenStart + offset
    (q + 1).moveInitialize(from: q, count: c &- offset)
    q.initialize(to: child)
  }

  /// Remove and return the item at `offset`, increasing the amount of free
  /// space available in the node.
  ///
  /// `itemMap` must not yet reflect the removal at the time this
  /// function is called. This method does not update `itemMap`.
  @inlinable
  internal func _removeItem(at offset: Int) -> Element {
    assertMutable()
    let count = itemCount
    assert(offset >= 0 && offset < count)
    let stride = MemoryLayout<Element>.stride
    bytesFree &+= stride

    let start = _memory
      .advanced(by: byteCapacity &- stride &* count)
      .assumingMemoryBound(to: Element.self)

    let q = start + offset
    let item = q.move()
    (start + 1).moveInitialize(from: start, count: offset)
    return item
  }

  /// Remove and return the child at `offset`, increasing the amount of free
  /// space available in the node.
  ///
  /// `childMap` must not yet reflect the removal at the time this
  /// function is called. This method does not update `childMap`.
  @inlinable
  internal func _removeChild(at offset: Int) -> _Node {
    assertMutable()
    assert(!isCollisionNode)
    let count = childCount
    assert(offset >= 0 && offset < count)

    bytesFree &+= MemoryLayout<_Node>.stride

    let q = _childrenStart + offset
    let child = q.move()
    q.moveInitialize(from: q + 1, count: count &- 1 &- offset)
    return child
  }
}

extension _Node {
  @inlinable
  internal mutating func insertItem(
    _ item: __owned Element, _ bucket: _Bucket
  ) {
    let offset = read { $0.itemMap.offset(of: bucket) }
    self.insertItem(item, at: offset, bucket)
  }

  /// Insert `item` at `offset` corresponding to `bucket`.
  /// There must be enough free space in the node to fit the new item.
  @inlinable
  internal mutating func insertItem(
    _ item: __owned Element, at offset: Int, _ bucket: _Bucket
  ) {
    self.count &+= 1
    update {
      $0._insertItem(item, at: offset)
      if $0.isCollisionNode {
        assert(bucket.isInvalid)
        $0.collisionCount &+= 1
      } else {
        assert(!$0.itemMap.contains(bucket))
        assert(!$0.childMap.contains(bucket))
        $0.itemMap.insert(bucket)
        assert($0.itemMap.offset(of: bucket) == offset)
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

      let offset = $0.childMap.offset(of: bucket)
      $0._insertChild(child, at: offset)
      $0.childMap.insert(bucket)
    }
  }

  /// Remove and return the item at `offset`, increasing the amount of free
  /// space available in the node.
  @inlinable
  internal mutating func removeItem(
    at offset: Int, _ bucket: _Bucket
  ) -> Element {
    defer { _invariantCheck() }
    assert(count > 0)
    count &-= 1
    return update {
      let old = $0._removeItem(at: offset)
      if $0.isCollisionNode {
        assert(bucket.isInvalid)
        assert(offset >= 0 && offset < $0.collisionCount)
        $0.collisionCount &-= 1
      } else {
        assert($0.itemMap.contains(bucket))
        assert($0.itemMap.offset(of: bucket) == offset)
        $0.itemMap.remove(bucket)
      }
      return old
    }
  }

  @inlinable
  internal mutating func removeChild(
    at offset: Int, _ bucket: _Bucket
  ) -> _Node {
    defer { _invariantCheck() }
    assert(!isCollisionNode)
    let child = update {
      assert($0.childMap.contains(bucket))
      assert($0.childMap.offset(of: bucket) == offset)
      let child = $0._removeChild(at: offset)
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
      let old = $0._removeItem(at: 0)
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
      let child = $0._removeChild(at: 0)
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
    case .found(_, let offset):
      ensureUnique(isUnique: isUnique)
      _invariantCheck() // FIXME
      return update {
        let p = $0.itemPtr(at: offset)
        let old = p.pointee.value
        p.pointee.value = value
        return old
      }
    case .notFound(let bucket, let offset):
      ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewItem)
      insertItem((key, value), at: offset, bucket)
      return nil
    case .newCollision(let bucket, let offset):
      let hash2 = read { _Hash($0[item: offset].key) }
      if hash == hash2, hasSingletonItem {
        // Convert current node to a collision node.
        ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewItem)
        update { $0.collisionCount = 1 }
        insertItem((key, value), at: 0, .invalid)
      } else {
        ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewCollision)
        let item2 = removeItem(at: offset, bucket)
        let node = _Node(
          level: level.descend(),
          item1: (key, value), hash,
          item2: item2, hash2)
        insertChild(node, bucket)
      }
      return nil
    case .expansion(let collisionHash):
      self = Self(
        level: level,
        item1: (key, value), hash,
        child2: self, collisionHash)
      return nil
    case .descend(_, let offset):
      ensureUnique(isUnique: isUnique)
      let old = update {
        $0[child: offset].updateValue(value, forKey: key, level.descend(), hash)
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
    case .found(let bucket, let offset):
      let old = removeItem(at: offset, bucket)
      if isAtrophied {
        self = removeSingletonChild()
      }
      return old
    case .notFound, .newCollision, .expansion:
      return nil
    case .descend(let bucket, let offset):
      let (old, needsInlining) = update {
        let child = $0.childPtr(at: offset)
        let old = child.pointee.remove(key, level.descend(), hash)
        guard old != nil else { return (old, false) }
        let needsInlining = child.pointee.hasSingletonItem
        return (old, needsInlining)
      }
      guard old != nil else { return nil }
      count &-= 1
      if needsInlining {
        ensureUnique(isUnique: true, withFreeSpace: Self.spaceForInlinedChild)
        var child = self.removeChild(at: offset, bucket)
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
  internal func removing(
    _ key: Key, _ level: _Level, _ hash: _Hash
  ) -> (replacement: _Node, old: Element)? {
    let r = find(level, key, hash, forInsert: false)
    switch r {
    case .found(let bucket, let offset):
      // Don't copy the node if we'd immediately discard it.
      let willAtrophy = read {
        $0.itemCount == 1 && $0.childCount == 1 && $0[child: 0].isCollisionNode
      }
      if willAtrophy {
        return read { ($0[child: 0], $0[item: 0]) }
      }
      var node = self.copy()
      let old = node.removeItem(at: offset, bucket)
      node._invariantCheck()
      return (node, old)
    case .notFound, .newCollision, .expansion:
      return nil
    case .descend(let bucket, let offset):
      let r = read { $0[child: offset].removing(key, level.descend(), hash) }
      guard var r = r else { return nil }
      if r.replacement.hasSingletonItem {
        var node = copy(withFreeSpace: Self.spaceForInlinedChild)
        _ = node.removeChild(at: offset, bucket)
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
      node.update { $0[child: offset] = r.replacement }
      node.count &-= 1
      node._invariantCheck()
      return (node, r.old)
    }
  }
}
