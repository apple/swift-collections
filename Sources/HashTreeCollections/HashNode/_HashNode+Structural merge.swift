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
  /// - Returns: The number of new items added to `self`.
  @inlinable
  internal mutating func merge(
  _ level: _HashLevel,
  _ other: _HashNode,
  _ combine: (Value, Value) throws -> Value
  ) rethrows -> Int {
    guard other.count > 0 else { return 0 }
    guard self.count > 0 else {
      self = other
      return self.count
    }
    if level.isAtRoot, self.hasSingletonItem {
      // In this special case, the root node may turn into a collision node
      // during the merge process. Prevent this from causing issues below by
      // handling it up front.
      var copy = other
      let delta = unsafe try self.read { l in
        let lp = unsafe l.itemPtr(at: .zero)
        let c = copy.count
        let res = unsafe copy.updateValue(
          level, forKey: lp.pointee.key, _Hash(lp.pointee.key)
        ) {
          unsafe $0.initialize(to: lp.pointee)
        }
        if unsafe !res.inserted {
          unsafe try UnsafeHandle.update(res.leaf) {
            let p = unsafe $0.itemPtr(at: res.slot)
            unsafe p.pointee.value = try combine(lp.pointee.value, p.pointee.value)
          }
        }
        return unsafe c - (res.inserted ? 0 : 1)
      }
      self = copy
      return delta
    }

    return try _merge(level, other, combine)
  }

  @inlinable
  internal mutating func _merge(
    _ level: _HashLevel,
    _ other: _HashNode,
    _ combine: (Value, Value) throws -> Value
  ) rethrows -> Int {
    // Note: don't check storage identities -- we do need to merge the contents
    // of identical nodes.

    if self.isCollisionNode || other.isCollisionNode {
      return try _merge_slow(level, other, combine)
    }

    return unsafe try other.read { r in
      var isUnique = self.isUnique()
      var delta = 0

      let (originalItems, originalChildren) = unsafe self.read {
        unsafe ($0.itemMap, $0.childMap)
      }

      for (bucket, _) in originalItems {
        assert(!isCollisionNode)
        if unsafe r.itemMap.contains(bucket) {
          let rslot = unsafe r.itemMap.slot(of: bucket)
          let rp = unsafe r.itemPtr(at: rslot)
          let lslot = unsafe self.read { unsafe $0.itemMap.slot(of: bucket) }
          let conflict = unsafe self.read { unsafe $0[item: lslot].key == rp.pointee.key }
          if conflict {
            self.ensureUnique(isUnique: isUnique)
            unsafe try self.update {
              let p = unsafe $0.itemPtr(at: lslot)
              unsafe p.pointee.value = try combine(p.pointee.value, rp.pointee.value)
            }
          } else {
            _ = unsafe self.ensureUniqueAndSpawnChild(
              isUnique: isUnique,
              level: level,
              replacing: bucket,
              itemSlot: lslot,
              newHash: _Hash(rp.pointee.key),
              { unsafe $0.initialize(to: rp.pointee) })
            // If we hadn't handled the singleton root node case above,
            // then this call would sometimes turn `self` into a collision
            // node on a compressed path, causing mischief.
            assert(!self.isCollisionNode)
            delta &+= 1
          }
          isUnique = true
        }
        else if unsafe r.childMap.contains(bucket) {
          let rslot = unsafe r.childMap.slot(of: bucket)
          let rp = unsafe r.childPtr(at: rslot)

          self.ensureUnique(
            isUnique: isUnique, withFreeSpace: _HashNode.spaceForSpawningChild)
          let item = unsafe self.removeItem(at: bucket)
          delta &-= 1
          var child = unsafe rp.pointee
          let r = unsafe child.updateValue(
            level.descend(), forKey: item.key, _Hash(item.key)
          ) {
            unsafe $0.initialize(to: item)
          }
          if unsafe !r.inserted {
            try unsafe UnsafeHandle.update(r.leaf) {
              let p = unsafe $0.itemPtr(at: r.slot)
              unsafe p.pointee.value = try combine(item.value, p.pointee.value)
            }
          }
          unsafe self.insertChild(child, bucket)
          isUnique = true
          delta &+= child.count
        }
      }

      for (bucket, _) in originalChildren {
        assert(!isCollisionNode)
        let lslot = unsafe self.read { unsafe $0.childMap.slot(of: bucket) }

        if unsafe r.itemMap.contains(bucket) {
          let rslot = unsafe r.itemMap.slot(of: bucket)
          let rp = unsafe r.itemPtr(at: rslot)
          self.ensureUnique(isUnique: isUnique)
          let h = unsafe _Hash(rp.pointee.key)
          let res = unsafe self.update { l in
            unsafe l[child: lslot].updateValue(
              level.descend(), forKey: rp.pointee.key, h
            ) {
              unsafe $0.initialize(to: rp.pointee)
            }
          }
          if unsafe res.inserted {
            self.count &+= 1
            delta &+= 1
          } else {
            unsafe try UnsafeHandle.update(res.leaf) {
              let p = unsafe $0.itemPtr(at: res.slot)
              unsafe p.pointee.value = try combine(p.pointee.value, rp.pointee.value)
            }
          }
          isUnique = true
        }
        else if unsafe r.childMap.contains(bucket) {
          let rslot = unsafe r.childMap.slot(of: bucket)
          self.ensureUnique(isUnique: isUnique)
          let d = unsafe try self.update { l in
            unsafe try l[child: lslot].merge(
              level.descend(),
              r[child: rslot],
              combine)
          }
          self.count &+= d
          delta &+= d
          isUnique = true
        }
      }

      assert(!self.isCollisionNode)

      /// Add buckets in `other` that we haven't processed above.
      let seen = unsafe self.read { l in unsafe l.itemMap.union(l.childMap) }
      for (bucket, _) in unsafe r.itemMap.subtracting(seen) {
        let rslot = unsafe r.itemMap.slot(of: bucket)
        unsafe self.ensureUniqueAndInsertItem(
          isUnique: isUnique, r[item: rslot], at: bucket)
        delta &+= 1
        isUnique = true
      }
      for (bucket, _) in unsafe r.childMap.subtracting(seen) {
        let rslot = unsafe r.childMap.slot(of: bucket)
        self.ensureUnique(
          isUnique: isUnique, withFreeSpace: _HashNode.spaceForNewChild)
        unsafe self.insertChild(r[child: rslot], bucket)
        unsafe delta &+= r[child: rslot].count
        isUnique = true
      }

      assert(isUnique)
      return delta
    }
  }

  @inlinable @inline(never)
  internal mutating func _merge_slow(
    _ level: _HashLevel,
    _ other: _HashNode,
    _ combine: (Value, Value) throws -> Value
  ) rethrows -> Int {
    let lc = self.isCollisionNode
    let rc = other.isCollisionNode
    if lc && rc {
      guard self.collisionHash == other.collisionHash else {
        self = _HashNode.build(
          level: level,
          child1: self, self.collisionHash,
          child2: other, other.collisionHash)
        return other.count
      }
      return unsafe try other.read { r in
        var isUnique = self.isUnique()
        var delta = 0
        let originalItemCount = self.count
        for rs: _HashSlot in stride(from: .zero, to: unsafe r.itemsEndSlot, by: 1) {
          let rp = unsafe r.itemPtr(at: rs)
          let lslot: _HashSlot? = unsafe self.read { l in
            let litems = unsafe l.reverseItems
            return unsafe litems
              .suffix(originalItemCount)
              .firstIndex { unsafe $0.key == rp.pointee.key }
              .map { _HashSlot(litems.count &- 1 &- $0) }
          }
          if let lslot = lslot {
            self.ensureUnique(isUnique: isUnique)
            unsafe try self.update {
              let p = unsafe $0.itemPtr(at: lslot)
              unsafe p.pointee.value = try combine(p.pointee.value, rp.pointee.value)
            }
          } else {
            _ = unsafe self.ensureUniqueAndAppendCollision(
              isUnique: isUnique, rp.pointee)
            delta &+= 1
          }
          isUnique = true
        }
        return delta
      }
    }

    // One of the nodes must be on a compressed path.
    assert(!level.isAtBottom)

    if lc {
      // `self` is a collision node on a compressed path. The other tree might
      // have the same set of collisions, just expanded a bit deeper.
      return unsafe try other.read { r in
        let bucket = self.collisionHash[level]
        if unsafe r.itemMap.contains(bucket) {
          let rslot = unsafe r.itemMap.slot(of: bucket)
          let rp = unsafe r.itemPtr(at: rslot)

          let h = unsafe _Hash(rp.pointee.key)
          let res = unsafe self.updateValue(
            level.descend(), forKey: rp.pointee.key, h
          ) {
            unsafe $0.initialize(to: rp.pointee)
          }
          if unsafe !res.inserted {
            unsafe try UnsafeHandle.update(res.leaf) {
              let p = unsafe $0.itemPtr(at: res.slot)
              unsafe p.pointee.value = try combine(p.pointee.value, rp.pointee.value)
            }
          }
          self = unsafe other._copyNodeAndReplaceItemWithNewChild(
            level: level, self, at: bucket, itemSlot: rslot)
          return unsafe other.count - (res.inserted ? 0 : 1)
        }

        if unsafe r.childMap.contains(bucket) {
          let originalCount = self.count
          let rslot = unsafe r.childMap.slot(of: bucket)
          _ = unsafe try self._merge(level.descend(), r[child: rslot], combine)
          var node = other.copy()
          _ = unsafe node.replaceChild(at: bucket, rslot, with: self)
          self = node
          return self.count - originalCount
        }

        var node = other.copy(withFreeSpace: _HashNode.spaceForNewChild)
        unsafe node.insertChild(self, bucket)
        self = node
        return other.count
      }
    }

    assert(rc)
    let isUnique = self.isUnique()
    // `other` is a collision node on a compressed path.
    return unsafe try other.read { r in
      let bucket = unsafe r.collisionHash[level]
      if unsafe self.read({ unsafe $0.itemMap.contains(bucket) }) {
        self.ensureUnique(
          isUnique: isUnique, withFreeSpace: _HashNode.spaceForSpawningChild)
        let item = unsafe self.removeItem(at: bucket)
        let h = _Hash(item.key)
        var copy = other
        let res = unsafe copy.updateValue(level.descend(), forKey: item.key, h) {
          unsafe $0.initialize(to: item)
        }
        if unsafe !res.inserted {
          unsafe try UnsafeHandle.update(res.leaf) {
            let p = unsafe $0.itemPtr(at: res.slot)
            unsafe p.pointee.value = try combine(item.value, p.pointee.value)
          }
        }
        assert(self.count > 0) // Singleton case handled up front above
        unsafe self.insertChild(copy, bucket)
        return unsafe other.count - (res.inserted ? 0 : 1)
      }
      if unsafe self.read({ unsafe $0.childMap.contains(bucket) }) {
        self.ensureUnique(isUnique: isUnique)
        let delta: Int = unsafe try self.update { l in
          let lslot = unsafe l.childMap.slot(of: bucket)
          let lchild = unsafe l.childPtr(at: lslot)
          return unsafe try lchild.pointee._merge(level.descend(), other, combine)
        }
        assert(delta >= 0)
        self.count &+= delta
        return delta
      }
      self.ensureUnique(
        isUnique: isUnique, withFreeSpace: _HashNode.spaceForNewChild)
      unsafe self.insertChild(other, bucket)
      return other.count
    }
  }
}
