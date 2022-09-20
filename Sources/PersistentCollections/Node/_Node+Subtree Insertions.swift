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
  internal mutating func updateValue(
    _ value: __owned Value,
    forKey key: Key,
    _ level: _Level,
    _ hash: _Hash
  ) -> Value? {
    defer { _invariantCheck() }
    let isUnique = self.isUnique()
    let r = find(level, key, hash, forInsert: true)
    switch r {
    case .found(_, let slot):
      ensureUnique(isUnique: isUnique)
      _invariantCheck() // FIXME
      return update {
        let p = $0.itemPtr(at: slot)
        let old = p.pointee.value
        p.pointee.value = value
        return old
      }
    case .notFound(let bucket, let slot):
      ensureUniqueAndInsertItem(isUnique: isUnique, slot, bucket) {
        $0.initialize(to: (key, value))
      }
      return nil
    case .newCollision(let bucket, let slot):
      _ = ensureUniqueAndMakeNewCollision(
        isUnique: isUnique,
        level: level,
        replacing: slot, bucket,
        newHash: hash
      ) {
        $0.initialize(to: (key, value))
      }
      return nil
    case .expansion(let collisionHash):
      self = _Node.build(
        level: level,
        item1: { $0.initialize(to: (key, value)) }, hash,
        child2: self, collisionHash
      ).top
      return nil
    case .descend(_, let slot):
      ensureUnique(isUnique: isUnique)
      let old = update {
        $0[child: slot].updateValue(value, forKey: key, level.descend(), hash)
      }
      if old == nil { count &+= 1 }
      return old
    }
  }

  @inlinable
  internal mutating func insertValue(
    forKey key: Key,
    _ level: _Level,
    _ hash: _Hash,
    with value: () -> Value
  ) -> (inserted: Bool, leaf: _UnmanagedNode, slot: _Slot) {
    defer { _invariantCheck() }
    let isUnique = self.isUnique()
    let r = find(level, key, hash, forInsert: true)
    switch r {
    case .found(_, let slot):
      ensureUnique(isUnique: isUnique)
      _invariantCheck() // FIXME
      return (false, unmanaged, slot)
    case .notFound(let bucket, let slot):
      ensureUniqueAndInsertItem(isUnique: isUnique, slot, bucket) {
        $0.initialize(to: (key, value()))
      }
      return (true, unmanaged, slot)
    case .newCollision(let bucket, let slot):
      let r = ensureUniqueAndMakeNewCollision(
        isUnique: isUnique,
        level: level,
        replacing: slot, bucket,
        newHash: hash
      ) {
        $0.initialize(to: (key, value()))
      }
      return (true, r.leaf, r.slot)
    case .expansion(let collisionHash):
      let r = _Node.build(
        level: level,
        item1: { $0.initialize(to: (key, value())) }, hash,
        child2: self, collisionHash
      )
      self = r.top
      return (true, r.leaf, r.slot1)
    case .descend(_, let slot):
      ensureUnique(isUnique: isUnique)
      let r = update {
        $0[child: slot]
          .insertValue(forKey: key, level.descend(), hash, with: value)
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
    // Copy items into new storage.
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
    // Copy items into new storage.
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
  internal mutating func ensureUniqueAndMakeNewCollision(
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
      ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewItem)
      count &+= 1
      update {
        $0.collisionCount = 1
        let p = $0._makeRoomForNewItem(at: _Slot(1), .invalid)
        inserter(p)
      }
      return (unmanaged, _Slot(1))
    }

    if !isUnique {
      let r = copyNodeAndMakeNewCollision(
        level: level,
        replacing: slot, bucket,
        existingHash: existingHash,
        newHash: newHash,
        inserter: inserter)
      self = r.node
      return (r.leaf, r.slot)
    }
    if !hasFreeSpace(Self.spaceForNewCollision) {
      return moveNodeAndMakeNewCollision(
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
  internal func copyNodeAndMakeNewCollision(
    level: _Level,
    replacing slot: _Slot,
    _ bucket: _Bucket,
    existingHash: _Hash,
    newHash: _Hash,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (node: _Node, leaf: _UnmanagedNode, slot: _Slot) {
    let (itemMap, childMap) = (
      self.raw.storage.header.bitmapsForNewCollision(at: slot, bucket))
    let c = self.count
    let childSlot = childMap.slot(of: bucket)
    let r = read { src in
      Self.allocate(
        itemMap: itemMap, childMap: childMap, count: c &+ 1
      ) { dstChildren, dstItems in
        let srcChildren = src.children
        let srcItems = src.reverseItems

        // Initialize children.
        dstChildren.prefix(childSlot.value)
          .initializeAll(fromContentsOf: srcChildren.prefix(childSlot.value))
        let rest = srcChildren.count &- childSlot.value
        dstChildren.suffix(rest)
          .initializeAll(fromContentsOf: srcChildren.suffix(rest))

        let r = _Node.build(
          level: level.descend(),
          item1: srcItems[slot.value], existingHash,
          item2: inserter, newHash)
        dstChildren.initializeElement(at: childSlot.value, to: r.top)

        // Initialize items.
        dstItems.prefix(slot.value)
          .initializeAll(fromContentsOf: srcItems.prefix(slot.value))
        let rest2 = dstItems.count &- slot.value
        dstItems.suffix(rest2)
          .initializeAll(fromContentsOf: srcItems.suffix(rest2))

        return (leaf: r.leaf, slot: r.slot2)
      }
    }
    return (r.node, r.result.leaf, r.result.slot)
  }

  @inlinable @inline(never)
  internal mutating func moveNodeAndMakeNewCollision(
    level: _Level,
    replacing slot: _Slot,
    _ bucket: _Bucket,
    existingHash: _Hash,
    newHash: _Hash,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (leaf: _UnmanagedNode, slot: _Slot) {
    let (itemMap, childMap) = (
      self.raw.storage.header.bitmapsForNewCollision(at: slot, bucket))
    let c = self.count
    let childSlot = childMap.slot(of: bucket)
    let r = update { src in
      Self.allocate(
        itemMap: itemMap, childMap: childMap, count: c &+ 1
      ) { dstChildren, dstItems in
        let srcChildren = src.children
        let srcItems = src.reverseItems

        // Initialize children.
        dstChildren.prefix(childSlot.value)
          .moveInitializeAll(fromContentsOf: srcChildren.prefix(childSlot.value))
        let rest = srcChildren.count &- childSlot.value
        dstChildren.suffix(rest)
          .moveInitializeAll(fromContentsOf: srcChildren.suffix(rest))

        let r = _Node.build(
          level: level.descend(),
          item1: srcItems.moveElement(from: slot.value), existingHash,
          item2: inserter, newHash)
        dstChildren.initializeElement(at: childSlot.value, to: r.top)

        // Initialize items.
        dstItems.prefix(slot.value)
          .moveInitializeAll(fromContentsOf: srcItems.prefix(slot.value))
        let rest2 = dstItems.count &- slot.value
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

