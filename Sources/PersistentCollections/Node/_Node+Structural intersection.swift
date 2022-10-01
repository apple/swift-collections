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
  internal func intersection(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> Builder? {
    if self.raw.storage === other.raw.storage { return nil }

    if self.isCollisionNode || other.isCollisionNode {
      return _intersection_slow(level, hashPrefix, other)
    }

    return self.read { l in
      other.read { r in
        var result: Builder = .empty
        var removing = false

        for (bucket, lslot) in l.itemMap {
          let lp = l.itemPtr(at: lslot)
          let include: Bool
          if r.itemMap.contains(bucket) {
            let rslot = r.itemMap.slot(of: bucket)
            include = (lp.pointee.key == r[item: rslot].key)
          }
          else if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            let h = _Hash(lp.pointee.key)
            include = r[child: rslot]
              .containsKey(level.descend(), lp.pointee.key, h)
          }
          else { include = false}

          if include, removing {
            let hashPrefix = hashPrefix.appending(bucket, at: level)
            result.addNewItem(level, lp.pointee, hashPrefix)
          }
          else if !include, !removing {
            removing = true
            result.copyItems(level, hashPrefix, from: l, upTo: bucket)
          }
        }

        for (bucket, lslot) in l.childMap {
          if r.itemMap.contains(bucket) {
            if !removing {
              removing = true
              result.copyItemsAndChildren(
                level, hashPrefix, from: l, upTo: bucket)
            }
            let rslot = r.itemMap.slot(of: bucket)
            let rp = r.itemPtr(at: rslot)
            let h = _Hash(rp.pointee.key)
            let res = l[child: lslot].lookup(level.descend(), rp.pointee.key, h)
            if let res = res {
              UnsafeHandle.read(res.node) {
                let p = $0.itemPtr(at: res.slot)
                result.addNewItem(level, p.pointee, h)
              }
            }
          }
          else if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            let branch = l[child: lslot].intersection(
              level.descend(),
              hashPrefix.appending(bucket, at: level),
              r[child: rslot])
            if let branch = branch {
              assert(branch.count < self.count)
              if !removing {
                removing = true
                result.copyItemsAndChildren(
                  level, hashPrefix, from: l, upTo: bucket)
              }
              result.addNewChildBranch(level, branch)
            } else if removing {
              let h = hashPrefix.appending(bucket, at: level)
              result.addNewChildBranch(level, .node(l[child: lslot], h))
            }
          }
          else if !removing {
            removing = true
            result.copyItemsAndChildren(
              level, hashPrefix, from: l, upTo: bucket)
          }
        }
        guard removing else { return nil }
        return result
      }
    }
  }

  @inlinable @inline(never)
  internal func _intersection_slow(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> Builder? {
    let lc = self.isCollisionNode
    let rc = other.isCollisionNode
    if lc && rc {
      return read { l in
        other.read { r in
          guard l.collisionHash == r.collisionHash else { return .empty }
          var result: Builder = .empty
          var removing = false

          let ritems = r.reverseItems
          for lslot: _Slot in stride(from: .zero, to: l.itemsEndSlot, by: 1) {
            let lp = l.itemPtr(at: lslot)
            let include = ritems.contains { $0.key == lp.pointee.key }
            if include, removing {
              result.addNewCollision(lp.pointee, l.collisionHash)
            }
            else if !include, !removing {
              removing = true
              result.copyCollisions(from: l, upTo: lslot)
            }
          }
          guard removing else { return nil }
          assert(result.count < self.count)
          return result
        }
      }
    }

    // One of the nodes must be on a compressed path.
    assert(!level.isAtBottom)

    if lc {
      // `self` is a collision node on a compressed path. The other tree might
      // have the same set of collisions, just expanded a bit deeper.
      return read { l in
        other.read { r in
          let bucket = l.collisionHash[level]
          if r.itemMap.contains(bucket) {
            let rslot = r.itemMap.slot(of: bucket)
            let ritem = r.itemPtr(at: rslot)
            let litems = l.reverseItems
            let i = litems.firstIndex { $0.key == ritem.pointee.key }
            guard let i = i else { return .empty }
            return .item(litems[i], l.collisionHash)
          }
          if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            return intersection(
              level.descend(),
              hashPrefix.appending(bucket, at: level),
              r[child: rslot])
          }
          return .empty
        }
      }
    }

    assert(rc)
    // `other` is a collision node on a compressed path.
    return read { l in
      other.read { r in
        let bucket = r.collisionHash[level]
        if l.itemMap.contains(bucket) {
          let lslot = l.itemMap.slot(of: bucket)
          let litem = l.itemPtr(at: lslot)
          let ritems = r.reverseItems
          let found = ritems.contains { $0.key == litem.pointee.key }
          guard found else { return .empty }
          return .item(litem.pointee, r.collisionHash)
        }
        if l.childMap.contains(bucket) {
          let lslot = l.childMap.slot(of: bucket)
          let branch = l[child: lslot].intersection(
            level.descend(),
            hashPrefix.appending(bucket, at: level),
            other)
          guard let branch = branch else {
            assert(l[child: lslot].isCollisionNode)
            assert(l[child: lslot].collisionHash == r.collisionHash)
            // Compression
            return .node(l[child: lslot], r.collisionHash)
          }
          return .childBranch(level, branch)
        }
        return .empty
      }
    }
  }
}
