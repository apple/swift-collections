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
  internal func symmetricDifference<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> _HashNode<Key, Void>.Builder? {
    guard self.count > 0 else {
      return .init(level, other.mapValuesToVoid())
    }
    guard other.count > 0 else { return nil }
    return _symmetricDifference(level, other)
  }

  @inlinable
  internal func _symmetricDifference<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> _HashNode<Key, Void>.Builder {
    typealias VoidNode = _HashNode<Key, Void>

    assert(self.count > 0 && other.count > 0)

    if self.raw.storage === other.raw.storage {
      return .empty(level)
    }
    if self.isCollisionNode || other.isCollisionNode {
      return _symmetricDifference_slow(level, other)
    }

    return unsafe self.read { l in
      unsafe other.read { r in
        var result: VoidNode.Builder = .empty(level)

        for (bucket, lslot) in unsafe l.itemMap {
          let lp = unsafe l.itemPtr(at: lslot)
          if unsafe r.itemMap.contains(bucket) {
            let rslot = unsafe r.itemMap.slot(of: bucket)
            let rp = unsafe r.itemPtr(at: rslot)
            if unsafe lp.pointee.key != rp.pointee.key {
              let h1 = unsafe _Hash(lp.pointee.key)
              let h2 = unsafe _Hash(rp.pointee.key)
              let child = unsafe VoidNode.build(
                level: level.descend(),
                item1: (lp.pointee.key, ()), h1,
                item2: { unsafe $0.initialize(to: (rp.pointee.key, ())) }, h2)
              unsafe result.addNewChildNode(level, child.top, at: bucket)
            }
          }
          else if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            let rp = unsafe r.childPtr(at: rslot)
            let h = unsafe _Hash(lp.pointee.key)
            let child = unsafe rp.pointee
              .removing(level.descend(), lp.pointee.key, h)?.replacement
            if let child = child {
              let child = child.mapValuesToVoid()
              unsafe result.addNewChildBranch(level, child, at: bucket)
            }
            else {
              var child2 = unsafe rp.pointee
                .mapValuesToVoid(
                  copy: true, extraBytes: VoidNode.spaceForNewItem)
              let r = unsafe child2.insert(level.descend(), (lp.pointee.key, ()), h)
              assert(unsafe r.inserted)
              unsafe result.addNewChildNode(level, child2, at: bucket)
            }
          }
          else {
            unsafe result.addNewItem(level, (lp.pointee.key, ()), at: bucket)
          }
        }

        for (bucket, lslot) in unsafe l.childMap {
          let lp = unsafe l.childPtr(at: lslot)
          if unsafe r.itemMap.contains(bucket) {
            let rslot = unsafe r.itemMap.slot(of: bucket)
            let rp = unsafe r.itemPtr(at: rslot)
            let h = unsafe _Hash(rp.pointee.key)
            let child = unsafe lp.pointee
              .mapValuesToVoid()
              .removing(level.descend(), rp.pointee.key, h)?.replacement
            if let child = child {
              unsafe result.addNewChildBranch(level, child, at: bucket)
            }
            else {
              var child2 = unsafe lp.pointee.mapValuesToVoid(
                copy: true, extraBytes: VoidNode.spaceForNewItem)
              let r2 = unsafe child2.insert(level.descend(), (rp.pointee.key, ()), h)
              assert(unsafe r2.inserted)
              unsafe result.addNewChildNode(level, child2, at: bucket)
            }
          }
          else if unsafe r.childMap.contains(bucket) {
            let rslot = unsafe r.childMap.slot(of: bucket)
            let b = unsafe l[child: lslot]._symmetricDifference(
              level.descend(), r[child: rslot])
            unsafe result.addNewChildBranch(level, b, at: bucket)
          }
          else {
            unsafe result.addNewChildNode(
              level, lp.pointee.mapValuesToVoid(), at: bucket)
          }
        }

        let seen = unsafe l.itemMap.union(l.childMap)
        for (bucket, rslot) in unsafe r.itemMap {
          guard !seen.contains(bucket) else { continue }
          unsafe result.addNewItem(level, (r[item: rslot].key, ()), at: bucket)
        }
        for (bucket, rslot) in unsafe r.childMap {
          guard !seen.contains(bucket) else { continue }
          unsafe result.addNewChildNode(
            level, r[child: rslot].mapValuesToVoid(), at: bucket)
        }
        return result
      }
    }
  }

  @inlinable @inline(never)
  internal func _symmetricDifference_slow<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> _HashNode<Key, Void>.Builder {
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
  internal func _symmetricDifference_slow_both<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> _HashNode<Key, Void>.Builder {
    typealias VoidNode = _HashNode<Key, Void>
    return unsafe read { l in
      unsafe other.read { r in
        guard unsafe l.collisionHash == r.collisionHash else {
          let node = unsafe VoidNode.build(
            level: level,
            child1: self.mapValuesToVoid(), l.collisionHash,
            child2: other.mapValuesToVoid(), r.collisionHash)
          return .node(level, node)
        }
        var result: VoidNode.Builder = .empty(level)
        let ritems = unsafe r.reverseItems
        for ls: _HashSlot in stride(from: .zero, to: unsafe l.itemsEndSlot, by: 1) {
          let lp = unsafe l.itemPtr(at: ls)
          let include = unsafe !ritems.contains(where: { unsafe $0.key == lp.pointee.key })
          if include {
            unsafe result.addNewCollision(level, (lp.pointee.key, ()), l.collisionHash)
          }
        }
        // FIXME: Consider remembering slots of shared items in r by
        // caching them in a bitset.
        let litems = unsafe l.reverseItems
        for rs: _HashSlot in stride(from: .zero, to: unsafe r.itemsEndSlot, by: 1) {
          let rp = unsafe r.itemPtr(at: rs)
          let include = unsafe !litems.contains(where: { unsafe $0.key == rp.pointee.key })
          if include {
            unsafe result.addNewCollision(level, (rp.pointee.key, ()), r.collisionHash)
          }
        }
        return result
      }
    }
  }

  @inlinable
  internal func _symmetricDifference_slow_left<Value2>(
    _ level: _HashLevel,
    _ other: _HashNode<Key, Value2>
  ) -> _HashNode<Key, Void>.Builder {
    typealias VoidNode = _HashNode<Key, Void>
    // `self` is a collision node on a compressed path. The other tree might
    // have the same set of collisions, just expanded a bit deeper.
    return unsafe read { l in
      unsafe other.read { r in
        assert(unsafe l.isCollisionNode && !r.isCollisionNode)
        let bucket = unsafe l.collisionHash[level]
        if unsafe r.itemMap.contains(bucket) {
          let rslot = unsafe r.itemMap.slot(of: bucket)
          let rp = unsafe r.itemPtr(at: rslot)
          let rh = unsafe _Hash(rp.pointee.key)
          guard unsafe rh == l.collisionHash else {
            var copy = other.mapValuesToVoid(
              copy: true, extraBytes: VoidNode.spaceForSpawningChild)
            let item = unsafe copy.removeItem(at: bucket, rslot)
            let child = unsafe VoidNode.build(
              level: level.descend(),
              item1: { unsafe $0.initialize(to: (item.key, ())) }, rh,
              child2: self.mapValuesToVoid(), l.collisionHash)
            unsafe copy.insertChild(child.top, bucket)
            return .node(level, copy)
          }
          let litems = unsafe l.reverseItems
          if let li = unsafe litems.firstIndex(where: { unsafe $0.key == rp.pointee.key }) {
            if unsafe l.itemCount == 2 {
              var node = other.mapValuesToVoid(copy: true)
              unsafe node.replaceItem(
                at: bucket, rslot,
                with: (litems[1 &- li].key, ()))
              return .node(level, node)
            }
            let lslot = _HashSlot(litems.count &- 1 &- li)
            var child = self.mapValuesToVoid(copy: true)
            _ = unsafe child.removeItem(at: .invalid, lslot)
            if other.hasSingletonItem {
              // Compression
              return .collisionNode(level, child)
            }
            var node = other.mapValuesToVoid(
              copy: true, extraBytes: VoidNode.spaceForSpawningChild)
            _ = unsafe node.removeItem(at: bucket, rslot)
            unsafe node.insertChild(child, bucket)
            return .node(level, node)
          }
          if other.hasSingletonItem {
            // Compression
            var copy = self.mapValuesToVoid(
              copy: true, extraBytes: VoidNode.spaceForNewItem)
            _ = unsafe copy.ensureUniqueAndAppendCollision(
              isUnique: true,
              (r[item: .zero].key, ()))
            return .collisionNode(level, copy)
          }
          var node = other.mapValuesToVoid(
            copy: true, extraBytes: VoidNode.spaceForSpawningChild)
          let item = unsafe node.removeItem(at: bucket, rslot)
          var child = self.mapValuesToVoid(
            copy: true, extraBytes: VoidNode.spaceForNewItem)
          _ = unsafe child.ensureUniqueAndAppendCollision(
            isUnique: true, (item.key, ()))
          unsafe node.insertChild(child, bucket)
          return .node(level, node)
        }
        if unsafe r.childMap.contains(bucket) {
          let rslot = unsafe r.childMap.slot(of: bucket)
          let rp = unsafe r.childPtr(at: rslot)
          let child = unsafe rp.pointee._symmetricDifference(level.descend(), self)
          return unsafe other
            .mapValuesToVoid()
            .replacingChild(level, at: bucket, rslot, with: child)
        }
        var node = other
          .mapValuesToVoid(copy: true, extraBytes: VoidNode.spaceForNewChild)
        unsafe node.insertChild(self.mapValuesToVoid(), bucket)
        return .node(level, node)
      }
    }
  }
}
