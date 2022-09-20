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
  @inlinable
  internal static func _collisionNode(
    _ item1: Element,
    _ inserter2: (UnsafeMutablePointer<Element>) -> Void
  ) -> _Node {
    var node = _Node(storage: Storage.allocate(itemCapacity: 2), count: 2)
    node.update {
      $0.collisionCount = 2
      let byteCount = 2 * MemoryLayout<Element>.stride
      assert($0.bytesFree >= byteCount)
      $0.bytesFree &-= byteCount
      let items = $0.reverseItems
      items.initializeElement(at: 1, to: item1)
      inserter2(items.baseAddress.unsafelyUnwrapped)
    }
    node._invariantCheck()
    return node
  }

  @inlinable
  internal static func _regularNode(
    _ item1: Element,
    _ bucket1: _Bucket,
    _ inserter2: (UnsafeMutablePointer<Element>) -> Void,
    _ bucket2: _Bucket
  ) -> (node: _Node, slot1: _Slot, slot2: _Slot) {
    assert(bucket1 != bucket2)
    var node = _Node(storage: Storage.allocate(itemCapacity: 2), count: 2)
    let (slot1, slot2) = node.update {
      $0.itemMap.insert(bucket1)
      $0.itemMap.insert(bucket2)
      $0.bytesFree &-= 2 * MemoryLayout<Element>.stride
      let i1 = bucket1 < bucket2 ? 1 : 0
      let i2 = 1 &- i1
      let items = $0.reverseItems
      items.initializeElement(at: i1, to: item1)
      inserter2(items.baseAddress.unsafelyUnwrapped + i2)
      return (_Slot(i2), _Slot(i1)) // Note: swapped
    }
    node._invariantCheck()
    return (node, slot1, slot2)
  }

  @inlinable
  internal static func _regularNode(
    _ child: _Node, _ bucket: _Bucket
  ) -> _Node {
    var node = _Node(
      storage: Storage.allocate(childCapacity: 1),
      count: child.count)
    node.update {
      $0.childMap.insert(bucket)
      $0.bytesFree &-= MemoryLayout<_Node>.stride
      $0.childPtr(at: .zero).initialize(to: child)
    }
    node._invariantCheck()
    return node
  }

  @inlinable
  internal static func _regularNode(
    _ inserter: (UnsafeMutablePointer<Element>) -> Void,
    _ itemBucket: _Bucket,
    _ child: _Node,
    _ childBucket: _Bucket
  ) -> _Node {
    assert(itemBucket != childBucket)
    var node = _Node(
      storage: Storage.allocate(itemCapacity: 1, childCapacity: 1),
      count: child.count &+ 1)
    node.update {
      $0.itemMap.insert(itemBucket)
      $0.childMap.insert(childBucket)
      $0.bytesFree &-= MemoryLayout<Element>.stride + MemoryLayout<_Node>.stride
      inserter($0.itemPtr(at: .zero))
      $0.childPtr(at: .zero).initialize(to: child)
    }
    node._invariantCheck()
    return node
  }
}

extension _Node {
  @inlinable
  internal static func build(
    level: _Level,
    item1: Element,
    _ hash1: _Hash,
    item2 inserter2: (UnsafeMutablePointer<Element>) -> Void,
    _ hash2: _Hash
  ) -> (top: _Node, leaf: _UnmanagedNode, slot1: _Slot, slot2: _Slot) {
    if hash1 == hash2 {
      let top = _collisionNode(item1, inserter2)
      return (top, top.unmanaged, _Slot(0), _Slot(1))
    }
    let r = _build(
      level: level, item1: item1, hash1, item2: inserter2, hash2)
    return (r.top, r.leaf, r.slot1, r.slot2)
  }

  @inlinable
  internal static func _build(
    level: _Level,
    item1: Element,
    _ hash1: _Hash,
    item2 inserter2: (UnsafeMutablePointer<Element>) -> Void,
    _ hash2: _Hash
  ) -> (top: _Node, leaf: _UnmanagedNode, slot1: _Slot, slot2: _Slot) {
    assert(hash1 != hash2)
    let b1 = hash1[level]
    let b2 = hash2[level]
    guard b1 == b2 else {
      let r = _regularNode(item1, b1, inserter2, b2)
      return (r.node, r.node.unmanaged, r.slot1, r.slot2)
    }
    let r = _build(
      level: level.descend(),
      item1: item1, hash1,
      item2: inserter2, hash2)
    return (_regularNode(r.top, b1), r.leaf, r.slot1, r.slot2)
  }

  @inlinable
  internal static func build(
    level: _Level,
    item1 inserter1: (UnsafeMutablePointer<Element>) -> Void,
    _ hash1: _Hash,
    child2: _Node,
    _ hash2: _Hash
  ) -> (top: _Node, leaf: _UnmanagedNode, slot1: _Slot, slot2: _Slot) {
    assert(child2.isCollisionNode)
    assert(hash1 != hash2)
    let b1 = hash1[level]
    let b2 = hash2[level]
    if b1 == b2 {
      let node = build(
        level: level.descend(),
        item1: inserter1, hash1,
        child2: child2, hash2)
      return (_regularNode(node.top, b1), node.leaf, node.slot1, node.slot2)
    }
    let node = _regularNode(inserter1, hash1[level], child2, hash2[level])
    return (node, node.unmanaged, .zero, .zero)
  }
}
