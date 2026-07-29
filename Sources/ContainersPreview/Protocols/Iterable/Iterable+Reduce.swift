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

#endif
