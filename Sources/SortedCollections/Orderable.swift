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
  A generic protocol that models a total preorder for elements.
  Types conforming to `Orderable` define a consistent way to compare two
  values of the same `Element` type in terms of increasing, equivalent,
  and decreasing relationships.
  This can be used to parameterize sorting, ordered collections, and
  algorithms that need a customizable notion of
  order without relying on `Comparable`.
  Conformers are expected to implement `areIncreasing(_: _:)` as a
  strict ordering relation.
  By default, `areEquivalent(_: _:)` and `areDecreasing(_: _:)` are derived
  from `areIncreasing(_: _:)` to form a total preorder: exactly one of
  increasing, equivalent, or decreasing holds for any pair of elements.

  Example:

  ```swift
  // A simple ascending ordering for Int values
  enum AscendingIntOrder: Orderable<Int> {
    static func areIncreasing(_ lhs: Int, _ rhs: Int) -> Bool { lhs < rhs }
  }

  let numbers = [5, 1, 3]
  let sortedAscending = numbers.sorted { AscendingIntOrder.areIncreasing($0,
   $1) }
  // [1, 3, 5]

  // A reverse ordering can be defined by flipping the relation
  enum DescendingIntOrder: Orderable<Int> {
    static func areIncreasing(_ lhs: Int, _ rhs: Int) -> Bool { lhs > rhs }
  }

  let sortedDescending = numbers.sorted { DescendingIntOrder.areIncreasing($0,
   $1) }
  // [5, 3, 1]
 ```
  */

/// An abstraction over a customizable ordering relation for values of
/// type `Element`.
///
/// Provide a strict "is increasing" relation via `areIncreasing(_: _:)`.
/// The default implementations derive equivalence and decreasing relations to
/// complete the ordering.
public protocol Orderable<Element> {

  /// The element type compared by this ordering.
  associatedtype Element

  /// Returns `true` if `lhs` should come before `rhs` according to
  /// this ordering.
  ///
  /// This relation should be strict and transitive. For any value `x`,
  /// `areIncreasing(x, x)` should be `false`.
  static func areIncreasing(_ lhs: Element, _ rhs: Element) -> Bool

  /// Returns `true` if `lhs` and `rhs` are considered equivalent under
  /// this ordering.
  ///
  /// By default, this is derived from `areIncreasing` and `areDecreasing` so
  /// that two elements are equivalent when neither precedes the other.
  static func areEquivalent(_ lhs: Element, _ rhs: Element) -> Bool

  /// Returns `true` if `lhs` should come after `rhs` according to
  /// this ordering.
  ///
  /// By default, this is implemented as `areIncreasing(rhs, lhs)`.
  static func areDecreasing(_ lhs: Element, _ rhs: Element) -> Bool
}

/// Default implementations derived from `areIncreasing(_: _:)`.
///
/// Conformers typically only need to implement `areIncreasing(_: _:)`.
/// The extension defines `areEquivalent(_: _:)` and `areDecreasing(_: _:)`
/// in terms of it.
extension Orderable {
  /// Two elements are equivalent when neither
  /// is strictly increasing over the other.
  static public func areEquivalent(_ lhs: Element, _ rhs: Element) -> Bool {
    return !areIncreasing(lhs, rhs) && !areDecreasing(lhs, rhs)
  }

  /// Decreasing is defined as the inverse of increasing.
  static public func areDecreasing(_ lhs: Element, _ rhs: Element) -> Bool {
    return areIncreasing(rhs, lhs)
  }
}
