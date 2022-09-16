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

// MARK: Node-level lookup operations

/// Represents the results of a lookup operation within a single node of a hash
/// tree. This enumeration captures all of the different cases that need to be
/// covered if we wanted to insert a new item into the tree.
///
/// For simple read-only lookup operations (and removals) some of the cases are
/// equivalent: `.notFound`, .newCollision` and `expansion` all represent the
/// same logical outcome: the key we're looking for is not present in this
/// subtree.
@usableFromInline
@frozen
internal enum _FindResult {
  /// The item we're looking for is stored directly in this node, at the
  /// bucket / item slot identified in the payload.
  ///
  /// If the current node is a collision node, then the bucket value is
  /// set to `_Bucket.invalid`.
  case found(_Bucket, _Slot)
  /// The item we're looking for is not currently inside the subtree rooted at
  /// this node.
  ///
  /// If we wanted to insert it, then its correct slot is within this node
  /// at the specified bucket / item slot. (Which is currently empty.)
  ///
  /// If the current node is a collision node, then the bucket value is
  /// set to `_Bucket.invalid`.
  case notFound(_Bucket, _Slot)
  /// The item we're looking for is not currently inside the subtree rooted at
  /// this node.
  ///
  /// If we wanted to insert it, then it would need to be stored in this node
  /// at the specified bucket / item slot. However, that bucket is already
  /// occupied by another item, so the insertion would need to involve replacing
  /// it with a new child node.
  ///
  /// (This case is never returned if the current node is a collision node.)
  case newCollision(_Bucket, _Slot)
  /// The item we're looking for is not in this subtree.
  ///
  /// However, the item doesn't belong in this subtree at all. This is an
  /// irregular case that can only happen with (compressed) hash collision nodes
  /// whose (otherwise empty) ancestors got eliminated, so they appear further
  /// up in the tree than what their (logical) level would indicate.
  ///
  /// If we wanted to insert a new item with this key, then we'd need to create
  /// (one or more) new parent nodes above this node, pushing this collision
  /// node further down the tree. (This undoes the compression by expanding
  /// the collision node's path, hence the name of the enum case.)
  ///
  /// The payload of the expansion case is the shared hash value of all items
  /// inside the current (collision) node -- this is needed to sort this node
  /// into the proper bucket in any newly created parents.
  ///
  /// (This case is never returned if the current node is a regular node.)
  case expansion(_Hash)
  /// The item we're looking for is not directly stored in this node, but it
  /// might be somewhere in the subtree rooted at the child at the given
  /// bucket & slot.
  ///
  /// (This case is never returned if the current node is a collision node.)
  case descend(_Bucket, _Slot)
}

extension _Node {
  @inlinable
  internal func find(
    _ level: _Level, _ key: Key, _ hash: _Hash, forInsert: Bool
  ) -> _FindResult {
    read { $0.find(level, key, hash, forInsert: forInsert) }
  }
}

extension _Node.UnsafeHandle {
  @inlinable
  internal func find(
    _ level: _Level, _ key: Key, _ hash: _Hash, forInsert: Bool
  ) -> _FindResult {
    guard !isCollisionNode else {
      if !level.isAtBottom {
        let h = _Hash(self[item: .zero].key)
        if h != hash {
          return .expansion(h)
        }
      }
      // Note: this searches the items in reverse insertion order.
      guard let slot = reverseItems.firstIndex(where: { $0.key == key }) else {
        return .notFound(.invalid, itemEnd)
      }
      return .found(.invalid, _Slot(itemCount &- 1 &- slot))
    }
    let bucket = hash[level]
    if itemMap.contains(bucket) {
      let slot = itemMap.slot(of: bucket)
      if self[item: slot].key == key {
        return .found(bucket, slot)
      }
      return .newCollision(bucket, slot)
    }
    if childMap.contains(bucket) {
      let slot = childMap.slot(of: bucket)
      return .descend(bucket, slot)
    }
    // Don't calculate the slot unless the caller will need it.
    let slot = forInsert ? itemMap.slot(of: bucket) : .zero
    return .notFound(bucket, slot)
  }
}

// MARK: Subtree-level lookup operations

extension _Node {
  @inlinable
  internal func get(_ level: _Level, _ key: Key, _ hash: _Hash) -> Value? {
    read {
      let r = $0.find(level, key, hash, forInsert: false)
      switch r {
      case .found(_, let slot):
        return $0[item: slot].value
      case .notFound, .newCollision, .expansion:
        return nil
      case .descend(_, let slot):
        return $0[child: slot].get(level.descend(), key, hash)
      }
    }
  }

  @inlinable
  internal func containsKey(
    _ level: _Level, _ key: Key, _ hash: _Hash
  ) -> Bool {
    read {
      let r = $0.find(level, key, hash, forInsert: false)
      switch r {
      case .found:
        return true
      case .notFound, .newCollision, .expansion:
        return false
      case .descend(_, let slot):
        return $0[child: slot].containsKey(level.descend(), key, hash)
      }
    }
  }
}

extension _Node {
  @inlinable
  internal func position(
    forKey key: Key, _ level: _Level, _ hash: _Hash
  ) -> Int? {
    let r = find(level, key, hash, forInsert: false)
    switch r {
    case .found(_, let slot):
      return slot.value
    case .notFound, .newCollision, .expansion:
      return nil
    case .descend(_, let slot):
      return read { h in
        let children = h._children
        let p = children[slot.value]
          .position(forKey: key, level.descend(), hash)
        guard let p = p else { return nil }
        let c = h.itemCount &+ p
        return children[..<slot.value].reduce(into: c) { $0 &+= $1.count }
      }
    }
  }

  @inlinable
  internal func item(position: Int) -> Element {
    assert(position >= 0 && position < self.count)
    return read {
      var itemsToSkip = position
      let itemCount = $0.itemCount
      if itemsToSkip < itemCount {
        return $0[item: _Slot(itemsToSkip)]
      }
      itemsToSkip -= itemCount
      let children = $0._children
      for i in children.indices {
        if itemsToSkip < children[i].count {
          return children[i].item(position: itemsToSkip)
        }
        itemsToSkip -= children[i].count
      }
      fatalError("Inconsistent tree")
    }
  }
}
