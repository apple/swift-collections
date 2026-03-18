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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension Container
where
  Self: ~Copyable /*FIXME: & ~Escapable*/,
  BorrowingIterator == ContainerIterator<Self>
{
  @_lifetime(borrow self)
  public func makeBorrowingIterator() -> BorrowingIterator {
    ContainerIterator(_borrowing: self, from: self.startIndex)
  }
}

@available(SwiftStdlib 5.0, *)
public struct ContainerIterator<
  Base: Container & ~Copyable /*FIXME: & ~Escapable*/
>: ~Copyable, ~Escapable {
  let _base: Borrow<Base> // FIXME: This doesn't support nonescapable Bases
  var _position: Base.Index

  @_lifetime(borrow base)
  init(_borrowing base: borrowing @_addressable Base, from position: Base.Index) {
    self._base = Borrow(_borrowing: base)
    self._position = position
  }
}

@available(SwiftStdlib 5.0, *)
extension ContainerIterator: BorrowingIteratorProtocol
where Base: ~Copyable /*FIXME: & ~Escapable*/
{
  public typealias Element = Base.Element

  @_unsafeNonescapableResult // FIXME: we cannot convert from a borrow to an inout dependence?!
  @_lifetime(&self)
  public mutating func nextSpan(maximumCount: Int) -> Span<Base.Element> {
    _base.value.nextSpan(after: &self._position, maximumCount: maximumCount)
  }

//  @_lifetime(copy self)
//  public mutating func nextSpan2(maximumCount: Int) -> Span<Base.Element> {
//    var i = self._position
//    let span = _base.value.nextSpan(
//      after: &i,
//      maximumCount: maximumCount)
//    _ = consume span
//    let result = _overrideLifetime(span, copying: self)
//    self._position = i
//    return .init()
//  }

  @_lifetime(self: copy self)
  public mutating func skip(by maximumOffset: Int) -> Int {
    // FIXME: If we aren't modeling bidirectional iterators, then this should
    // trap on negative maximumOffsets
    var n = maximumOffset
    let limit = (n < 0 ? _base.value.startIndex : _base.value.endIndex)
    var i = self._position
    self._base.value.formIndex(&i, offsetBy: &n, limitedBy: limit)
    self._position = i
    return maximumOffset - n
  }
}

#endif
