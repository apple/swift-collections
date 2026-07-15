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
public protocol Container<Element>:
  Iterable_, ~Copyable, ~Escapable
  where Element: ~Copyable, Element == Element_, Failure_ == Never
{
  associatedtype Element: ~Copyable

  /// Indices are expected to implement `==` and `hash(into:)` with
  /// constant complexity.
  associatedtype Index: Equatable, Hashable

  // FIXME: We need Container to define a default value for BorrowingIterator,
  // but we can only do that once ContainerIterator can support a
  // nonescapable Base.
  //associatedtype BorrowingIterator = ContainerIterator<Self>

  // FIXME: Ideally Index should also be required to be Hashable.
  // FIXME: If we discard the separate BorrowingSequence abstraction, then we
  // should consider dropping Comparable and just having Equatable indices, so
  // that linked lists can conform to this protocol.
  // This (potentially) complicates `distance(from:to:)` and similar algorithms,
  // and we'd probably want to re-add index comparability in a refining protocol
  // somewhere -- `RandomAccessContainer` or `BidirectionalContainer` would be
  // the obvious candidates.

  /// - Complexity: Recommended to be O(1); conforming types must clearly
  ///   document deviations from this expectation.
  @_lifetime(borrow self)
  func makeBorrowingIterator(from start: Index) -> BorrowingIterator_

  /// - Complexity: Recommended to be O(1); conforming types must clearly
  ///   document deviations from this expectation.
  func currentIndex(of iterator: borrowing BorrowingIterator_) -> Index

  /// Complexity: O(1)
  var isEmpty: Bool { get }

  /// Complexity: O(1)
  var count: Int { get }

  /// - Complexity: Recommended to be O(1); conforming types must clearly
  ///   document deviations from this expectation.
  var startIndex: Index { get }

  /// Complexity: Must be O(1) on all container types.
  var endIndex: Index { get }
  
  /// Returns the position immediately after the given index.
  ///
  /// - Parameter index: A valid index of the container. `i` must be less
  ///     than `endIndex`.
  /// - Returns: The index immediately following `i`.
  /// - Complexity: Recommended to be O(1); conforming types must clearly
  ///   document deviations from this expectation.
  func index(after index: Index) -> Index
  
  /// Replaces the given index with its successor.
  ///
  /// - Parameter index: A valid index of the container. `i` must be less
  ///     than `endIndex`.
  /// - Complexity: Recommended to be O(1); conforming types must clearly
  ///   document deviations from this expectation.
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
  /// - Complexity: Recommended to be O(`n`); conforming types must clearly
  ///   document deviations from this expectation.
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
  /// - Complexity: Recommended to be O(n); conforming types must clearly
  ///   document deviations from this expectation.
  func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  )
  
  /// Returns the distance between two indices.
  ///
  /// - Parameter start: A valid index of the collection.
  /// - Parameter end: Another valid index of the collection. If end is equal
  ///    to start, the result is zero.
  /// - Returns: The distance between `start` and `end`.
  /// - Complexity: Recommended to be O(*d*), where *d* is the resulting
  ///    distance.  Conforming types must clearly document deviations from this
  ///    expectation.
  func distance(from start: Index, to end: Index) -> Int

  /// Accesses the element at the specified position.
  ///
  /// You can subscript a collection with any valid index other than the
  /// collection’s end index. The end index refers to the position one past the
  /// last element of a collection, so it doesn’t correspond with an element.
  ///
  /// - Parameter position: The position of the element to access.
  ///    `position` must be a valid index of the container that is not equal
  ///    to the `endIndex` property.
  /// - Complexity: O(1). This is a hard requirement.
  subscript(index: Index) -> Element { borrow }

  /// Return a span over the container's storage that begins with the element at
  /// the given index, and extends to the end of the contiguous storage chunk
  /// that contains it, but no more than `maxCount` items.
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
  ///       let span = items.nextSpan(after: &index, maxCount: 4)
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
  ///     var items: some Container<Int>
  ///     var index = items.startIndex
  ///     var remainder = numberOfItemsToRead
  ///     while remainder > 0 {
  ///       let next = items.nextSpan(after: &index, maxCount: remainder)
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
  /// - Parameter maxCount: The maximum number of items the caller is able
  ///     to process immediately. `maxCount` must be greater than zero.
  ///     If you are able to process an arbitrary number of items, set
  ///     `maxCount` to `Int.max`, or call the `nextSpan(after:)` method.
  /// - Returns: A span over contiguous storage that starts at the given index.
  ///     If the input index is the end index, then this returns an empty span.
  ///     Otherwise the result is non-empty, with its first element matching the
  ///     element at the input index.
  /// - Complexity: Recommended to be O(1). Conforming types must clearly
  ///    document deviations from this expectation.
  @_lifetime(borrow self)
  func nextSpan(after index: inout Index, maxCount: Int) -> Span<Element>

  // This allows faster default implementations for algorithms like
  // `distance(from:to:)` or `formIndex(_:offsetBy:limitedBy:)`.
  @_lifetime(borrow self)
  func nextSpan(
    after index: inout Index,
    limitedBy limit: Index
  ) -> Span<Element>

  func _customIndexOfEquatableElement(_ element: borrowing Element) -> Index??
  func _customLastIndexOfEquatableElement(_ element: borrowing Element) -> Index??
}

