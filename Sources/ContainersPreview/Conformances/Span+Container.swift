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
  public func nextSpan(after index: inout Int, maxCount: Int) -> Span<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maxCount > 0, "maxCount must be positive")
    let limit = index &+ Swift.min(maxCount, count &- index)
    return self.extracting(unchecked: Range(uncheckedBounds: (index, limit)))
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(before index: inout Int, maxCount: Int) -> Span<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maxCount > 0, "maxCount must be positive")
    let limit = index &- Swift.min(maxCount, index)
    return self.extracting(unchecked: Range(uncheckedBounds: (limit, index)))
  }
}

#endif
