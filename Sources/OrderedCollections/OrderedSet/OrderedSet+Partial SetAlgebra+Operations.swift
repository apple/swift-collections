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
  /// Adds the elements of the given set to this set.
  ///
  /// Members of `other` that aren't already in `self` get appended to the end
  /// of the set, in the order they appear in `other`.
  ///
  ///     var a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [0, 2, 4, 6]
  ///     a.formUnion(b)
  ///     // `a` is now `[1, 2, 3, 4, 0, 6]`
  ///
  /// - Parameter other: The set of elements to insert.
  ///
  /// - Complexity: Expected to be O(`other.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public mutating func formUnion(_ other: __owned Self) {
    append(contentsOf: other)
  }

  /// Returns a new set with the elements of both this and the given set.
  ///
  /// Members of `other` that aren't already in `self` get appended to the end
  /// of the result, in the order they appear in `other`.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [0, 2, 4, 6]
  ///     a.union(b) // [1, 2, 3, 4, 0, 6]
  ///
  /// - Parameter other: The set of elements to add.
  ///
  /// - Complexity: Expected to be O(`self.count` + `other.count`) on average,
  ///    if `Element` implements high-quality hashing.
  @inlinable
  public __consuming func union(_ other: __owned Self) -> Self {
    var result = self
    result.formUnion(other)
    return result
  }

  // Generalizations

  /// Adds the elements of the given set to this set.
  ///
  /// Members of `other` that aren't already in `self` get appended to the end
  /// of the set, in the order they appear in `other`.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [0, 2, 4, 6]
  ///     a.formUnion(b.unordered)
  ///     // a is now [1, 2, 3, 4, 0, 6]
  ///
  /// - Parameter other: The set of elements to add.
  ///
  /// - Complexity: Expected to be O(`self.count` + `other.count`) on average,
  ///    if `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public mutating func formUnion(_ other: __owned UnorderedView) {
    formUnion(other._base)
  }

  /// Returns a new set with the elements of both this and the given set.
  ///
  /// Members of `other` that aren't already in `self` get appended to the end
  /// of the result, in the order they appear in `other`.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: OrderedSet = [0, 2, 4, 6]
  ///     a.union(b.unordered) // [1, 2, 3, 4, 0, 6]
  ///
  /// - Parameter other: The set of elements to add.
  ///
  /// - Complexity: Expected to be O(`self.count` + `other.count`) on average,
  ///    if `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public __consuming func union(_ other: __owned UnorderedView) -> Self {
    union(other._base)
  }

  /// Adds the elements of the given sequence to this set.
  ///
  /// Members of `other` that aren't already in `self` get appended to the end
  /// of the set, in the order they appear in `other`.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: Array = [0, 2, 4, 6]
  ///     a.formUnion(b)
  ///     // a is now [1, 2, 3, 4, 0, 6]
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Complexity: Expected to be O(`self.count` + `other.count`) on average,
  ///    if `Element` implements high-quality hashing.
  @inlinable
  public mutating func formUnion<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Element {
    append(contentsOf: other)
  }

  /// Returns a new set with the elements of both this and the given set.
  ///
  /// Members of `other` that aren't already in `self` get appended to the end
  /// of the result, in the order they appear in `other`.
  ///
  ///     let a: OrderedSet = [1, 2, 3, 4]
  ///     let b: Array = [0, 2, 4, 6]
  ///     a.union(b) // [1, 2, 3, 4, 0, 6]
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Complexity: Expected to be O(`self.count` + `other.count`) on average,
  ///    if `Element` implements high-quality hashing.
  @inlinable
  public __consuming func union<S: Sequence>(
    _ other: __owned S
  ) -> Self where S.Element == Element {
    var result = self
    result.formUnion(other)
    return result
  }
}

