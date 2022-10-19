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

extension PersistentSet {
  /// Return a new set that contains `newMember` in addition to all existing
  /// elements in this set.
  ///
  /// If `self` already contains `newMember`, then this simply returns self.
  ///
  /// - Parameter newMember: The element to insert into the set.
  ///
  /// - Returns: A new set containing `newMember` and all existing members of
  ///    `self`.
  ///
  /// - Complexity: The operation is expected to copy at most O(log(`count`))
  ///    existing members if `newMember` is not already a member of `self`,
  ///    as long as `Element` properly implements hashing.
  ///
  ///    In addition to this, this operation is expected to perform O(1)
  ///    hashing/comparison operations on the `Element` type (with the same
  ///    caveat.)
  @inlinable
  public func inserting(_ newMember: __owned Element) -> Self {
    let hash = _Hash(newMember)
    let r = _root.inserting(.top, (newMember, ()), hash)
    return PersistentSet(_new: r.node)
  }

  @inlinable
  public func removing(_ member: Element) -> Self {
    let hash = _Hash(member)
    let r = _root.removing(.top, member, hash)
    guard let r = r else { return self }
    return PersistentSet(_new: r.replacement)
  }

  @inlinable
  public func updating(with newMember: __owned Element) -> Self {
    var copy = self
    copy.update(with: newMember)
    return copy
  }
}
