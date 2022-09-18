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
      ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewItem)
      insertItem((key, value), at: slot, bucket)
      return nil
    case .newCollision(let bucket, let slot):
      _ = _insertNewCollision(
        isUnique: isUnique,
        level: level,
        for: hash,
        replacing: slot, bucket,
        inserter: { $0.initialize(to: (key, value)) })
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
}

extension _Node {
  @inlinable
  internal mutating func _insertNewCollision(
    isUnique: Bool,
    level: _Level,
    for hash: _Hash,
    replacing slot: _Slot, _ bucket: _Bucket,
    inserter: (UnsafeMutablePointer<Element>) -> Void
  ) -> (node: _UnmanagedNode, slot: _Slot) {
    let existingHash = read { _Hash($0[item: slot].key) }
    if hash == existingHash, hasSingletonItem {
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
    ensureUnique(isUnique: isUnique, withFreeSpace: Self.spaceForNewCollision)
    let existing = removeItem(at: slot, bucket) { $0.move() }
    let r = _Node.build(
      level: level.descend(),
      item1: existing, existingHash,
      item2: inserter, hash)
    insertChild(r.top, bucket)
    return (r.leaf, r.slot2)
  }
}