extension OrderedSet {
  /// Returns a new set with the elements that are common to both this set and
  /// the provided other one, in the order they appear in `self`.
  ///
  ///     let set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.intersection(other) // [2, 4]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public __consuming func intersection(_ other: Self) -> Self {
    var result = Self()
    for item in self {
      if other.contains(item) {
        result._appendNew(item)
      }
    }
    return result
  }

  /// Removes the elements of this set that aren't also in the given one.
  ///
  ///     var set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.formIntersection(other)
  ///     // set is now [2, 4]
  ///
  /// - Parameter other: A set of elements.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  public mutating func formIntersection(_ other: Self) {
    self = self.intersection(other)
  }

  // Generalizations

  /// Returns a new set with the elements that are common to both this set and
  /// the provided other one, in the order they appear in `self`.
  ///
  ///     let set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.intersection(other) // [2, 4]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  @inline(__always)
  public __consuming func intersection(_ other: UnorderedView) -> Self {
    intersection(other._base)
  }

  /// Removes the elements of this set that aren't also in the given one.
  ///
  ///     var set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.formIntersection(other)
  ///     // set is now [2, 4]
  ///
  /// - Parameter other: A set of elements.
  ///
  /// - Complexity: Expected to be O(`self.count`) on average, if `Element`
  ///    implements high-quality hashing.
  @inlinable
  @inline(__always)
  public mutating func formIntersection(_ other: UnorderedView) {
    formIntersection(other._base)
  }

  /// Returns a new set with the elements that are common to both this set and
  /// the provided sequence, in the order they appear in `self`.
  ///
  ///     let set: OrderedSet = [1, 2, 3, 4]
  ///     set.intersection([6, 4, 2, 0] as Array) // [2, 4]
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: Expected to be O(*n*) on average where *n* is the number of
  ///    elements in `other`, if `Element` implements high-quality hashing.
  @inlinable
  public __consuming func intersection<S: Sequence>(
    _ other: S
  ) -> Self where S.Element == Element {
    _UnsafeBitset.withTemporaryBitset(capacity: self.count) { bitset in
      for item in other {
        if let index = self._find_inlined(item).index {
          bitset.insert(index)
        }
      }
      return self._extractSubset(using: bitset)
    }
  }

  /// Removes the elements of this set that aren't also in the given sequence.
  ///
  ///     var set: OrderedSet = [1, 2, 3, 4]
  ///     set.formIntersection([6, 4, 2, 0] as Array)
  ///     // set is now [2, 4]
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Complexity: Expected to be O(*n*) on average where *n* is the number of
  ///    elements in `other`, if `Element` implements high-quality hashing.
  @inlinable
  public mutating func formIntersection<S: Sequence>(
    _ other: S
  ) where S.Element == Element {
    self = self.intersection(other)
  }
}

extension OrderedSet {
  /// Returns a new set with the elements that are either in this set or in
  /// `other`, but not in both.
  ///
  /// The result contains elements from `self` followed by elements in `other`,
  /// in the same order they appeared in the original sets.
  ///
  ///     let set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.symmetricDifference(other) // [1, 3, 6, 0]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: Expected to be O(`self.count + other.count`) on average, if
  ///    `Element` implements high-quality hashing.
  @inlinable
  public __consuming func symmetricDifference(_ other: __owned Self) -> Self {
    _UnsafeBitset.withTemporaryBitset(capacity: self.count) { bitset1 in
      _UnsafeBitset.withTemporaryBitset(capacity: other.count) { bitset2 in
        bitset1.insertAll(upTo: self.count)
        for item in other {
          if let index = self._find(item).index {
            bitset1.remove(index)
          }
        }
        bitset2.insertAll(upTo: other.count)
        for item in self {
          if let index = other._find(item).index {
            bitset2.remove(index)
          }
        }
        var result = self._extractSubset(using: bitset1,
                                         extraCapacity: bitset2.count)
        for offset in bitset2 {
          result._appendNew(other._elements[offset])
        }
        return result
      }
    }
  }

  /// Replace this set with the elements contained in this set or the given
  /// set, but not both.
  ///
  /// On return, `self` contains elements originally from `self` followed by
  /// elements in `other`, in the same order they appeared in the input values.
  ///
  ///     var set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.formSymmetricDifference(other)
  ///     // set is now [1, 3, 6, 0]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Complexity: Expected to be O(`self.count + other.count`) on average, if
  ///    `Element` implements high-quality hashing.
  @inlinable
  public mutating func formSymmetricDifference(_ other: __owned Self) {
    self = self.symmetricDifference(other)
  }

  // Generalizations

