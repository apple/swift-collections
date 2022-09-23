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

import _CollectionsUtilities

extension _Node {
  @inlinable
  internal mutating func insert(
    _ item: __owned Element,
    _ level: _Level,
    _ hash: _Hash
  ) -> Bool {
    let r = update(item.key, level, hash)
    guard r.inserted else { return false }
    UnsafeHandle.update(r.leaf) {
      let p = $0.itemPtr(at: r.slot)
      p.initialize(to: item)
    }
    return true
  }

  @inlinable
  internal mutating func update(
    _ key: Key,
    _ level: _Level,
    _ hash: _Hash
  ) -> (inserted: Bool, leaf: _UnmanagedNode, slot: _Slot) {
    defer { _invariantCheck() }
    let isUnique = self.isUnique()
    let r = findForInsertion(level, key, hash)
    switch r {
    case .found(_, let slot):
      ensureUnique(isUnique: isUnique)
      return (false, unmanaged, slot)
    case .insert(let bucket, let slot):
      ensureUniqueAndInsertItem(isUnique: isUnique, slot, bucket) { _ in }
      return (true, unmanaged, slot)
    case .appendCollision:
      ensureUniqueAndAppendCollision(isUnique: isUnique, hash) { _ in }
      return (true, unmanaged, _Slot(self.count &- 1))
    case .spawnChild(let bucket, let slot):
      let r = ensureUniqueAndSpawnChild(
        isUnique: isUnique,
        level: level,
        replacing: slot, bucket,
        newHash: hash,
        inserter: { _ in }
      )
      return (true, r.leaf, r.slot)
    case .expansion:
      let r = _Node.build(
        level: level,
        item1: { _ in }, hash,
        child2: self, self.collisionHash)
      self = r.top
      return (true, r.leaf, r.slot1)
    case .descend(_, let slot):
      ensureUnique(isUnique: isUnique)
      let r = update {
        $0[child: slot].update(key, level.descend(), hash)
      }
      if r.inserted { count &+= 1 }
      return r
    }
  }
}

extension _Node {
  @inlinable
  internal mutating func ensureUniqueAndInsertItem(
    isUnique: Bool,
    _ slot: _Slot,
    _ bucket: _Bucket,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) {
    assert(!isCollisionNode)

    if !isUnique {
      self = copyNodeAndInsertItem(at: slot, bucket, inserter: inserter)
      return
    }
    if !hasFreeSpace(Self.spaceForNewItem) {
      moveNodeAndInsertItem(at: slot, bucket, inserter: inserter)
      return
    }
    // In-place insert.
    update {
      let p = $0._makeRoomForNewItem(at: slot, bucket)
      inserter(p)
    }
    self.count &+= 1
  }

  @inlinable @inline(never)
  internal func copyNodeAndInsertItem(
    at slot: _Slot,
    _ bucket: _Bucket,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> _Node {
    assert(!isCollisionNode)
    let (itemMap, childMap) = (
      self.raw.storage.header.bitmapsForInsertingItem(at: slot, bucket))
    let c = self.count
    return read { src in
      Self.allocate(
        itemMap: itemMap, childMap: childMap, count: c &+ 1
      ) { dstChildren, dstItems in
        dstChildren.initializeAll(fromContentsOf: src.children)

        let srcItems = src.reverseItems
        assert(dstItems.count == srcItems.count + 1)
        dstItems.suffix(slot.value)
          .initializeAll(fromContentsOf: srcItems.suffix(slot.value))
        let rest = srcItems.count &- slot.value
        dstItems.prefix(rest)
          .initializeAll(fromContentsOf: srcItems.prefix(rest))

        inserter(dstItems.baseAddress! + rest)
      }
    }.node
  }

  @inlinable @inline(never)
  internal mutating func moveNodeAndInsertItem(
    at slot: _Slot,
    _ bucket: _Bucket,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) {
    assert(!isCollisionNode)
    let (itemMap, childMap) = (
      self.raw.storage.header.bitmapsForInsertingItem(at: slot, bucket))
    let c = self.count
    self = update { src in
      Self.allocate(
        itemMap: itemMap, childMap: childMap, count: c &+ 1
      ) { dstChildren, dstItems in
        dstChildren.moveInitializeAll(fromContentsOf: src.children)

        let srcItems = src.reverseItems
        assert(dstItems.count == srcItems.count + 1)
        dstItems.suffix(slot.value)
          .moveInitializeAll(fromContentsOf: srcItems.suffix(slot.value))
        let rest = srcItems.count &- slot.value
        dstItems.prefix(rest)
          .moveInitializeAll(fromContentsOf: srcItems.prefix(rest))

        inserter(dstItems.baseAddress! + rest)

        src.clear()
      }
    }.node
  }
}

extension _Node {
  @inlinable
  internal mutating func ensureUniqueAndAppendCollision(
    isUnique: Bool,
    _ hash: _Hash,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) {
    assert(isCollisionNode)
    if !isUnique {
      self = copyNodeAndAppendCollision(hash, inserter: inserter)
      return
    }
    if !hasFreeSpace(Self.spaceForNewItem) {
      moveNodeAndAppendCollision(hash, inserter: inserter)
      return
    }
    // In-place insert.
    update {
      let p = $0._makeRoomForNewItem(at: $0.itemsEndSlot, .invalid)
      inserter(p)
    }
    self.count &+= 1
  }

