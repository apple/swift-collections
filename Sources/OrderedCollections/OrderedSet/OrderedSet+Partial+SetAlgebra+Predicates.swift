//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// `OrderedSet` does not directly conform to `SetAlgebra` because its definition
// of equality conflicts with `SetAlgebra` requirements. However, it still
// implements most `SetAlgebra` requirements (except `insert`, which is replaced
// by `append`).
//
// `OrderedSet` also provides an `unordered` view that explicitly conforms to
// `SetAlgebra`. That view implements `Equatable` by ignoring element order,
// so it can satisfy `SetAlgebra` requirements.

extension OrderedSet {
  /// Returns a Boolean value that indicates whether this set is a subset of
  /// the given set.
  ///
  /// Set *A* is a subset of another set *B* if every member of *A* is also a
  /// member of *B*, ignoring the order they appear in the two sets.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [4, 2, 1]
  ///     b.isSubset(of: a) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public func isSubset(of other: Self) -> Bool {
    guard other.count >= self.count else { return false }
    for item in self {
      guard other.contains(item) else { return false }
    }
    return true
  }

  // Generalizations

  /// Returns a Boolean value that indicates whether this set is a subset of
  /// the given set.
  ///
  /// Set *A* is a subset of another set *B* if every member of *A* is also a
  /// member of *B*, ignoring the order they appear in the two sets.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [4, 2, 1]
  ///     b.isSubset(of: a.unordered) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  @inline(__always)
  public func isSubset(of other: UnorderedView) -> Bool {
    isSubset(of: other._base)
  }

  /// Returns a Boolean value that indicates whether this set is a subset of
  /// the given set.
  ///
  /// Set *A* is a subset of another set *B* if every member of *A* is also a
  /// member of *B*, ignoring the order they appear in the two sets.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: Set = [4, 2, 1]
  ///     b.isSubset(of: a) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public func isSubset(of other: Set<Element>) -> Bool {
    guard other.count >= self.count else { return false }
    for item in self {
      guard other.contains(item) else { return false }
    }
    return true
  }

  /// Returns a Boolean value that indicates whether this set is a subset of
  /// the elements in the given sequence.
  ///
  /// Set *A* is a subset of another set *B* if every member of *A* is also a
  /// member of *B*, ignoring the order they appear in the two sets.
  ///
  ///     let a: Array = [1, 2, 3, 4]
  ///     let b: OrderedSet = [4, 2, 1]
  ///     b.isSubset(of: a) // true
  ///
  /// - Parameter other: A finite sequence.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(`self.count` + *n*) on average, where *n*
  ///    is the number of elements in `other`, if `Element` implements
  ///    high-quality hashing.
  @inlinable
  public func isSubset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    guard !isEmpty else { return true }
    return _UnsafeBitset.withTemporaryBitset(capacity: count) { seen in
      // Mark elements in `self` that we've seen in `other`.
      for item in other {
        if let index = _find(item).index {
          if seen.insert(index), seen.count == self.count {
            // We've seen enough.
            return true
          }
        }
      }
      return false
    }
  }
}

extension OrderedSet {
  /// Returns a Boolean value that indicates whether this set is a superset of
  /// the given set.
  ///
  /// Set *A* is a superset of another set *B* if every member of *B* is also a
  /// member of *A*, ignoring the order they appear in the two sets.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [4, 2, 1]
  ///     a.isSuperset(of: b) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(`other.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public func isSuperset(of other: Self) -> Bool {
    other.isSubset(of: self)
  }

  // Generalizations

  /// Returns a Boolean value that indicates whether this set is a superset of
  /// the given set.
  ///
  /// Set *A* is a superset of another set *B* if every member of *B* is also a
  /// member of *A*, ignoring the order they appear in the two sets.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: Set = [4, 2, 1]
  ///     a.isSuperset(of: b) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(`other.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public func isSuperset(of other: UnorderedView) -> Bool {
    isSuperset(of: other._base)
  }

  @inlinable
  public func isSuperset(of other: Set<Element>) -> Bool {
    guard self.count >= other.count else { return false }
    return _isSuperset(of: other)
  }

  /// Returns a Boolean value that indicates whether this set is a superset of
  /// the given sequence.
  ///
  /// Set *A* is a superset of another set *B* if every member of *B* is also a
  /// member of *A*, ignoring the order they appear in the two sets.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: Array = [4, 2, 1]
  ///     a.isSuperset(of: b) // true
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(*n*) on average, where *n* is the number of
  ///    elements in `other`, if `Element` implements high-quality hashing.
  @inlinable
  public func isSuperset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    _isSuperset(of: other)
  }

  @inlinable
  internal func _isSuperset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    for item in other {
      guard self.contains(item) else { return false }
    }
    return true
  }
}

