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
}
