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
  internal func compactMapValues<T>(
    _ level: _HashLevel,
    _ transform: (Value) throws -> T?
  ) rethrows -> _HashNode<Key, T>.Builder {
    return unsafe try self.read {
      var result: _HashNode<Key, T>.Builder = .empty(level)

      if isCollisionNode {
        let items = unsafe $0.reverseItems
        for i in items.indices {
          if let v = unsafe try transform(items[i].value) {
            unsafe result.addNewCollision(level, (items[i].key, v), $0.collisionHash)
          }
        }
        return result
      }

      for (bucket, slot) in unsafe $0.itemMap {
        let p = unsafe $0.itemPtr(at: slot)
        if let v = unsafe try transform(p.pointee.value) {
          unsafe result.addNewItem(level, (p.pointee.key, v), at: bucket)
        }
      }

      for (bucket, slot) in unsafe $0.childMap {
        let branch = unsafe try $0[child: slot]
          .compactMapValues(level.descend(), transform)
        unsafe result.addNewChildBranch(level, branch, at: bucket)
      }
      return result
    }
  }
}