  @inlinable @inline(never)
  internal func copyNodeAndAppendCollision(
    _ hash: _Hash,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> _Node {
    assert(isCollisionNode)
    assert(hash == collisionHash)
    assert(self.count == read { $0.collisionCount })
    let c = self.count
    return read { src in
      Self.allocateCollision(count: c &+ 1, hash) { dstItems in
        let srcItems = src.reverseItems
        assert(dstItems.count == srcItems.count + 1)
        dstItems.dropFirst().initializeAll(fromContentsOf: srcItems)
        inserter(dstItems.baseAddress!)
      }.node
    }
  }

  @inlinable @inline(never)
  internal mutating func moveNodeAndAppendCollision(
    _ hash: _Hash,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) {
    assert(isCollisionNode)
    assert(hash == collisionHash)
    assert(self.count == read { $0.collisionCount })
    let c = self.count
    self = update { src in
      Self.allocateCollision(count: c &+ 1, hash) { dstItems in
        let srcItems = src.reverseItems
        assert(dstItems.count == srcItems.count + 1)
        dstItems.dropFirst().moveInitializeAll(fromContentsOf: srcItems)
        inserter(dstItems.baseAddress!)

        src.clear()
      }.node
    }
  }
}

extension _Node {
  @inlinable
  internal mutating func ensureUniqueAndSpawnChild(
    isUnique: Bool,
    level: _Level,
    replacing slot: _Slot,
    _ bucket: _Bucket,
    newHash: _Hash,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (leaf: _UnmanagedNode, slot: _Slot) {
    let existingHash = read { _Hash($0[item: slot].key) }
    if newHash == existingHash, hasSingletonItem {
      // Convert current node to a collision node.
      self = _Node._collisionNode(newHash, read { $0[item: .zero] }, inserter)
      return (unmanaged, _Slot(1))
    }

    if !isUnique {
      let r = copyNodeAndSpawnChild(
        level: level,
        replacing: slot, bucket,
        existingHash: existingHash,
        newHash: newHash,
        inserter: inserter)
      self = r.node
      return (r.leaf, r.slot)
    }
    if !hasFreeSpace(Self.spaceForSpawningChild) {
      return moveNodeAndSpawnChild(
        level: level,
        replacing: slot, bucket,
        existingHash: existingHash,
        newHash: newHash,
        inserter: inserter)
    }

    let existing = removeItem(at: slot, bucket) { $0.move() }
    let r = _Node.build(
      level: level.descend(),
      item1: existing, existingHash,
      item2: inserter, newHash)
    insertChild(r.top, bucket)
    return (r.leaf, r.slot2)
  }

  @inlinable @inline(never)
  internal func copyNodeAndSpawnChild(
    level: _Level,
    replacing slot: _Slot,
    _ bucket: _Bucket,
    existingHash: _Hash,
    newHash: _Hash,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (node: _Node, leaf: _UnmanagedNode, slot: _Slot) {
    let (itemMap, childMap) = (
      self.raw.storage.header.bitmapsForSpawningChild(at: slot, bucket))
    let c = self.count
    let childSlot = childMap.slot(of: bucket)
    let r = read { src in
      Self.allocate(
        itemMap: itemMap, childMap: childMap, count: c &+ 1
      ) { dstChildren, dstItems in
        let srcChildren = src.children
        let srcItems = src.reverseItems
        let i = srcItems.count &- 1 &- slot.value

        // Initialize children.
        dstChildren.prefix(childSlot.value)
          .initializeAll(fromContentsOf: srcChildren.prefix(childSlot.value))
        let rest = srcChildren.count &- childSlot.value
        dstChildren.suffix(rest)
          .initializeAll(fromContentsOf: srcChildren.suffix(rest))

        let r = _Node.build(
          level: level.descend(),
          item1: srcItems[i], existingHash,
          item2: inserter, newHash)
        dstChildren.initializeElement(at: childSlot.value, to: r.top)

        // Initialize items.
        dstItems.prefix(i).initializeAll(fromContentsOf: srcItems.prefix(i))
        let rest2 = dstItems.count &- i
        dstItems.suffix(rest2)
          .initializeAll(fromContentsOf: srcItems.suffix(rest2))

        return (leaf: r.leaf, slot: r.slot2)
      }
    }
    return (r.node, r.result.leaf, r.result.slot)
  }

  @inlinable @inline(never)
  internal mutating func moveNodeAndSpawnChild(
    level: _Level,
    replacing slot: _Slot,
    _ bucket: _Bucket,
    existingHash: _Hash,
    newHash: _Hash,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (leaf: _UnmanagedNode, slot: _Slot) {
    let (itemMap, childMap) = (
      self.raw.storage.header.bitmapsForSpawningChild(at: slot, bucket))
    let c = self.count
    let childSlot = childMap.slot(of: bucket)
    let r = update { src in
      Self.allocate(
        itemMap: itemMap, childMap: childMap, count: c &+ 1
      ) { dstChildren, dstItems in
        let srcChildren = src.children
        let srcItems = src.reverseItems
        let i = srcItems.count &- 1 &- slot.value

        // Initialize children.
        dstChildren.prefix(childSlot.value)
          .moveInitializeAll(fromContentsOf: srcChildren.prefix(childSlot.value))
        let rest = srcChildren.count &- childSlot.value
        dstChildren.suffix(rest)
          .moveInitializeAll(fromContentsOf: srcChildren.suffix(rest))

        let r = _Node.build(
          level: level.descend(),
          item1: srcItems.moveElement(from: i), existingHash,
          item2: inserter, newHash)
        dstChildren.initializeElement(at: childSlot.value, to: r.top)

        // Initialize items.
        dstItems.prefix(i).moveInitializeAll(fromContentsOf: srcItems.prefix(i))
        let rest2 = dstItems.count &- i
        dstItems.suffix(rest2)
          .moveInitializeAll(fromContentsOf: srcItems.suffix(rest2))

        src.clear()
        return (leaf: r.leaf, slot: r.slot2)
      }
    }
    r.node._invariantCheck()
    self = r.node
    return (r.result.leaf, r.result.slot)
  }
}

