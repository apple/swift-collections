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

// MARK: Node-level insertion operations

extension _HashNode.UnsafeHandle {
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
  @unsafe
  internal func _makeRoomForNewItem(
    at slot: _HashSlot, _ bucket: _Bucket
  ) -> UnsafeMutablePointer<Element> {
    assertMutable()
    let c = unsafe itemCount
    assert(slot.value <= c)

    let stride = MemoryLayout<Element>.stride
    assert(unsafe bytesFree >= stride)
    unsafe bytesFree &-= stride

    let start = unsafe _memory
      .advanced(by: byteCapacity &- (c &+ 1) &* stride)
      .bindMemory(to: Element.self, capacity: 1)

    let prefix = c &- slot.value
    unsafe start.moveInitialize(from: start + 1, count: prefix)

    if bucket.isInvalid {
      assert(unsafe isCollisionNode)
      unsafe collisionCount &+= 1
    } else {
      assert(unsafe !itemMap.contains(bucket))
      assert(unsafe !childMap.contains(bucket))
      unsafe itemMap.insert(bucket)
      assert(unsafe itemMap.slot(of: bucket) == slot)
    }

    return unsafe start + prefix
  }

  /// Insert `child` at `slot`. There must be enough free space in the node
  /// to fit the new child.
  ///
  /// `childMap` must not yet reflect the insertion at the time this
  /// function is called. This method does not update `childMap`.
  @inlinable
  @unsafe
  internal func _insertChild(_ child: __owned _HashNode, at slot: _HashSlot) {
    assertMutable()
    assert(unsafe !isCollisionNode)

    let c = unsafe childMap.count
    assert(slot.value <= c)

    let stride = MemoryLayout<_HashNode>.stride
    assert(unsafe bytesFree >= stride)
    unsafe bytesFree &-= stride

    unsafe _memory.bindMemory(to: _HashNode.self, capacity: c &+ 1)
    let q = unsafe _childrenStart + slot.value
    unsafe (q + 1).moveInitialize(from: q, count: c &- slot.value)
    unsafe q.initialize(to: child)
  }
}

extension _HashNode {
  @inlinable @inline(__always)
  @unsafe
  internal mutating func insertItem(
    _ item: __owned Element, at bucket: _Bucket
  ) {
    let slot = unsafe read { unsafe $0.itemMap.slot(of: bucket) }
    unsafe self.insertItem(item, at: slot, bucket)
  }

  @inlinable @inline(__always)
  @unsafe
  internal mutating func insertItem(
    _ item: __owned Element, at slot: _HashSlot, _ bucket: _Bucket
  ) {
    self.count &+= 1
    unsafe update {
      let p = unsafe $0._makeRoomForNewItem(at: slot, bucket)
      unsafe p.initialize(to: item)
    }
  }

  /// Insert `child` in `bucket`. There must be enough free space in the
  /// node to fit the new child.
  @inlinable
  @unsafe
  internal mutating func insertChild(
    _ child: __owned _HashNode, _ bucket: _Bucket
  ) {
    count &+= child.count
    unsafe update {
      assert(unsafe !$0.isCollisionNode)
      assert(unsafe !$0.itemMap.contains(bucket))
      assert(unsafe !$0.childMap.contains(bucket))

      let slot = unsafe $0.childMap.slot(of: bucket)
      unsafe $0._insertChild(child, at: slot)
      unsafe $0.childMap.insert(bucket)
    }
  }
}
