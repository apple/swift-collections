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

// MARK: Subtree-level in-place mutation operations

extension _HashNode {
  @inlinable
  internal mutating func ensureUnique(
    level: _HashLevel, at path: _UnsafePath
  ) -> (leaf: _UnmanagedHashNode, slot: _HashSlot) {
    ensureUnique(isUnique: isUnique())
    guard level < path.level else { return unsafe (unmanaged, path.currentItemSlot) }
    return unsafe update {
      unsafe $0[child: path.childSlot(at: level)]
        .ensureUnique(level: level.descend(), at: path)
    }
  }
}

extension _HashNode {
  @usableFromInline
  @frozen
  @unsafe
  internal struct ValueUpdateState {
    @usableFromInline
    @safe
    internal var key: Key

    @usableFromInline
    @safe
    internal var value: Value?

    @usableFromInline
    @safe
    internal let hash: _Hash

    @usableFromInline
    internal var path: _UnsafePath

    @usableFromInline
    @safe
    internal var found: Bool

    @inlinable
    internal init(
      _ key: Key,
      _ hash: _Hash,
      _ path: _UnsafePath
    ) {
      self.key = key
      self.value = nil
      self.hash = hash
      unsafe self.path = path
      self.found = false
    }
  }

  @inlinable
  @unsafe
  internal mutating func prepareValueUpdate(
    _ key: Key,
    _ hash: _Hash
  ) -> ValueUpdateState {
    var state = unsafe ValueUpdateState(key, hash, _UnsafePath(root: raw))
    unsafe _prepareValueUpdate(&state)
    return unsafe state
  }

  @inlinable
  @unsafe
  internal mutating func _prepareValueUpdate(
    _ state: inout ValueUpdateState
  ) {
    // This doesn't make room for a new item if the key doesn't already exist
    // but it does ensure that all parent nodes along its eventual path are
    // uniquely held.
    //
    // If the key already exists, we ensure uniqueness for its node and extract
    // its item but otherwise leave the tree as it was.
    let isUnique = self.isUnique()
    let r = unsafe findForInsertion(state.path.level, state.key, state.hash)
    switch r {
    case .found(_, let slot):
      ensureUnique(isUnique: isUnique)
      unsafe state.path.node = unmanaged
      unsafe state.path.selectItem(at: slot)
      state.found = true
      (state.key, state.value) = unsafe update { unsafe $0.itemPtr(at: slot).move() }


    case .insert(_, let slot):
      unsafe state.path.selectItem(at: slot)

    case .appendCollision:
      unsafe state.path.selectItem(at: _HashSlot(self.count))

    case .spawnChild(_, let slot):
      unsafe state.path.selectItem(at: slot)

    case .expansion:
      unsafe state.path.selectEnd()

    case .descend(_, let slot):
      ensureUnique(isUnique: isUnique)
      unsafe update {
        let p = unsafe $0.childPtr(at: slot)
        unsafe state.path.descendToChild(p.pointee.unmanaged, at: slot)
        unsafe p.pointee._prepareValueUpdate(&state)
      }
    }
  }

  @inlinable
  @unsafe
  internal mutating func finalizeValueUpdate(
    _ state: __owned ValueUpdateState
  ) {
    switch (state.found, state.value != nil) {
    case (true, true):
      // Fast path: updating an existing value.
      unsafe UnsafeHandle.update(state.path.node) {
        unsafe $0.itemPtr(at: state.path.currentItemSlot)
          .initialize(to: (state.key, state.value.unsafelyUnwrapped))
      }
    case (true, false):
      // Removal
      let remainder = unsafe _finalizeRemoval(.top, state.hash, at: state.path)
      assert(remainder == nil)
    case (false, true):
      // Insertion
      let r = unsafe updateValue(.top, forKey: state.key, state.hash) {
        unsafe $0.initialize(to: (state.key, state.value.unsafelyUnwrapped))
      }
      assert(unsafe r.inserted)
    case (false, false):
      // Noop
      break
    }
  }

