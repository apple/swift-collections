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
  internal func filter(
    _ level: _HashLevel,
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Builder? {
    guard !isCollisionNode else {
      return try _filter_slow(level, isIncluded)
    }
    return unsafe try self.read {
      var result: Builder = .empty(level)
      var removing = false // true if we need to remove something

      for (bucket, slot) in unsafe $0.itemMap {
        let p = unsafe $0.itemPtr(at: slot)
        let include = try isIncluded(unsafe p.pointee)
        switch (include, removing) {
        case (true, true):
          unsafe result.addNewItem(level, p.pointee, at: bucket)
        case (false, false):
          removing = true
          unsafe result.copyItems(level, from: $0, upTo: bucket)
        default:
          break
        }
      }

      for (bucket, slot) in unsafe $0.childMap {
        let branch = unsafe try $0[child: slot].filter(level.descend(), isIncluded)
        if let branch = branch {
          assert(branch.count < self.count)
          if !removing {
            removing = true
            unsafe result.copyItemsAndChildren(level, from: $0, upTo: bucket)
          }
          unsafe result.addNewChildBranch(level, branch, at: bucket)
        } else if removing {
          unsafe result.addNewChildNode(level, $0[child: slot], at: bucket)
        }
      }

      guard removing else { return nil }
      return result
    }
  }

  @inlinable @inline(never)
  internal func _filter_slow(
    _ level: _HashLevel,
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Builder? {
    unsafe try self.read {
      var result: Builder = .empty(level)
      var removing = false

      for slot: _HashSlot in stride(from: .zero, to: unsafe $0.itemsEndSlot, by: 1) {
        let p = unsafe $0.itemPtr(at: slot)
        let include = unsafe try isIncluded(p.pointee)
        if include, removing {
          unsafe result.addNewCollision(level, p.pointee, $0.collisionHash)
        }
        else if !include, !removing {
          removing = true
          unsafe result.copyCollisions(from: $0, upTo: slot)
        }
      }
      guard removing else { return nil }
      assert(result.count < self.count)
      return result
    }
  }
}
