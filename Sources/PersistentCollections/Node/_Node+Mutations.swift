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
  /// Make room for a new item at `slot` corresponding to `bucket`.
  /// There must be enough free space in the node to fit the new item.
  ///
  /// `itemMap` must not already reflect the insertion at the time this
  /// function is called. This method does not update `itemMap`.
  ///
  /// - Returns: an unsafe mutable pointer to uninitialized memory that is
  ///    ready to store the new item. It is the caller's responsibility to
  ///    initialize this memory.
  @inlinable
  internal func _makeRoomForNewItem(
    at slot: _Slot, _ bucket: _Bucket
  ) -> UnsafeMutablePointer<Element> {
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

    if bucket.isInvalid {
      assert(isCollisionNode)
      collisionCount &+= 1
    } else {
      assert(!itemMap.contains(bucket))
      assert(!childMap.contains(bucket))
      itemMap.insert(bucket)
      assert(itemMap.slot(of: bucket) == slot)
    }

    return start + prefix
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
  internal func _removeItem<R>(
    at slot: _Slot,
    by remover: (UnsafeMutablePointer<Element>) -> R
  ) -> R {
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
    defer {
      (start + 1).moveInitialize(from: start, count: prefix)
    }
    return remover(q)
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
  @inlinable @inline(__always)
  internal mutating func insertItem(
    _ item: __owned Element, _ bucket: _Bucket
  ) {
    let slot = read { $0.itemMap.slot(of: bucket) }
    self.insertItem(item, at: slot, bucket)
  }

  @inlinable @inline(__always)
  internal mutating func insertItem(
    _ item: __owned Element, at slot: _Slot, _ bucket: _Bucket
  ) {
    self.count &+= 1
    update {
      let p = $0._makeRoomForNewItem(at: slot, bucket)
      p.initialize(to: item)
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

  /// Remove the item at `slot`, increasing the amount of free
  /// space available in the node.
  ///
  /// The closure `remove` is called to perform the deinitialization of the
  /// storage slot corresponding to the item to be removed.
  @inlinable
  internal mutating func removeItem<R>(
    at slot: _Slot, _ bucket: _Bucket,
    by remover: (UnsafeMutablePointer<Element>) -> R
  ) -> R {
    defer { _invariantCheck() }
    assert(count > 0)
    count &-= 1
    return update {
      let old = $0._removeItem(at: slot, by: remover)
      if $0.isCollisionNode {
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
      let old = $0._removeItem(at: .zero) { $0.move() }
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
      _ = _insertNewCollision(
        isUnique: isUnique,
        level: level,
        for: hash,
        replacing: slot, bucket,
        inserter: { $0.initialize(to: (key, value)) })
      return nil
    case .expansion(let collisionHash):
      self = _Node.build(
        level: level,
        item1: { $0.initialize(to: (key, value)) }, hash,
        child2: self, collisionHash
      ).top
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

  @inlinable
  internal mutating func _insertNewCollision(
    isUnique: Bool,
    level: _Level,
    for hash: _Hash,
    replacing slot: _Slot, _ bucket: _Bucket,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (node: _UnmanagedNode, slot: _Slot) {
    let existingHash = read { _Hash($0[item: slot].key) }
    if hash == existingHash, hasSingletonItem {
      // Convert current node to a collision node.
      ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewItem)
      count &+= 1
      update {
        $0.collisionCount = 1
        let p = $0._makeRoomForNewItem(at: _Slot(1), .invalid)
        inserter(p)
      }
      return (unmanaged, _Slot(1))
    }
    ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewCollision)
    let existing = removeItem(at: slot, bucket) { $0.move() }
    let r = _Node.build(
      level: level.descend(),
      item1: existing, existingHash,
      item2: inserter, hash)
    insertChild(r.top, bucket)
    return (r.leaf, r.slot2)
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
      return _removeItemFromUniqueLeafNode(level, bucket, slot) { $0.move() }
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
      _fixupUniqueAncestorAfterItemRemoval(
        slot, { _ in bucket }, needsInlining: needsInlining)
      return old
    }
  }

  @inlinable
  internal mutating func _removeItemFromUniqueLeafNode<R>(
    _ level: _Level,
    _ bucket: _Bucket,
    _ slot: _Slot,
    by remover: (UnsafeMutablePointer<Element>) -> R
  ) -> R {
    assert(isUnique())
    let result = removeItem(at: slot, bucket, by: remover)
    if isAtrophied {
      self = removeSingletonChild()
    }
    if level.isAtRoot, isCollisionNode, hasSingletonItem {
      self._convertToRegularNode()
    }
    return result
  }

  @inlinable
  internal mutating func _fixupUniqueAncestorAfterItemRemoval(
    _ slot: _Slot,
    _ bucket: (inout Self) -> _Bucket,
    needsInlining: Bool
  ) {
    assert(isUnique())
    count &-= 1
    if needsInlining {
      ensureUnique(isUnique: true, withFreeSpace: Self.spaceForInlinedChild)
      let bucket = bucket(&self)
      var child = self.removeChild(at: slot, bucket)
      let item = child.removeSingletonItem()
      insertItem(item, bucket)
    }
    if isAtrophied {
      self = removeSingletonChild()
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
      return _removingItemFromLeaf(level, slot, bucket)
    case .notFound, .newCollision, .expansion:
      return nil
    case .descend(let bucket, let slot):
      let r = read { $0[child: slot].removing(key, level.descend(), hash) }
      guard let r = r else { return nil }
      return (
        _fixedUpAncestorAfterItemRemoval(level, slot, bucket, r.replacement),
        r.old)
    }
  }

  @inlinable
  internal func _removingItemFromLeaf(
    _ level: _Level, _ slot: _Slot, _ bucket: _Bucket
  )  -> (replacement: _Node, old: Element) {
    // Don't copy the node if we'd immediately discard it.
    let willAtrophy = read {
      $0.itemCount == 1
      && $0.childCount == 1
      && $0[child: .zero].isCollisionNode
    }
    if willAtrophy {
      return read { (replacement: $0[child: .zero], old: $0[item: .zero]) }
    }
    var node = self.copy()
    let old = node.removeItem(at: slot, bucket) { $0.move() }
    if level.isAtRoot, node.isCollisionNode, node.hasSingletonItem {
      node._convertToRegularNode()
    }
    node._invariantCheck()
    return (node, old)
  }

  @inlinable
  internal func _fixedUpAncestorAfterItemRemoval(
    _ level: _Level,
    _ slot: _Slot,
    _ bucket: _Bucket,
    _ newChild: __owned _Node
  )  -> _Node {
    var newChild = newChild
    if newChild.hasSingletonItem {
      var node = copy(withFreeSpace: Self.spaceForInlinedChild)
      _ = node.removeChild(at: slot, bucket)
      let item = newChild.removeSingletonItem()
      node.insertItem(item, bucket)
      node._invariantCheck()
      return node
    }
    if newChild.isCollisionNode && self.hasSingletonChild {
      // Don't return an atrophied node.
      return newChild
    }
    var node = copy()
    node.update { $0[child: slot] = newChild }
    node.count &-= 1
    node._invariantCheck()
    return node
  }
}

extension _Node {
  @inlinable
  internal mutating func remove(
    _ level: _Level, at path: _UnsafePath
  ) -> Element {
    defer { _invariantCheck() }
    guard self.isUnique() else {
      let r = removing(level, at: path)
      self = r.replacement
      return r.old
    }
    if level == path.level {
      let slot = path.currentItemSlot
      let bucket = read { $0.itemBucket(at: slot) }
      return _removeItemFromUniqueLeafNode(
        level, bucket, slot, by: { $0.move() })
    }
    let slot = path.childSlot(at: level)
    let (item, needsInlining) = update {
      let child = $0.childPtr(at: slot)
      let item = child.pointee.remove(level.descend(), at: path)
      return (item, child.pointee.hasSingletonItem)
    }
    _fixupUniqueAncestorAfterItemRemoval(
      slot,
      { $0.read { $0.childMap.bucket(at: slot) } },
      needsInlining: needsInlining)
    return item
  }

  @inlinable
  internal func removing(
    _ level: _Level, at path: _UnsafePath
  ) -> (replacement: _Node, old: Element) {
    if level == path.level {
      let slot = path.currentItemSlot
      let bucket = read { $0.itemBucket(at: slot) }
      return _removingItemFromLeaf(level, slot, bucket)
    }
    let slot = path.childSlot(at: level)
    let (bucket, r) = read {
      ($0.childMap.bucket(at: slot),
       $0[child: slot].removing(level.descend(), at: path))
    }
    return (
      _fixedUpAncestorAfterItemRemoval(level, slot, bucket, r.replacement),
      r.old
    )
  }
}

extension _Node {
  @usableFromInline
  @frozen
  internal struct ValueUpdateState {
    @usableFromInline
    internal var key: Key

    @usableFromInline
    internal var value: Value?

    @usableFromInline
    internal let hash: _Hash

    @usableFromInline
    internal var path: _UnsafePath

    @usableFromInline
    internal var found: Bool

    @inlinable
    internal init(
      _ key: Key,
      _ hash: _Hash,
      _ path: _UnsafePath
    ) {
      self.key = key
      self.value = nil
      self.hash = hash
      self.path = path
      self.found = false
    }
  }

  @inlinable
  internal mutating func prepareValueUpdate(
    _ key: Key,
    _ hash: _Hash
  ) -> ValueUpdateState {
    var state = ValueUpdateState(key, hash, _UnsafePath(root: raw))
    _prepareValueUpdate(&state)
    return state
  }

  @inlinable
  internal mutating func _prepareValueUpdate(
    _ state: inout ValueUpdateState
  ) {
    // This doesn't make room for a new item if the key doesn't already exist
    // but it does ensure that all parent nodes along its eventual path are
    // uniquely held.
    //
    // If the key already exists, we ensure uniqueness for its node and extract
    // its item but otherwise leave the tree as it was.
    let isUnique = self.isUnique()
    let r = find(state.path.level, state.key, state.hash, forInsert: true)
    switch r {
    case .found(_, let slot):
      ensureUnique(isUnique: isUnique)
      state.path.node = unmanaged
      state.path.selectItem(at: slot)
      state.found = true
      (state.key, state.value) = update { $0.itemPtr(at: slot).move() }

    case .notFound(_, let slot):
      state.path.selectItem(at: slot)

    case .newCollision(_, let slot):
      state.path.selectItem(at: slot)

    case .expansion(_):
      state.path.selectEnd()

    case .descend(_, let slot):
      ensureUnique(isUnique: isUnique)
      state.path.selectChild(at: slot)
      state.path.descend()
      update { $0[child: slot]._prepareValueUpdate(&state) }
    }
  }

  @inlinable
  internal mutating func finalizeValueUpdate(
    _ state: __owned ValueUpdateState
  ) {
    switch (state.found, state.value != nil) {
    case (true, true):
      // Fast path: updating an existing value.
      UnsafeHandle.update(state.path.node) {
        $0.itemPtr(at: state.path.currentItemSlot)
          .initialize(to: (state.key, state.value.unsafelyUnwrapped))
      }
    case (true, false):
      // Removal
      _finalizeRemoval(.top, state.hash, at: state.path)
    case (false, true):
      // Insertion
      _ = updateValue(
        state.value.unsafelyUnwrapped, forKey: state.key, .top, state.hash)
    case (false, false):
      // Noop
      break
    }
  }

  @inlinable
  internal mutating func _finalizeRemoval(
    _ level: _Level, _ hash: _Hash, at path: _UnsafePath
  ) {
    assert(isUnique())
    if level == path.level {
      _removeItemFromUniqueLeafNode(
        level, hash[level], path.currentItemSlot, by: { _ in })
    } else {
      let slot = path.childSlot(at: level)
      let needsInlining = update {
        let child = $0.childPtr(at: slot)
        child.pointee._finalizeRemoval(level.descend(), hash, at: path)
        return child.pointee.hasSingletonItem
      }
      _fixupUniqueAncestorAfterItemRemoval(
        slot, { _ in hash[level] }, needsInlining: needsInlining)
    }
  }
}

extension _Node {
  @usableFromInline
  @frozen
  internal struct DefaultedValueUpdateState {
    @usableFromInline
    internal var item: Element

    @usableFromInline
    internal var node: _UnmanagedNode

    @usableFromInline
    internal var slot: _Slot

    @usableFromInline
    internal var inserted: Bool

    @inlinable
    internal init(
      _ item: Element,
      in node: _UnmanagedNode,
      at slot: _Slot,
      inserted: Bool
    ) {
      self.item = item
      self.node = node
      self.slot = slot
      self.inserted = inserted
    }
  }

  @inlinable
  internal mutating func prepareDefaultedValueUpdate(
    _ level: _Level,
    _ key: Key,
    _ defaultValue: () -> Value,
    _ hash: _Hash
  ) -> DefaultedValueUpdateState {
    let isUnique = self.isUnique()
    let r = find(level, key, hash, forInsert: true)
    switch r {
    case .found(_, let slot):
      ensureUnique(isUnique: isUnique)
      return DefaultedValueUpdateState(
        update { $0.itemPtr(at: slot).move() },
        in: unmanaged,
        at: slot,
        inserted: false)

    case .notFound(let bucket, let slot):
      ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewItem)
      update { _ = $0._makeRoomForNewItem(at: slot, bucket) }
      self.count &+= 1
      return DefaultedValueUpdateState(
        (key, defaultValue()),
        in: unmanaged,
        at: slot,
        inserted: true)

    case .newCollision(let bucket, let slot):
      let r = _insertNewCollision(
        isUnique: isUnique,
        level: level,
        for: hash,
        replacing: slot, bucket,
        inserter: { _ in })
      return DefaultedValueUpdateState(
        (key, defaultValue()),
        in: r.node,
        at: r.slot,
        inserted: true)

    case .expansion(let collisionHash):
      let r = _Node.build(
        level: level,
        item1: { _ in }, hash,
        child2: self, collisionHash
      )
      self = r.top
      return DefaultedValueUpdateState(
        (key, defaultValue()),
        in: r.leaf,
        at: r.slot1,
        inserted: true)

    case .descend(_, let slot):
      ensureUnique(isUnique: isUnique)
      let res = update {
        $0[child: slot].prepareDefaultedValueUpdate(
          level.descend(), key, defaultValue, hash)
      }
      if res.inserted { count &+= 1 }
      return res
    }
  }

  @inlinable
  internal mutating func finalizeDefaultedValueUpdate(
    _ state: __owned DefaultedValueUpdateState
  ) {
    UnsafeHandle.update(state.node) {
      $0.itemPtr(at: state.slot).initialize(to: state.item)
    }
  }
}
