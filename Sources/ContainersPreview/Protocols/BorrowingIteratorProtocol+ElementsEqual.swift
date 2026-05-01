//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence_
where
  Self: ~Copyable & ~Escapable, Element_: Equatable,
  Element_: ~Copyable,
  Failure == Never
{
  @inlinable
  package func _elementsEqual<
    Other: BorrowingSequence_<Element_, Never> & ~Copyable & ~Escapable
  >(
    _ other: borrowing Other,
  ) -> Bool
  where Other.Element_: ~Copyable
  {
    let it1 = self.makeBorrowingIterator_()
    let it2 = other.makeBorrowingIterator_()
    return it1.elementsEqual(it2)
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence_
where
  Self: ~Copyable & ~Escapable,
  Element_: ~Copyable
{
  /// Returns a Boolean value indicating whether two borrowing sequences contain
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
    Other: BorrowingSequence_ & ~Copyable & ~Escapable
  >(
    _ other: borrowing Other,
    by areEquivalent: (borrowing Element_, borrowing Other.Element_) throws(Failure) -> Bool
  ) throws(Failure) -> Bool
  where Other.Element_: ~Copyable, Other.Failure == Failure
  {
    let it1 = try self.makeBorrowingIterator_()
    let it2 = try other.makeBorrowingIterator_()
    return try it1.elementsEqual(it2, by: areEquivalent)
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol_
where
  Self: ~Copyable & ~Escapable,
  Element_: ~Copyable & Equatable,
  Failure == Never
{
  @inlinable
  package consuming func elementsEqual<
    Other: BorrowingIteratorProtocol_<Element_, Never> & ~Copyable & ~Escapable
  >(
    _ other: consuming Other,
  ) -> Bool
  where Other.Element_: ~Copyable
  {
    var result = true
    _spanwiseZip(state: &result, with: other) { state, a, b in
      if a.isEmpty || b.isEmpty {
        state = false
        return false
      }
      precondition(a.count == b.count)
      for i in 0 ..< a.count {
        guard a[unchecked: i] == b[unchecked: i] else {
          state = false
          return false
        }
      }
      return true
    }
    return result
  }

  @inlinable
  package consuming func _directElementsEqual<
    Other: BorrowingIteratorProtocol_<Element_, Never> & ~Copyable & ~Escapable
  >(
    _ other: consuming Other,
  ) -> Bool
  where Other.Element_: ~Copyable
  {
#if true // FIXME: rdar://150228920 Exclusive access scopes aren't expanded enough
    // Note: This is the less efficient implementation of elementsEqual. The
    // variant in the #else branch would be preferable, but it doesn't work yet.
    // (It lets the two iterators run at their native speeds, with no artificial
    // maximumCounts.)
    while true {
      let a = self.nextSpan_()
      var i = 0
      if a.isEmpty {
        return other.nextSpan_().isEmpty
      }
      while i < a.count {
        let b = other.nextSpan_(maximumCount: a.count - i)
        if b.isEmpty {
          return false
        }
        precondition(b.count <= a.count - i)

        var j = 0
        while j < b.count {
          guard a[unchecked: i] == b[unchecked: j] else { return false }
          i &+= 1
          j &+= 1
        }
      }
    }
#else
    var a = Span<Element>()
    var b = Span<Element>()
  loop:
    while true {
      if a.isEmpty {
        a = self.nextSpan()
      }
      if b.isEmpty {
        b = other.nextSpan()
      }
      if a.isEmpty || b.isEmpty {
        return a.isEmpty && b.isEmpty
      }

      let c = Swift.min(a.count, b.count)
      var i = 0
      while i < c {
        guard a[unchecked: i] == b[unchecked: i] else { return false }
        i &+= 1
      }
      a = a.extracting(droppingFirst: c)
      b = b.extracting(droppingFirst: c)
    }
#endif
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol_
where
  Self: ~Copyable & ~Escapable,
  Element_: ~Copyable
{
  @inlinable
  package consuming func elementsEqual<
    Other: BorrowingIteratorProtocol_ & ~Copyable & ~Escapable
  >(
    _ other: consuming Other,
    by areEquivalent: (borrowing Element_, borrowing Other.Element_) throws(Failure) -> Bool
  ) throws(Failure) -> Bool
  where Other.Element_: ~Copyable, Other.Failure == Failure // FIXME(throws): Union
  {
    var result = true
    try _spanwiseZip(state: &result, with: other) { state, a, b throws(Failure) in
      assert(a.count == b.count || a.isEmpty || b.isEmpty)
      if a.isEmpty || b.isEmpty {
        state = false
        return false
      }
      for i in 0 ..< a.count {
        guard try areEquivalent(a[i], b[i]) else {
          state = false
          return false
        }
      }
      return true
    }
    return result
  }
}

#endif
