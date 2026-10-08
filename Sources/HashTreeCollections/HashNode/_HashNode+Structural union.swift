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
  @inlinable
  internal func union<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> (copied: Bool, node: _HashNode<Key, Void>) {
    guard self.count > 0 else { return (true, other.mapValuesToVoid()) }
    guard other.count > 0 else { return (false, self.mapValuesToVoid()) }
    if level.isAtRoot, self.hasSingletonItem {
      // In this special case, the root node may turn into a collision node
      // during the merge process. Prevent this from causing issues below by
      // handling it up front.
      return unsafe self.read { l in
        let lp = unsafe l.itemPtr(at: .zero)
        var copy = other.mapValuesToVoid(copy: true)
        let r = unsafe copy.updateValue(
          level, forKey: lp.pointee.key, _Hash(lp.pointee.key)
        ) {
          unsafe $0.initialize(to: (lp.pointee.key, ()))
        }
        if unsafe !r.inserted {
          unsafe UnsafeHandle.update(r.leaf) {
            unsafe $0[item: r.slot] = lp.pointee
          }
        }
        return (true, copy)
      }
    }
    return _union(level, other)
  }

  @inlinable
  internal func _union<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> (copied: Bool, node: _HashNode<Key, Void>) {
    if self.raw.storage === other.raw.storage {
      return (false, self.mapValuesToVoid())
    }

    if self.isCollisionNode || other.isCollisionNode {
      return _union_slow(level, other)
    }

    return unsafe self.read { l in
      unsafe other.read { r in
        var node = self.mapValuesToVoid()
        var copied = false

        for (bucket, lslot) in unsafe l.itemMap {
          assert(!node.isCollisionNode)
          if unsafe r.itemMap.contains(bucket) {
            let rslot = unsafe r.itemMap.slot(of: bucket)
            let lp = unsafe l.itemPtr(at: lslot)
            let rp = unsafe r.itemPtr(at: rslot)
            if unsafe lp.pointee.key != rp.pointee.key {
              let slot = (
                copied
                ? unsafe node.read { unsafe $0.itemMap.slot(of: bucket) }
                : lslot)
              _ = unsafe node.ensureUniqueAndSpawnChild(
                isUnique: copied,
                level: level,
                replacing: bucket,
                itemSlot: slot,
                newHash: _Hash(rp.pointee.key),
                { unsafe $0.initialize(to: (rp.pointee.key, ())) })
              // If we hadn't handled the singleton root node case above,
              // then this call would sometimes turn `node` into a collision
              // node on a compressed path, causing mischief.
              assert(!node.isCollisionNode)
              copied = true
            }
          }
          else if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            let rp = unsafe r.childPtr(at: rslot)

            node.ensureUnique(
              isUnique: copied, withFreeSpace: _HashNode.spaceForSpawningChild)
            let item = unsafe node.removeItem(at: bucket)
            let r = unsafe rp.pointee.mapValuesToVoid()
              .inserting(level.descend(), (item.key, ()), _Hash(item.key))
            unsafe node.insertChild(r.node, bucket)
            copied = true
          }
        }

        for (bucket, lslot) in unsafe l.childMap {
          assert(!node.isCollisionNode)
          if unsafe r.itemMap.contains(bucket) {
            let rslot = unsafe r.itemMap.slot(of: bucket)
            let rp = unsafe r.itemPtr(at: rslot)
            let h = unsafe _Hash(rp.pointee.key)
            let r = unsafe l[child: lslot].mapValuesToVoid()
              .inserting(level.descend(), (rp.pointee.key, ()), h)
            guard unsafe r.inserted else {
              // Nothing to do
              continue
            }
            node.ensureUnique(isUnique: copied)
            let delta = unsafe node.replaceChild(at: bucket, with: r.node)
            assert(delta == 1)
            copied = true
          }
          else if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            let child = unsafe l[child: lslot]._union(level.descend(), r[child: rslot])
            guard child.copied else {
              // Nothing to do
              continue
            }
            node.ensureUnique(isUnique: copied)
            let delta = unsafe node.replaceChild(at: bucket, with: child.node)
            assert(delta > 0) // If we didn't add an item, why did we copy?
            copied = true
          }
        }

        assert(!node.isCollisionNode)

        /// Add buckets in `other` that we haven't processed above.
        let seen = unsafe l.itemMap.union(l.childMap)

        for (bucket, _) in unsafe r.itemMap.subtracting(seen) {
          let rslot = unsafe r.itemMap.slot(of: bucket)
          unsafe node.ensureUniqueAndInsertItem(
            isUnique: copied, (r[item: rslot].key, ()), at: bucket)
          copied = true
        }
        for (bucket, _) in unsafe r.childMap.subtracting(seen) {
          let rslot = unsafe r.childMap.slot(of: bucket)
          node.ensureUnique(
            isUnique: copied, withFreeSpace: _HashNode.spaceForNewChild)
          copied = true
          unsafe node.insertChild(r[child: rslot].mapValuesToVoid(), bucket)
        }

        return (copied, node)
      }
    }
  }

  @inlinable @inline(never)
  internal func _union_slow<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> (copied: Bool, node: _HashNode<Key, Void>) {
    let lc = self.isCollisionNode
    let rc = other.isCollisionNode
    if lc && rc {
      return unsafe read { l in
        unsafe other.read { r in
          guard unsafe l.collisionHash == r.collisionHash else {
            let node = unsafe _HashNode<Key, Void>.build(
              level: level,
              child1: self.mapValuesToVoid(), l.collisionHash,
              child2: other.mapValuesToVoid(), r.collisionHash)
            return (true, node)
          }
          var copied = false
          var node = self.mapValuesToVoid()
          let litems = unsafe l.reverseItems
          for rs: _HashSlot in stride(from: .zero, to: unsafe r.itemsEndSlot, by: 1) {
            let p = unsafe r.itemPtr(at: rs)
            if unsafe !litems.contains(where: { unsafe $0.key == p.pointee.key }) {
              _ = unsafe node.ensureUniqueAndAppendCollision(
                isUnique: copied, (p.pointee.key, ()))
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
      return unsafe read { l in
        unsafe other.read { r in
          let bucket = unsafe l.collisionHash[level]
          if unsafe r.itemMap.contains(bucket) {
            let rslot = unsafe r.itemMap.slot(of: bucket)
            let rp = unsafe r.itemPtr(at: rslot)
            if
              unsafe r.hasSingletonItem
              && l.reverseItems.contains(where: { unsafe $0.key == rp.pointee.key })
            {
              return (false, self.mapValuesToVoid())
            }
            let node = unsafe other.mapValuesToVoid().copyNodeAndPushItemIntoNewChild(
              level: level, self.mapValuesToVoid(), at: bucket, itemSlot: rslot)
            return (true, node)
          }

          if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            let res = unsafe self._union(level.descend(), r[child: rslot])
            var node = other.mapValuesToVoid(copy: true)
            let delta = unsafe node.replaceChild(at: bucket, rslot, with: res.node)
            assert(delta >= 0)
            return (true, node)
          }

          var node = other.mapValuesToVoid(
            copy: true, extraBytes: _HashNode<Key, Void>.spaceForNewChild)
          unsafe node.insertChild(self.mapValuesToVoid(), bucket)
          return (true, node)
        }
      }
    }

    assert(rc)
    // `other` is a collision node on a compressed path.
    return unsafe read { l -> (copied: Bool, node: _HashNode<Key, Void>) in
      unsafe other.read { r -> (copied: Bool, node: _HashNode<Key, Void>) in
        let bucket = unsafe r.collisionHash[level]
        if unsafe l.itemMap.contains(bucket) {
          let lslot = unsafe l.itemMap.slot(of: bucket)
          assert(unsafe !l.hasSingletonItem) // Handled up front above
          let node = unsafe self.mapValuesToVoid().copyNodeAndPushItemIntoNewChild(
            level: level, other.mapValuesToVoid(), at: bucket, itemSlot: lslot)
          return (true, node)
        }
        if unsafe l.childMap.contains(bucket) {
          let lslot = unsafe l.childMap.slot(of: bucket)
          let child = unsafe l[child: lslot]._union(level.descend(), other)
          guard child.copied else { return (false, self.mapValuesToVoid()) }
          var node = self.mapValuesToVoid(copy: true)
          let delta = unsafe node.replaceChild(at: bucket, lslot, with: child.node)
          assert(delta > 0) // If we didn't add an item, why did we copy?
          return (true, node)
        }

        var node = self.mapValuesToVoid(
          copy: true, extraBytes: _HashNode.spaceForNewChild)
        unsafe node.insertChild(other.mapValuesToVoid(), bucket)
        return (true, node)
      }
    }
  }
}
