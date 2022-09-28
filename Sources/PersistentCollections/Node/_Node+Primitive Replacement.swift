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
  internal mutating func replaceChild(
    at bucket: _Bucket, with child: _Node
  ) -> Int {
    let slot = read { $0.childMap.slot(of: bucket) }
    return replaceChild(at: bucket, slot, with: child)
  }

  @inlinable
  internal mutating func replaceChild(
    at bucket: _Bucket, _ slot: _Slot, with child: _Node
  ) -> Int {
    let delta = update {
      assert(!$0.isCollisionNode)
      assert($0.childMap.contains(bucket))
      assert($0.childMap.slot(of: bucket) == slot)
      let p = $0.childPtr(at: slot)
      let delta = child.count &- p.pointee.count
      p.pointee = child
      return delta
    }
    self.count &+= delta
    return delta
  }

  @inlinable
  internal func replacingChild(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ slot: _Slot,
    with child: __owned Builder
  ) -> Builder {
    let bucket = hashPrefix[level]
    read {
      assert(!$0.isCollisionNode)
      assert($0.childMap.contains(bucket))
      assert(slot == $0.childMap.slot(of: bucket))
    }
    switch child {
    case .empty:
      return _removingChild(level, hashPrefix, bucket, slot)
    case let .item(item, hash):
      assert(hash.isEqual(to: hashPrefix, upTo: level))
      assert(hash[level] == bucket)
      if hasSingletonChild {
        return child
      }
      var node = self.copy(withFreeSpace: _Node.spaceForInlinedChild)
      _ = node.removeChild(at: slot, bucket)
      node.insertItem(item, at: bucket)
      node._invariantCheck()
      return .node(node, hashPrefix)
    case let .node(node, hash):
      assert(hash.isEqual(to: hashPrefix, upTo: level))
      assert(hash[level] == bucket)
      if node.isCollisionNode, self.hasSingletonChild {
        // Compression
        assert(!level.isAtBottom)
        return child
      }
      var copy = self.copy()
      _ = copy.replaceChild(at: bucket, slot, with: node)
      return .node(copy, hashPrefix)
    }
  }
}
