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

extension PersistentSet {
  /// Returns a Boolean value that indicates whether this set is a subset of
  /// the given set.
  ///
  /// Set *A* is a subset of another set *B* if every member of *A* is also a
  /// member of *B*, ignoring the order they appear in the two sets.
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     b.isSubset(of: a) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing. The implementation is careful to make
  ///    the best use of hash tree structure to minimize work when possible,
  ///    e.g. by skipping over parts of the input trees.
  @inlinable
  public func isSubset(of other: Self) -> Bool {
    self._root.isSubset(.top, of: other._root)
  }

  /// Returns a Boolean value that indicates whether this set is a subset of
  /// the given set.
  ///
  /// Set *A* is a subset of another set *B* if every member of *A* is also a
  /// member of *B*, ignoring the order they appear in the two sets.
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     b.isSubset(of: a) // true
  ///
  /// - Parameter other: The keys view of a persistent dictionary.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing. The implementation is careful to make
  ///    the best use of hash tree structure to minimize work when possible,
  ///    e.g. by skipping over parts of the input trees.
  @inlinable
  public func isSubset<Value>(
    of other: PersistentDictionary<Element, Value>.Keys
  ) -> Bool {
    self._root.isSubset(.top, of: other._base._root)
  }

  /// Returns a Boolean value that indicates whether this set is a subset of
  /// the given set.
  ///
  /// Set *A* is a subset of another set *B* if every member of *A* is also a
  /// member of *B*, ignoring the order they appear in the two sets.
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     b.isSubset(of: a) // true
  ///
  /// - Parameter other: A container with a fast `contains` implementation.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: O(`self.count`) calls to `other.contains`.
  @inlinable
  public func isSubset<S: _FastMembershipCheckable>(
    of other: S
  ) -> Bool
  where S.Element == Element {
    self.allSatisfy { other.contains($0) }
  }

  /// Returns a Boolean value that indicates whether this set is a subset of
  /// the given sequence.
  ///
  /// Set *A* is a subset of another set *B* if every member of *A* is also a
  /// member of *B*, ignoring the order they appear in the two sets.
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     b.isSubset(of: a) // true
  ///
  /// - Parameter other: A sequence with a fast `contains` implementation,
  ///    some of whose elements may appear more than once.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: O(`self.count`) calls to `other.contains`.
  @inlinable
  public func isSubset<S: Sequence & _FastMembershipCheckable>(
    of other: S
  ) -> Bool
  where S.Element == Element {
    self.allSatisfy { other.contains($0) }
  }

  /// Returns a Boolean value that indicates whether this set is a subset of
  /// the given sequence.
  ///
  /// Set *A* is a subset of another set *B* if every member of *A* is also a
  /// member of *B*, ignoring the order they appear in the two sets.
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     b.isSubset(of: a) // true
  ///
  /// - Parameter other: A sequence of elements, some of whose elements may
  ///    appear more than once.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: In the worst case, this makes O(*n*) calls to
  ///    `self.contains` (where *n* is the number of elements in `other`),
  ///    and it constructs a temporary persistent set containing every
  ///    element of the sequence.
  @inlinable
  public func isSubset<S: Sequence>(of other: S) -> Bool
  where S.Element == Element
  {
    // FIXME: Would making this a BitSet of seen positions be better?
    var seen: PersistentSet = []
    for item in other {
      if contains(item), seen._insert(item), seen.count == self.count {
        return true
      }
    }
    return false
  }
}
