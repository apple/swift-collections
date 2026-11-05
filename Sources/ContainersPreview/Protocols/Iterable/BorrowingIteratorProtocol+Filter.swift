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
extension BorrowingIteratorProtocol
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @inlinable
  @_lifetime(copy self)
  public consuming func filter(
    _ isIncluded: @escaping (borrowing Element) -> Bool
  ) -> BorrowingFilterIterator<Self> {
    // FIXME: isIncluded should be allowed to throw
    BorrowingFilterIterator(_base: self, isIncluded: isIncluded)
  }
}

@available(SwiftStdlib 6.4, *)
public struct BorrowingFilterIterator<
  Base: BorrowingIteratorProtocol & ~Copyable & ~Escapable
>: ~Copyable, ~Escapable
where Base.Element: ~Copyable {
  public typealias Element = Base.Element
  public typealias Failure = Base.Failure

  @_alwaysEmitIntoClient
  public let _isIncluded: (borrowing Element) -> Bool

  @_alwaysEmitIntoClient
  public var _base: Base

  @inlinable
  @_lifetime(copy _base)
  internal init(
    _base: consuming Base,
    isIncluded: @escaping (borrowing Element) -> Bool
  ) {
    self._isIncluded = isIncluded
    self._base = _base
  }
}

// FIXME: Sendable

@available(SwiftStdlib 6.4, *)
extension BorrowingFilterIterator: BorrowingIteratorProtocol
where Base: ~Copyable & ~Escapable, Base.Element: ~Copyable {
  @inlinable
  @_lifetime(&self)
  public mutating func nextSpan(maxCount: Int) throws(Failure) -> Span<Element> {
    // FIXME: This is quite inefficient compared to Container's filter
    while true {
      let span = try _base.nextSpan(maxCount: 1)
      if span.isEmpty { return span }
      precondition(span.count == 1, "Invalid BorrowingIterator")
      if unsafe _isIncluded(span[unchecked: 0]) { return span }
    }
  }
}

#endif
