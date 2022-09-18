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

// MARK: Subtree-level removal operations

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
}

extension _Node {
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
}

extension _Node {
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
  internal mutating func _convertToRegularNode() {
    assert(isCollisionNode && hasSingletonItem)
    assert(isUnique())
    update {
      let hash = _Hash($0[item: .zero].key)
      $0.itemMap = _Bitmap(hash[.top])
      $0.childMap = .empty
    }
  }
}
