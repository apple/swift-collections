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

extension PersistentSet: _FastMembershipCheckable {
  @inlinable
  public func contains(_ item: Element) -> Bool {
    _root.containsKey(.top, item, _Hash(item))
  }
}

extension PersistentSet: SetAlgebra {
  @discardableResult
  @inlinable
  public mutating func insert(
    _ newMember: __owned Element
  ) -> (inserted: Bool, memberAfterInsert: Element) {
    let hash = _Hash(newMember)
    _invalidateIndices()
    let r = _root.update(newMember, .top, hash)
    return _Node.UnsafeHandle.update(r.leaf) {
      let p = $0.itemPtr(at: r.slot)
      if r.inserted {
        p.initialize(to: (newMember, ()))
        return (true, newMember)
      }
      return (false, p.pointee.key)
    }
  }

  @discardableResult
  @inlinable
  internal mutating func _insert(_ newMember: __owned Element) -> Bool {
    let hash = _Hash(newMember)
    let r = _root.update(newMember, .top, hash)
    guard r.inserted else { return false }
    _Node.UnsafeHandle.update(r.leaf) {
      let p = $0.itemPtr(at: r.slot)
      p.initialize(to: (newMember, ()))
    }
    return true
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
    let r = _root.update(newMember, .top, hash)
    return _Node.UnsafeHandle.update(r.leaf) {
      let p = $0.itemPtr(at: r.slot)
      if r.inserted {
        p.initialize(to: (newMember, ()))
        return nil
      }
      let old = p.pointee.key
      p.pointee = (newMember, ())
      return old
    }
  }
}