  /// Returns a new set with the elements that are either in this set or in
  /// `other`, but not in both.
  ///
  /// The result contains elements from `self` followed by elements in `other`,
  /// in the same order they appeared in the original sets.
  ///
  ///     let set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.symmetricDifference(other.unordered) // [1, 3, 6, 0]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: Expected to be O(`self.count + other.count`) on average, if
  ///    `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public __consuming func symmetricDifference(
    _ other: __owned UnorderedView
  ) -> Self {
    symmetricDifference(other._base)
  }

  /// Replace this set with the elements contained in this set or the given
  /// set, but not both.
  ///
  /// On return, `self` contains elements originally from `self` followed by
  /// elements in `other`, in the same order they appeared in the input values.
  ///
  ///     var set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.formSymmetricDifference(other.unordered)
  ///     // set is now [1, 3, 6, 0]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Complexity: Expected to be O(`self.count + other.count`) on average, if
  ///    `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public mutating func formSymmetricDifference(_ other: __owned UnorderedView) {
    formSymmetricDifference(other._base)
  }

  /// Returns a new set with the elements that are either in this set or in
  /// `other`, but not in both.
  ///
  /// The result contains elements from `self` followed by elements in `other`,
  /// in the same order they appeared in the original input values.
  ///
  ///     let set: OrderedSet = [1, 2, 3, 4]
  ///     let other: Array = [6, 4, 2, 0]
  ///     set.symmetricDifference(other) // [1, 3, 6, 0]
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: Expected to be O(`self.count` + *n*) on average where *n* is
  ///    the number of elements in `other`, if `Element` implements high-quality
  ///    hashing.
  @inlinable
  public __consuming func symmetricDifference<S: Sequence>(
    _ other: __owned S
  ) -> Self where S.Element == Element {
    _UnsafeBitset.withTemporaryBitset(capacity: self.count) { bitset in
      var new = Self()
      bitset.insertAll(upTo: self.count)
      for item in other {
        if let index = self._find(item).index {
          bitset.remove(index)
        } else {
          new.append(item)
        }
      }
      var result = _extractSubset(using: bitset, extraCapacity: new.count)
      for item in new._elements {
        result._appendNew(item)
      }
      return result
    }
  }

  /// Replace this set with the elements contained in this set or the given
  /// sequence, but not both.
  ///
  /// On return, `self` contains elements originally from `self` followed by
  /// elements in `other`, in the same order they first appeared in the input
  /// values.
  ///
  ///     var set: OrderedSet = [1, 2, 3, 4]
  ///     set.formSymmetricDifference([6, 4, 2, 0] as Array)
  ///     // set is now [1, 3, 6, 0]
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Complexity: Expected to be O(`self.count` + *n*) on average where *n* is
  ///    the number of elements in `other`, if `Element` implements high-quality
  ///    hashing.
  @inlinable
  public mutating func formSymmetricDifference<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Element {
    self = self.symmetricDifference(other)
  }
}

extension OrderedSet {
  /// Returns a new set containing the elements of this set that do not occur
  /// in the given set.
  ///
  /// The result contains elements in the same order they appear in `self`.
  ///
  ///     let set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.subtracting(other) // [1, 3]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: Expected to be O(`self.count + other.count`) on average, if
  ///    `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public __consuming func subtracting(_ other: Self) -> Self {
    _subtracting(other)
  }

  /// Removes the elements of the given set from this set.
  ///
  ///     var set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.subtract(other)
  ///     // set is now [1, 3]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Complexity: Expected to be O(`self.count + other.count`) on average, if
  ///    `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public mutating func subtract(_ other: Self) {
    self = subtracting(other)
  }

  // Generalizations

  /// Returns a new set containing the elements of this set that do not occur
  /// in the given set.
  ///
  /// The result contains elements in the same order they appear in `self`.
  ///
  ///     let set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.subtracting(other.unordered) // [1, 3]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: Expected to be O(`self.count + other.count`) on average, if
  ///    `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public __consuming func subtracting(_ other: UnorderedView) -> Self {
    subtracting(other._base)
  }

  /// Removes the elements of the given set from this set.
  ///
  ///     var set: OrderedSet = [1, 2, 3, 4]
  ///     let other: OrderedSet = [6, 4, 2, 0]
  ///     set.subtract(other.unordered)
  ///     // set is now [1, 3]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Complexity: Expected to be O(`self.count + other.count`) on average, if
  ///    `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public mutating func subtract(_ other: UnorderedView) {
    subtract(other._base)
  }

  /// Returns a new set containing the elements of this set that do not occur
  /// in the given sequence.
  ///
  /// The result contains elements in the same order they appear in `self`.
  ///
  ///     let set: OrderedSet = [1, 2, 3, 4]
  ///     set.subtracting([6, 4, 2, 0] as Array) // [1, 3]
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: Expected to be O(`self.count + other.count`) on average, if
  ///    `Element` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public __consuming func subtracting<S: Sequence>(
    _ other: S
  ) -> Self where S.Element == Element {
    _subtracting(other)
  }

  /// Removes the elements of the given sequence from this set.
  ///
  ///     var set: OrderedSet = [1, 2, 3, 4]
  ///     set.subtract([6, 4, 2, 0] as Array)
  ///     // set is now [1, 3]
  ///
  /// - Parameter other: A finite sequence of elements.
  ///
  /// - Complexity: Expected to be O(`self.count` + *n*) on average, where *n*
  ///    is the number of elements in `other`, if `Element` implements
  ///    high-quality hashing.
  @inlinable
  @inline(__always)
  public mutating func subtract<S: Sequence>(
    _ other: S
  ) where S.Element == Element {
    self = _subtracting(other)
  }

  @inlinable
  __consuming func _subtracting<S: Sequence>(
    _ other: S
  ) -> Self where S.Element == Element {
    guard count > 0 else { return Self() }
    return _UnsafeBitset.withTemporaryBitset(capacity: count) { difference in
      difference.insertAll(upTo: count)
      for item in other {
        if let index = self._find(item).index {
          if difference.remove(index), difference.count == 0 {
            return Self()
          }
        }
      }
      assert(difference.count > 0)
      return _extractSubset(using: difference)
    }
  }
}


