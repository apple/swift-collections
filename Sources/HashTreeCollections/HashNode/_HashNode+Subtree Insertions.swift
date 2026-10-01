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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

extension _HashNode {
  @inlinable
  internal mutating func insert(
    _ level: _HashLevel,
    _ item: Element,
    _ hash: _Hash
  ) -> (inserted: Bool, leaf: _UnmanagedHashNode, slot: _HashSlot) {
    unsafe insert(level, item.key, hash) { unsafe $0.initialize(to: item) }
  }

  @inlinable
  internal mutating func insert(
    _ level: _HashLevel,
    _ key: Key,
    _ hash: _Hash,
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (inserted: Bool, leaf: _UnmanagedHashNode, slot: _HashSlot) {
    defer { _invariantCheck() }
    let isUnique = self.isUnique()
    if !isUnique {
      let r = unsafe self.inserting(level, key, hash, inserter)
      self = unsafe r.node
      return unsafe (r.inserted, r.leaf, r.slot)
    }
    let r = findForInsertion(level, key, hash)
    switch r {
    case .found(_, let slot):
      return (false, unsafe unmanaged, slot)
    case .insert(let bucket, let slot):
      unsafe ensureUniqueAndInsertItem(
        isUnique: true, at: bucket, itemSlot: slot, inserter)
      return (true, unsafe unmanaged, slot)
    case .appendCollision:
      let slot = unsafe ensureUniqueAndAppendCollision(isUnique: true, inserter)
      return (true, unsafe unmanaged, slot)
    case .spawnChild(let bucket, let slot):
      let r = unsafe ensureUniqueAndSpawnChild(
        isUnique: true,
        level: level,
        replacing: bucket,
        itemSlot: slot,
        newHash: hash,
        inserter)
      return unsafe (true, r.leaf, r.slot)
    case .expansion:
      let r = unsafe _HashNode.build(
        level: level,
        item1: inserter, hash,
        child2: self, self.collisionHash)
      self = unsafe r.top
      return unsafe (true, r.leaf, r.slot1)
    case .descend(_, let slot):
      let r = unsafe update {
        unsafe $0[child: slot].insert(level.descend(), key, hash, inserter)
      }
      if unsafe r.inserted { count &+= 1 }
      return unsafe r
    }
  }

  @inlinable
  internal func inserting(
    _ level: _HashLevel,
    _ item: __owned Element,
    _ hash: _Hash
  ) -> (
    inserted: Bool, node: _HashNode, leaf: _UnmanagedHashNode, slot: _HashSlot
  ) {
    unsafe inserting(level, item.key, hash, { unsafe $0.initialize(to: item) })
  }

  @inlinable
  internal func inserting(
    _ level: _HashLevel,
    _ key: Key,
    _ hash: _Hash,
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (
    inserted: Bool, node: _HashNode, leaf: _UnmanagedHashNode, slot: _HashSlot
  ) {
    defer { _invariantCheck() }
    let r = findForInsertion(level, key, hash)
    switch r {
    case .found(_, let slot):
      return unsafe (false, self, unmanaged, slot)
    case .insert(let bucket, let slot):
      let node = unsafe copyNodeAndInsertItem(at: bucket, itemSlot: slot, inserter)
      return unsafe (true, node, node.unmanaged, slot)
    case .appendCollision:
      let r = unsafe copyNodeAndAppendCollision(inserter)
      return unsafe (true, r.node, r.node.unmanaged, r.slot)
    case .spawnChild(let bucket, let slot):
      let existingHash = unsafe read { unsafe _Hash($0[item: slot].key) }
      let r = unsafe copyNodeAndSpawnChild(
        level: level,
        replacing: bucket,
        itemSlot: slot,
        existingHash: existingHash,
        newHash: hash,
        inserter)
      return unsafe (true, r.node, r.leaf, r.slot)
    case .expansion:
      let r = unsafe _HashNode.build(
        level: level,
        item1: inserter, hash,
        child2: self, self.collisionHash)
      return unsafe (true, r.top, r.leaf, r.slot1)
    case .descend(_, let slot):
      let r = unsafe read {
        unsafe $0[child: slot].inserting(level.descend(), key, hash, inserter)
      }
      guard unsafe r.inserted else {
        return unsafe (false, self, r.leaf, r.slot)
      }
      var copy = self.copy()
      unsafe copy.update { unsafe $0[child: slot] = r.node }
      copy.count &+= 1
      return unsafe (true, copy, r.leaf, r.slot)
    }
  }

  @inlinable
  internal mutating func updateValue(
    _ level: _HashLevel,
    forKey key: Key,
    _ hash: _Hash,
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (inserted: Bool, leaf: _UnmanagedHashNode, slot: _HashSlot) {
    defer { _invariantCheck() }
    let isUnique = self.isUnique()
    let r = findForInsertion(level, key, hash)
    switch r {
    case .found(_, let slot):
      ensureUnique(isUnique: isUnique)
      return unsafe (false, unmanaged, slot)
    case .insert(let bucket, let slot):
      unsafe ensureUniqueAndInsertItem(
        isUnique: isUnique, at: bucket, itemSlot: slot, inserter)
      return unsafe (true, unmanaged, slot)
    case .appendCollision:
      let slot = unsafe ensureUniqueAndAppendCollision(isUnique: isUnique, inserter)
      return unsafe (true, unmanaged, slot)
    case .spawnChild(let bucket, let slot):
      let r = unsafe ensureUniqueAndSpawnChild(
        isUnique: isUnique,
        level: level,
        replacing: bucket,
        itemSlot: slot,
        newHash: hash,
        inserter)
      return unsafe (true, r.leaf, r.slot)
    case .expansion:
      let r = unsafe _HashNode.build(
        level: level,
        item1: inserter, hash,
        child2: self, self.collisionHash)
      self = unsafe r.top
      return unsafe (true, r.leaf, r.slot1)
    case .descend(_, let slot):
      ensureUnique(isUnique: isUnique)
      let r = unsafe update {
        unsafe $0[child: slot].updateValue(
          level.descend(), forKey: key, hash, inserter)
      }
      if unsafe r.inserted { count &+= 1 }
      return unsafe r
    }
  }
}

extension _HashNode {
  @inlinable
  internal mutating func ensureUniqueAndInsertItem(
    isUnique: Bool,
    _ item: Element,
    at bucket: _Bucket
  ) {
    let slot = unsafe self.read { unsafe $0.itemMap.slot(of: bucket) }
    unsafe ensureUniqueAndInsertItem(
      isUnique: isUnique,
      at: bucket,
      itemSlot: slot
    ) {
      unsafe $0.initialize(to: item)
    }
  }

  @inlinable
  internal mutating func ensureUniqueAndInsertItem(
    isUnique: Bool,
    at bucket: _Bucket,
    itemSlot slot: _HashSlot,
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) {
    assert(!isCollisionNode)

    if !isUnique {
      self = unsafe copyNodeAndInsertItem(at: bucket, itemSlot: slot, inserter)
      return
    }
    if !hasFreeSpace(Self.spaceForNewItem) {
      unsafe resizeNodeAndInsertItem(at: bucket, itemSlot: slot, inserter)
      return
    }
    // In-place insert.
    unsafe update {
      let p = unsafe $0._makeRoomForNewItem(at: slot, bucket)
      unsafe inserter(p)
    }
    self.count &+= 1
  }

  @inlinable @inline(never)
  internal func copyNodeAndInsertItem(
    at bucket: _Bucket,
    itemSlot slot: _HashSlot,
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> _HashNode {
    assert(!isCollisionNode)
    let c = self.count
    return unsafe read { src in
      assert(unsafe !src.itemMap.contains(bucket))
      assert(unsafe !src.childMap.contains(bucket))
      return unsafe Self.allocate(
        itemMap: src.itemMap.inserting(bucket),
        childMap: src.childMap,
        count: c &+ 1
      ) { dstChildren, dstItems in
        unsafe dstChildren.initializeAll(fromContentsOf: src.children)

        let srcItems = unsafe src.reverseItems
        assert(dstItems.count == srcItems.count + 1)
        unsafe dstItems.suffix(slot.value)
          .initializeAll(fromContentsOf: srcItems.suffix(slot.value))
        let rest = srcItems.count &- slot.value
        unsafe dstItems.prefix(rest)
          .initializeAll(fromContentsOf: srcItems.prefix(rest))

        unsafe inserter(dstItems.baseAddress! + rest)
      }.node
    }
  }

  @inlinable @inline(never)
  internal mutating func resizeNodeAndInsertItem(
    at bucket: _Bucket,
    itemSlot slot: _HashSlot,
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) {
    assert(!isCollisionNode)
    let c = self.count
    self = unsafe update { src in
      assert(unsafe !src.itemMap.contains(bucket))
      assert(unsafe !src.childMap.contains(bucket))
      return unsafe Self.allocate(
        itemMap: src.itemMap.inserting(bucket),
        childMap: src.childMap,
        count: c &+ 1
      ) { dstChildren, dstItems in
        unsafe dstChildren.moveInitializeAll(fromContentsOf: src.children)

        let srcItems = unsafe src.reverseItems
        assert(dstItems.count == srcItems.count + 1)
        unsafe dstItems.suffix(slot.value)
          .moveInitializeAll(fromContentsOf: srcItems.suffix(slot.value))
        let rest = srcItems.count &- slot.value
        unsafe dstItems.prefix(rest)
          .moveInitializeAll(fromContentsOf: srcItems.prefix(rest))

        unsafe inserter(dstItems.baseAddress! + rest)

        unsafe src.clear()
      }.node
    }
  }
}

extension _HashNode {
  @inlinable
  @unsafe
  internal mutating func ensureUniqueAndAppendCollision(
    isUnique: Bool,
    _ item: Element
  ) -> _HashSlot {
    unsafe ensureUniqueAndAppendCollision(isUnique: isUnique) {
      unsafe $0.initialize(to: item)
    }
  }

  @inlinable
  @unsafe
  internal mutating func ensureUniqueAndAppendCollision(
    isUnique: Bool,
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> _HashSlot {
    assert(isCollisionNode)
    if !isUnique {
      let r = unsafe copyNodeAndAppendCollision(inserter)
      self = r.node
      return r.slot
    }
    if !hasFreeSpace(Self.spaceForNewItem) {
      return unsafe resizeNodeAndAppendCollision(inserter)
    }
    // In-place insert.
    unsafe update {
      let p = unsafe $0._makeRoomForNewItem(at: $0.itemsEndSlot, .invalid)
      unsafe inserter(p)
    }
    self.count &+= 1
    return _HashSlot(self.count &- 1)
  }

  @inlinable @inline(never)
  @unsafe
  internal func copyNodeAndAppendCollision(
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (node: _HashNode, slot: _HashSlot) {
    assert(isCollisionNode)
    assert(unsafe self.count == read { unsafe $0.collisionCount })
    let c = self.count
    let node = unsafe read { src in
      unsafe Self.allocateCollision(count: c &+ 1, src.collisionHash) { dstItems in
        let srcItems = unsafe src.reverseItems
        assert(dstItems.count == srcItems.count + 1)
        unsafe dstItems.dropFirst().initializeAll(fromContentsOf: srcItems)
        unsafe inserter(dstItems.baseAddress!)
      }.node
    }
    return (node, _HashSlot(c))
  }

  @inlinable @inline(never)
  @unsafe
  internal mutating func resizeNodeAndAppendCollision(
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> _HashSlot {
    assert(isCollisionNode)
    assert(unsafe self.count == read { unsafe $0.collisionCount })
    let c = self.count
    self = unsafe update { src in
      unsafe Self.allocateCollision(count: c &+ 1, src.collisionHash) { dstItems in
        let srcItems = unsafe src.reverseItems
        assert(dstItems.count == srcItems.count + 1)
        unsafe dstItems.dropFirst().moveInitializeAll(fromContentsOf: srcItems)
        unsafe inserter(dstItems.baseAddress!)

        unsafe src.clear()
      }.node
    }
    return _HashSlot(c)
  }
}

extension _HashNode {
  @inlinable
  @unsafe
  internal func _copyNodeAndReplaceItemWithNewChild(
    level: _HashLevel,
    _ newChild: __owned _HashNode,
    at bucket: _Bucket,
    itemSlot: _HashSlot
  ) -> _HashNode {
    let c = self.count
    return unsafe read { src in
      assert(unsafe !src.isCollisionNode)
      assert(unsafe src.itemMap.contains(bucket))
      assert(unsafe !src.childMap.contains(bucket))
      assert(unsafe src.itemMap.slot(of: bucket) == itemSlot)

      if unsafe src.hasSingletonItem && newChild.isCollisionNode {
        // Compression
        return newChild
      }

      let childSlot = unsafe src.childMap.slot(of: bucket)
      return unsafe Self.allocate(
        itemMap: src.itemMap.removing(bucket),
        childMap: src.childMap.inserting(bucket),
        count: c &+ newChild.count &- 1
      ) { dstChildren, dstItems in
        let srcChildren = unsafe src.children
        let srcItems = unsafe src.reverseItems

        // Initialize children.
        unsafe dstChildren.prefix(childSlot.value)
          .initializeAll(fromContentsOf: srcChildren.prefix(childSlot.value))
        let rest = srcChildren.count &- childSlot.value
        unsafe dstChildren.suffix(rest)
          .initializeAll(fromContentsOf: srcChildren.suffix(rest))

        unsafe dstChildren.initializeElement(at: childSlot.value, to: newChild)

        // Initialize items.
        unsafe dstItems.suffix(itemSlot.value)
          .initializeAll(fromContentsOf: srcItems.suffix(itemSlot.value))
        let rest2 = dstItems.count &- itemSlot.value
        unsafe dstItems.prefix(rest2)
          .initializeAll(fromContentsOf: srcItems.prefix(rest2))
      }.node
    }
  }

  /// The item at `itemSlot` must have already been deinitialized by the time
  /// this function is called.
  @inlinable
  @unsafe
  internal mutating func _resizeNodeAndReplaceItemWithNewChild(
    level: _HashLevel,
    _ newChild: __owned _HashNode,
    at bucket: _Bucket,
    itemSlot: _HashSlot
  ) {
    let c = self.count
    let node: _HashNode = unsafe update { src in
      assert(unsafe !src.isCollisionNode)
      assert(unsafe src.itemMap.contains(bucket))
      assert(unsafe !src.childMap.contains(bucket))
      assert(unsafe src.itemMap.slot(of: bucket) == itemSlot)

      let childSlot = unsafe src.childMap.slot(of: bucket)
      return unsafe Self.allocate(
        itemMap: src.itemMap.removing(bucket),
        childMap: src.childMap.inserting(bucket),
        count: c &+ newChild.count &- 1
      ) { dstChildren, dstItems in
        let srcChildren = unsafe src.children
        let srcItems = unsafe src.reverseItems

        // Initialize children.
        unsafe dstChildren.prefix(childSlot.value)
          .moveInitializeAll(fromContentsOf: srcChildren.prefix(childSlot.value))
        let rest = srcChildren.count &- childSlot.value
        unsafe dstChildren.suffix(rest)
          .moveInitializeAll(fromContentsOf: srcChildren.suffix(rest))

        unsafe dstChildren.initializeElement(at: childSlot.value, to: newChild)

        // Initialize items.
        unsafe dstItems.suffix(itemSlot.value)
          .moveInitializeAll(fromContentsOf: srcItems.suffix(itemSlot.value))
        let rest2 = dstItems.count &- itemSlot.value
        unsafe dstItems.prefix(rest2)
          .moveInitializeAll(fromContentsOf: srcItems.prefix(rest2))

        unsafe src.clear()
      }.node
    }
    self = node
  }
}

extension _HashNode {
  @inlinable @inline(never)
  @unsafe
  internal func copyNodeAndPushItemIntoNewChild(
    level: _HashLevel,
    _ newChild: __owned _HashNode,
    at bucket: _Bucket,
    itemSlot: _HashSlot
  ) -> _HashNode {
    assert(!isCollisionNode)
    let item = unsafe read { unsafe $0[item: itemSlot] }
    let hash = _Hash(item.key)
    let r = unsafe newChild.inserting(level.descend(), item, hash)
    return unsafe _copyNodeAndReplaceItemWithNewChild(
      level: level,
      r.node,
      at: bucket,
      itemSlot: itemSlot)
  }
}

extension _HashNode {
  @inlinable
  @unsafe
  internal mutating func ensureUniqueAndSpawnChild(
    isUnique: Bool,
    level: _HashLevel,
    replacing bucket: _Bucket,
    itemSlot: _HashSlot,
    newHash: _Hash,
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (leaf: _UnmanagedHashNode, slot: _HashSlot) {
    let existingHash = unsafe read { unsafe _Hash($0[item: itemSlot].key) }
    assert(existingHash.isEqual(to: newHash, upTo: level))
    if newHash == existingHash, hasSingletonItem {
      // Convert current node to a collision node.
      self = unsafe _HashNode._collisionNode(newHash, read { unsafe $0[item: .zero] }, inserter)
      return unsafe (unmanaged, _HashSlot(1))
    }

    if !isUnique {
      let r = unsafe copyNodeAndSpawnChild(
        level: level,
        replacing: bucket,
        itemSlot: itemSlot,
        existingHash: existingHash,
        newHash: newHash,
        inserter)
      self = unsafe r.node
      return unsafe (r.leaf, r.slot)
    }
    if !hasFreeSpace(Self.spaceForSpawningChild) {
      return unsafe resizeNodeAndSpawnChild(
        level: level,
        replacing: bucket,
        itemSlot: itemSlot,
        existingHash: existingHash,
        newHash: newHash,
        inserter)
    }

    let existing = unsafe removeItem(at: bucket, itemSlot)
    let r = unsafe _HashNode.build(
      level: level.descend(),
      item1: existing, existingHash,
      item2: inserter, newHash)
    unsafe insertChild(r.top, bucket)
    return unsafe (r.leaf, r.slot2)
  }

  @inlinable @inline(never)
  @unsafe
  internal func copyNodeAndSpawnChild(
    level: _HashLevel,
    replacing bucket: _Bucket,
    itemSlot: _HashSlot,
    existingHash: _Hash,
    newHash: _Hash,
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (node: _HashNode, leaf: _UnmanagedHashNode, slot: _HashSlot) {
    let r = unsafe read {
      unsafe _HashNode.build(
        level: level.descend(),
        item1: $0[item: itemSlot], existingHash,
        item2: inserter, newHash)
    }
    let node = unsafe _copyNodeAndReplaceItemWithNewChild(
      level: level,
      r.top,
      at: bucket,
      itemSlot: itemSlot)
    node._invariantCheck()
    return unsafe (node, r.leaf, r.slot2)
  }

  @inlinable @inline(never)
  @unsafe
  internal mutating func resizeNodeAndSpawnChild(
    level: _HashLevel,
    replacing bucket: _Bucket,
    itemSlot: _HashSlot,
    existingHash: _Hash,
    newHash: _Hash,
    _ inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (leaf: _UnmanagedHashNode, slot: _HashSlot) {
    let r = unsafe update {
      unsafe _HashNode.build(
        level: level.descend(),
        item1: $0.itemPtr(at: itemSlot).move(), existingHash,
        item2: inserter, newHash)
    }
    unsafe _resizeNodeAndReplaceItemWithNewChild(
      level: level,
      r.top,
      at: bucket,
      itemSlot: itemSlot)
    _invariantCheck()
    return unsafe (r.leaf, r.slot2)
  }
}

