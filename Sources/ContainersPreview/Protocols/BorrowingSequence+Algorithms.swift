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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 6.4, *)
extension BorrowingSequence_
  where Self: ~Copyable & ~Escapable, Element_: ~Copyable
{
  @inlinable
  public func reduce<Result: ~Copyable>(
    _ initialResult: consuming Result,
    _ nextPartialResult:
      (_ partialResult: consuming Result, borrowing Element_) throws -> Result
  ) rethrows -> Result {
    try makeBorrowingIterator_().reduce(initialResult, nextPartialResult)
  }

  @inlinable
  public func reduce<Result>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult:
      (_ partialResult: inout Result, borrowing Element_) throws -> ()
  ) rethrows -> Result {
    try makeBorrowingIterator_().reduce(into: initialResult, updateAccumulatingResult)
  }
}

// Ambiguity breakers
@available(SwiftStdlib 6.4, *)
extension Sequence where Self: BorrowingSequence_ {
  public func reduce<Result: ~Copyable>(
    _ initialResult: consuming Result,
    _ nextPartialResult:
      (_ partialResult: consuming Result, borrowing Element_) throws -> Result
  ) rethrows -> Result {
    try makeBorrowingIterator_().reduce(initialResult, nextPartialResult)
  }

  @inlinable
  public func reduce<Result>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult:
      (_ partialResult: inout Result, borrowing Element_) throws -> ()
  ) rethrows -> Result {
    try makeBorrowingIterator_().reduce(into: initialResult, updateAccumulatingResult)
  }
}

@available(SwiftStdlib 6.4, *)
extension BorrowingSequence_
  where Self: ~Copyable & ~Escapable, Element_: ~Copyable
{
  @inlinable
  public func elementsEqual<OtherSequence: BorrowingSequence_>(
    _ other: borrowing OtherSequence,
    by areEquivalent: (borrowing Element_, borrowing OtherSequence.Element_) throws -> Bool
  ) rethrows -> Bool
  where OtherSequence: ~Copyable & ~Escapable, OtherSequence.Element_: ~Copyable
  {
    // FIXME: Forward to the iterator's implementation of same
    var iter1 = makeBorrowingIterator_()
    var iter2 = other.makeBorrowingIterator_()
    while true {
      var el1 = iter1.nextSpan_()

      if el1.isEmpty {
        // LHS is empty - sequences are equal iff RHS is also empty
        let el2 = iter2.nextSpan_(maximumCount: 1)
        return el2.isEmpty
      }

      while el1.count > 0 {
        let el2 = iter2.nextSpan_(maximumCount: el1.count)
        if el2.isEmpty { return false }
        for i in 0..<el2.count {
          if try !areEquivalent(el1[i], el2[i]) { return false }
        }
        el1 = el1.extracting(droppingFirst: el2.count)
      }
    }
  }
}

@available(SwiftStdlib 6.4, *)
extension BorrowingSequence_
where Self: ~Copyable & ~Escapable, Element_: ~Copyable & Equatable {
  @inlinable
  public func elementsEqual<OtherSequence: BorrowingSequence_<Element_>>(
    _ other: borrowing OtherSequence
  ) -> Bool
  where
    OtherSequence: ~Copyable & ~Escapable,
    OtherSequence.Element_: ~Copyable
  {
    return self.elementsEqual(other, by: ==)
  }
}

#endif
