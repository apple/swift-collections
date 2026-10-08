//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// MARK: Subtree-level removal operations

extension _HashNode {
  /// Remove the item with the specified key from this subtree and return it.
  ///
  /// This function may leave `self` containing a singleton item.
  /// It is up to the caller to detect this situation & correct it when needed,
  /// by inlining the remaining item into the parent node.
  @inlinable
  @unsafe
  internal mutating func remove(
    _ level: _HashLevel, _ key: Key, _ hash: _Hash
  ) -> (removed: Element, remainder: Element?)? {
    guard self.isUnique() else {
      guard let r = unsafe removing(level, key, hash) else { return nil }
      let remainder = unsafe self.applyReplacement(level, r.replacement)
      return (r.removed, remainder)
    }
    guard let r = find(level, key, hash) else { return nil }
    let bucket = hash[level]
    guard r.descend else {
      let r = unsafe _removeItemFromUniqueLeafNode(level, at: bucket, r.slot) {
        unsafe $0.move()
      }
      return (r.result, r.remainder)
    }

    let r2 = unsafe update { unsafe $0[child: r.slot].remove(level.descend(), key, hash) }
    guard let r2 = r2 else { return nil }
    let remainder = unsafe _fixupUniqueAncestorAfterItemRemoval(
      level,
      at: { _ in hash[level] },
      r.slot,
      remainder: r2.remainder)
    return (r2.removed, remainder)
  }
}

extension _HashNode {
  @inlinable
  @unsafe
  internal func removing(
    _ level: _HashLevel, _ key: Key, _ hash: _Hash
  ) -> (removed: Element, replacement: Builder)? {
    guard let r = find(level, key, hash) else { return nil }
    let bucket = hash[level]
    guard r.descend else {
      return unsafe _removingItemFromLeaf(level, at: bucket, r.slot)
    }
    let r2 = unsafe read { unsafe $0[child: r.slot].removing(level.descend(), key, hash) }
    guard let r2 = r2 else { return nil }
    let replacement = unsafe self.replacingChild(
      level, at: bucket, r.slot, with: r2.replacement)
    return (r2.removed, replacement)
  }
}

extension _HashNode {
  @inlinable
  @unsafe
  internal mutating func remove(
    _ level: _HashLevel, at path: _UnsafePath
  ) -> (removed: Element, remainder: Element?) {
    defer { _invariantCheck() }
    guard self.isUnique() else {
      let r = unsafe removing(level, at: path)
      let remainder = unsafe applyReplacement(level, r.replacement)
      return (r.removed, remainder)
    }
    if level == path.level {
      let slot = unsafe path.currentItemSlot
      let bucket = unsafe read { unsafe $0.itemBucket(at: slot) }
      let r = unsafe _removeItemFromUniqueLeafNode(
        level, at: bucket, slot, by: { unsafe $0.move() })
      return (r.result, r.remainder)
    }
    let slot = unsafe path.childSlot(at: level)
    let r = unsafe update { unsafe $0[child: slot].remove(level.descend(), at: path) }
    let remainder = unsafe _fixupUniqueAncestorAfterItemRemoval(
      level,
      at: { unsafe $0.childMap.bucket(at: slot) },
      slot,
      remainder: r.remainder)
    return (r.removed, remainder)
  }

  @inlinable
  @unsafe
  internal func removing(
    _ level: _HashLevel, at path: _UnsafePath
  ) -> (removed: Element, replacement: Builder) {
    if level == path.level {
      let slot = unsafe path.currentItemSlot
      let bucket = unsafe read { unsafe $0.itemBucket(at: slot) }
      return unsafe _removingItemFromLeaf(level, at: bucket, slot)
    }
    let slot = unsafe path.childSlot(at: level)
    return unsafe read {
      let bucket = unsafe $0.childMap.bucket(at: slot)
      let r = unsafe $0[child: slot].removing(level.descend(), at: path)
      return (
        r.removed,
        unsafe self.replacingChild(level, at: bucket, slot, with: r.replacement))
    }
  }
}

extension _HashNode {
  @inlinable
  @unsafe
  internal mutating func _removeItemFromUniqueLeafNode<R>(
    _ level: _HashLevel,
    at bucket: _Bucket,
    _ slot: _HashSlot,
    by remover: (UnsafeMutablePointer<Element>) -> R
  ) -> (result: R, remainder: Element?) {
    assert(isUnique())
    let result = unsafe removeItem(at: bucket, slot, by: remover)
    if isAtrophied {
      self = removeSingletonChild()
    }
    if hasSingletonItem {
      if level.isAtRoot {
        if isCollisionNode {
          _convertToRegularNode()
        }
        return (result, nil)
      }
      let item = unsafe removeSingletonItem()
      return (result, item)
    }
    return (result, nil)
  }

