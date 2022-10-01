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
    _ other: _Node
  ) -> Builder? {
    guard self.count > 0 else { return Builder(level, other) }
    guard other.count > 0 else { return nil }
    return _symmetricDifference(level, other)
  }

  @inlinable
  internal func _symmetricDifference(
    _ level: _Level,
    _ other: _Node
  ) -> Builder {
    assert(self.count > 0 && other.count > 0)

    if self.raw.storage === other.raw.storage {
      return .empty(level)
    }
    if self.isCollisionNode || other.isCollisionNode {
      return _symmetricDifference_slow(level, other)
    }

    return self.read { l in
      other.read { r in
        var result: Builder = .empty(level)

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
              result.addNewChildNode(level, child.top, at: bucket)
            }
          }
          else if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            let rp = r.childPtr(at: rslot)
            let h = _Hash(lp.pointee.key)
            let child = rp.pointee
              .removing(level.descend(), lp.pointee.key, h)?.replacement
            if let child = child {
              result.addNewChildBranch(level, child, at: bucket)
            }
            else {
              let child2 = rp.pointee.inserting(level.descend(), lp.pointee, h)
              assert(child2.inserted)
              result.addNewChildNode(level, child2.node, at: bucket)
            }
          }
          else {
            result.addNewItem(level, lp.pointee, at: bucket)
          }
        }

        for (bucket, lslot) in l.childMap {
          let lp = l.childPtr(at: lslot)
          if r.itemMap.contains(bucket) {
            let rslot = r.itemMap.slot(of: bucket)
            let rp = r.itemPtr(at: rslot)
            let h = _Hash(rp.pointee.key)
            let child = lp.pointee
              .removing(level.descend(), rp.pointee.key, h)?.replacement
            if let child = child {
              result.addNewChildBranch(level, child, at: bucket)
            }
            else {
              let child2 = lp.pointee.inserting(level.descend(), rp.pointee, h)
              assert(child2.inserted)
              result.addNewChildNode(level, child2.node, at: bucket)
            }
          }
          else if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            let b = l[child: lslot]._symmetricDifference(
              level.descend(), r[child: rslot])
            result.addNewChildBranch(level, b, at: bucket)
          }
          else {
            result.addNewChildNode(level, lp.pointee, at: bucket)
          }
        }

        let seen = l.itemMap.union(l.childMap)
        for (bucket, rslot) in r.itemMap {
          guard !seen.contains(bucket) else { continue }
          result.addNewItem(level, r[item: rslot], at: bucket)
        }
        for (bucket, rslot) in r.childMap {
          guard !seen.contains(bucket) else { continue }
          result.addNewChildNode(level, r[child: rslot], at: bucket)
        }
        return result
      }
    }
  }

  @inlinable @inline(never)
  internal func _symmetricDifference_slow(
    _ level: _Level,
    _ other: _Node
  ) -> Builder {
    switch (self.isCollisionNode, other.isCollisionNode) {
    case (true, true):
      return self._symmetricDifference_slow_both(level, other)
    case (true, false):
      return self._symmetricDifference_slow_left(level, other)
    case (false, _):
      return other._symmetricDifference_slow_left(level, self)
    }
  }

  @inlinable
  internal func _symmetricDifference_slow_both(
    _ level: _Level,
    _ other: _Node
  ) -> Builder {
    read { l in
      other.read { r in
        guard l.collisionHash == r.collisionHash else {
          let node = _Node.build(
            level: level,
            child1: self, l.collisionHash,
            child2: other, r.collisionHash)
          return .node(level, node)
        }
        var result: Builder = .empty(level)
        let ritems = r.reverseItems
        for ls: _Slot in stride(from: .zero, to: l.itemsEndSlot, by: 1) {
          let lp = l.itemPtr(at: ls)
          let include = !ritems.contains(where: { $0.key == lp.pointee.key })
          if include {
            result.addNewCollision(level, lp.pointee, l.collisionHash)
          }
        }
        // FIXME: Consider remembering slots of shared items in r by
        // caching them in a bitset.
        let litems = l.reverseItems
        for rs: _Slot in stride(from: .zero, to: r.itemsEndSlot, by: 1) {
          let rp = r.itemPtr(at: rs)
          let include = !litems.contains(where: { $0.key == rp.pointee.key })
          if include {
            result.addNewCollision(level, rp.pointee, r.collisionHash)
          }
        }
        return result
      }
    }
  }

  @inlinable
  internal func _symmetricDifference_slow_left(
    _ level: _Level,
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
          let rh = _Hash(rp.pointee.key)
          guard rh == l.collisionHash else {
            var copy = other.copy(withFreeSpace: _Node.spaceForSpawningChild)
            let item = copy.removeItem(at: bucket, rslot)
            let child = _Node.build(
              level: level.descend(),
              item1: { $0.initialize(to: item) }, rh,
              child2: self, l.collisionHash)
            copy.insertChild(child.top, bucket)
            return .node(level, copy)
          }
          let litems = l.reverseItems
          if let li = litems.firstIndex(where: { $0.key == rp.pointee.key }) {
            if l.itemCount == 2 {
              var node = other.copy()
              node.replaceItem(at: bucket, rslot, with: litems[1 &- li])
              return .node(level, node)
            }
            let lslot = _Slot(litems.count &- 1 &- li)
            var child = self.copy()
            _ = child.removeItem(at: .invalid, lslot)
            if other.hasSingletonItem {
              // Compression
              return .collisionNode(level, child)
            }
            var node = other.copy(withFreeSpace: _Node.spaceForSpawningChild)
            _ = node.removeItem(at: bucket, rslot)
            node.insertChild(child, bucket)
            return .node(level, node)
          }
          if other.hasSingletonItem {
            // Compression
            let copy = self.copyNodeAndAppendCollision {
              $0.initialize(to: r[item: .zero])
            }
            return .collisionNode(level, copy.node)
          }
          var node = other.copy(withFreeSpace: _Node.spaceForSpawningChild)
          let item = node.removeItem(at: bucket, rslot)
          let child = self.copyNodeAndAppendCollision {
            $0.initialize(to: item)
          }
          node.insertChild(child.node, bucket)
          return .node(level, node)
        }
        if r.childMap.contains(bucket) {
          let rslot = r.childMap.slot(of: bucket)
          let rp = r.childPtr(at: rslot)
          let child = rp.pointee._symmetricDifference(level.descend(), self)
          return other.replacingChild(level, at: bucket, rslot, with: child)
        }
        var node = other.copy(withFreeSpace: _Node.spaceForNewChild)
        node.insertChild(self, bucket)
        return .node(level, node)
      }
    }
  }
}
