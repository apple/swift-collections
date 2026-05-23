//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/**
  Case-insensitive ordered set of `String`.

  This file defines `CaseInsensitiveStringSet`,
  a lightweight wrapper around `SortedSet` that compares and stores `String`
  values using a case-insensitive collation.
  Membership, ordering, and set operations all use case-insensitive comparisons.
  For example, the strings "apple" and "APPLE" are considered equivalent and
  the set will contain at most one of them.

  The underlying storage is a `SortedSet` parameterized by a custom `Orderable`
  implementation that performs localized,
  case-insensitive comparisons with `String.compare(_:options:locale:)` using
  the `.caseInsensitive` option.

  ### Examples
  ```swift
  var set = CaseInsensitiveStringSet()
  set.insert("apple")
  set.insert("APPLE") // Not added as a distinct element
  set.insert("Banana")

  // Membership is case-insensitive
  set.contains("apple")    // true
  set.contains("APPLE")    // true
  set.contains("banana")   // true
  set.contains("BANANA")   // true

  // Iteration yields case-insensitive ascending order
  // ["apple", "Banana"] (actual stored casing depends on first insertion)
  let elements = Array(set)
  ```
 */

import Foundation

/// A set of unique `String` values compared case-insensitively and kept in
/// sorted order.
///
/// `CaseInsensitiveStringSet` behaves like a regular set,
/// but all equality and ordering checks are performed without regard to
/// letter case.
/// This means inserting any casing variant of an existing element will not
/// increase the set's count,
/// and iteration yields elements in case-insensitive ascending order.
///
/// ### Examples
/// ```swift
/// // Create from a sequence
/// let s1 = CaseInsensitiveStringSet(["a", "B", "b"]) // contains "a", "B"
///
/// // Create from an array literal
/// let s2: CaseInsensitiveStringSet = ["Hello", "WORLD", "world"]
/// // s2.count == 2
///
/// // Insertion returns whether a new element was inserted
/// var s3: CaseInsensitiveStringSet = []
/// let result1 = s3.insert("Swift")
/// result1.inserted                 // true
/// let result2 = s3.insert("swift")
/// result2.inserted                 // false (equivalent element already present)
///
/// // Set algebra operations
/// let a: CaseInsensitiveStringSet = ["red", "GREEN"]
/// let b: CaseInsensitiveStringSet = ["Green", "BLUE"]
/// let u = a.union(b)               // ["BLUE", "GREEN", "red"]
/// let i = a.intersection(b)        // ["GREEN"]
/// let d = a.subtracting(b)         // ["red"]
/// let x = a.symmetricDifference(b) // ["BLUE", "red"]
/// ```
public struct CaseInsensitiveStringSet {
  /// The element type stored by the set. Always `String`.
  public typealias Element = _Ordering.Element

  /// Creates a set by wrapping an existing sorted-set implementation.
  ///
  /// - Parameter implementation: The underlying storage configured with the
  ///   case-insensitive ordering used by this type.
  ///
  /// - Postcondition: This set will have the same elements as `implementation`.
  /// - Note: This initializer is internal and primarily intended for bridging
  ///   with the underlying `SortedSet`.
  init(wrapping implementation: _Inner) {
    self.inner = implementation
  }

  /// The underlying storage type.
  public typealias _Inner = SortedSet<_Ordering>

  /// The wrapped storage instance implementing all set semantics.
  var inner: _Inner

  /// Case-insensitive ordering for `String` elements.
  ///
  /// This `Orderable` implementation defines a total order and equivalence that
  /// both use case-insensitive string comparison.
  public enum _Ordering: Orderable {
    public static func areDecreasing(_ lhs: Element, _ rhs: Element) -> Bool {
      lhs.compare(rhs, options: .caseInsensitive, locale: nil)
        == .orderedDescending
    }

    public static func areEquivalent(_ lhs: Element, _ rhs: Element) -> Bool {
      lhs.compare(rhs, options: .caseInsensitive, locale: nil) == .orderedSame
    }

    public static func areIncreasing(_ lhs: Element, _ rhs: Element) -> Bool {
      lhs.compare(rhs, options: .caseInsensitive, locale: nil)
        == .orderedAscending
    }

    public typealias Element = String
  }
}

extension CaseInsensitiveStringSet: Comparable, Sequence, SetAlgebra {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.inner < rhs.inner
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.inner == rhs.inner
  }

  public func contains(_ member: Element) -> Bool {
    return self.inner.contains(member)
  }

  public mutating func formIntersection(_ other: Self) {
    self.inner.formIntersection(other.inner)
  }

  public mutating func formSymmetricDifference(_ other: __owned Self) {
    self.inner.formSymmetricDifference(other.inner)
  }

  public mutating func formUnion(_ other: __owned Self) {
    self.inner.formUnion(other.inner)
  }

  public init() {
    self.init(wrapping: .init())
  }

  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }

  public init(_ sequence: __owned some Sequence<Element>) {
    self.init(wrapping: .init(sequence))
  }

  @discardableResult
  public mutating func insert(_ newMember: __owned Element) -> (
    inserted: Bool, memberAfterInsert: Element
  ) {
    return self.inner.insert(newMember)
  }

  public func intersection(_ other: Self) -> Self {
    return Self(wrapping: self.inner.intersection(other.inner))
  }

  public func isDisjoint(with other: Self) -> Bool {
    return self.inner.isDisjoint(with: other.inner)
  }

  public var isEmpty: Bool { inner.isEmpty }

  public func isSubset(of other: Self) -> Bool {
    return self.inner.isSubset(of: other.inner)
  }

  public func isSuperset(of other: Self) -> Bool {
    return self.inner.isSuperset(of: other.inner)
  }

  public typealias Iterator = _Inner.Iterator

  public func makeIterator() -> Iterator {
    return inner.makeIterator()
  }

  @discardableResult
  public mutating func remove(_ member: Element) -> Element? {
    return self.inner.remove(member)
  }

  public mutating func subtract(_ other: Self) {
    self.inner.subtract(other.inner)
  }

  public func subtracting(_ other: Self) -> Self {
    return Self(wrapping: self.inner.subtracting(other.inner))
  }

  public func symmetricDifference(_ other: __owned Self) -> Self {
    return Self(wrapping: self.inner.symmetricDifference(other.inner))
  }

  public var underestimatedCount: Int { inner.underestimatedCount }

  public func union(_ other: __owned Self) -> Self {
    return Self(wrapping: self.inner.union(other.inner))
  }

  @discardableResult
  public mutating func update(with newMember: __owned Element) -> Element? {
    return self.inner.update(with: newMember)
  }
}
