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
  /// Returns true if `self` contains a disjoint set of keys than `other`.
  /// Otherwise, returns false.
  @inlinable @inline(never)
  internal func isDisjoint<Value2>(
    _ level: _Level,
    with other: _Node<Key, Value2>
  ) -> Bool {
    if self.raw.storage === other.raw.storage { return count == 0 }

    if self.isCollisionNode {
      return _isDisjointCollision(level, with: other)
    }
    if other.isCollisionNode {
      return other._isDisjointCollision(level, with: other)
    }

    return self.read { l in
      other.read { r in
        let lmap = l.itemMap.union(l.childMap)
        let rmap = r.itemMap.union(r.childMap)
        if lmap.isDisjoint(with: rmap) { return true }

        for bucket in l.itemMap.intersection(r.itemMap) {
          let lslot = l.itemMap.slot(of: bucket)
          let rslot = r.itemMap.slot(of: bucket)
          guard l[item: lslot].key == r[item: rslot].key else { return false }
        }
        for bucket in l.itemMap.intersection(r.childMap) {
          let lslot = l.itemMap.slot(of: bucket)
          let hash = _Hash(l[item: lslot].key)
          let rslot = r.childMap.slot(of: bucket)
          let found = r[child: rslot].containsKey(
            level.descend(),
            l[item: lslot].key,
            hash)
          if found { return false }
        }
        for bucket in l.childMap.intersection(r.itemMap) {
          let lslot = l.childMap.slot(of: bucket)
          let rslot = r.itemMap.slot(of: bucket)
          let hash = _Hash(r[item: rslot].key)
          let found = l[child: lslot].containsKey(
            level.descend(),
            r[item: rslot].key,
            hash)
          if found { return false }
        }
        for bucket in l.childMap.intersection(r.childMap) {
          let lslot = l.childMap.slot(of: bucket)
          let rslot = r.childMap.slot(of: bucket)
          guard
            l[child: lslot].isDisjoint(level.descend(), with: r[child: rslot])
          else { return false }
        }
        return true
      }
    }
  }

  @inlinable @inline(never)
  internal func _isDisjointCollision<Value2>(
    _ level: _Level,
    with other: _Node<Key, Value2>
  ) -> Bool {
    // Beware, self might be on a compressed path
    assert(isCollisionNode)
    return read {
      let items = $0.reverseItems
      let hash = $0.collisionHash
      return items.indices.allSatisfy {
        !other.containsKey(level, items[$0].key, hash)
      }
    }
  }
}
