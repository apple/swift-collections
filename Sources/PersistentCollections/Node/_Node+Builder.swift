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

extension _Node {
  @usableFromInline
  @frozen
  internal enum Builder {
    @usableFromInline typealias Element = _Node.Element

    case empty
    case item(Element, _Hash)
    case node(_Node, _Hash)
  }
}

extension _Node.Builder {
  @inlinable
  internal var count: Int {
    switch self {
    case .empty:
      return 0
    case .item:
      return 1
    case .node(let node, _):
      return node.count
    }
  }

  @inlinable
  internal var isEmpty: Bool {
    guard case .empty = self else { return false }
    return true
  }
}

extension _Node.Builder {
  @inlinable
  internal init(_ level: _Level, _ node: _Node, _ hashPrefix: _Hash) {
    if node.count == 0 {
      self = .empty
    } else if node.hasSingletonItem {
      let item = node.read { $0[item: .zero] }
      self = .item(item, hashPrefix)
    } else {
      self = .node(node, hashPrefix)
    }
  }

  @inlinable
  internal func finalize(_ level: _Level) -> _Node {
    assert(level.isAtRoot)
    switch self {
    case .empty:
      return _Node(storage: _emptySingleton, count: 0)
    case .item(let item, let h):
      return _Node._regularNode(item, h[level])
    case .node(let node, _):
      return node
    }
  }

  @inlinable
  internal mutating func addNewCollision(_ newItem: Element, _ hash: _Hash) {
    switch self {
    case .empty:
      self = .item(newItem, hash)
    case .item(let oldItem, let h):
      assert(hash == h)
      let node = _Node._collisionNode(hash, oldItem, newItem)
      self = .node(node, hash)
    case .node(var node, let h):
      self = .empty
      assert(node.isCollisionNode)
      assert(hash == h)
      assert(hash == node.collisionHash)
      _ = node.ensureUniqueAndAppendCollision(isUnique: true, newItem)
      self = .node(node, h)
    }
  }

  @inlinable
  internal mutating func addNewItem(
    _ level: _Level, _ newItem: Element, _ hashPrefix: _Hash
  ) {
    switch self {
    case .empty:
      self = .item(newItem, hashPrefix)
    case .item(let oldItem, let oldHash):
      let bucket1 = oldHash[level]
      let bucket2 = hashPrefix[level]
      assert(bucket1 != bucket2)
      assert(oldHash.isEqual(to: hashPrefix, upTo: level))
      let node = _Node._regularNode(oldItem, bucket1, newItem, bucket2)
      self = .node(node, hashPrefix)
    case .node(var node, let nodeHash):
      self = .empty
      if node.isCollisionNode {
        // Expansion
        assert(!level.isAtBottom)
        node = _Node._regularNode(node, nodeHash[level])
      }
      assert(nodeHash.isEqual(to: hashPrefix, upTo: level))
      let bucket = hashPrefix[level]
      node.ensureUniqueAndInsertItem(isUnique: true, newItem, at: bucket)
      self = .node(node, nodeHash)
    }
  }

  @inlinable
  internal mutating func addNewChildBranch(
    _ level: _Level, _ branch: Self
  ) {
    switch (self, branch) {
    case (_, .empty):
      break
    case (.empty, .item):
      self = branch
    case (.empty, .node(let child, let childHash)):
      if child.isCollisionNode {
        // Compression
        assert(!level.isAtBottom)
        self = branch
      } else {
        let node = _Node._regularNode(child, childHash[level])
        self = .node(node, childHash)
      }
    case let (.item(li, lh), .item(ri, rh)):
      let node = _Node._regularNode(li, lh[level], ri, rh[level])
      self = .node(node, lh)
    case let (.item(item, itemHash), .node(child, childHash)):
      assert(itemHash.isEqual(to: childHash, upTo: level))
      let node = _Node._regularNode(
        item, itemHash[level],
        child, childHash[level])
      self = .node(node, childHash)
    case (.node(var node, let nodeHash), .item(let item, let itemHash)):
      if node.isCollisionNode {
        // Expansion
        assert(!level.isAtBottom)
        node = _Node._regularNode(node, nodeHash[level])
      }
      assert(!node.isCollisionNode)
      assert(nodeHash.isEqual(to: itemHash, upTo: level))
      node.ensureUniqueAndInsertItem(
        isUnique: true, item, at: itemHash[level])
      self = .node(node, nodeHash)
    case (.node(var node, let nodeHash), .node(let child, let childHash)):
      if node.isCollisionNode {
        // Expansion
        assert(!level.isAtBottom)
        node = _Node._regularNode(node, nodeHash[level])
      }
      assert(nodeHash.isEqual(to: childHash, upTo: level))
      node.ensureUnique(isUnique: true, withFreeSpace: _Node.spaceForNewChild)
      node.insertChild(child, childHash[level])
      self = .node(node, nodeHash)
    }
  }

  @inlinable
  internal static func childBranch(
    _ level: _Level, _ branch: Self
  ) -> Self {
    var result: Self = .empty
    result.addNewChildBranch(level, branch)
    return result
  }
}

extension _Node.Builder {
  @inlinable
  internal mutating func copyCollisions(
    from source: _Node.UnsafeHandle,
    upTo end: _Slot
  ) {
    assert(isEmpty)
    assert(source.isCollisionNode)
    assert(end < source.itemsEndSlot)
    let h = source.collisionHash
    for slot: _Slot in stride(from: .zero, to: end, by: 1) {
      self.addNewCollision(source[item: slot], h)
    }
  }

  @inlinable
  internal mutating func copyItems(
    _ level: _Level,
    _ hashPrefix: _Hash,
    from source: _Node.UnsafeHandle,
    upTo end: _Bucket
  ) {
    assert(isEmpty)
    assert(!source.isCollisionNode)
    for (b, s) in source.itemMap.intersection(_Bitmap(upTo: end)) {
      let h = hashPrefix.appending(b, at: level)
      self.addNewItem(level, source[item: s], h)
    }
  }

  @inlinable
  internal mutating func copyItemsAndChildren(
    _ level: _Level,
    _ hashPrefix: _Hash,
    from source: _Node.UnsafeHandle,
    upTo end: _Bucket
  ) {
    assert(isEmpty)
    assert(!source.isCollisionNode)
    for (b, s) in source.itemMap {
      let h = hashPrefix.appending(b, at: level)
      self.addNewItem(level, source[item: s], h)
    }
    for (b, s) in source.childMap.intersection(_Bitmap(upTo: end)) {
      let h = hashPrefix.appending(b, at: level)
      self.addNewChildBranch(level, .node(source[child: s], h))
    }
  }

}
