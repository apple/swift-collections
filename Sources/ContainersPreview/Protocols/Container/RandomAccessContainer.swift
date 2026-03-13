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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 6.2, *)
public protocol RandomAccessContainer<Element>
: BidirectionalContainer, ~Copyable, ~Escapable {}


@available(SwiftStdlib 6.2, *)
extension RandomAccessContainer
where Self: ~Copyable & ~Escapable, Index: Strideable, Index.Stride == Int
{
  @inlinable
  public var isEmpty: Bool { startIndex == endIndex }

  @inlinable
  public var count: Int { startIndex.distance(to: endIndex) }

  @inlinable
  public func index(after index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: 1)
  }

  @inlinable
  public func index(before index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: -1)
  }

  @inlinable
  public func formIndex(after index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: 1)
  }

  @inlinable
  public func formIndex(before index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: -1)
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    // Note: Range checks are deferred until element access.
    start.distance(to: end)
  }

  @inlinable
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: n)
  }

  @inlinable
  public func formIndex(
    _ index: inout Index, offsetBy distance: inout Index.Stride, limitedBy limit: Index
  ) {
    // Note: Range checks are deferred until element access.
    index.advance(by: &distance, limitedBy: limit)
  }


  @_lifetime(borrow self)
  @inlinable
  public func nextSpan(
    after index: inout Index, maximumCount: Int
  ) -> Span<Element> {
    precondition(maximumCount >= 0, "Maximum count must be non-negative")
    let span = self.nextSpan(after: &index)
    if span.count <= maximumCount { return span }
    index = index.advanced(by: maximumCount - span.count)
    return span.extracting(first: maximumCount)
  }
}

// Disambiguate parallel extensions on RandomAccessContainer and RandomAccessCollection

@available(SwiftStdlib 6.2, *)
extension RandomAccessCollection
where
  Self: RandomAccessContainer,
  Index: Strideable,
  Index.Stride == Int,
  Indices == Range<Int>
{
  @inlinable
  public var isEmpty: Bool { startIndex == endIndex }

  @inlinable
  public var count: Int { endIndex - startIndex }

  @inlinable
  public func index(after index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: 1)
  }

  @inlinable
  public func index(before index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: -1)
  }

  @inlinable
  public func formIndex(after index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: 1)
  }

  @inlinable
  public func formIndex(before index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: -1)
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    // Note: Range checks are deferred until element access.
    start.distance(to: end)
  }

  @inlinable
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: n)
  }
}

#endif
