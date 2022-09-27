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
  internal func filter(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Builder {
    try self.read {
      var result: Builder = .empty

      if isCollisionNode {
        let items = $0.reverseItems
        for i in items.indices {
          if try isIncluded(items[i]) {
            result.addNewCollision(items[i], $0.collisionHash)
          }
        }
        if result.count == self.count {
          // FIXME: Delay allocating a result node until we know for sure
          // we're going to need it.
          return .node(self, $0.collisionHash)
        }
        return result
      }

      for (bucket, slot) in $0.itemMap {
        let p = $0.itemPtr(at: slot)
        if try isIncluded(p.pointee) {
          let h = hashPrefix.appending(bucket, at: level)
          result.addNewItem(level, p.pointee, h)
        }
      }

      for (bucket, slot) in $0.childMap {
        let h = hashPrefix.appending(bucket, at: level)
        let branch = try $0[child: slot].filter(level.descend(), h, isIncluded)
        result.addNewChildBranch(level, branch)
      }

      if result.count == self.count {
        // FIXME: Delay allocating a result node until we know for sure
        // we're going to need it.
        return .node(self, hashPrefix)
      }
      return result
    }
  }
}
