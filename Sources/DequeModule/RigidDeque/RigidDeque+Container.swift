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
#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @frozen
  public struct BorrowingIterator: ~Escapable, BorrowingIteratorProtocol_ {
    @usableFromInline
    internal var _currentSegment: Span<Element>
    
    @usableFromInline
    internal var _nextSegment: Span<Element>
    
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
    }
    
    @_alwaysEmitIntoClient
    @_lifetime(copy self)
    @_lifetime(self: copy self)
    public mutating func nextSpan_(maximumCount: Int) -> Span<Element> {
      let result = _currentSegment._trim(first: maximumCount)
      if _currentSegment.isEmpty {
        _currentSegment = _nextSegment
        _nextSegment = Span()
      }
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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension RigidDeque: Container where Element: ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension RigidDeque: BidirectionalContainer where Element: ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension RigidDeque: RandomAccessContainer where Element: ~Copyable {}

#if compiler(>=6.3)
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

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW // FIXME: Enable unconditionally in 1.5.0
  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(before index: Int) -> Int { index - 1 }
#endif

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(after index: inout Int) { index += 1 }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW // FIXME: Enable unconditionally in 1.5.0
  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(before index: inout Int) { index -= 1 }
#endif

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
  public func nextSpan(after index: inout Int, maximumCount: Int) -> Span<Element> {
    _checkValidIndex(index)
    precondition(maximumCount > 0, "maximumCount must be positive")
    let segment = self._handle
      .nextSegment(after: index)
      ._extracting(first: maximumCount)
    index &+= segment.count
    return _overrideLifetime(Span(_unsafeElements: segment), borrowing: self)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW // FIXME: Enable unconditionally in 1.5.0
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int, maximumCount: Int
  ) -> MutableSpan<Element> {
    let segment = self._handle
      .nextSegment(after: index)
      ._extracting(first: maximumCount)
    index &+= segment.count
    return _overrideLifetime(
      MutableSpan(_unsafeElements: .init(mutating: segment)),
      mutating: &self)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(before index: inout Int, maximumCount: Int) -> Span<Element> {
    _checkValidIndex(index)
    precondition(maximumCount > 0, "maximumCount must be positive")
    let segment = self._handle
      .previousSegment(before: index)
      ._extracting(last: maximumCount)
    index &-= segment.count
    return _overrideLifetime(Span(_unsafeElements: segment), borrowing: self)
  }
#endif
}

#endif
