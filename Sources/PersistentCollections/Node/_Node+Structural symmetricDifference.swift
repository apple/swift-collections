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
  internal func symmetricDifference(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> Builder? {
    guard self.count > 0 else { return .node(other, hashPrefix) }
    guard other.count > 0 else { return nil }
    return _symmetricDifference(level, hashPrefix, other)
  }

  @inlinable
  internal func _symmetricDifference(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> Builder {
    assert(self.count > 0 && other.count > 0)

    if self.raw.storage === other.raw.storage {
      return .empty
    }
    if self.isCollisionNode || other.isCollisionNode {
      return _symmetricDifference_slow(level, hashPrefix, other)
    }

    return self.read { l in
      other.read { r in
        var result: Builder = .empty

        for (bucket, lslot) in l.itemMap {
          let lp = l.itemPtr(at: lslot)
          if r.itemMap.contains(bucket) {
            let rslot = r.itemMap.slot(of: bucket)
            let rp = r.itemPtr(at: rslot)
            if lp.pointee.key != rp.pointee.key {
              let h1 = _Hash(lp.pointee.key)
              let h2 = _Hash(rp.pointee.key)
              let child = _Node.build(
                level: level.descend(),
                item1: lp.pointee, h1,
                item2: { $0.initialize(to: rp.pointee) }, h2)
              result.addNewChildBranch(level, .node(child.top, h1))
            }
          }
          else if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            let rp = r.childPtr(at: rslot)
            let h = _Hash(lp.pointee.key)
            let child = rp.pointee
              .removing2(level.descend(), lp.pointee.key, h)?.replacement
            if let child = child {
              result.addNewChildBranch(level, child)
            }
            else {
              let child2 = rp.pointee.inserting(level.descend(), lp.pointee, h)
              assert(child2.inserted)
              result.addNewChildBranch(level, .node(child2.node, h))
            }
          }
          else {
            let h = hashPrefix.appending(bucket, at: level)
            result.addNewItem(level, lp.pointee, h)
          }
        }

        for (bucket, lslot) in l.childMap {
          let lp = l.childPtr(at: lslot)
          if r.itemMap.contains(bucket) {
            let rslot = r.itemMap.slot(of: bucket)
            let rp = r.itemPtr(at: rslot)
            let h = _Hash(rp.pointee.key)
            let child = lp.pointee
              .removing2(level.descend(), rp.pointee.key, h)?.replacement
            if let child = child {
              result.addNewChildBranch(level, child)
            }
            else {
              let child2 = lp.pointee.inserting(level.descend(), rp.pointee, h)
              assert(child2.inserted)
              result.addNewChildBranch(level, .node(child2.node, h))
            }
          }
          else if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            let hp = hashPrefix.appending(bucket, at: level)
            let b = l[child: lslot]._symmetricDifference(
              level.descend(), hp, r[child: rslot])
            result.addNewChildBranch(level, b)
          }
          else {
            let h = hashPrefix.appending(bucket, at: level)
            result.addNewChildBranch(level, .node(lp.pointee, h))
          }
        }

        let seen = l.itemMap.union(l.childMap)
        for (bucket, rslot) in r.itemMap {
          guard !seen.contains(bucket) else { continue }
          let h = hashPrefix.appending(bucket, at: level)
          result.addNewItem(level, r[item: rslot], h)
        }
        for (bucket, rslot) in r.childMap {
          guard !seen.contains(bucket) else { continue }
          let h = hashPrefix.appending(bucket, at: level)
          result.addNewChildBranch(level, .node(r[child: rslot], h))
        }
        return result
      }
    }
  }

  @inlinable @inline(never)
  internal func _symmetricDifference_slow(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> Builder {
    switch (self.isCollisionNode, other.isCollisionNode) {
    case (true, true):
      return self._symmetricDifference_slow_both(level, hashPrefix, other)
    case (true, false):
      return self._symmetricDifference_slow_left(level, hashPrefix, other)
    case (false, _):
      return other._symmetricDifference_slow_left(level, hashPrefix, self)
    }
  }

  @inlinable
  internal func _symmetricDifference_slow_both(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> Builder {
    read { l in
      other.read { r in
        guard l.collisionHash == r.collisionHash else {
          let node = _Node.build(
            level: level,
            child1: self, l.collisionHash,
            child2: other, r.collisionHash)
          return .node(node, l.collisionHash)
        }
        var result: Builder = .empty
        let ritems = r.reverseItems
        for ls: _Slot in stride(from: .zero, to: l.itemsEndSlot, by: 1) {
          let lp = l.itemPtr(at: ls)
          let include = !ritems.contains(where: { $0.key == lp.pointee.key })
          if include {
            result.addNewCollision(lp.pointee, l.collisionHash)
          }
        }
        // FIXME: Consider remembering slots of shared items in r by
        // caching them in a bitset.
        let litems = l.reverseItems
        for rs: _Slot in stride(from: .zero, to: r.itemsEndSlot, by: 1) {
          let rp = r.itemPtr(at: rs)
          let include = !litems.contains(where: { $0.key == rp.pointee.key })
          if include {
            result.addNewCollision(rp.pointee, r.collisionHash)
          }
        }
        return result
      }
    }
  }

  @inlinable
  internal func _symmetricDifference_slow_left(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> Builder {
    // `self` is a collision node on a compressed path. The other tree might
    // have the same set of collisions, just expanded a bit deeper.
    read { l in
      other.read { r in
        assert(l.isCollisionNode && !r.isCollisionNode)
        let bucket = l.collisionHash[level]
        if r.itemMap.contains(bucket) {
          let rslot = r.itemMap.slot(of: bucket)
          let rp = r.itemPtr(at: rslot)
          let litems = l.reverseItems
          if let li = litems.firstIndex(where: { $0.key == rp.pointee.key }) {
            if l.itemCount == 2 {
              var node = other.copy()
              node.replaceItem(at: bucket, rslot, with: litems[1 &- li])
              return .node(node, l.collisionHash)
            }
            let lslot = _Slot(litems.count &- 1 &- li)
            var child = self.copy()
            _ = child.removeItem(at: lslot, .invalid)
            var node = other.copy(withFreeSpace: _Node.spaceForSpawningChild)
            _ = node.removeItem(at: rslot, bucket)
            node.insertChild(child, bucket)
            return .node(node, hashPrefix)
          }
          var node = other.copy(withFreeSpace: _Node.spaceForSpawningChild)
          let item = node.removeItem(at: rslot, bucket)
          let child = self.copyNodeAndAppendCollision {
            $0.initialize(to: item)
          }
          node.insertChild(child.node, bucket)
          return .node(node, hashPrefix)
        }
        if r.childMap.contains(bucket) {
          let rslot = r.childMap.slot(of: bucket)
          let rp = r.childPtr(at: rslot)
          let hp = hashPrefix.appending(bucket, at: level)
          let child = rp.pointee._symmetricDifference(
            level.descend(), hp, self)
          return other.replacingChild(level, hp, rslot, with: child)
        }
        var node = other.copy(withFreeSpace: _Node.spaceForNewChild)
        node.insertChild(self, bucket)
        return .node(node, hashPrefix)
      }
    }
  }
}
