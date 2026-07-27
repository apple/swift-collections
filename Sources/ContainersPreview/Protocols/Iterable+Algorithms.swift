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

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension Iterable
  where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @inlinable
  public func reduce<Result: ~Copyable>(
    _ initialResult: consuming Result,
    _ nextPartialResult:
      (_ partialResult: consuming Result, borrowing Element) throws(Failure) -> Result
  ) throws(Failure) -> Result {
    try makeBorrowingIterator().reduce(initialResult, nextPartialResult)
  }

  @inlinable
  public func reduce<Result>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult:
      (_ partialResult: inout Result, borrowing Element) throws(Failure) -> ()
  ) throws(Failure) -> Result {
    try makeBorrowingIterator().reduce(into: initialResult, updateAccumulatingResult)
  }
}

// Ambiguity breakers
@available(SwiftStdlib 6.4, *)
extension Sequence where Self: Iterable {
  public func reduce<Result: ~Copyable>(
    _ initialResult: consuming Result,
    _ nextPartialResult:
      (_ partialResult: consuming Result, borrowing Element) throws(Failure) -> Result
  ) throws(Failure) -> Result {
    try makeBorrowingIterator().reduce(initialResult, nextPartialResult)
  }

  @inlinable
  public func reduce<Result>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult:
      (_ partialResult: inout Result, borrowing Element) throws(Failure) -> ()
  ) throws(Failure) -> Result {
    try makeBorrowingIterator().reduce(into: initialResult, updateAccumulatingResult)
  }
}

@available(SwiftStdlib 6.4, *)
extension Iterable
  where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @inlinable
  public func elementsEqual<OtherSequence: Iterable>(
    _ other: borrowing OtherSequence,
    by areEquivalent: (borrowing Element, borrowing OtherSequence.Element) throws(Failure) -> Bool
  ) throws(Failure) -> Bool
  where OtherSequence: ~Copyable & ~Escapable, OtherSequence.Element: ~Copyable, OtherSequence.Failure == Failure
  {
    // FIXME: Forward to the iterator's implementation of same
    var iter1 = makeBorrowingIterator()
    var iter2 = other.makeBorrowingIterator()
    while true {
      var el1 = try iter1.nextSpan()

      if el1.isEmpty {
        // LHS is empty - sequences are equal iff RHS is also empty
        let el2 = try iter2.nextSpan(maxCount: 1)
        return el2.isEmpty
      }

      while el1.count > 0 {
        let el2 = try iter2.nextSpan(maxCount: el1.count)
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
extension Iterable
where Self: ~Copyable & ~Escapable, Element: ~Copyable & Equatable {
  @inlinable
  public func elementsEqual<OtherSequence: Iterable<Element, Failure>>(
    _ other: borrowing OtherSequence
  ) throws(Failure) -> Bool
  where
    OtherSequence: ~Copyable & ~Escapable,
    OtherSequence.Element: ~Copyable
  {
    return try self.elementsEqual(other, by: ==)
  }
}

#endif
