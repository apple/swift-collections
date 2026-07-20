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
extension Span: RandomAccessContainer where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(from start: Int) -> BorrowingIterator_ {
    precondition(start >= 0 && start <= self.count, "Index out of bounds")
    // FIXME: SpanIterator needs to have a direct initializer that takes `start`
    var it = BorrowingIterator_(self)
    var remainder = start
    while remainder > 0 {
      let d = it.skip_(by: remainder)
      precondition(d > 0)
      remainder &-= d
    }
    return it
  }

  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: borrowing BorrowingIterator_) -> Int {
    // FIXME: SpanIterator needs to have public `base` and `position` properties
    precondition(
      self.isTriviallyIdentical(to: iterator._span),
      "Invalid iterator")
    return iterator._start
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
