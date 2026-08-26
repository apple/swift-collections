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

#if compiler(>=6.4)

@available(SwiftStdlib 6.4, *)
extension Iterable
where
  Self: ~Copyable & ~Escapable,
  Element: Equatable & ~Copyable
{
  @inlinable
  package func _elementsEqual<
    Other: Iterable<Element, Failure> & ~Copyable & ~Escapable
  >(
    _ other: borrowing Other,
  ) throws(Failure) -> Bool
  where Other.Element: ~Copyable
  {
    let it1 = self.makeBorrowingIterator()
    let it2 = other.makeBorrowingIterator()
    return try it1._elementsEqual(it2)
  }
}

@available(SwiftStdlib 6.4, *)
extension Iterable
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  /// Returns a Boolean value indicating whether two iterables contain
  /// equivalent elements in the same order, using the given predicate as the
  /// equivalence test.
  ///
  /// The predicate must form an *equivalence relation* over the elements. That
  /// is, for any elements `a`, `b`, and `c`, the following conditions must
  /// hold:
  ///
  /// - `areEquivalent(a, a)` is always `true`. (Reflexivity)
  /// - `areEquivalent(a, b)` implies `areEquivalent(b, a)`. (Symmetry)
  /// - If `areEquivalent(a, b)` and `areEquivalent(b, c)` are both `true`, then
  ///   `areEquivalent(a, c)` is also `true`. (Transitivity)
  ///
  /// - Parameters:
  ///   - other: A BorrowingSequence to compare to this BorrowingSequence.
  ///   - areEquivalent: A predicate that returns `true` if its two arguments
  ///     are equivalent; otherwise, `false`.
  /// - Returns: `true` if this BorrowingSequence and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the count of the longer of the input sequences.
  @inlinable
  package func _elementsEqual<
    Other: Iterable & ~Copyable & ~Escapable
  >(
    _ other: borrowing Other,
    by areEquivalent: (borrowing Element, borrowing Other.Element) throws(Failure) -> Bool
  ) throws(Failure) -> Bool
  where Other.Element: ~Copyable, Other.Failure == Failure
  {
    let it1 = self.makeBorrowingIterator()
    let it2 = other.makeBorrowingIterator()
    return try it1._elementsEqual(it2, by: areEquivalent)
  }
}

#endif
