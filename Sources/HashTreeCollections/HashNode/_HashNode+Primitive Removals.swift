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

// MARK: Node-level removal operations

extension _HashNode.UnsafeHandle {
  /// Remove and return the item at `slot`, increasing the amount of free
  /// space available in the node.
  ///
  /// `itemMap` must not yet reflect the removal at the time this
  /// function is called. This method does not update `itemMap`.
  @inlinable
  @unsafe
  internal func _removeItem<R>(
    at slot: _HashSlot,
    by remover: (UnsafeMutablePointer<Element>) -> R
  ) -> R {
    assertMutable()
    let c = unsafe itemCount
    assert(slot.value < c)
    let stride = MemoryLayout<Element>.stride
    unsafe bytesFree &+= stride

    let start = unsafe _memory
      .advanced(by: byteCapacity &- stride &* c)
      .assumingMemoryBound(to: Element.self)

    let prefix = c &- 1 &- slot.value
    let q = unsafe start + prefix
    defer {
      unsafe (start + 1).moveInitialize(from: start, count: prefix)
    }
    return unsafe remover(q)
  }

  /// Remove and return the child at `slot`, increasing the amount of free
  /// space available in the node.
  ///
  /// `childMap` must not yet reflect the removal at the time this
  /// function is called. This method does not update `childMap`.
  @inlinable
  @unsafe
  internal func _removeChild(at slot: _HashSlot) -> _HashNode {
    assertMutable()
    assert(unsafe !isCollisionNode)
    let count = unsafe childCount
    assert(slot.value < count)

    unsafe bytesFree &+= MemoryLayout<_HashNode>.stride

    let q = unsafe _childrenStart + slot.value
    let child = unsafe q.move()
    unsafe q.moveInitialize(from: q + 1, count: count &- 1 &- slot.value)
    return child
  }
}

extension _HashNode {
  @inlinable
  @unsafe
  internal mutating func removeItem(
    at bucket: _Bucket
  ) -> Element {
    let slot = unsafe read { unsafe $0.itemMap.slot(of: bucket) }
    return unsafe removeItem(at: bucket, slot, by: { unsafe $0.move() })
  }

  @inlinable
  @unsafe
  internal mutating func removeItem(
    at bucket: _Bucket, _ slot: _HashSlot
  ) -> Element {
    unsafe removeItem(at: bucket, slot, by: { unsafe $0.move() })
  }

  /// Remove the item at `slot`, increasing the amount of free
  /// space available in the node.
  ///
  /// The closure `remove` is called to perform the deinitialization of the
  /// storage slot corresponding to the item to be removed.
  @inlinable
  @unsafe
  internal mutating func removeItem<R>(
    at bucket: _Bucket, _ slot: _HashSlot,
    by remover: (UnsafeMutablePointer<Element>) -> R
  ) -> R {
    defer { _invariantCheck() }
    assert(count > 0)
    count &-= 1
    return unsafe update {
      let old = unsafe $0._removeItem(at: slot, by: remover)
      if unsafe $0.isCollisionNode {
        assert(unsafe slot.value < $0.collisionCount)
        unsafe $0.collisionCount &-= 1
      } else {
        assert(unsafe $0.itemMap.contains(bucket))
        assert(unsafe $0.itemMap.slot(of: bucket) == slot)
        unsafe $0.itemMap.remove(bucket)
      }
      return old
    }
  }

  @inlinable
  @unsafe
  internal mutating func removeChild(
    at bucket: _Bucket, _ slot: _HashSlot
  ) -> _HashNode {
    assert(!isCollisionNode)
    let child: _HashNode = unsafe update {
      assert(unsafe $0.childMap.contains(bucket))
      assert(unsafe $0.childMap.slot(of: bucket) == slot)
      let child = unsafe $0._removeChild(at: slot)
      unsafe $0.childMap.remove(bucket)
      return child
    }
    assert(self.count >= child.count)
    self.count &-= child.count
    return child
  }

  @inlinable
  @unsafe
  internal mutating func removeSingletonItem() -> Element {
    defer { _invariantCheck() }
    assert(count == 1)
    count = 0
    return unsafe update {
      assert(unsafe $0.hasSingletonItem)
      let old = unsafe $0._removeItem(at: .zero) { unsafe $0.move() }
      unsafe $0.clear()
      return old
    }
  }

  @inlinable
  internal mutating func removeSingletonChild() -> _HashNode {
    defer { _invariantCheck() }
    let child: _HashNode = unsafe update {
      assert(unsafe $0.hasSingletonChild)
      let child = unsafe $0._removeChild(at: .zero)
      unsafe $0.childMap = .empty
      return child
    }
    assert(self.count == child.count)
    self.count = 0
    return child
  }
}

