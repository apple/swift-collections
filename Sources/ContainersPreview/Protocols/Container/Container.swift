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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
public protocol Container<Element>:
  BorrowingSequence_, ~Copyable, ~Escapable
  where Element: ~Copyable, Element == Element_
{
  associatedtype Element: ~Copyable
  associatedtype Index: Equatable
  // FIXME: Ideally Index should also be required to be Hashable.
  // FIXME: If we discard the separate BorrowingSequence abstraction, then we
  // should consider dropping Comparable and just having Equatable indices, so
  // that linked lists can conform to this protocol.
  // This (potentially) complicates `distance(from:to:)` and similar algorithms,
  // and we'd probably want to re-add index comparability in a refining protocol
  // somewhere -- `RandomAccessContainer` or `BidirectionalContainer` would be
  // the obvious candidates.

  var isEmpty: Bool { get }
  var count: Int { get }

  var startIndex: Index { get }
  var endIndex: Index { get }
  
  /// Returns the position immediately after the given index.
  ///
  /// - Parameter index: A valid index of the container. `i` must be less
  ///     than `endIndex`.
  /// - Returns: The index immediately following `i`.
  func index(after index: Index) -> Index
  
  /// Replaces the given index with its successor.
  ///
  /// - Parameter index: A valid index of the container. `i` must be less
  ///     than `endIndex`.
  func formIndex(after index: inout Index)

  /// Returns an index that is the specified distance from the given index.
  ///
  /// The value passed as `n` must not offset `index` beyond the bounds of the
  /// container.
  ///
  /// - Parameter index: A valid index of the container.
  /// - Parameter n: The distance by which to offset `index`.
  /// - Returns: An index offset by distance from `index`. If `n` is positive,
  ///    this is the same value as the result of `n` calls to `index(after:)`.
  ///    If `n` is negative, this is the same value as the result of `abs(n)`
  ///    calls to `index(before:)`.
  func index(_ index: Index, offsetBy n: Int) -> Index
  
  /// Offsets the given index by the specified distance, but no further than
  /// the given limiting index.
  ///
  /// If the operation was able to offset `index` by exactly the requested
  /// number of steps without hitting `limit`, then on return `n` is set to `0`,
  /// and `index` is set to the adjusted index.
  ///
  /// If the operation hits the limit before it can take the requested number
  /// of steps, then on return `index` is set to `limit`, and `n` is set
  /// to the number of steps that couldn't be taken.
  ///
  /// The value passed as `n` must not offset `index` beyond the bounds of the
  /// container, unless the index passed as `limit` prevents offsetting beyond
  /// those bounds.
  ///
  /// - Parameter index: A valid index of the container.
  /// - Parameter n: The distance to offset `index`. `n` must not be negative
  ///    unless the container conforms to the `BidirectionalContainer` protocol.
  /// - Parameter limit: A valid index of the container to use as a limit.
  ///    If `n > 0`, a limit that is less than `index` has no effect.
  ///    Likewise, if `n < 0`, a limit that is greater than `index` has no
  ///    effect.
  func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  )
  
  /// Returns the distance between two indices.
  ///
  /// - Parameter start: A valid index of the collection.
  /// - Parameter end: Another valid index of the collection. If end is equal
  ///    to start, the result is zero.
  /// - Returns: The distance between `start` and `end`.
  func distance(from start: Index, to end: Index) -> Int

  /// Return a span over the container's storage that begins with the element at
  /// the given index, and extends to the end of the contiguous storage chunk
  /// that contains it, but no more than `maximumCount` items.
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
  ///       let span = items.nextSpan(after: &index, maximumCount: 4)
  ///       if span.isEmpty { break }
  ///       // Process items in `span`
  ///     }
  ///
  /// The `maximumCount` argument gives the caller control over the number of
  /// items it receives from the iterator. This lets the caller avoid getting
  /// more elements than it would be able to immediately process, which would
  /// significantly complicate container use.
  ///
  /// If the caller is able to process any number available items, it can signal
  /// that by passing `Int.max` as the `maximumCount`, or simply by calling the
  /// `nexSpan(after:)` method, which does precisely that. This is frequently
  /// the case when the caller simply wants to iterate over the entire
  /// container in a single loop.
  ///
  /// `maximumCount` sets an upper bound. To read a specific number of items,
  /// the caller usually needs to invoke `nextSpan` in a loop:
  ///
  ///     var items: some Container<Int>
  ///     var index = items.startIndex
  ///     var remainder = numberOfItemsToRead
  ///     while remainder > 0 {
  ///       let next = items.nextSpan(after: &index, maximumCount: remainder)
  ///       guard !next.isEmpty else {
  ///         // Container does not have enough items
  ///         break
  ///       }
  ///       remainder -= next.count
  ///       // Process items in `next`
  ///     }
  ///
  /// - Note: The spans returned by this method are not guaranteed to be
  ///    disjunct. Some containers may use the same storage chunk (or parts of a
  ///    storage chunk) multiple times, to repeat their contents.
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
  /// - Parameter maximumCount: The maximum number of items the caller is able
  ///     to process immediately. `maximumCount` must be greater than zero.
  ///     If you are able to process an arbitrary number of items, set
  ///     `maximumCount` to `Int.max`, or call the `nextSpan(after:)` method.
  /// - Returns: A span over contiguous storage that starts at the given index.
  ///     If the input index is the end index, then this returns an empty span.
  ///     Otherwise the result is non-empty, with its first element matching the
  ///     element at the input index.
  @_lifetime(borrow self)
  func nextSpan(after index: inout Index, maximumCount: Int) -> Span<Element>

  //  subscript(index: Index) -> Element { borrow }

  /// Return the nearest valid index in this container less than or equal to
  /// the given index value, which must be valid in at least one view of self.
  ///
  /// This operation is important for container types that provide multiple
  /// alternative projections (or "views") over the same underlying
  /// representation, with each view conforming to `Container`, and sharing
  /// the same `Index`. (Like `String` does with its UTF-8, UTF-16,
  /// Unicode ccalar and character views in the `Collection` world.)
  /// This rounding operation enables clients to convert/normalize valid index
  /// values in one container view into valid indices in another, allowing them
  /// to (easily) decide whether two (potentially misaligned) index values
  /// address the same element.
  ///
  /// The default implementation of this operation simply returns `index`.
  func index(alignedDown index: Index) -> Index

  /// Return the nearest valid index in this container greater than or equal to
  /// the given index value, which must be valid in at least one view of self.
  ///
  /// This operation is important for container types that provide multiple
  /// alternative projections (or "views") over the same underlying
  /// representation, with each view conforming to `Container`, and sharing
  /// the same `Index`. (Like `String` does with its UTF-8, UTF-16,
  /// Unicode ccalar and character views in the `Collection` world.)
  /// This rounding operation enables clients to convert/normalize valid index
  /// values in one container view into valid indices in another, allowing them
  /// to (easily) decide whether two (potentially misaligned) index values
  /// address the same element.
  ///
  /// The default implementation of this operation simply returns `index`.
  func index(alignedUp index: Index) -> Index

  func _customIndexOfEquatableElement(_ element: borrowing Element) -> Index??
  func _customLastIndexOfEquatableElement(_ element: borrowing Element) -> Index??
}

