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
  internal mutating func merge(
  _ level: _Level,
  _ other: _Node,
  _ combine: (Value, Value) throws -> Value
  ) rethrows {
    guard other.count > 0 else { return }
    guard self.count > 0 else {
      self = other
      return
    }
    if level.isAtRoot, self.hasSingletonItem {
      // In this special case, the root node may turn into a collision node
      // during the merge process. Prevent this from causing issues below by
      // handling it up front.
      var copy = other
      try self.read { l in
        let lp = l.itemPtr(at: .zero)
        let res = copy.updateValue(
          level, forKey: lp.pointee.key, _Hash(lp.pointee.key)
        ) {
          $0.initialize(to: lp.pointee)
        }
        if !res.inserted {
          try UnsafeHandle.update(res.leaf) {
            let p = $0.itemPtr(at: res.slot)
            p.pointee.value = try combine(lp.pointee.value, p.pointee.value)
          }
        }
      }
      self = copy
      return
    }

    try _merge(level, other, combine)
  }

  @inlinable
  internal mutating func _merge(
    _ level: _Level,
    _ other: _Node,
    _ combine: (Value, Value) throws -> Value
  ) rethrows {
    // Note: don't check storage identities -- we do need to merge the contents
    // of identical nodes.

    if self.isCollisionNode || other.isCollisionNode {
      try _merge_slow(level, other, combine)
      return
    }

    var isUnique = self.isUnique()

    try other.read { r in
      let (originalItems, originalChildren) = self.read {
        ($0.itemMap, $0.childMap)
      }

      for (bucket, _) in originalItems {
        assert(!isCollisionNode)
        if r.itemMap.contains(bucket) {
          let rslot = r.itemMap.slot(of: bucket)
          let rp = r.itemPtr(at: rslot)
          let lslot = self.read { $0.itemMap.slot(of: bucket) }
          let conflict = self.read { $0[item: lslot].key == rp.pointee.key }
          if conflict {
            self.ensureUnique(isUnique: isUnique)
            try self.update {
              let p = $0.itemPtr(at: lslot)
              p.pointee.value = try combine(p.pointee.value, rp.pointee.value)
            }
          } else {
            _ = self.ensureUniqueAndSpawnChild(
              isUnique: isUnique,
              level: level,
              replacing: bucket,
              itemSlot: lslot,
              newHash: _Hash(rp.pointee.key),
              { $0.initialize(to: rp.pointee) })
            // If we hadn't handled the singleton root node case above,
            // then this call would sometimes turn `self` into a collision
            // node on a compressed path, causing mischief.
            assert(!self.isCollisionNode)
          }
          isUnique = true
        }
        else if r.childMap.contains(bucket) {
          let rslot = r.childMap.slot(of: bucket)
          let rp = r.childPtr(at: rslot)

          self.ensureUnique(
            isUnique: isUnique, withFreeSpace: _Node.spaceForSpawningChild)
          let item = self.removeItem(at: bucket)
          var child = rp.pointee
          let r = child.updateValue(
            level.descend(), forKey: item.key, _Hash(item.key)
          ) {
            $0.initialize(to: item)
          }
          if !r.inserted {
            try UnsafeHandle.update(r.leaf) {
              let p = $0.itemPtr(at: r.slot)
              p.pointee.value = try combine(item.value, p.pointee.value)
            }
          }
          self.insertChild(child, bucket)
          isUnique = true
        }
      }

      for (bucket, _) in originalChildren {
        assert(!isCollisionNode)
        let lslot = self.read { $0.childMap.slot(of: bucket) }

        if r.itemMap.contains(bucket) {
          let rslot = r.itemMap.slot(of: bucket)
          let rp = r.itemPtr(at: rslot)
          self.ensureUnique(isUnique: isUnique)
          let h = _Hash(rp.pointee.key)
          let res = self.update { l in
            l[child: lslot].updateValue(
              level.descend(), forKey: rp.pointee.key, h
            ) {
              $0.initialize(to: rp.pointee)
            }
          }
          if res.inserted {
            self.count &+= 1
          } else {
            try UnsafeHandle.update(res.leaf) {
              let p = $0.itemPtr(at: res.slot)
              p.pointee.value = try combine(p.pointee.value, rp.pointee.value)
            }
          }
          isUnique = true
        }
        else if r.childMap.contains(bucket) {
          let rslot = r.childMap.slot(of: bucket)
          self.ensureUnique(isUnique: isUnique)
          try self.update { l in
            try l[child: lslot].merge(
              level.descend(),
              r[child: rslot],
              combine)
          }
          isUnique = true
        }
      }

      assert(!self.isCollisionNode)

      /// Add buckets in `other` that we haven't processed above.
      let seen = self.read { l in l.itemMap.union(l.childMap) }
      for (bucket, _) in r.itemMap.subtracting(seen) {
        let rslot = r.itemMap.slot(of: bucket)
        self.ensureUniqueAndInsertItem(
          isUnique: isUnique, r[item: rslot], at: bucket)
        isUnique = true
      }
      for (bucket, _) in r.childMap.subtracting(seen) {
        let rslot = r.childMap.slot(of: bucket)
        self.ensureUnique(
          isUnique: isUnique, withFreeSpace: _Node.spaceForNewChild)
        self.insertChild(r[child: rslot], bucket)
        isUnique = true
      }

      assert(isUnique)
    }
  }

  @inlinable @inline(never)
  internal mutating func _merge_slow(
    _ level: _Level,
    _ other: _Node,
    _ combine: (Value, Value) throws -> Value
  ) rethrows {
    let lc = self.isCollisionNode
    let rc = other.isCollisionNode
    if lc && rc {
      guard self.collisionHash == other.collisionHash else {
        self = _Node.build(
          level: level,
          child1: self, self.collisionHash,
          child2: other, other.collisionHash)
        return
      }
      var isUnique = self.isUnique()
      return try other.read { r in
        let originalItemCount = self.count
        for rs: _Slot in stride(from: .zero, to: r.itemsEndSlot, by: 1) {
          let rp = r.itemPtr(at: rs)
          let lslot: _Slot? = self.read { l in
            let litems = l.reverseItems
            return litems
              .suffix(originalItemCount)
              .firstIndex { $0.key == rp.pointee.key }
              .map { _Slot(litems.count &- 1 &- $0) }
          }
          if let lslot = lslot {
            self.ensureUnique(isUnique: isUnique)
            try self.update {
              let p = $0.itemPtr(at: lslot)
              p.pointee.value = try combine(p.pointee.value, rp.pointee.value)
            }
          } else {
            _ = self.ensureUniqueAndAppendCollision(
              isUnique: isUnique, rp.pointee)
          }
          isUnique = true
        }
        return
      }
    }

    // One of the nodes must be on a compressed path.
    assert(!level.isAtBottom)

    if lc {
      // `self` is a collision node on a compressed path. The other tree might
      // have the same set of collisions, just expanded a bit deeper.
      return try other.read { r in
        let bucket = self.collisionHash[level]
        if r.itemMap.contains(bucket) {
          let rslot = r.itemMap.slot(of: bucket)
          let rp = r.itemPtr(at: rslot)

          let h = _Hash(rp.pointee.key)
          let res = self.updateValue(
            level.descend(), forKey: rp.pointee.key, h
          ) {
            $0.initialize(to: rp.pointee)
          }
          if !res.inserted {
            try UnsafeHandle.update(res.leaf) {
              let p = $0.itemPtr(at: res.slot)
              p.pointee.value = try combine(p.pointee.value, rp.pointee.value)
            }
          }
          self = other._copyNodeAndReplaceItemWithNewChild(
            level: level, self, at: bucket, itemSlot: rslot)
          return
        }

        if r.childMap.contains(bucket) {
          let rslot = r.childMap.slot(of: bucket)
          try self._merge(level.descend(), r[child: rslot], combine)
          var node = other.copy()
          _ = node.replaceChild(at: bucket, rslot, with: self)
          self = node
          return
        }

        var node = other.copy(withFreeSpace: _Node.spaceForNewChild)
        node.insertChild(self, bucket)
        self = node
        return
      }
    }

    assert(rc)
    let isUnique = self.isUnique()
    // `other` is a collision node on a compressed path.
    return try other.read { r in
      let bucket = r.collisionHash[level]
      if self.read({ $0.itemMap.contains(bucket) }) {
        self.ensureUnique(
          isUnique: isUnique, withFreeSpace: _Node.spaceForSpawningChild)
        let item = self.removeItem(at: bucket)
        let h = _Hash(item.key)
        var copy = other
        let res = copy.updateValue(level.descend(), forKey: item.key, h) {
          $0.initialize(to: item)
        }
        if !res.inserted {
          try UnsafeHandle.update(res.leaf) {
            let p = $0.itemPtr(at: res.slot)
            p.pointee.value = try combine(item.value, p.pointee.value)
          }
        }
        assert(self.count > 0) // Singleton case handled up front above
        self.insertChild(copy, bucket)
        return
      }
      if self.read({ $0.childMap.contains(bucket) }) {
        self.ensureUnique(isUnique: isUnique)
        let delta: Int = try self.update { l in
          let lslot = l.childMap.slot(of: bucket)
          let lchild = l.childPtr(at: lslot)
          let origCount = lchild.pointee.count
          try lchild.pointee._merge(level.descend(), other, combine)
          return lchild.pointee.count &- origCount
        }
        assert(delta >= 0)
        self.count &+= delta
        return
      }
      self.ensureUnique(
        isUnique: isUnique, withFreeSpace: _Node.spaceForNewChild)
      self.insertChild(other, bucket)
      return
    }
  }
}
