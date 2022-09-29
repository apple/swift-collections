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
  /// Returns a Boolean value that indicates whether the set is a strict subset
  /// of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     b.isStrictSubset(of: a) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` is a strict subset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing. The implementation is careful to make
  ///    the best use of hash tree structure to minimize work when possible,
  ///    e.g. by skipping over parts of the input trees.
  @inlinable
  public func isStrictSubset(of other: Self) -> Bool {
    guard self.count < other.count else { return false }
    return isSubset(of: other)
  }

  /// Returns a Boolean value that indicates whether the set is a strict subset
  /// of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     b.isStrictSubset(of: a) // true
  ///
  /// - Parameter other: The keys view of a persistent dictionary.
  ///
  /// - Returns: `true` if `self` is a strict subset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing. The implementation is careful to make
  ///    the best use of hash tree structure to minimize work when possible,
  ///    e.g. by skipping over parts of the input trees.
  @inlinable
  public func isStrictSubset<Value>(
    of other: PersistentDictionary<Element, Value>.Keys
  ) -> Bool {
    guard self.count < other.count else { return false }
    return isSubset(of: other)
  }

  /// Returns a Boolean value that indicates whether the set is a strict subset
  /// of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     b.isStrictSubset(of: a) // true
  ///
  /// - Parameter other: A sequence with a fast `contains` implementation,
  ///    some of whose elements may appear more than once.
  ///
  /// - Returns: `true` if `self` is a strict subset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: In the worst case, this makes `self.count`
  ///    calls to `other.contains`, followed by *n* calls to `self.contains`
  ///    where *n* is the length of the sequence.
  @inlinable
  public func isStrictSubset<S: Sequence & _FastMembershipCheckable>(
    of other: S
  ) -> Bool
  where S.Element == Element {
    guard self.isSubset(of: other) else { return false }
    return !other.allSatisfy { self.contains($0) }
  }


  /// Returns a Boolean value that indicates whether the set is a strict subset
  /// of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [4, 2, 1]
  ///     b.isStrictSubset(of: a) // true
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
  public func isStrictSubset<S: Sequence>(of other: S) -> Bool
  where S.Element == Element
  {
    if other.underestimatedCount > self.count {
      return isSubset(of: other)
    }
    // FIXME: Would making this a BitSet of seen positions be better?
    var seen: PersistentSet? = []
    var isStrict = false
    for item in other {
      if self.contains(item), seen?._insert(item) == true {
        if seen?.count == self.count {
          if isStrict { return true }
          // Stop collecting seen items -- we just need to decide
          // strictness now.
          seen = nil
        }
      } else {
        isStrict = true
        if seen == nil { return true }
      }
    }
    return false
  }
}
