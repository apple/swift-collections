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
import ContainersPreview
#endif

#if compiler(>=6.2)


@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
#if compiler(>=6.4) && UnstableContainersPreview
  @frozen
  public struct BorrowingIterator: ~Escapable, BorrowingIteratorProtocol_ {
    public typealias Element_ = Element

    @usableFromInline
    internal var _currentSegment: Span<Element>
    
    @usableFromInline
    internal var _nextSegment: Span<Element>

    @usableFromInline
    internal var _position: Int

    @_alwaysEmitIntoClient
    @_lifetime(borrow _deque)
    internal init(_deque: borrowing RigidDeque<Element>) {
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
    internal init(
      _deque: borrowing RigidDeque<Element>,
      from start: Int
    ) {
      precondition(start >= 0 && start <= _deque.count, "Index out of bounds")
      self.init(_deque: _deque)
      var remainder = start
      while remainder > 0 {
        let d = self.skip_(by: remainder)
        precondition(d > 0)
        remainder &-= d
      }
      self._position = start
    }

    @_alwaysEmitIntoClient
    @_lifetime(&self)
    @_lifetime(self: copy self)
    public mutating func nextSpan_(maxCount: Int) -> Span<Element> {
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
  public borrowing func makeBorrowingIterator_() -> BorrowingIterator {
    BorrowingIterator(_deque: self)
  }
#endif
}

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension RigidDeque: Container where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(
    from start: Index
  ) -> BorrowingIterator_ {
    BorrowingIterator(_deque: self, from: start)
  }

  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: borrowing BorrowingIterator_) -> Index {
    // FIXME: This should validate that the iterator belongs to this deque.
    return iterator._position
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque: BidirectionalContainer where Element: ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension RigidDeque: RandomAccessContainer where Element: ~Copyable {}

#if compiler(>=6.4)
@available(SwiftStdlib 5.0, *)
extension RigidDeque: MutableContainer where Element: ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension RigidDeque: RangeReplaceableContainer where Element: ~Copyable {}
#endif
#endif

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(after index: Int) -> Int { index + 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(before index: Int) -> Int { index - 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(after index: inout Int) { index += 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(before index: inout Int) { index -= 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(_ index: Int, offsetBy n: Int) -> Int {
    index + n
  }

  @_alwaysEmitIntoClient
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    index._advance(by: &n, limitedBy: limit)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Span<Element> {
    _checkValidIndex(index)
    let segment = self._handle.nextSegment(after: index)
    index &+= segment.count
    return _overrideLifetime(Span(_unsafeElements: segment), borrowing: self)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> Span<Element> {
    _checkValidIndex(index)
    _checkValidIndex(limit)
    let segment = self._handle
      .nextSegment(after: index)
      ._extracting(first: maxCount)
    var span = _overrideLifetime(Span(_unsafeElements: segment), borrowing: self)
    if limit >= index, span.count > limit &- index {
      span = span.extracting(first: limit &- index)
    }
    index &+= span.count
    return span
  }

  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int, maxCount: Int
  ) -> MutableSpan<Element> {
    _checkValidIndex(index)
    precondition(maxCount > 0, "maxCount must be positive")
    let segment = self._handle
      .nextSegment(after: index)
      ._extracting(first: maxCount)
    index &+= segment.count
    return _overrideLifetime(
      MutableSpan(_unsafeElements: .init(mutating: segment)),
      mutating: &self)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(before index: Index) -> (index: Index, distance: Int) {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    let r = self._handle.spanBoundary(before: index)
    return (r.offset, r.distance)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(
    before index: Index, maxDistance: Int, limitedBy limit: Index
  ) -> (index: Index, distance: Int) {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(limit >= 0 && limit <= count, "Index out of bounds")
    precondition(maxDistance > 0, "maxDistance must be positive")
    let r = self._handle.spanBoundary(before: index, maxDistance: maxDistance, limitedBy: limit)
    return (r.offset, r.distance)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(before index: inout Int, maxCount: Int) -> Span<Element> {
    // FIXME: Remove this in favor of the BidirectionalContainer algorithm.
    _checkValidIndex(index)
    precondition(maxCount > 0, "maxCount must be positive")
    let segment = self._handle
      .previousSegment(before: index)
      ._extracting(last: maxCount)
    index &-= segment.count
    return _overrideLifetime(Span(_unsafeElements: segment), borrowing: self)
  }
}

#endif
