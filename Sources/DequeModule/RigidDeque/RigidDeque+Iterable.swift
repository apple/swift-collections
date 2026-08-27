//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4)

@available(SwiftStdlib 5.0, *)
extension RigidDeque: Iterable where Element: ~Copyable {
  @frozen
  public struct BorrowingIterator: ~Escapable, BorrowingIteratorProtocol {
    @usableFromInline
    package var _currentSegment: Span<Element>

    @usableFromInline
    package var _nextSegment: Span<Element>

    @usableFromInline
    package var _position: Int

    @_alwaysEmitIntoClient
    @_lifetime(borrow _deque)
    package init(_deque: borrowing RigidDeque<Element>) {
      let segments = _deque._handle.segments()
      self._currentSegment = _overrideLifetime(
        Span(_unsafeElements: segments.first),
        borrowing: _deque)
      self._nextSegment = _overrideLifetime(
        Span(
          _unsafeElements: segments.second ?? UnsafeBufferPointer._empty),
        borrowing: _deque)
      self._position = 0
    }

    @_alwaysEmitIntoClient
    @_lifetime(borrow _deque)
    package init(
      _deque: borrowing RigidDeque<Element>,
      from start: Int,
      to end: Int
    ) {
      precondition(start >= 0 && start <= _deque.count, "Index out of bounds")
      precondition(end >= 0 && end <= _deque.count, "Index out of bounds")
      precondition(start <= end, "The start must not be greater than the end")
      let segments = _deque._handle.segments(forOffsets: start ..< end)
      self._currentSegment = _overrideLifetime(
        Span(_unsafeElements: segments.first),
        borrowing: _deque)
      self._nextSegment = _overrideLifetime(
        Span(
          _unsafeElements: segments.second ?? UnsafeBufferPointer._empty),
        borrowing: _deque)
      self._position = start
    }

    @_alwaysEmitIntoClient
    @_lifetime(&self)
    @_lifetime(self: copy self)
    public mutating func nextSpan(maxCount: Int) -> Span<Element> {
      let result = _currentSegment._trim(first: maxCount)
      if _currentSegment.isEmpty {
        _currentSegment = _nextSegment
        _nextSegment = Span()
      }
      _position &+= result.count
      return result
    }
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public borrowing func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(_deque: self)
  }
}
#endif