  @inlinable
  @unsafe
  internal func _removingItemFromLeaf(
    _ level: _HashLevel, at bucket: _Bucket, _ slot: _HashSlot
  )  -> (removed: Element, replacement: Builder) {
    unsafe read {
      if unsafe $0.isCollisionNode {
        assert(unsafe slot.value < $0.collisionCount )

        if unsafe $0.collisionCount == 2 {
          // Node will evaporate
          let remainder = _HashSlot(1 &- slot.value)
          let bucket = unsafe $0.collisionHash[level]
          return (
            removed: unsafe $0[item: slot],
            replacement: unsafe .item(level, $0[item: remainder], at: bucket))
        }

        var node = self.copy()
        let old = unsafe node.removeItem(at: bucket, slot)
        node._invariantCheck()
        return (old, .collisionNode(level, node))
      }

      assert(unsafe $0.itemMap.contains(bucket))
      assert(unsafe slot == $0.itemMap.slot(of: bucket))

      let willAtrophy = (
        unsafe !$0.isCollisionNode
        && $0.itemMap.hasExactlyOneMember
        && $0.childMap.hasExactlyOneMember
        && $0[child: .zero].isCollisionNode)
      if willAtrophy {
        // Compression
        let child = unsafe $0[child: .zero]
        let old = unsafe $0[item: .zero]
        return (old, .collisionNode(level, child))
      }

      if unsafe $0.itemMap.count == 2 && $0.childMap.isEmpty {
        // Evaporating node
        let remainder = _HashSlot(1 &- slot.value)

        var map = unsafe $0.itemMap
        if remainder != .zero { _ = map.popFirst() }
        let bucket = map.first!

        return (
          removed: unsafe $0[item: slot],
          replacement: unsafe .item(level, $0[item: remainder], at: bucket))
      }
      var node = self.copy()
      let old = unsafe node.removeItem(at: bucket, slot)
      node._invariantCheck()
      return (old, .node(level, node))
    }
  }
}

extension _HashNode {
  @inlinable
  @unsafe
  internal func _removingChild(
    _ level: _HashLevel, at bucket: _Bucket, _ slot: _HashSlot
  ) -> Builder {
    unsafe read {
      assert(unsafe !$0.isCollisionNode && $0.childMap.contains(bucket))
      let willAtrophy = unsafe (
        $0.itemMap.isEmpty
        && $0.childCount == 2
        && $0[child: _HashSlot(1 &- slot.value)].isCollisionNode
      )
      if willAtrophy {
        // Compression
        let child = unsafe $0[child: _HashSlot(1 &- slot.value)]
        return .collisionNode(level, child)
      }
      if unsafe $0.itemMap.hasExactlyOneMember && $0.childMap.hasExactlyOneMember {
        return unsafe .item(level, $0[item: .zero], at: $0.itemMap.first!)
      }
      if unsafe $0.hasSingletonChild {
        // Evaporate node
        return .empty(level)
      }
      
      var node = self.copy()
      _ = unsafe node.removeChild(at: bucket, slot)
      node._invariantCheck()
      return .node(level, node)
    }
  }
}

extension _HashNode {
  @inlinable
  @unsafe
  internal mutating func _fixupUniqueAncestorAfterItemRemoval(
    _ level: _HashLevel,
    at bucket: (UnsafeHandle) -> _Bucket,
    _ childSlot: _HashSlot,
    remainder: Element?
  ) -> Element? {
    assert(isUnique())
    count &-= 1
    if let remainder = remainder {
      if hasSingletonChild, !level.isAtRoot {
        self = ._emptyNode()
        return remainder
      }
      // Child to be inlined has already been cleared, so we need to adjust
      // the count manually.
      assert(unsafe read { unsafe $0[child: childSlot].count == 0 })
      count &-= 1
      let bucket = unsafe read { unsafe bucket($0) }
      ensureUnique(isUnique: true, withFreeSpace: Self.spaceForInlinedChild)
      _ = unsafe self.removeChild(at: bucket, childSlot)
      unsafe insertItem(remainder, at: bucket)
      return nil
    }
    if isAtrophied {
      self = removeSingletonChild()
    }
    return nil
  }
}

extension _HashNode {
  @inlinable
  internal mutating func _convertToRegularNode() {
    assert(isCollisionNode && hasSingletonItem)
    assert(isUnique())
    unsafe update {
      unsafe $0.itemMap = _Bitmap($0.collisionHash[.top])
      unsafe $0.childMap = .empty
      unsafe $0.bytesFree &+= MemoryLayout<_Hash>.stride
    }
  }
}