extension OrderedSet {
  /// Returns a Boolean value that indicates whether the set is a strict subset
  /// of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [4, 2, 1]
  ///     b.isStrictSubset(of: a) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` is a strict subset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public func isStrictSubset(of other: Self) -> Bool {
    self.count < other.count && self.isSubset(of: other)
  }

  // Generalizations

  /// Returns a Boolean value that indicates whether the set is a strict subset
  /// of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [4, 2, 1]
  ///     b.isStrictSubset(of: a.unordered) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` is a strict subset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  @inline(__always)
  public func isStrictSubset(of other: UnorderedView) -> Bool {
    isStrictSubset(of: other._base)
  }

  /// Returns a Boolean value that indicates whether the set is a strict subset
  /// of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: Set = [1, 2, 3, 4]
  ///     let b: OrderedSet = [4, 2, 1]
  ///     b.isStrictSubset(of: a) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` is a strict subset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public func isStrictSubset(of other: Set<Element>) -> Bool {
    self.count < other.count && self.isSubset(of: other)
  }

  /// Returns a Boolean value that indicates whether the set is a strict subset
  /// of the given sequence.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: Array = [1, 2, 3, 4]
  ///     let b: OrderedSet = [4, 2, 1]
  ///     b.isStrictSubset(of: a) // true
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Returns: `true` if `self` is a strict subset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`self.count` + *n*) on average, where *n*
  ///    is the number of elements in `other`, if `Element` implements
  ///    high-quality hashing.
  @inlinable
  public func isStrictSubset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    _UnsafeBitset.withTemporaryBitset(capacity: count) { seen in
      // Mark elements in `self` that we've seen in `other`.
      var isKnownStrict = false
      for item in other {
        if let index = _find(item).index {
          if seen.insert(index), seen.count == self.count, isKnownStrict {
            // We've seen enough.
            return true
          }
        } else {
          if !isKnownStrict, seen.count == self.count { return true }
          isKnownStrict = true
        }
      }
      return false
    }
  }
}

