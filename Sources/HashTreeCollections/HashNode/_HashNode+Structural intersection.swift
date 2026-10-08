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
  internal func intersection<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> _HashNode? {
    assert(level.isAtRoot)
    let builder = _intersection(level, other)
    guard let builder = builder else { return nil }
    let root = builder.finalize(.top)
    root._fullInvariantCheck()
    return root
  }

  @inlinable
  internal func _intersection<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> Builder? {
    if self.raw.storage === other.raw.storage { return nil }

    if self.isCollisionNode || other.isCollisionNode {
      return _intersection_slow(level, other)
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
            include = unsafe (lp.pointee.key == r[item: rslot].key)
          }
          else if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            let h = unsafe _Hash(lp.pointee.key)
            include = unsafe r[child: rslot]
              .containsKey(level.descend(), lp.pointee.key, h)
          }
          else { include = false}

          if include, removing {
            unsafe result.addNewItem(level, lp.pointee, at: bucket)
          }
          else if !include, !removing {
            removing = true
            unsafe result.copyItems(level, from: l, upTo: bucket)
          }
        }

        for (bucket, lslot) in unsafe l.childMap {
          if unsafe r.itemMap.contains(bucket) {
            if !removing {
              removing = true
              unsafe result.copyItemsAndChildren(level, from: l, upTo: bucket)
            }
            let rslot = unsafe r.itemMap.slot(of: bucket)
            let rp = unsafe r.itemPtr(at: rslot)
            let h = unsafe _Hash(rp.pointee.key)
            let res = unsafe l[child: lslot].lookup(level.descend(), rp.pointee.key, h)
            if let res = unsafe res {
              let item = unsafe UnsafeHandle.read(res.node) { unsafe $0[item: res.slot] }
              unsafe result.addNewItem(level, item, at: bucket)
            }
          }
          else if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            let branch = unsafe l[child: lslot]
              ._intersection(level.descend(), r[child: rslot])
            if let branch = branch {
              assert(branch.count < self.count)
              if !removing {
                removing = true
                unsafe result.copyItemsAndChildren(level, from: l, upTo: bucket)
              }
              unsafe result.addNewChildBranch(level, branch, at: bucket)
            } else if removing {
              unsafe result.addNewChildNode(level, l[child: lslot], at: bucket)
            }
          }
          else if !removing {
            removing = true
            unsafe result.copyItemsAndChildren(level, from: l, upTo: bucket)
          }
        }
        guard removing else { return nil }
        return result
      }
    }
  }

  @inlinable @inline(never)
  internal func _intersection_slow<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> Builder? {
    let lc = self.isCollisionNode
    let rc = other.isCollisionNode
    if lc && rc {
      return unsafe read { l in
        unsafe other.read { r in
          var result: Builder = .empty(level)
          guard unsafe l.collisionHash == r.collisionHash else { return result }

          var removing = false
          let ritems = unsafe r.reverseItems
          for lslot: _HashSlot in stride(from: .zero, to: unsafe l.itemsEndSlot, by: 1) {
            let lp = unsafe l.itemPtr(at: lslot)
            let include = unsafe ritems.contains { unsafe $0.key == lp.pointee.key }
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
            let litems = unsafe l.reverseItems
            let i = unsafe litems.firstIndex { unsafe $0.key == ritem.pointee.key }
            guard let i = i else { return .empty(level) }
            return unsafe .item(level, litems[i], at: l.collisionHash[level])
          }
          if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            return unsafe _intersection(level.descend(), r[child: rslot])
              .map { unsafe .childBranch(level, $0, at: bucket) }
          }
          return .empty(level)
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
          let ritems = unsafe r.reverseItems
          let found = unsafe ritems.contains { unsafe $0.key == litem.pointee.key }
          guard found else { return .empty(level) }
          return unsafe .item(level, litem.pointee, at: bucket)
        }
        if unsafe l.childMap.contains(bucket) {
          let lslot = unsafe l.childMap.slot(of: bucket)
          let branch = unsafe l[child: lslot]._intersection(level.descend(), other)
          guard let branch = branch else {
            assert(unsafe l[child: lslot].isCollisionNode)
            assert(unsafe l[child: lslot].collisionHash == r.collisionHash)
            // Compression
            return .collisionNode(level, unsafe l[child: lslot])
          }
          return unsafe .childBranch(level, branch, at: bucket)
        }
        return .empty(level)
      }
    }
  }
}
