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

@usableFromInline
@frozen
internal enum _FindResult {
  case notFound(_Bucket, Int)
  case found(_Bucket, Int)
  case newCollision(_Bucket, Int)
  case newSplit(_Hash)
  case descend(_Bucket, Int)
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
        let h = _Hash(self[item: 0].key)
        if h != hash {
          return .newSplit(h)
        }
      }
      guard let offset = _items.firstIndex(where: { $0.key == key }) else {
        return .notFound(.invalid, 0)
      }
      return .found(.invalid, offset)
    }
    let bucket = hash[level]
    if itemMap.contains(bucket) {
      let offset = itemMap.offset(of: bucket)
      if self[item: offset].key == key {
        return .found(bucket, offset)
      }
      return .newCollision(bucket, offset)
    }
    if childMap.contains(bucket) {
      let offset = childMap.offset(of: bucket)
      return .descend(bucket, offset)
    }
    // Don't calculate the offset unless the caller will need it.
    let offset = forInsert ? itemMap.offset(of: bucket) : 0
    return .notFound(bucket, offset)
  }
}

// MARK: Subtree-level lookup operations

extension _Node {
  @inlinable
  internal func get(_ level: _Level, _ key: Key, _ hash: _Hash) -> Value? {
    read {
      let r = $0.find(level, key, hash, forInsert: false)
      switch r {
      case .found(_, let offset):
        return $0[item: offset].value
      case .notFound, .newCollision, .newSplit:
        return nil
      case .descend(_, let offset):
        return $0[child: offset].get(level.descend(), key, hash)
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
      case .notFound, .newCollision, .newSplit:
        return false
      case .descend(_, let offset):
        return $0[child: offset].containsKey(level.descend(), key, hash)
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
    case .found(_, let offset):
      return offset
    case .notFound, .newCollision, .newSplit:
      return nil
    case .descend(_, let offset):
      return read { h in
        let children = h._children
        let p = children[offset].position(forKey: key, level.descend(), hash)
        guard let p = p else { return nil }
        let c = h.itemCount &+ p
        return children[..<offset].reduce(into: c) { $0 &+= $1.count }
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
        return $0[item: itemsToSkip]
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
