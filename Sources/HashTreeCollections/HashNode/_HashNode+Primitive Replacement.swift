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

extension _HashNode {
  @inlinable
  @unsafe
  internal mutating func replaceItem(
    at bucket: _Bucket, _ slot: _HashSlot, with item: __owned Element
  ) {
    unsafe update {
      assert(unsafe $0.isCollisionNode || $0.itemMap.contains(bucket))
      assert(unsafe $0.isCollisionNode || slot == $0.itemMap.slot(of: bucket))
      assert(unsafe !$0.isCollisionNode || slot.value < $0.collisionCount)
      unsafe $0[item: slot] = item
    }
  }

  @inlinable
  @unsafe
  internal mutating func replaceChild(
    at bucket: _Bucket, with child: __owned _HashNode
  ) -> Int {
    let slot = unsafe read { unsafe $0.childMap.slot(of: bucket) }
    return unsafe replaceChild(at: bucket, slot, with: child)
  }

  @inlinable
  @unsafe
  internal mutating func replaceChild(
    at bucket: _Bucket, _ slot: _HashSlot, with child: __owned _HashNode
  ) -> Int {
    let delta: Int = unsafe update {
      assert(unsafe !$0.isCollisionNode)
      assert(unsafe $0.childMap.contains(bucket))
      assert(unsafe $0.childMap.slot(of: bucket) == slot)
      let p = unsafe $0.childPtr(at: slot)
      let delta = unsafe child.count &- p.pointee.count
      unsafe p.pointee = child
      return delta
    }
    self.count &+= delta
    return delta
  }

  @inlinable
  @unsafe
  internal func replacingChild(
    _ level: _HashLevel,
    at bucket: _Bucket,
    _ slot: _HashSlot,
    with child: __owned Builder
  ) -> Builder {
    assert(child.level == level.descend())
    unsafe read {
      assert(unsafe !$0.isCollisionNode)
      assert(unsafe $0.childMap.contains(bucket))
      assert(unsafe slot == $0.childMap.slot(of: bucket))
    }
    switch child.kind {
    case .empty:
      return unsafe _removingChild(level, at: bucket, slot)
    case let .item(item, _):
      if hasSingletonChild {
        return .item(level, item, at: bucket)
      }
      var node = self.copy(withFreeSpace: _HashNode.spaceForInlinedChild)
      _ = unsafe node.removeChild(at: bucket, slot)
      unsafe node.insertItem(item, at: bucket)
      node._invariantCheck()
      return .node(level, node)
    case let .node(node):
      var copy = self.copy()
      _ = unsafe copy.replaceChild(at: bucket, slot, with: node)
      return .node(level, copy)
    case let .collisionNode(node):
      if hasSingletonChild {
        // Compression
        assert(!level.isAtBottom)
        return .collisionNode(level, node)
      }
      var copy = self.copy()
      _ = unsafe copy.replaceChild(at: bucket, slot, with: node)
      return .node(level, copy)
    }
  }
}
