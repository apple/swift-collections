//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
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
extension UniqueDeque where Element: ~Copyable {
#if compiler(>=6.4) && UnstableContainersPreview
  public typealias BorrowingIterator = RigidDeque<Element>.BorrowingIterator
  
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public borrowing func makeBorrowingIterator_() -> BorrowingIterator {
    BorrowingIterator(_deque: self._storage)
  }
#endif
}

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension UniqueDeque: Container where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(
    from start: Index, to end: Index
  ) -> BorrowingIterator_ {
    _storage.makeBorrowingIterator(from: start, to: end)
  }

  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: borrowing BorrowingIterator_) -> Index {
    _storage.currentIndex(of: iterator)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque: BidirectionalContainer where Element: ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque: RandomAccessContainer where Element: ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque: MutableContainer where Element: ~Copyable {}

#if compiler(>=6.4)
@available(SwiftStdlib 5.0, *)
extension UniqueDeque: RangeReplaceableContainer where Element: ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque: DynamicContainer where Element: ~Copyable {}
#endif
#endif

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(after index: Int) -> Int { index + 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(before index: Int) -> Int { index - 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(after index: inout Int) { index += 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(before index: inout Int) { index -= 1 }

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
  public func nextSpan(after index: inout Int) -> Span<Element> {
    _storage.nextSpan(after: &index)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> Span<Element> {
    _storage.nextSpan(after: &index, maxCount: maxCount, limitedBy: limit)
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int
  ) -> MutableSpan<Element> {
    _storage.nextMutableSpan(after: &index)
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> MutableSpan<Element> {
    _storage.nextMutableSpan(after: &index, maxCount: maxCount, limitedBy: limit)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(before index: Index) -> (index: Index, distance: Int) {
    _storage.spanBoundary(before: index)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(
    before index: Index, maxDistance: Int, limitedBy limit: Index
  ) -> (index: Index, distance: Int) {
    _storage.spanBoundary(before: index, maxDistance: maxDistance, limitedBy: limit)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(before index: inout Int, maxCount: Int) -> Span<Element> {
    // FIXME: Remove this in favor of the BidirectionalContainer algorithm.
    _storage.previousSpan(before: &index, maxCount: maxCount)
  }
}

#endif
