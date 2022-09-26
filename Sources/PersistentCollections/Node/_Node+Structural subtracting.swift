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
  internal func subtracting(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> Builder {
    // FIXME: Consider preserving `self` when nothing needs to be removed.
    if self.raw.storage === other.raw.storage { return .empty }

    if self.isCollisionNode || other.isCollisionNode {
      return _subtracting_slow(level, hashPrefix, other)
    }

    return self.read { l in
      other.read { r in
        var result: Builder = .empty
        for (bucket, _) in l.itemMap.intersection(r.itemMap) {
          let lslot = l.itemMap.slot(of: bucket)
          let rslot = r.itemMap.slot(of: bucket)
          let lp = l.itemPtr(at: lslot)
          if lp.pointee.key != r[item: rslot].key {
            let hashPrefix = hashPrefix.appending(bucket, at: level)
            result.addNewItem(level, lp.pointee, hashPrefix)
          }
        }

        for (bucket, _) in l.itemMap.intersection(r.childMap) {
          let lslot = l.itemMap.slot(of: bucket)
          let rslot = r.childMap.slot(of: bucket)
          let lp = l.itemPtr(at: lslot)
          let h = _Hash(lp.pointee.key)
          if !r[child: rslot].containsKey(level.descend(), lp.pointee.key, h) {
            result.addNewItem(level, lp.pointee, h)
          }
        }

        for (bucket, _) in l.childMap.intersection(r.itemMap) {
          let lslot = l.childMap.slot(of: bucket)
          let rslot = r.itemMap.slot(of: bucket)
          let rp = r.itemPtr(at: rslot)
          let h = _Hash(rp.pointee.key)
          let node = (
            l[child: lslot]
              .removing(level.descend(), rp.pointee.key, h)?.replacement
            ?? l[child: lslot])
          let branch = Builder(
            level.descend(), node, hashPrefix.appending(bucket, at: level))
          result.addNewChildBranch(level, branch)
        }

        for (bucket, _) in l.childMap.intersection(r.childMap) {
          let lslot = l.childMap.slot(of: bucket)
          let rslot = r.childMap.slot(of: bucket)
          let branch = l[child: lslot].subtracting(
            level.descend(),
            hashPrefix.appending(bucket, at: level),
            r[child: rslot])
          result.addNewChildBranch(level, branch)
        }
        return result
      }
    }
  }

  @inlinable @inline(never)
  internal func _subtracting_slow(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> Builder {
    let lc = self.isCollisionNode
    let rc = other.isCollisionNode
    if lc && rc {
      return read { l in
        other.read { r in
          guard l.collisionHash == r.collisionHash else { return .empty }
          var result: Builder = .empty
          let litems = l.reverseItems
          let ritems = r.reverseItems
          for i in litems.indices {
            if !ritems.contains(where: { $0.key == litems[i].key }) {
              result.addNewCollision(litems[i], l.collisionHash)
            }
          }
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
            let res = l.find(level, ritem.pointee.key, _Hash(ritem.pointee.key))
            guard let res = res else {
              return .node(self, l.collisionHash)
            }
            assert(!res.descend)
            var node = self.copy()
            node.removeItem(at: res.slot, .invalid) {
              _ = $0.deinitialize(count: 1)
            }
            return Builder(level, node, l.collisionHash)
          }
          else if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            let h = hashPrefix.appending(bucket, at: level)
            return subtracting(level.descend(), h, r[child: rslot])
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
          let h = _Hash(litem.pointee.key)
          let res = r.find(level, litem.pointee.key, h)
          if res != nil { return .empty }
          return .item(litem.pointee, h)
        }
        if l.childMap.contains(bucket) {
          let lslot = l.itemMap.slot(of: bucket)
          return subtracting(
            level.descend(),
            hashPrefix.appending(bucket, at: level),
            l[child: lslot])
        }
        return .empty
      }
    }
  }

}
