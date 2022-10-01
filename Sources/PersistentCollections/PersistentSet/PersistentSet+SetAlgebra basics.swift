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

extension PersistentSet: SetAlgebra {
  @inlinable
  public func contains(_ item: Element) -> Bool {
    _root.containsKey(.top, item, _Hash(item))
  }

  @discardableResult
  @inlinable
  public mutating func insert(
    _ newMember: __owned Element
  ) -> (inserted: Bool, memberAfterInsert: Element) {
    let hash = _Hash(newMember)
    let r = _root.insert(.top, newMember, hash) {
      $0.initialize(to: (newMember, ()))
    }
    if r.inserted {
      _invalidateIndices()
      return (true, newMember)
    }
    return _Node.UnsafeHandle.read(r.leaf) {
      (false, $0[item: r.slot].key)
    }
  }

  @discardableResult
  @inlinable
  internal mutating func _insert(_ newMember: __owned Element) -> Bool {
    let hash = _Hash(newMember)
    let r = _root.insert(.top, newMember, hash) {
      $0.initialize(to: (newMember, ()))
    }
    return r.inserted
  }

  @discardableResult
  @inlinable
  public mutating func remove(_ member: Element) -> Element? {
    let hash = _Hash(member)
    _invalidateIndices()
    return _root.remove(.top, member, hash)?.key
  }

  @discardableResult
  @inlinable
  public mutating func update(with newMember: __owned Element) -> Element? {
    let hash = _Hash(newMember)
    let r = _root.updateValue(.top, forKey: newMember, hash) {
      $0.initialize(to: (newMember, ()))
    }
    if r.inserted { return nil }
    return _Node.UnsafeHandle.update(r.leaf) {
      let p = $0.itemPtr(at: r.slot)
      let old = p.move().key
      p.initialize(to: (newMember, ()))
      return old
    }
  }
}
