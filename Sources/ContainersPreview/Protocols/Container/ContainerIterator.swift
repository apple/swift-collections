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

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension Container
where
  Self: ~Copyable /*FIXME: & ~Escapable*/,
  Element: ~Copyable,
  BorrowingIterator_ == ContainerIterator<Self>
{
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator_() -> BorrowingIterator_ {
    ContainerIterator(
      _borrowing: self,
      from: self.startIndex,
      to: self.endIndex)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(from start: Index, to end: Index) -> BorrowingIterator_ {
    ContainerIterator(_borrowing: self, from: start, to: end)
  }

  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: borrowing BorrowingIterator_) -> Index {
    iterator._position
  }
}

@available(SwiftStdlib 6.4, *)
public struct ContainerIterator<
  Base: Container & ~Copyable /*FIXME: & ~Escapable*/
>: ~Copyable, ~Escapable
where Base.Element: ~Copyable
{
  public typealias Element = Base.Element

  @_alwaysEmitIntoClient
  package let _base: Ref<Base> // FIXME: This doesn't support nonescapable Bases

  @_alwaysEmitIntoClient
  package let _end: Base.Index

  @_alwaysEmitIntoClient
  package var _position: Base.Index

  @_alwaysEmitIntoClient
  @_lifetime(borrow base)
  package init(_borrowing base: borrowing Base, from start: Base.Index, to end: Base.Index) {
    self._base = Ref(base)
    self._end = end
    self._position = start
  }
}

@available(SwiftStdlib 6.4, *)
extension ContainerIterator: BorrowingIteratorProtocol_
where
  Base: ~Copyable /*FIXME: & ~Escapable*/,
  Base.Element: ~Copyable
{
  public typealias Element_ = Base.Element

  @_alwaysEmitIntoClient
  @_unsafeNonescapableResult // FIXME: we cannot convert from a borrow to an inout dependence?!
  @_lifetime(&self)
  public mutating func nextSpan_(maxCount: Int) -> Span<Base.Element> {
    _base.value
      .nextSpan(
        after: &self._position,
        maxCount: maxCount,
        limitedBy: self._end)
  }

  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  public mutating func skip_(by maximumOffset: Int) -> Int {
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
