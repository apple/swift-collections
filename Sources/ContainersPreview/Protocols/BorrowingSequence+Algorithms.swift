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

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence_
  where Self: ~Copyable & ~Escapable, Element_: ~Copyable
{
  @inlinable
  public func reduce<Result: ~Copyable>(
    _ initialResult: consuming Result,
    _ nextPartialResult:
      (_ partialResult: consuming Result, borrowing Element_) throws(Failure) -> Result // FIXME(throws): Union
  ) throws(Failure) -> Result {
    try makeBorrowingIterator_().reduce(initialResult, nextPartialResult)
  }

  @inlinable
  public func reduce<Result>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult:
      (_ partialResult: inout Result, borrowing Element_) throws(Failure) -> ()
  ) throws(Failure) -> Result {
    try makeBorrowingIterator_().reduce(into: initialResult, updateAccumulatingResult)
  }
}

// Ambiguity breakers
@available(SwiftStdlib 5.0, *)
extension Sequence where Self: BorrowingSequence_ {
  public func reduce<Result: ~Copyable>(
    _ initialResult: consuming Result,
    _ nextPartialResult:
      (_ partialResult: consuming Result, borrowing Element_) throws(Failure) -> Result // FIXME(throws): Union
  ) throws(Failure) -> Result {
    try makeBorrowingIterator_().reduce(initialResult, nextPartialResult)
  }

  @inlinable
  public func reduce<Result>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult:
      (_ partialResult: inout Result, borrowing Element_) throws(Failure) -> () // FIXME(throws): Union
  ) throws(Failure) -> Result {
    try makeBorrowingIterator_().reduce(into: initialResult, updateAccumulatingResult)
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence_
  where Self: ~Copyable & ~Escapable, Element_: ~Copyable
{
  @inlinable
  public func elementsEqual<OtherSequence: BorrowingSequence_>(
    _ other: borrowing OtherSequence,
    by areEquivalent: (borrowing Element_, borrowing OtherSequence.Element_) throws(Failure) -> Bool // FIXME(throws): Union
  ) throws(Failure) -> Bool
  where OtherSequence: ~Copyable & ~Escapable, OtherSequence.Element_: ~Copyable, OtherSequence.Failure == Failure
  {
    // FIXME: Forward to the iterator's implementation of same
    var iter1 = try makeBorrowingIterator_()
    var iter2 = try other.makeBorrowingIterator_()
    while true {
      var el1 = try iter1.nextSpan_()

      if el1.isEmpty {
        // LHS is empty - sequences are equal iff RHS is also empty
        let el2 = try iter2.nextSpan_(maximumCount: 1)
        return el2.isEmpty
      }

      while el1.count > 0 {
        let el2 = try iter2.nextSpan_(maximumCount: el1.count)
        if el2.isEmpty { return false }
        for i in 0..<el2.count {
          if try !areEquivalent(el1[i], el2[i]) { return false }
        }
        el1 = el1.extracting(droppingFirst: el2.count)
      }
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence_
where Self: ~Copyable & ~Escapable, Element_: ~Copyable & Equatable {
  @inlinable
  public func elementsEqual<OtherSequence: BorrowingSequence_<Element_, Failure>>( // FIXME(throws): Union
    _ other: borrowing OtherSequence
  ) throws(Failure) -> Bool
  where
    OtherSequence: ~Copyable & ~Escapable,
    OtherSequence.Element_: ~Copyable
  {
    return try self.elementsEqual(other, by: ==)
  }
}

#endif
