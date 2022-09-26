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
  internal func compactMapValues<T>(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ transform: (Value) throws -> T?
  ) rethrows -> _Node<Key, T>.Builder {
    return try self.read {
      var result: _Node<Key, T>.Builder = .empty

      if isCollisionNode {
        let items = $0.reverseItems
        for i in items.indices {
          if let v = try transform(items[i].value) {
            result.addNewCollision((items[i].key, v), $0.collisionHash)
          }
        }
        return result
      }

      for (bucket, slot) in $0.itemMap {
        let p = $0.itemPtr(at: slot)
        if let v = try transform(p.pointee.value) {
          let h = hashPrefix.appending(bucket, at: level)
          result.addNewItem(level, (p.pointee.key, v), h)
        }
      }

      for (bucket, slot) in $0.childMap {
        let h = hashPrefix.appending(bucket, at: level)
        let branch = try $0[child: slot].compactMapValues(
          level.descend(), h, transform)
        result.addNewChildBranch(level, branch)
      }
      return result
    }
  }
}
