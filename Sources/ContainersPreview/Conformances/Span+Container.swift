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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import SpanPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
extension Span: RandomAccessContainer where Element: ~Copyable {
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
    return self.withUnsafeBufferPointer { ourBuffer in
      iterator._withShamIterator { sham in
        precondition(
          sham._basePointer == UnsafeRawPointer(ourBuffer.baseAddress)
          && sham._baseCount <= ourBuffer.count,
          "Iterator does not belong to this container")
        return sham._start
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
  @_transparent
  public var startIndex: Int {
    0
  }

  @_alwaysEmitIntoClient
  @_transparent
  public var endIndex: Int {
    count
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Self {
    _nextSpan(after: &index)
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
    _spanBoundary(before: index, maxDistance: maxDistance, limitedBy: limit)
  }
}
#endif
