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
where
  Self: ~Copyable /*& ~Escapable*/,
  Element: ~Copyable
{
  @inlinable
  @_lifetime(borrow self)
  public borrowing func filter( // FIXME: Ambiguity with Sequence.filter
    _ isIncluded: @escaping (borrowing Element) -> Bool
  ) -> BorrowingFilter<Self> {
    // FIXME: isIncluded should be allowed to throw
    BorrowingFilter(_base: self, isIncluded: isIncluded)
  }
}

@available(SwiftStdlib 6.4, *)
public struct BorrowingFilter<
  Base: Iterable & ~Copyable /*& ~Escapable*/
>: ~Copyable, ~Escapable
where Base.Element: ~Copyable {
  public typealias Element = Base.Element
  public typealias Failure = Base.Failure

  @_alwaysEmitIntoClient
  public let _isIncluded: (borrowing Element) -> Bool

  @_alwaysEmitIntoClient
  public var _base: Ref<Base> // FIXME: Support for ~Escapable

  @inlinable
  @_lifetime(borrow _base)
  internal init(
    _base: borrowing Base,
    isIncluded: @escaping (borrowing Element) -> Bool
  ) {
    self._isIncluded = isIncluded
    self._base = Ref(_base)
  }
}

// FIXME: Sendable

@available(SwiftStdlib 6.4, *)
extension BorrowingFilter: Iterable
where
  Base: ~Copyable /*& ~Escapable*/,
  Base.Element: ~Copyable
{
  public typealias BorrowingIterator = BorrowingFilterIterator<Base.BorrowingIterator>

  @inlinable
  @_lifetime(borrow self)
  public borrowing func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingFilterIterator(
      _base: self._base.value.makeBorrowingIterator(),
      isIncluded: self._isIncluded)
  }
}

#endif
