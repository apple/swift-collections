//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
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
  public struct BorrowIterator: ~Escapable, BorrowIteratorProtocol {
    var currentSegment: Span<Element>
    var nextSegment: Span<Element>
    
    @_lifetime(borrow deque)
    internal init(deque: borrowing RigidDeque<Element>, iteratedCount: Int = 0) {
      let segments = deque._handle.segments()
      self.currentSegment = _overrideLifetime(
        Span(_unsafeElements: segments.first),
        borrowing: deque)
      self.nextSegment = _overrideLifetime(
        Span(
          _unsafeElements: segments.second ?? UnsafeBufferPointer(start: nil, count: 0)),
        borrowing: deque)
    }
    
    @_lifetime(copy self)
    @_lifetime(self: copy self)
    public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
      let max = maximumCount
      let c = Swift.min(currentSegment.count, max)
      let result = currentSegment.extracting(first: c)
      if c == currentSegment.count {
        currentSegment = nextSegment
        nextSegment = Span()
      } else {
        currentSegment = currentSegment.extracting(droppingFirst: c)
      }
      return result
    }
  }
  
  @_lifetime(borrow self)
  public borrowing func startBorrowIteration() -> BorrowIterator {
    BorrowIterator(deque: self)
  }
#endif
}

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension RigidDeque: Container where Element: ~Copyable {}
#endif

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @inlinable @inline(__always)
  public func index(after index: Int) -> Int { index + 1 }

  @inlinable @inline(__always)
  public func formIndex(after index: inout Int) { index += 1 }

  @inlinable @inline(__always)
  public func index(_ index: Int, offsetBy n: Int) -> Int {
    index + n
  }

  @inlinable
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    index._advance(by: &n, limitedBy: limit)
  }

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
