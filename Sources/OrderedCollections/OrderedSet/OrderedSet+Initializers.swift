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

extension OrderedSet {
  @inlinable
  internal init(_uncheckedUniqueElements elements: ContiguousArray<Element>) {
#if DEBUG
    self.init(_uniqueElements: elements)
#else
    guard elements.count > _HashTable.maximumUnhashedCount else {
      self.init(_uniqueElements: elements, nil)
      return
    }
    let table = _HashTable.create(uncheckedUniqueElements: elements)
    self.init(_uniqueElements: elements, table)
#endif
  }

  /// Creates a set with the contents of the given sequence, which
  /// must not include duplicate elements.
  ///
  /// In optimized builds, this initializer does not verify that the
  /// elements are actually unique. This makes creating the set
  /// somewhat faster if you know for sure that the elements are
  /// unique (e.g., because they come from another collection with
  /// guaranteed-unique members, such as a `Set`). However, if you
  /// accidentally call this initializer with duplicate members, it
  /// can return a corrupt set value that may be difficult to debug.
  ///
  /// - Parameter elements: A finite sequence of unique elements.
  ///
  /// - Complexity: Expected to be O(*n*) on average, where *n* is the
  ///    number of elements in the sequence, if `Element` implements
  ///    high-quality hashing.
  @inlinable
  @inline(__always)
  public init<S: Sequence>(uncheckedUniqueElements elements: S)
  where S.Element == Element {
    self.init(_uncheckedUniqueElements: ContiguousArray<Element>(elements))
  }
}

extension OrderedSet {
  /// Creates a new set from a finite sequence of items.
  ///
  /// - Parameter elements: The elements to use as members of the new set.
  ///
  /// - Complexity: This operation is expected to perform O(*n*)
  ///    comparisons on average (where *n* is the number of elements
  ///    in the sequence), provided that `Element` implements
  ///    high-quality hashing.
  @inlinable
  public init<S: Sequence>(_ elements: S) where S.Element == Element {
    if S.self == Self.self {
      self = elements as! Self
      return
    }
    // Fast paths for when we know elements are all unique
    if S.self == Set<Element>.self || S.self == SubSequence.self {
      self.init(uncheckedUniqueElements: elements)
      return
    }

    self.init()
    append(contentsOf: elements)
  }

  // Specializations

  /// Creates a new set from a an existing set. This is functionally the same as
  /// copying the value of `elements` into a new variable.
  ///
  /// - Parameter elements: The elements to use as members of the new set.
  ///
  /// - Complexity: O(1)
  @inlinable
  public init(_ elements: Self) {
    self = elements
  }

  /// Creates a new set from an existing slice of another set.
  ///
  /// - Parameter elements: The elements to use as members of the new set.
  ///
  /// - Complexity: This operation is expected to perform
  ///    O(`elements.count`) operations on average, provided that
  ///    `Element` implements high-quality hashing.
  @inlinable
  public init(_ elements: SubSequence) {
    self.init(uncheckedUniqueElements: elements._slice)
  }

  /// Creates a new set from an existing `Set` value.
  ///
  /// - Parameter elements: The elements to use as members of the new set.
  ///
  /// - Complexity: This operation is expected to perform
  ///    O(`elements.count`) operations on average, provided that
  ///    `Element` implements high-quality hashing.
  @inlinable
  public init(_ elements: Set<Element>) {
    self.init(uncheckedUniqueElements: elements)
  }

  /// Creates a new set from the keys view of a dictionary.
  ///
  /// - Parameter elements: The elements to use as members of the new set.
  ///
  /// - Complexity: This operation is expected to perform
  ///    O(`elements.count`) operations on average, provided that
  ///    `Element` implements high-quality hashing.
  @inlinable
  public init<Value>(_ elements: Dictionary<Element, Value>.Keys) {
    self._elements = ContiguousArray(elements)
    _regenerateHashTable()
    _checkInvariants()
  }

  /// Creates a new set from a collection of items.
  ///
  /// - Parameter elements: The elements to use as members of the new set.
  ///
  /// - Complexity: This operation is expected to perform O(*n*)
  ///    comparisons on average (where *n* is the number of elements
  ///    in the sequence), provided that `Element` implements
  ///    high-quality hashing.
  @inlinable
  public init<C: RandomAccessCollection>(
    _ elements: C
  ) where C.Element == Element {
    // This code is careful not to copy storage if `C` is an Array
    // or ContiguousArray and the elements are already unique.
    let (table, firstDupe) = _HashTable.create(
      untilFirstDuplicateIn: elements)
    if firstDupe == elements.endIndex {
      // Fast path: `elements` consists of unique values.
      self.init(_uniqueElements: ContiguousArray(elements), table)
      return
    }

    // Otherwise keep the elements we've processed and add the rest one by one.
    self.init(_uniqueElements: ContiguousArray(elements[..<firstDupe]), table)
    self.append(contentsOf: elements[firstDupe...])
  }
}
