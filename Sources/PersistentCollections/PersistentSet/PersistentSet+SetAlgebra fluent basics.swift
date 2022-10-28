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
  /// If `self` already contains `newMember`, then this simply returns `self`.
  ///
  /// - Parameter newMember: The element to insert into the set.
  ///
  /// - Returns: A new set containing `newMember` and all existing members of
  ///    `self`.
  ///
  /// - Complexity: This operation is expected to copy at most O(log(`count`))
  ///    existing members and to perform at most O(1) hashing/comparison
  ///    operations on the `Element` type, as long as `Element` properly
  ///    implements hashing.
  @inlinable
  public func inserting(_ newMember: __owned Element) -> Self {
    let hash = _Hash(newMember)
    let r = _root.inserting(.top, (newMember, ()), hash)
    return PersistentSet(_new: r.node)
  }

  /// Return a new set that contains all members of this set except `member`.
  ///
  /// If `self` does not contain `member`, then this simply returns `self`.
  ///
  /// - Parameter member: The element to remove.
  ///
  /// - Returns: A new set with all existing members of `self` except `member`.
  ///
  /// - Complexity: This operation is expected to copy at most O(log(`count`))
  ///    existing members and to perform at most O(1) hashing/comparison
  ///    operations on the `Element` type, as long as `Element` properly
  ///    implements hashing.
  @inlinable
  public func removing(_ member: Element) -> Self {
    let hash = _Hash(member)
    let r = _root.removing(.top, member, hash)
    guard let r = r else { return self }
    let root = r.replacement.finalize(.top)
    return PersistentSet(_new: root)
  }

  /// Return a new set that contains `newMember` in addition to all members of
  /// this set.
  ///
  /// If an element equal to `newMember` is already contained in this set,
  /// then `newMember` replaces the existing element in the returned result.
  /// In some cases, the original element may be distinguishable from
  /// `newMember` by identity comparison or some other means.
  ///
  /// - Parameter newMember: An element to update in the set.
  ///
  /// - Returns: A new set containing all existing members and `newMember`.
  ///
  /// - Complexity: This operation is expected to copy at most O(log(`count`))
  ///    existing members and to perform at most O(1) hashing/comparison
  ///    operations on the `Element` type, as long as `Element` properly
  ///    implements hashing.
  @inlinable
  public func updating(with newMember: __owned Element) -> Self {
    var copy = self
    copy.update(with: newMember)
    return copy
  }
}
