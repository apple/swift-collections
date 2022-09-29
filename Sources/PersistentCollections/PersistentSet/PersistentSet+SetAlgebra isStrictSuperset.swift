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
  /// Returns a Boolean value that indicates whether the set is a strict
  /// superset of the given set.
  ///
  /// Set *A* is a strict superset of another set *B* if every member of *B* is
  /// also a member of *A* and *A* contains at least one element that is *not*
  /// a member of *B*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     a.isStrictSuperset(of: b.unordered) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` is a strict superset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`other.count`) on average, if `Element`
  ///    implements high-quality hashing. The implementation is careful to make
  ///    the best use of hash tree structure to minimize work when possible,
  ///    e.g. by skipping over parts of the input trees.
  @inlinable
  public func isStrictSuperset(of other: Self) -> Bool {
    guard self.count > other.count else { return false }
    return other._root.isSubset(.top, of: self._root)
  }

  /// Returns a Boolean value that indicates whether the set is a strict
  /// superset of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     a.isStrictSuperset(of: b.unordered) // true
  ///
  /// - Parameter other: The keys view of a persistent dictionary.
  ///
  /// - Returns: `true` if `self` is a strict subset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`other.count`) on average, if `Element`
  ///    implements high-quality hashing. The implementation is careful to make
  ///    the best use of hash tree structure to minimize work when possible,
  ///    e.g. by skipping over parts of the input trees.
  @inlinable
  public func isStrictSuperset<Value>(
    of other: PersistentDictionary<Element, Value>.Keys
  ) -> Bool {
    guard self.count > other.count else { return false }
    return other._base._root.isSubset(.top, of: self._root)
  }

  /// Returns a Boolean value that indicates whether the set is a strict
  /// superset of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     a.isStrictSuperset(of: b.unordered) // true
  ///
  /// - Parameter other: A sequence with a fast `contains` implementation,
  ///    some of whose elements may appear more than once.
  ///
  /// - Returns: `true` if `self` is a strict subset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: In the worst case, this makes `other.count`
  ///    calls to `self.contains`, followed by *n* calls to `other.contains`
  ///    where *n* is the length of the sequence.
  @inlinable
  public func isStrictSuperset<S: Sequence & _FastMembershipCheckable>(
    of other: S
  ) -> Bool
  where S.Element == Element
  {
    if !other.allSatisfy({ self.contains($0) }) { return false }
    return !self.allSatisfy { other.contains($0) }
  }

  /// Returns a Boolean value that indicates whether the set is a strict
  /// superset of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     a.isStrictSuperset(of: b.unordered) // true
  ///
  /// - Parameter other: A sequence of elements, some of whose elements may
  ///    appear more than once.
  ///
  /// - Returns: `true` if `self` is a strict subset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: In the worst case, this makes O(*n*) calls to
  ///    `self.contains` (where *n* is the number of elements in `other`),
  ///    and it constructs a temporary persistent set containing every
  ///    element of the sequence.
  @inlinable
  public func isStrictSuperset<S: Sequence>(of other: S) -> Bool
  where S.Element == Element
  {
    // FIXME: Would making this a BitSet of seen positions be better?
    var seen: PersistentSet = []
    for item in other {
      guard self.contains(item) else { return false }
      if seen._insert(item), seen.count == self.count {
        return false
      }
    }
    assert(seen.count < self.count)
    return true
  }
}
