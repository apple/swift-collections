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
extension BorrowingIteratorProtocol_
where
  Self: ~Copyable & ~Escapable,
  Element_: ~Copyable
{
  @inlinable
  @_lifetime(copy self)
  public consuming func filter(
    _ isIncluded: @escaping (borrowing Element_) throws(Failure) -> Bool // FIXME(throws): Union
  ) -> BorrowingFilter<Self> {
    BorrowingFilter(_base: self, isIncluded: isIncluded)
  }
}

@available(SwiftStdlib 5.0, *)
public struct BorrowingFilter<
  Base: BorrowingIteratorProtocol_ & ~Copyable & ~Escapable
>: ~Copyable, ~Escapable
where Base.Element_: ~Copyable {
  public typealias Element_ = Base.Element_
  public typealias Failure = Base.Failure

  @_alwaysEmitIntoClient
  public let _isIncluded: (borrowing Element_) throws(Failure) -> Bool

  @_alwaysEmitIntoClient
  public var _base: Base

  @inlinable
  @_lifetime(copy _base)
  internal init(
    _base: consuming Base,
    isIncluded: @escaping (borrowing Element_) throws(Failure) -> Bool
  ) {
    self._isIncluded = isIncluded
    self._base = _base
  }
}

// FIXME: Sendable

@available(SwiftStdlib 5.0, *)
extension BorrowingFilter: BorrowingIteratorProtocol_
where Base: ~Copyable & ~Escapable, Base.Element_: ~Copyable {
  @_lifetime(&self)
  public mutating func nextSpan_(maximumCount: Int) throws(Failure) -> Span<Element_> {
    // FIXME: This is quite inefficient compared to Container's filter
    while true {
      let span = try _base.nextSpan_(maximumCount: 1)
      if span.isEmpty { return span }
      precondition(span.count == 1, "Invalid BorrowingIterator")
      if try _isIncluded(span[unchecked: 0]) { return span }
    }
  }
}

#endif