@available(SwiftStdlib 6.4, *)
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
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(after index: inout Index) -> Span<Element> {
    nextSpan(after: &index, maxCount: Int.max)
  }
}

@available(SwiftStdlib 6.4, *)
extension Container where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_alwaysEmitIntoClient
  public var isEmpty: Bool {
    count == 0
  }

  @_alwaysEmitIntoClient
  public var count: Int {
    distance(from: startIndex, to: endIndex)
  }

  @_alwaysEmitIntoClient
  public func formIndex(after index: inout Index) {
    index = self.index(after: index)
  }

  @_alwaysEmitIntoClient
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    precondition(
      n >= 0,
      "Only BidirectionalContainers can be advanced by a negative amount")

    var index = index
    var n = n

#if true // with nextSpan(after:maxCount:)
    while n > 0 {
      let span = self.nextSpan(after: &index, maxCount: n)
      precondition(
        !span.isEmpty,
        "Cannot advance index beyond the end of the container")
      n &-= span.count
    }
    return index
#else // without nextSpan(after:maxCount:)
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

  @_alwaysEmitIntoClient
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    precondition(
      n >= 0,
      "Only BidirectionalContainers can be advanced by a negative amount")

    // Note: with Index not conforming to `Comparable`, we cannot do bulk
    // iteration here, as we have no way to decide if we stepped over `limit`.
    while n > 0, index != limit {
      self.formIndex(after: &index)
      n &-= 1
    }
  }

  @_alwaysEmitIntoClient
  public func index(
    _ index: Index, offsetBy n: Int, limitedBy limit: Index
  ) -> Index? {
    var index = index
    var n = n
    self.formIndex(&index, offsetBy: &n, limitedBy: limit)
    if n != 0 { return nil }
    return index
  }

  @_alwaysEmitIntoClient
  public func distance(from start: Index, to end: Index) -> Int {
#if true
    // This variant does not require that `start` precede `end`, but it's
    // slower/larger.
    // FIXME: Linked lists may require an even slower implementation
    // to avoid looping (turtle/hare cycle detection).
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
    // FIXME: Certain linked lists may require an even slower implementation
    // to avoid looping indefinitely (turtle/hare cycle detection).
    var i = start
    let target = end
    let limit = self.endIndex
    var count = 0
    while i != target {
      self.formIndex(after: &i)
      // We cannot rely on `formIndex(after:)` catching the end in a resonable
      // time, as container implementations often delay index validation until
      // an element is actually accessed.
      precondition(i != limit, "Only BidirectionalContainers can have end come before start")
      count += 1
    }
    return count
#endif
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Index,
    limitedBy limit: Index
  ) -> Span<Element> {
    let d = self.distance(from: index, to: limit)
    return self.nextSpan(after: &index, maxCount: d)
  }

  @_alwaysEmitIntoClient
  public func _customIndexOfEquatableElement(_: borrowing Element) -> Index?? {
    nil
  }

  @_alwaysEmitIntoClient
  public func _customLastIndexOfEquatableElement(
    _ element: borrowing Element
  ) -> Index?? {
    nil
  }
}

@available(SwiftStdlib 6.4, *)
extension Container
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable,
  Index: Comparable
{
  @_alwaysEmitIntoClient
  public func distance(from start: Index, to end: Index) -> Int {
    var (i, j, step): (Index, Index, Int) = (start <= end
     ? (start, end, 1)
     : (end, start, -1))
    var d = 0
    while i < j {
      // FIXME: Consider using bulk iteration here, with binary search within the final chunk.
      // (The code size complexity may not be worth the effort.)
      self.formIndex(after: &i)
      d += step
    }
    return d
  }
}

@available(SwiftStdlib 6.4, *)
extension Container where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public var underestimatedCount_: Int { count }
}

// FIXME: Add ambiguity resolvers against Collection's algorithms.

#endif

