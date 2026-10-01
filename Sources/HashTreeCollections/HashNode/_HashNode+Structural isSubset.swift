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
  /// Returns true if `self` contains a subset of the keys in `other`.
  /// Otherwise, returns false.
  @inlinable @inline(never)
  internal func isSubset<Value2>(
    _ level: _HashLevel,
    of other: _HashNode<Key, Value2>
  ) -> Bool {
    guard self.count > 0 else { return true }
    if self.raw.storage === other.raw.storage { return true }
    guard self.count <= other.count else { return false }

    if self.isCollisionNode {
      if other.isCollisionNode {
        guard self.collisionHash == other.collisionHash else { return false }
        return unsafe read { l in
          unsafe other.read { r in
            let li = unsafe l.reverseItems
            let ri = unsafe r.reverseItems
            return unsafe l.reverseItems.indices.allSatisfy { i in
              unsafe ri.contains { unsafe $0.key == li[i].key }
            }
          }
        }
      }
      // `self` is on a compressed path. Try to descend down by one level.
      assert(!level.isAtBottom)
      let bucket = self.collisionHash[level]
      return unsafe other.read {
        guard unsafe $0.childMap.contains(bucket) else { return false }
        let slot = unsafe $0.childMap.slot(of: bucket)
        return unsafe self.isSubset(level.descend(), of: $0[child: slot])
      }
    }
    if other.isCollisionNode {
      return unsafe read { l in
        guard level.isAtRoot, unsafe l.hasSingletonItem else { return false }
        // Annoying special case: the root node may contain a single item
        // that matches one in the collision node.
        return unsafe other.read { r in
          let hash = unsafe _Hash(l[item: .zero].key)
          return unsafe r.find(level, l[item: .zero].key, hash) != nil
        }
      }
    }

    return unsafe self.read { l in
      unsafe other.read { r in
        guard unsafe l.childMap.isSubset(of: r.childMap) else { return false }
        guard unsafe l.itemMap.isSubset(of: r.itemMap.union(r.childMap)) else {
          return false
        }
        for (bucket, lslot) in unsafe l.itemMap {
          if unsafe r.itemMap.contains(bucket) {
            let rslot = unsafe r.itemMap.slot(of: bucket)
            guard unsafe l[item: lslot].key == r[item: rslot].key else { return false }
          } else {
            let hash = unsafe _Hash(l[item: lslot].key)
            let rslot = unsafe r.childMap.slot(of: bucket)
            guard
              unsafe r[child: rslot].containsKey(
                level.descend(),
                l[item: lslot].key,
                hash)
            else { return false }
          }
        }

        for (bucket, lslot) in unsafe l.childMap {
          let rslot = unsafe r.childMap.slot(of: bucket)
          guard unsafe l[child: lslot].isSubset(level.descend(), of: r[child: rslot])
          else { return false }
        }
        return true
      }
    }
  }
}