@available(SwiftStdlib 5.0, *)
extension Container where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  /// Return a span over the container's storage that begins with the element at
  /// the given index, and extends to the end of the contiguous storage chunk
  /// that contains it. On return, the index is updated to address the next item
  /// following the end of the returned span.
  ///
  /// This method can be used to efficiently process the items of a container in
  /// bulk, by directly iterating over its piecewise contiguous pieces of
  /// storage:
  ///
  ///     var index = items.startIndex
  ///     while true {
  ///       let span = items.nextSpan(after: &index)
  ///       if span.isEmpty { break }
  ///       // Process items in `span`
  ///     }
  ///
  /// - Note: The spans returned by this method are not guaranteed to be
  ///    disjunct. Some containers may use the same storage chunk (or parts of a
  ///    storage chunk) multiple times, to repeat their contents.
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
  /// - Returns: A span over contiguous storage that starts at the given index.
  ///     If the input index is the end index, then this returns an empty span.
  ///     Otherwise the result is non-empty, with its first element matching the
  ///     element at the input index.
  @inlinable
  @_lifetime(borrow self)
  public func nextSpan(after index: inout Index) -> Span<Element> {
    nextSpan(after: &index, maximumCount: Int.max)
  }

//  @inlinable
//  @_lifetime(borrow self)
//  public func nextSpan(after index: inout Index, maximumCount: Int) -> Span<Element> {
//    let original = index
//    var span = nextSpan(after: &index)
//    if span.count > maximumCount {
//      span = span.extracting(first: maximumCount)
//      // Index remains within the same span, so offseting it is expected to be quick
//      index = self.index(original, offsetBy: maximumCount)
//    }
//    return span
//  }
}

