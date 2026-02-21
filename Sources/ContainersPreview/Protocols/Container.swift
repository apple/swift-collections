//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
public protocol Container<Element>: BorrowingSequence, ~Copyable, ~Escapable {
  associatedtype Index: Comparable
  
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
  
  // FIXME: Do we want these as standard requirements this time?
  func index(alignedDown index: Index) -> Index
  func index(alignedUp index: Index) -> Index
}

@available(SwiftStdlib 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
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
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  public func formIndex(after index: inout Index) {
    index = self.index(after: index)
  }

  @inlinable
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    _defaultIndex(index, advancedBy: n)
  }
  
  @inlinable
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    _defaultFormIndex(&index, advancedBy: &n, limitedBy: limit)
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    _defaultDistance(from: start, to: end)
  }

  @inlinable
  public func index(alignedDown index: Index) -> Index { index }

  @inlinable
  public func index(alignedUp index: Index) -> Index { index }
}


@available(SwiftStdlib 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  public func _defaultDistance(from start: Index, to end: Index) -> Int {
    // FIXME: Use binary search here (with nextSpan(after:maximumCount:))
    var start = index(alignedDown: start)
    let end = index(alignedDown: end)
    if start > end {
      return -_defaultDistance(from: end, to: start)
    }
    var count = 0
    while start != end {
      count = count + 1
      formIndex(after: &start)
    }
    return count
  }

  @inlinable
  public func _defaultIndex(_ i: Index, advancedBy distance: Int) -> Index {
    precondition(
      distance >= 0,
      "Only BidirectionalContainers can be advanced by a negative amount")

    var i = index(alignedDown: i)
    var distance = distance

    #if true // with nextSpan(after:maximumCount:)
    while distance > 0 {
      let span = self.nextSpan(after: &i, maximumCount: distance)
      precondition(
        !span.isEmpty,
        "Cannot advance index beyond the end of the container")
      distance &-= span.count
    }
    return i
    #else // without nextSpan(after:maximumCount:)
    // FIXME: This implementation can be wasteful for contiguous containers,
    // as iterating over spans will overshoot the target immediately.
    // Reintroducing `nextSpan(after:maximumCount:)` would help avoid
    // having to use a second loop to refine the result, but it would
    // complicate conformances.

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
  public func _defaultFormIndex(
    _ i: inout Index,
    advancedBy distance: inout Int,
    limitedBy limit: Index
  ) {
    precondition(
      distance >= 0,
      "Only BidirectionalContainers can be advanced by a negative amount")

    i = index(alignedDown: i)
    let limit = index(alignedDown: limit)
    if i > limit {
      i = self.index(i, offsetBy: distance)
      distance = 0
      return
    }

#if true // with nextSpan(after:maximumCount:)
    // Skip forward until find our target or overshoot the limit.
    while distance > 0, i < limit {
      var j = i
      let span = self.nextSpan(after: &j, maximumCount: distance)
      precondition(
        !span.isEmpty,
        "Cannot advance index beyond the end of the container")
      if j > limit {
        break
      }
      i = j
      distance &-= span.count
    }
    // Step through to find the precise target.
    // FIXME: Use binary search here
    while distance != 0 {
      if i == limit {
        return
      }
      formIndex(after: &i)
      distance &-= 1
    }
#else // without nextSpan(after:maximumCount:)
    // Skip forward until we find the span that contains our target.
    while distance > 0 {
      var j = i
      let span = self.nextSpan(after: &j)
      precondition(
        !span.isEmpty,
        "Cannot advance index beyond the end of the container")
      guard span.count <= distance, j < limit else {
        break
      }
      i = j
      distance &-= span.count
    }
    // Step through to find the precise target.
    while distance != 0 {
      if i == limit {
        return
      }
      formIndex(after: &i)
      distance &-= 1
    }
#endif
  }
}

@available(SwiftStdlib 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  @_transparent
  public var estimatedCount: EstimatedCount { .exactly(count) }
}


@available(SwiftStdlib 5.0, *)
public struct ContainerIterator<
  Base: Container & ~Copyable /*FIXME: & ~Escapable*/
>: ~Copyable, ~Escapable {
  let _base: Borrow<Base> // FIXME: This doesn't support nonescapable Bases
  var _position: Base.Index
  
  @_lifetime(borrow base)
  init(_borrowing base: borrowing @_addressable Base, from position: Base.Index) {
    self._base = Borrow(_borrowing: base)
    self._position = position
  }
}

@available(SwiftStdlib 5.0, *)
extension ContainerIterator: BorrowingIteratorProtocol
where Base: ~Copyable /*FIXME: & ~Escapable*/
{
  public typealias Element = Base.Element

  @_unsafeNonescapableResult // FIXME: we cannot convert from a borrow to an inout dependence!
  @_lifetime(&self)
  public mutating func nextSpan(maximumCount: Int) -> Span<Base.Element> {
    _base.value.nextSpan(after: &self._position, maximumCount: maximumCount)
  }
}

@available(SwiftStdlib 5.0, *)
extension Container
where
  Self: ~Copyable /*FIXME: & ~Escapable*/,
  BorrowingIterator == ContainerIterator<Self>
{
  @_lifetime(borrow self)
  public func makeBorrowingIterator() -> BorrowingIterator {
    ContainerIterator(_borrowing: self, from: self.startIndex)
  }
}

#endif

extension Strideable {
  @inlinable
  package mutating func _advance(
    by distance: inout Stride, limitedBy limit: Self
  ) {
    if distance >= 0 {
      guard limit >= self else {
        self = self.advanced(by: distance)
        distance = 0
        return
      }
      let d = Swift.min(distance, self.distance(to: limit))
      self = self.advanced(by: d)
      distance -= d
    } else {
      guard limit <= self else {
        self = self.advanced(by: distance)
        distance = 0
        return
      }
      let d = Swift.max(distance, self.distance(to: limit))
      self = self.advanced(by: d)
      distance -= d
    }
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  public mutating func advance(
    by distance: inout Stride, limitedBy limit: Self
  ) {
    _advance(by: &distance, limitedBy: limit)
  }
#endif
}

