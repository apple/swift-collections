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

// MARK: Borrowing

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  public struct BorrowIterator: ~Escapable {
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
    public mutating func nextSpan(maximumCount: Int? = nil) -> Span<Element> {
      let max = maximumCount ?? Int.max
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
}

#endif
