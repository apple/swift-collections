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

@_frozen
@usableFromInline
package struct _ShamSpanIterator {
  // FIXME: Remove this when `Span.BorrowingIterator` becomes actually usable.
  @_alwaysEmitIntoClient
  internal var _basePointer: UnsafeRawPointer?

  @_alwaysEmitIntoClient
  internal var _baseCount: Int

  @_alwaysEmitIntoClient
  internal var _start: Int

  @_alwaysEmitIntoClient
  internal var _count: Int
}

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
extension Span: RandomAccessContainer where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  package func _makeBorrowingIterator(from start: Int, to end: Int) -> BorrowingIterator {
    // Note: This is declared `copy self` so that types can forward to it without having to override lifetimes.
    #if false // FIXME: Span's iterator needs to provide a public "slicing" initializer
    return BorrowingIterator(self, from: start, to: end)
    #else
    var it = BorrowingIterator(self.extracting(first: end))
    let c = it.skip(by: start)
    precondition(c == start)
    return it
    #endif
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(from start: Int, to end: Int) -> BorrowingIterator {
    _makeBorrowingIterator(from: start, to: end)
  }

  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: inout BorrowingIterator) -> Int {
    #if false // FIXME: SpanIterator needs to provide public `base` and `position` properties
    precondition(
      self.isTriviallyIdentical(to: iterator._span),
      "Iterator does not belong to this container")
    return iterator._start
    #else
    precondition(MemoryLayout<BorrowingIterator>.stride == MemoryLayout<_ShamSpanIterator>.stride)
    return self.withUnsafeBufferPointer { ourBuffer in
      Swift.withUnsafeBytes(of: &iterator) { buffer in
        buffer.withMemoryRebound(to: _ShamSpanIterator.self) { shamBuffer in
          precondition(
            shamBuffer[0]._basePointer == UnsafeRawPointer(ourBuffer.baseAddress) && shamBuffer[0]._baseCount <= ourBuffer.count,
            "Iterator does not belong to this container")
          return shamBuffer[0]._start
        }
      }
    }
    #endif
  }
}
#endif

#if compiler(>=6.2)
@available(SwiftStdlib 5.0, *)
extension Span where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public var startIndex: Int {
    0
  }

  @_alwaysEmitIntoClient
  public var endIndex: Int {
    count
  }

  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  public func _nextSpan(after index: inout Int) -> Self {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    let result = self.extracting(last: count - index)
    index = count
    return result
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Self {
    _nextSpan(after: &index)
  }

  // FIXME: This has the proper lifetime declaration but can't fulfill the Container requirement.
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  public func _nextSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> Self {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maxCount > 0, "maxCount must be positive")
    precondition(limit >= 0 && limit <= count, "Index out of bounds")
    var end = index &+ Swift.min(maxCount, count &- index)
    if limit >= index, limit < end {
      end = limit
    }
    let r = self.extracting(unchecked: Range(uncheckedBounds: (index, end)))
    index = end
    return r
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> Self {
    _nextSpan(after: &index, maxCount: maxCount, limitedBy: limit)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(
    before index: Index
  ) -> (index: Index, distance: Int) {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    return (0, index)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(
    before index: Index, maxDistance: Int, limitedBy limit: Index
  ) -> (index: Index, distance: Int) {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(limit >= 0 && limit <= count, "Index out of bounds")
    precondition(maxDistance > 0, "maxDistance must be positive")
    let p = index._clampedDown(towards: 0, maxDistance: maxDistance, limitedBy: limit)
    return (p, index &- p)
  }
}
#endif
