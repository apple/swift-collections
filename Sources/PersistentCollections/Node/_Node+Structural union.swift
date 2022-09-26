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
  internal func union(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> (copied: Bool, node: _Node) {
    if self.raw.storage === other.raw.storage {
      return (false, self)
    }

    if self.isCollisionNode || other.isCollisionNode {
      return _union_slow(level, hashPrefix, other)
    }

    return self.read { l in
      other.read { r in
        var node = self
        var copied = false

        for (bucket, lslot) in l.itemMap {
          if r.itemMap.contains(bucket) {
            let rslot = r.itemMap.slot(of: bucket)
            let lp = l.itemPtr(at: lslot)
            let rp = r.itemPtr(at: rslot)
            if lp.pointee.key != rp.pointee.key {
              _ = node.ensureUniqueAndSpawnChild(
                isUnique: copied,
                level: level,
                replacing: bucket,
                itemSlot: lslot,
                newHash: _Hash(rp.pointee.key),
                { $0.initialize(to: rp.pointee) })
              copied = true
            }
          }
          else if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            let lp = l.itemPtr(at: lslot)
            let rp = r.childPtr(at: rslot)
            let h = _Hash(lp.pointee.key)
            if !rp.pointee.containsKey(level.descend(), lp.pointee.key, h) {
              node.ensureUniqueAndPushItemIntoNewChild(
                isUnique: copied,
                level: level,
                rp.pointee,
                at: bucket,
                itemSlot: lslot)
              copied = true
            }
          }
        }

        for (bucket, lslot) in l.childMap {
          if r.itemMap.contains(bucket) {
            let rslot = r.itemMap.slot(of: bucket)
            let rp = r.itemPtr(at: rslot)
            let h = _Hash(rp.pointee.key)
            let r = l[child: lslot].inserting(
              level.descend(), rp.pointee.key, h
            ) {
              $0.initialize(to: rp.pointee)
            }
            guard r.inserted else {
              // Nothing to do
              continue
            }
            node.ensureUnique(isUnique: copied)
            node.update { $0[child: lslot] = r.node }
            node.count &+= 1
            copied = true
          }
          else if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            let child = l[child: lslot].union(
              level.descend(),
              hashPrefix.appending(bucket, at: level),
              r[child: rslot])
            guard child.copied else {
              // Nothing to do
              continue
            }
            node.ensureUnique(isUnique: copied)
            let delta = node.update {
              let p = $0.childPtr(at: lslot)
              let delta = child.node.count &- p.pointee.count
              $0[child: lslot] = child.node
              return delta
            }
            assert(delta > 0)
            node.count &+= delta
            copied = true
          }
        }

        return (copied, node)
      }
    }
  }

  @inlinable @inline(never)
  internal func _union_slow(
    _ level: _Level,
    _ hashPrefix: _Hash,
    _ other: _Node
  ) -> (copied: Bool, node: _Node) {
    let lc = self.isCollisionNode
    let rc = other.isCollisionNode
    if lc && rc {
      return read { l in
        other.read { r in
          guard l.collisionHash == r.collisionHash else {
            let node = _Node.build(
              level: level,
              child1: self, l.collisionHash,
              child2: other, r.collisionHash)
            return (true, node)
          }
          var copied = false
          var node = self
          let litems = l.reverseItems
          var p = r.itemPtr(at: .zero)
          let end = r.itemPtr(at: r.itemsEndSlot)
          while p != end {
            if !litems.contains(where: { $0.key == p.pointee.key }) {
              _ = node.ensureUniqueAndAppendCollision(
                isUnique: copied, p.pointee)
              copied = true
            }
          }
          return (copied, node)
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
            let node = other.copyNodeAndPushItemIntoNewChild(
              level: level,
              self,
              at: bucket,
              itemSlot: rslot)
            return (true, node)
          }
          else if r.childMap.contains(bucket) {
            let rslot = r.childMap.slot(of: bucket)
            let h = hashPrefix.appending(bucket, at: level)
            let res = self.union(level.descend(), h, r[child: rslot])
            var node = other.copy()
            node.update { $0[child: rslot] = res.node }
            return (true, node)
          }
          else {
            var node = other.copy(withFreeSpace: _Node.spaceForNewChild)
            node.insertChild(self, bucket)
            return (true, node)
          }
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
          let node = self.copyNodeAndPushItemIntoNewChild(
            level: level,
            other,
            at: bucket,
            itemSlot: lslot)
          return (true, node)
        }
        else if l.childMap.contains(bucket) {
          let lslot = l.childMap.slot(of: bucket)
          let h = hashPrefix.appending(bucket, at: level)
          let res = l[child: lslot].union(level.descend(), h, other)
          var node = self.copy()
          node.update { $0[child: lslot] = res.node }
          return (true, node)
        }
        else {
          var node = self.copy(withFreeSpace: _Node.spaceForNewChild)
          node.insertChild(other, bucket)
          return (true, node)
        }
      }
    }
  }
}
