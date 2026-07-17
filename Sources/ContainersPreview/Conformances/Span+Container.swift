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

  // FIXME: This has the proper lifetime declaration but can't fulfill the Container requirement.
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  public func _nextSpan(after index: inout Int, maxCount: Int) -> Self {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maxCount > 0, "maxCount must be positive")
    let limit = index &+ Swift.min(maxCount, count &- index)
    return self.extracting(unchecked: Range(uncheckedBounds: (index, limit)))
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(after index: inout Int, maxCount: Int) -> Self {
    _nextSpan(after: &index, maxCount: maxCount)
  }

  // FIXME: This has the proper lifetime declaration but can't fulfill the Container requirement.
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  public func _nextSpan(
    after index: inout Index, limitedBy limit: Index?
  ) -> Self {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    let end: Index
    if let limit {
      precondition(limit >= 0 && limit <= count, "Index out of bounds")
      end = Swift.min(limit, count)
    } else {
      end = count
    }
    let range = Range(uncheckedBounds: (index, end))
    index = end
    return self.extracting(unchecked: range)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Index, limitedBy limit: Index?
  ) -> Self {
    _nextSpan(after: &index, limitedBy: limit)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(before index: Index, maxDistance: Int) -> Index? {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maxDistance > 0, "maxDistance must be positive")
    guard index > 0 else { return nil }
    return Swift.max(0, index &- maxDistance)
  }
}

#endif
