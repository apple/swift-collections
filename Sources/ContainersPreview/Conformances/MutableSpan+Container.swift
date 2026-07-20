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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@available(SwiftStdlib 6.4, *)
extension MutableSpan: RandomAccessContainer where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(
    from start: Int
  ) -> BorrowingIterator_ {
    var it = Span<Element>.BorrowingIterator_(self.span)
    var remainder = start
    while remainder > 0 {
      let d = it.skip_(by: remainder)
      precondition(d > 0)
      remainder &-= d
    }
    return it
  }

  @_alwaysEmitIntoClient
  public func currentIndex(
    of iterator: borrowing BorrowingIterator_
  ) -> Int {
    precondition(
      self.span.isTriviallyIdentical(to: iterator._span),
      "Invalid iterator")
    return iterator._start
  }

  @_alwaysEmitIntoClient
  public var startIndex: Int {
    0
  }

  @_alwaysEmitIntoClient
  public var endIndex: Int {
    count
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Int
  ) -> Span<Element> {
    self.span._nextSpan(after: &index)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Index, maxCount: Int, limitedBy limit: Index
  ) -> Span<Element> {
    self.span._nextSpan(after: &index, maxCount: maxCount, limitedBy: limit)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(
    before index: Index
  ) -> (index: Index, distance: Int) {
    self.span.spanBoundary(before: index)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(
    before index: Index, maxDistance: Int, limitedBy limit: Index
  ) -> (index: Index, distance: Int) {
    self.span.spanBoundary(before: index, maxDistance: maxDistance, limitedBy: limit)
  }
}

@available(SwiftStdlib 6.4, *)
extension MutableSpan: MutableContainer where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  public consuming func _nextMutableSpan(
    after index: inout Int
  ) -> MutableSpan<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    let end = self.count
    let r = self._consumingExtracting(unchecked: Range(uncheckedBounds: (index, end)))
    index = end
    return r
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int
  ) -> MutableSpan<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    let end = self.count
    let r = self._mutatingExtracting(
      unchecked: Range(uncheckedBounds: (index, end)))
    index = end
    return r
  }

  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  public consuming func _nextMutableSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> MutableSpan<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(limit >= 0 && limit <= count, "Index out of bounds")
    precondition(maxCount > 0, "maxCount must be positive")
    var end = index &+ Swift.min(maxCount, count &- index)
    if limit >= index, limit < end {
      end = limit
    }
    let r = self._consumingExtracting(
      unchecked: Range(uncheckedBounds: (index, end)))
    index = end
    return r
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> MutableSpan<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(limit >= 0 && limit <= count, "Index out of bounds")
    precondition(maxCount > 0, "maxCount must be positive")
    var end = index &+ Swift.min(maxCount, count &- index)
    if limit >= index, limit < end {
      end = limit
    }
    let r = self._mutatingExtracting(
      unchecked: Range(uncheckedBounds: (index, end)))
    index = end
    return r
  }
}

#endif