@available(SwiftStdlib 5.0, *)
extension Container where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @inlinable
  public var isEmpty: Bool {
    startIndex == endIndex
  }

  @inlinable
  public var count: Int {
    distance(from: startIndex, to: endIndex)
  }

  @inlinable
  public func formIndex(after index: inout Index) {
    index = self.index(after: index)
  }

  @inlinable
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    precondition(
      n >= 0,
      "Only BidirectionalContainers can be advanced by a negative amount")

    var index = self.index(alignedDown: index)
    var n = n

#if true // with nextSpan(after:maximumCount:)
    while n > 0 {
      let span = self.nextSpan(after: &index, maximumCount: n)
      precondition(
        !span.isEmpty,
        "Cannot advance index beyond the end of the container")
      n &-= span.count
    }
    return index
#else // without nextSpan(after:maximumCount:)
    // FIXME: This implementation can be wasteful for piecewise contiguous
    // containers, as iterating over spans will tend to overshoot the target.

    // Skip forward until we find the span that contains our target.
    while distance > 0 {
      var j = i
      let span = self.nextSpan(after: &j)
      precondition(
        !span.isEmpty,
        "Cannot advance index beyond the end of the container")
      guard span.count <= distance else { break }
      i = j
      distance &-= span.count
    }
    // Step through to find the precise target.
    while distance > 0 {
      self.formIndex(after: &i)
      distance &-= 1
    }
    return i
#endif
  }

  @inlinable
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    precondition(
      n >= 0,
      "Only BidirectionalContainers can be advanced by a negative amount")

    index = self.index(alignedDown: index)
    let limit = self.index(alignedDown: limit)

    // Note: with Index not conforming to `Comparable`, we cannot do bulk
    // iteration here, as we have no way to decide if we stepped over `limit`.
    while n > 0, index != limit {
      self.formIndex(after: &index)
      n &-= 1
    }
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
#if true
    // This variant does not require that `start` precede `end`, but it's
    // slower/larger.
    // FIXME: Linked lists may require an even slower implementation
    // to avoid looping (turtle/hare cycle detection).
    let start = self.index(alignedDown: start)
    let end = self.index(alignedDown: end)
    let limit = self.endIndex
    var a = start
    var b = end
    var d = 0
    while true {
      if a == end { return d }
      if b == start { return -d }
      if a == limit {
        while b != end {
          self.formIndex(after: &b)
          d += 1
        }
        return -d
      }
      if b == limit {
        while a != end {
          self.formIndex(after: &a)
          d += 1
        }
        return d
      }
      self.formIndex(after: &a)
      self.formIndex(after: &b)
      d += 1
    }
#else
    // This variant requires that `start` precede `end`, but we cannot ensure
    // that with a quick check, so we need to compare against the `endIndex` to
    // avoid looping indefinitely.
    // FIXME: Linked lists may require an even slower implementation
    // to avoid looping (turtle/hare cycle detection).
    let i = self.index(alignedDown: start)
    let target = self.index(alignedDown: end)
    let limit = self.endIndex
    var count = 0
    while i != target {
      self.formIndex(after: &i)
      precondition(i != limit, "Only BidirectionalContainers can have end come before start")
      count += 1
    }
    return count
#endif
  }

  @inlinable
  public func index(alignedDown index: Index) -> Index { index }

  @inlinable
  public func index(alignedUp index: Index) -> Index { index }

  @inlinable
  public func _customIndexOfEquatableElement(_: borrowing Element) -> Index?? {
    nil
  }

  @inlinable
  public func _customLastIndexOfEquatableElement(
    _ element: borrowing Element
  ) -> Index?? {
    nil
  }
}


@available(SwiftStdlib 5.0, *)
extension Container where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_transparent
  public var underestimatedCount_: Int { count }
}

#endif