extension OrderedSet {
  /// Returns a Boolean value that indicates whether the set is a strict
  /// superset of the given set.
  ///
  /// Set *A* is a strict superset of another set *B* if every member of *B* is
  /// also a member of *A* and *A* contains at least one element that is *not*
  /// a member of *B*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [4, 2, 1]
  ///     a.isStrictSuperset(of: b) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` is a strict superset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`other.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public func isStrictSuperset(of other: Self) -> Bool {
    self.count > other.count && other.isSubset(of: self)
  }

  // Generalizations

  /// Returns a Boolean value that indicates whether the set is a strict
  /// superset of the given set.
  ///
  /// Set *A* is a strict superset of another set *B* if every member of *B* is
  /// also a member of *A* and *A* contains at least one element that is *not*
  /// a member of *B*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [4, 2, 1]
  ///     a.isStrictSuperset(of: b.unordered) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` is a strict superset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`other.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  @inline(__always)
  public func isStrictSuperset(of other: UnorderedView) -> Bool {
    isStrictSuperset(of: other._base)
  }

  /// Returns a Boolean value that indicates whether the set is a strict
  /// superset of the given set.
  ///
  /// Set *A* is a strict superset of another set *B* if every member of *B* is
  /// also a member of *A* and *A* contains at least one element that is *not*
  /// a member of *B*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: Set = [4, 2, 1]
  ///     a.isStrictSuperset(of: b) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` is a strict superset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`other.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public func isStrictSuperset(of other: Set<Element>) -> Bool {
    self.count > other.count && other.isSubset(of: self)
  }

  /// Returns a Boolean value that indicates whether the set is a strict
  /// superset of the given sequence.
  ///
  /// Set *A* is a strict superset of another set *B* if every member of *B* is
  /// also a member of *A* and *A* contains at least one element that is *not*
  /// a member of *B*. (Ignoring the order the elements appear in the sets.)
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: Array = [4, 2, 1]
  ///     a.isStrictSuperset(of: b) // true
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Returns: `true` if `self` is a strict superset of `other`; otherwise,
  ///    `false`.
  ///
  /// - Complexity: Expected to be O(`self.count` + *n*) on average, where *n*
  ///    is the number of elements in `other`, if `Element` implements
  ///    high-quality hashing.
  @inlinable
  public func isStrictSuperset<S: Sequence>(
    of other: S
  ) -> Bool where S.Element == Element {
    _UnsafeBitset.withTemporaryBitset(capacity: count) { seen in
      // Mark elements in `self` that we've seen in `other`.
      for item in other {
        guard let index = _find(item).index else {
          return false
        }
        if seen.insert(index), seen.count == self.count {
          // We've seen enough.
          return false
        }
      }
      return seen.count < self.count
    }
  }
}

extension OrderedSet {
  /// Returns a Boolean value that indicates whether the set has no members in
  /// common with the given set.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [5, 6]
  ///     a.isDisjoint(with: b) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` has no elements in common with `other`;
  ///   otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(min(`self.count`, `other.count`)) on
  ///    average, if `Element` implements high-quality hashing.
  @inlinable
  public func isDisjoint(with other: Self) -> Bool {
    guard !self.isEmpty && !other.isEmpty else { return true }
    if self.count <= other.count {
      for item in self {
        if other.contains(item) { return false }
      }
    } else {
      for item in other {
        if self.contains(item) { return false }
      }
    }
    return true
  }

  // Generalizations

  /// Returns a Boolean value that indicates whether the set has no members in
  /// common with the given set.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [5, 6]
  ///     a.isDisjoint(with: b.unordered) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` has no elements in common with `other`;
  ///   otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(min(`self.count`, `other.count`)) on
  ///    average, if `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public func isDisjoint(with other: UnorderedView) -> Bool {
    isDisjoint(with: other._base)
  }

  /// Returns a Boolean value that indicates whether the set has no members in
  /// common with the given set.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: Set = [5, 6]
  ///     a.isDisjoint(with: b) // true
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if `self` has no elements in common with `other`;
  ///   otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(min(`self.count`, `other.count`)) on
  ///    average, if `Element` implements high-quality hashing.
  @inlinable
  public func isDisjoint(with other: Set<Element>) -> Bool {
    guard !self.isEmpty && !other.isEmpty else { return true }
    if self.count <= other.count {
      for item in self {
        if other.contains(item) { return false }
      }
    } else {
      for item in other {
        if self.contains(item) { return false }
      }
    }
    return true
  }

  /// Returns a Boolean value that indicates whether the set has no members in
  /// common with the given sequence.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: Array = [5, 6]
  ///     a.isDisjoint(with: b) // true
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Returns: `true` if `self` has no elements in common with `other`;
  ///   otherwise, `false`.
  ///
  /// - Complexity: Expected to be O(*n*) on average, where *n* is the number of
  ///    elements in `other`, if `Element` implements high-quality hashing.
  @inlinable
  public func isDisjoint<S: Sequence>(
    with other: S
  ) -> Bool where S.Element == Element {
    guard !self.isEmpty else { return true }
    for item in other {
      if self.contains(item) { return false }
    }
    return true
  }
}

