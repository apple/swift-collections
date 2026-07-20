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
public protocol MutableContainer<Element>:
  PermutableContainer, ~Copyable, ~Escapable
where
  Element: ~Copyable
{
  /// Accesses the element at the specified position.
  ///
  /// - Parameter position: The position of the element to access.
  ///    `position` must be a valid index of the container that is not equal
  ///    to the `endIndex` property.
  /// - Complexity: O(1)
  subscript(index: Index) -> Element { borrow mutate }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  mutating func nextMutableSpan(after index: inout Index) -> MutableSpan<Element>

    /// Return a mutable span over the container's storage that begins with the
  /// element at the given index, and extends to the end of the contiguous
  /// storage chunk that contains it, but no more than `maxCount` items.
  ///
  /// On return, the index is updated to address the next item following the
  /// end of the returned span.
  ///
  /// This method can be used to efficiently process the items of a container in
  /// bulk, by directly iterating over its piecewise contiguous pieces of
  /// storage:
  ///
  ///     var index = items.startIndex
  ///     while true {
  ///       var span = items.nextMutableSpan(after: &index, maxCount: 4)
  ///       if span.isEmpty { break }
  ///       // Process items in `span`
  ///     }
  ///
  /// The `maxCount` argument gives the caller control over the number of
  /// items it receives from the iterator. This lets the caller avoid getting
  /// more elements than it would be able to immediately process, which would
  /// significantly complicate container use.
  ///
  /// If the caller is able to process any number available items, it can signal
  /// that by passing `Int.max` as the `maxCount`, or simply by calling the
  /// `nexSpan(after:)` method, which does precisely that. This is frequently
  /// the case when the caller simply wants to iterate over the entire
  /// container in a single loop.
  ///
  /// `maxCount` sets an upper bound. To read a specific number of items,
  /// the caller usually needs to invoke `nextSpan` in a loop:
  ///
  ///     var items: some MutableContainer<Int>
  ///     var index = items.startIndex
  ///     var remainder = numberOfItemsToRead
  ///     while remainder > 0 {
  ///       let next = items.nextMutableSpan(after: &index, maxCount: remainder)
  ///       guard !next.isEmpty else {
  ///         // Container does not have enough items
  ///         break
  ///       }
  ///       remainder -= next.count
  ///       // Process items in `next`
  ///     }
  ///
  /// - Note: Repeated invocations of `nextSpan` on the same container and index
  ///    are not guaranteed to return identical results. (This is particularly
  ///    the case with containers that can store contents in their "inline"
  ///    representation. Such containers may not always have a unique address
  ///    in memory; the locations of the spans exposed by this method may vary
  ///    between different borrows of the same container.)
  ///
  /// - Parameter index: A valid index in the container, including the end
  ///     index. On return, this index is advanced by the count of the resulting
  ///     span, to simplify iteration.
  /// - Parameter maxCount: The maximum number of items the caller is able
  ///     to process immediately. `maxCount` must be greater than zero.
  ///     If you are able to process an arbitrary number of items, set
  ///     `maxCount` to `Int.max`, or call the `nextSpan(after:)` method.
  /// - Returns: A mutable span over contiguous storage that starts at the given
  ///     index. If the input index is the end index, then this returns an empty
  ///     span. Otherwise the result is non-empty, with its first element
  ///     matching the element at the input index.
  @_lifetime(&self)
  mutating func nextMutableSpan(
    after index: inout Index,
    maxCount: Int,
    limitedBy limit: Index
  ) -> MutableSpan<Element>
}

@available(SwiftStdlib 6.4, *)
extension MutableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Index
  ) -> MutableSpan<Element> {
    nextMutableSpan(after: &index, maxCount: Int.max, limitedBy: self.endIndex)
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Index,
    limitedBy limit: Index
  ) -> MutableSpan<Element> {
    nextMutableSpan(after: &index, maxCount: Int.max, limitedBy: limit)
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Index,
    maxCount: Int
  ) -> MutableSpan<Element> {
    nextMutableSpan(after: &index, maxCount: maxCount, limitedBy: self.endIndex)
  }
}

@available(SwiftStdlib 6.4, *)
extension MutableContainer
where
  Self: BidirectionalContainer & ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func previousMutableSpan(
    before index: inout Index
  ) -> MutableSpan<Element> {
    let start = self.spanBoundary(before: index).index
    var i = start
    let span = self.nextMutableSpan(after: &i, limitedBy: index)
    precondition(i == index, "Invalid BidirectionalContainer")
    return span
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func previousMutableSpan(
    before index: inout Index,
    maxCount: Int,
    limitedBy limit: Index
  ) -> MutableSpan<Element> {
    let start = self.spanBoundary(
      before: index,
      maxDistance: maxCount,
      limitedBy: limit
    ).index
    var i = start
    let span = self.nextMutableSpan(after: &i, limitedBy: index)
    precondition(i == index, "Invalid BidirectionalContainer")
    index = start
    return span
  }
}

#endif
