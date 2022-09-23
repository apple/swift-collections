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
  /// Returns true if `self` contains a subset of the keys in `other`.
  /// Otherwise, returns false.
  @inlinable @inline(never)
  internal func isSubset<Value2>(
    _ level: _Level,
    of other: _Node<Key, Value2>
  ) -> Bool {
    if self.raw.storage === other.raw.storage { return true }
    guard self.count <= other.count else { return false }

    if self.isCollisionNode {
      // Beware, self might be on a compressed path
      return read {
        let items = $0.reverseItems
        let hash = $0.collisionHash
        return items.indices.allSatisfy {
          other.containsKey(level, items[$0].key, hash)
        }
      }
    }

    guard !other.isCollisionNode else { return false }

    return self.read { l in
      other.read { r in
        guard l.childMap.isSubset(of: r.childMap) else { return false }
        guard l.itemMap.isSubset(of: r.itemMap.union(r.childMap)) else {
          return false
        }
        for bucket in l.itemMap {
          if r.itemMap.contains(bucket) {
            let lslot = l.itemMap.slot(of: bucket)
            let rslot = r.itemMap.slot(of: bucket)
            guard l[item: lslot].key == r[item: rslot].key else { return false }
          } else {
            let lslot = l.itemMap.slot(of: bucket)
            let hash = _Hash(l[item: lslot].key)
            let rslot = r.childMap.slot(of: bucket)
            guard
              r[child: rslot].containsKey(
                level.descend(),
                l[item: lslot].key,
                hash)
            else { return false }
          }
        }

        for bucket in l.childMap {
          let lslot = l.childMap.slot(of: bucket)
          let rslot = r.childMap.slot(of: bucket)
          guard l[child: lslot].isSubset(level.descend(), of: r[child: rslot])
          else { return false }
        }
        return true
      }
    }
  }
}
