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
  internal func subtracting<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> _HashNode? {
    assert(level.isAtRoot)
    let builder = _subtracting(level, other)
    guard let builder = builder else { return nil }
    let root = builder.finalize(.top)
    root._fullInvariantCheck()
    return root
  }

  @inlinable
  internal func _subtracting<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> Builder? {
    if self.raw.storage === other.raw.storage { return .empty(level) }

    if self.isCollisionNode || other.isCollisionNode {
      return _subtracting_slow(level, other)
    }

    return unsafe self.read { l in
      unsafe other.read { r in
        var result: Builder = .empty(level)
        var removing = false

        for (bucket, lslot) in unsafe l.itemMap {
          let lp = unsafe l.itemPtr(at: lslot)
          let include: Bool
          if unsafe r.itemMap.contains(bucket) {
            let rslot = unsafe r.itemMap.slot(of: bucket)
            include = unsafe (lp.pointee.key != r[item: rslot].key)
          }
          else if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            let h = unsafe _Hash(lp.pointee.key)
            include = unsafe !r[child: rslot]
              .containsKey(level.descend(), lp.pointee.key, h)
          }
          else {
            include = true
          }

          if include, removing {
            unsafe result.addNewItem(level, lp.pointee, at: bucket)
          }
          else if !include, !removing {
            removing = true
            unsafe result.copyItems(level, from: l, upTo: bucket)
          }
        }

        for (bucket, lslot) in unsafe l.childMap {
          var done = false
          if unsafe r.itemMap.contains(bucket) {
            let rslot = unsafe r.itemMap.slot(of: bucket)
            let rp = unsafe r.itemPtr(at: rslot)
            let h = unsafe _Hash(rp.pointee.key)
            let child = unsafe l[child: lslot]
                .removing(level.descend(), rp.pointee.key, h)?.replacement
            if let child = child {
              assert(child.count < self.count)
              if !removing {
                removing = true
                unsafe result.copyItemsAndChildren(level, from: l, upTo: bucket)
              }
              unsafe result.addNewChildBranch(level, child, at: bucket)
              done = true
            }
          }
          else if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            let child = unsafe l[child: lslot]
              ._subtracting(level.descend(), r[child: rslot])
            if let child = child {
              assert(child.count < self.count)
              if !removing {
                removing = true
                unsafe result.copyItemsAndChildren(level, from: l, upTo: bucket)
              }
              unsafe result.addNewChildBranch(level, child, at: bucket)
              done = true
            }
          }
          if !done, removing {
            unsafe result.addNewChildNode(level, l[child: lslot], at: bucket)
          }
        }
        guard removing else { return nil }
        return result
      }
    }
  }

  @inlinable @inline(never)
  internal func _subtracting_slow<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> Builder? {
    let lc = self.isCollisionNode
    let rc = other.isCollisionNode
    if lc && rc {
      return unsafe read { l in
        unsafe other.read { r in
          guard unsafe l.collisionHash == r.collisionHash else {
            return nil
          }
          var result: Builder = .empty(level)
          var removing = false

          let ritems = unsafe r.reverseItems
          for lslot: _HashSlot in stride(from: .zero, to: unsafe l.itemsEndSlot, by: 1) {
            let lp = unsafe l.itemPtr(at: lslot)
            let include = unsafe !ritems.contains { unsafe $0.key == lp.pointee.key }
            if include, removing {
              unsafe result.addNewCollision(level, lp.pointee, l.collisionHash)
            }
            else if !include, !removing {
              removing = true
              unsafe result.copyCollisions(from: l, upTo: lslot)
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
      return unsafe read { l in
        unsafe other.read { r in
          let bucket = unsafe l.collisionHash[level]
          if unsafe r.itemMap.contains(bucket) {
            let rslot = unsafe r.itemMap.slot(of: bucket)
            let ritem = unsafe r.itemPtr(at: rslot)
            let h = unsafe _Hash(ritem.pointee.key)
            let res = unsafe l.find(level, ritem.pointee.key, h)
            guard let res = res else { return nil }
            return unsafe self._removingItemFromLeaf(level, at: bucket, res.slot)
              .replacement
          }
          else if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            return unsafe _subtracting(level.descend(), r[child: rslot])
              .map { unsafe .childBranch(level, $0, at: bucket) }
          }
          return nil
        }
      }
    }

    assert(rc)
    // `other` is a collision node on a compressed path.
    return unsafe read { l in
      unsafe other.read { r in
        let bucket = unsafe r.collisionHash[level]
        if unsafe l.itemMap.contains(bucket) {
          let lslot = unsafe l.itemMap.slot(of: bucket)
          let litem = unsafe l.itemPtr(at: lslot)
          let h = unsafe _Hash(litem.pointee.key)
          let res = unsafe r.find(level, litem.pointee.key, h)
          if res == nil { return nil }
          return unsafe self._removingItemFromLeaf(level, at: bucket, lslot)
            .replacement
        }
        if unsafe l.childMap.contains(bucket) {
          let lslot = unsafe l.childMap.slot(of: bucket)
          let branch = unsafe l[child: lslot]._subtracting(level.descend(), other)
          guard let branch = branch else { return nil }
          var result = unsafe self._removingChild(level, at: bucket, lslot)
          unsafe result.addNewChildBranch(level, branch, at: bucket)
          return result
        }
        return nil
      }
    }
  }
}
