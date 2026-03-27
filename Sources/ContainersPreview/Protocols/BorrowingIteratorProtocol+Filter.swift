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
extension BorrowingIteratorProtocol
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @inlinable
  @_lifetime(copy self)
  public consuming func filter(
    _ isIncluded: @escaping (borrowing Element) -> Bool
  ) -> BorrowingFilter<Self> {
    BorrowingFilter(_base: self, isIncluded: isIncluded)
  }
}

@available(SwiftStdlib 6.4, *)
public struct BorrowingFilter<
  Base: BorrowingIteratorProtocol & ~Copyable & ~Escapable
>: ~Copyable, ~Escapable
where Base.Element: ~Copyable {
  public typealias Element = Base.Element

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
extension BorrowingFilter: BorrowingIteratorProtocol
where Base: ~Copyable & ~Escapable, Base.Element: ~Copyable {
  @_lifetime(&self)
  public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
    // FIXME: This is quite inefficient compared to Container's filter
    while true {
      let span = _base.nextSpan(maximumCount: 1)
      if span.isEmpty { return span }
      precondition(span.count == 1, "Invalid BorrowingIterator")
      if _isIncluded(span[unchecked: 0]) { return span }
    }
  }
}

#endif
