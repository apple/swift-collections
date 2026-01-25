//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2)


@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @frozen
  public struct BorrowingIterator: ~Escapable, BorrowingIteratorProtocol {
    @usableFromInline
    internal var _currentSegment: Span<Element>
    
    @usableFromInline
    internal var _nextSegment: Span<Element>
    
    @_alwaysEmitIntoClient
    @_lifetime(borrow deque)
    internal init(deque: borrowing RigidDeque<Element>, iteratedCount: Int = 0) {
      let segments = deque._handle.segments()
      self._currentSegment = _overrideLifetime(
        Span(_unsafeElements: segments.first),
        borrowing: deque)
      self._nextSegment = _overrideLifetime(
        Span(
          _unsafeElements: segments.second ?? UnsafeBufferPointer(start: nil, count: 0)),
        borrowing: deque)
    }
    
    @_alwaysEmitIntoClient
    @_lifetime(copy self)
    @_lifetime(self: copy self)
    public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
      let c = Swift.min(_currentSegment.count, maximumCount)
      // FIXME: Define and use Span._trim(first:)
      let result = _currentSegment.extracting(first: c)
      if c == _currentSegment.count {
        _currentSegment = _nextSegment
        _nextSegment = Span()
      } else {
        _currentSegment = _currentSegment.extracting(droppingFirst: c)
      }
      return result
    }
  }
  
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public borrowing func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(deque: self)
  }
#endif
}

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension RigidDeque: Container where Element: ~Copyable {}
#endif

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(after index: Int) -> Int { index + 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(after index: inout Int) { index += 1 }

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
    precondition(index >= 0 && index <= count, "Index out of bounds")
    let segment = self._handle
      .nextSegment(from: index)
      ._extracting(first: maximumCount)
    index &+= segment.count
    return _overrideLifetime(Span(_unsafeElements: segment), borrowing: self)
  }
}

#endif
