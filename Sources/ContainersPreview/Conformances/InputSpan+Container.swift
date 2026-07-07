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
#endif

#if compiler(>=6.2) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension InputSpan: RandomAccessContainer, MutableContainer
where Element: ~Copyable
{
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(
    from start: Index
  ) -> BorrowingIterator_ {
    let span = self.span
    let it = span.makeBorrowingIterator(from: start)
    // FIXME: `it` is borrowing `span`, not self
    return _overrideLifetime(it, borrowing: self)
  }

  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: borrowing BorrowingIterator_) -> Index {
    self.span.currentIndex(of: iterator)
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public var startIndex: Index { 0 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public var endIndex: Index { count }

  @inlinable
  @_lifetime(borrow self)
  public func nextSpan(after index: inout Index, maxCount: Int) -> Span<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maxCount > 0, "maxCount must be positive")
    let c = Swift.min(count &- index, maxCount)
    let start = capacity &- count &+ index
    return _uncheckedSpan(in: Range(uncheckedBounds: (start, start &+ c)))
  }

  @inlinable
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Index, maxCount: Int
  ) -> MutableSpan<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maxCount > 0, "maxCount must be positive")
    let c = Swift.min(count &- index, maxCount)
    let start = capacity &- count &+ index
    return _uncheckedMutableSpan(in: Range(uncheckedBounds: (start, start &+ c)))
  }

  @inlinable
  @_lifetime(borrow self)
  public func previousSpan(before index: inout Int, maxCount: Int) -> Span<Element> {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maxCount > 0, "maxCount must be positive")
    let c = Swift.min(index, maxCount)
    let end = capacity &- count &+ index
    return _uncheckedSpan(in: Range(uncheckedBounds: (end &- c, end)))
  }
}
#endif