  @inlinable
  @unsafe
  internal mutating func _finalizeRemoval(
    _ level: _HashLevel, _ hash: _Hash, at path: _UnsafePath
  ) -> Element? {
    assert(isUnique())
    if level == path.level {
      return unsafe _removeItemFromUniqueLeafNode(
        level, at: hash[level], path.currentItemSlot, by: { _ in }
      ).remainder
    }
    let slot = unsafe path.childSlot(at: level)
    let remainder = unsafe update {
      unsafe $0[child: slot]._finalizeRemoval(level.descend(), hash, at: path)
    }
    return unsafe _fixupUniqueAncestorAfterItemRemoval(
      level, at: { _ in hash[level] }, slot, remainder: remainder)
  }
}

extension _HashNode {
  @usableFromInline
  @frozen
  @unsafe
  internal struct DefaultedValueUpdateState {
    @usableFromInline
    @safe
    internal var item: Element

    @usableFromInline
    internal var node: _UnmanagedHashNode

    @usableFromInline
    @safe
    internal var slot: _HashSlot

    @usableFromInline
    @safe
    internal var inserted: Bool

    @inlinable
    internal init(
      _ item: Element,
      in node: _UnmanagedHashNode,
      at slot: _HashSlot,
      inserted: Bool
    ) {
      self.item = item
      unsafe self.node = node
      self.slot = slot
      self.inserted = inserted
    }
  }

  @inlinable
  internal mutating func prepareDefaultedValueUpdate(
    _ level: _HashLevel,
    _ key: Key,
    _ defaultValue: () -> Value,
    _ hash: _Hash
  ) -> DefaultedValueUpdateState {
    let isUnique = self.isUnique()
    let r = findForInsertion(level, key, hash)
    switch r {
    case .found(_, let slot):
      ensureUnique(isUnique: isUnique)
      return unsafe DefaultedValueUpdateState(
        update { unsafe $0.itemPtr(at: slot).move() },
        in: unmanaged,
        at: slot,
        inserted: false)

    case .insert(let bucket, let slot):
      unsafe ensureUniqueAndInsertItem(
        isUnique: isUnique, at: bucket, itemSlot: slot
      ) { _ in }
      return unsafe DefaultedValueUpdateState(
        (key, defaultValue()),
        in: unmanaged,
        at: slot,
        inserted: true)

    case .appendCollision:
      let slot = unsafe ensureUniqueAndAppendCollision(isUnique: isUnique) { _ in }
      return unsafe DefaultedValueUpdateState(
        (key, defaultValue()),
        in: unmanaged,
        at: slot,
        inserted: true)

    case .spawnChild(let bucket, let slot):
      let r = unsafe ensureUniqueAndSpawnChild(
        isUnique: isUnique,
        level: level,
        replacing: bucket,
        itemSlot: slot,
        newHash: hash) { _ in }
      return unsafe DefaultedValueUpdateState(
        (key, defaultValue()),
        in: r.leaf,
        at: r.slot,
        inserted: true)

    case .expansion:
      let r = unsafe _HashNode.build(
        level: level,
        item1: { _ in }, hash,
        child2: self, self.collisionHash
      )
      self = unsafe r.top
      return unsafe DefaultedValueUpdateState(
        (key, defaultValue()),
        in: r.leaf,
        at: r.slot1,
        inserted: true)

    case .descend(_, let slot):
      ensureUnique(isUnique: isUnique)
      let res = unsafe update {
        unsafe $0[child: slot].prepareDefaultedValueUpdate(
          level.descend(), key, defaultValue, hash)
      }
      if res.inserted { count &+= 1 }
      return unsafe res
    }
  }

  @inlinable
  internal mutating func finalizeDefaultedValueUpdate(
    _ state: __owned DefaultedValueUpdateState
  ) {
    unsafe UnsafeHandle.update(state.node) {
      unsafe $0.itemPtr(at: state.slot).initialize(to: state.item)
    }
  }
}

