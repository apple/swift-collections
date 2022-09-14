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
  internal init(_collisions item1: Element, _ item2: Element) {
    defer { _invariantCheck() }
    self.init(collisionCapacity: 2)
    self.count = 2
    update {
      $0.collisionCount = 2
      let byteCount = 2 * MemoryLayout<Element>.stride
      assert($0.bytesFree >= byteCount)
      $0.bytesFree &-= byteCount
      let items = $0._items
      items.initializeElement(at: 0, to: item1)
      items.initializeElement(at: 1, to: item2)
    }
  }

  @inlinable
  internal init(
    _items item1: Element, _ bucket1: _Bucket,
    _ item2: Element, _ bucket2: _Bucket
  ) {
    defer { _invariantCheck() }
    assert(bucket1 != bucket2)
    self.init(itemCapacity: 2)
    self.count = 2
    update {
      $0.itemMap.insert(bucket1)
      $0.itemMap.insert(bucket2)
      $0.bytesFree &-= 2 * MemoryLayout<Element>.stride
      let i = bucket1 < bucket2 ? 0 : 1
      let items = $0._items
      items.initializeElement(at: i, to: item1)
      items.initializeElement(at: 1 - i, to: item2)
    }
  }

  @inlinable
  internal init(_child: _Node, _ bucket: _Bucket) {
    defer { _invariantCheck() }
    self.init(childCapacity: 1)
    self.count = _child.count
    update {
      $0.childMap.insert(bucket)
      $0.bytesFree &-= MemoryLayout<_Node>.stride
      $0.childPtr(at: 0).initialize(to: _child)
    }
  }

  @inlinable
  internal init(
    _item: Element, _ itemBucket: _Bucket,
    child: _Node, _ childBucket: _Bucket
  ) {
    defer { _invariantCheck() }
    assert(itemBucket != childBucket)
    self.init(itemCapacity: 1, childCapacity: 1)
    self.count = child.count + 1
    update {
      $0.itemMap.insert(itemBucket)
      $0.childMap.insert(childBucket)
      $0.bytesFree &-= MemoryLayout<Element>.stride + MemoryLayout<_Node>.stride
      $0.itemPtr(at: 0).initialize(to: _item)
      $0.childPtr(at: 0).initialize(to: child)
    }
  }
}

extension _Node {
  @inlinable
  internal init(
    level: _Level,
    item1: Element,
    _ hash1: _Hash,
    item2: Element,
    _ hash2: _Hash
  ) {
    if hash1 == hash2 {
      self.init(_collisions: item1, item2)
    } else {
      let b1 = hash1[level]
      let b2 = hash2[level]
      if b1 == b2 {
        let node = Self(
          level: level.descend(),
          item1: item1, hash1,
          item2: item2, hash2)
        self.init(_child: node, b1)
      } else {
        self.init(_items: item1, b1, item2, b2)
      }
    }
  }

  @inlinable
  internal init(
    level: _Level,
    item1: Element,
    _ hash1: _Hash,
    child2: _Node,
    _ hash2: _Hash
  ) {
    assert(child2.isCollisionNode)
    assert(hash1 != hash2)
    let b1 = hash1[level]
    let b2 = hash2[level]
    if b1 == b2 {
      let node = Self(
        level: level.descend(),
        item1: item1, hash1,
        child2: child2, hash2)
      self.init(_child: node, b1)
    } else {
      self.init(_item: item1, hash1[level], child: child2, hash2[level])
    }
  }
}
