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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@available(SwiftStdlib 5.0, *)
public protocol BorrowingIteratorProtocol<Element>: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable

  // FIXME: This ought to be a core requirement, but `Ref` is not a thing yet.
//  @_lifetime(&self)
//  @_lifetime(self: copy self)
//  mutating func next() -> Ref<Element>?

  /// Advance the iterator, returning an ephemeral span over the elements
  /// that are ready to be visited.
  ///
  /// If the underlying sequence is a container type, then the returned span
  /// typically directly addresses one of its storage buffers. On the other
  /// hand, if the underlying sequence materializes its elements on demand,
  /// then the returned span addresses some temporary buffer associated with
  /// the iterator itself. Consequently, the returned span is tied to this
  /// particular invocation of `nextSpan`, and it cannot survive until the next
  /// invocation of it.
  ///
  /// If the iterator has not yet reached the end of the underlying sequence,
  /// then this method returns a non-empty span of at most `maximumCount`
  /// elements, and updates the iterator's current position to the element
  /// following the last item in the returned span (or the end, if there is
  /// none). The `maximumCount` argument allows callers to avoid getting more
  /// items that they are able to process in one go, simplifying usage, and
  /// avoiding materializing more elements than needed.
  ///
  /// If the iterator's current position is at the end of the container, then
  /// this method returns an empty span without updating the position.
  ///
  /// This method can be used to efficiently process the items of a container
  /// in bulk, by directly iterating over its piecewise contiguous pieces of
  /// storage:
  ///
  ///     var it = items.makeBorrowingIterator()
  ///     while true {
  ///       let span = it.nextSpan(after: &index)
  ///       if span.isEmpty { break }
  ///       // Process items in `span`
  ///     }
  ///
  /// Note: The spans returned by this method are not guaranteed to be disjunct.
  /// Iterators that materialize elements on demand typically reuse the same
  /// buffer over and over again; and even some proper containers may link to a
  /// single storage chunk (or parts of a storage chunk) multiple times, for
  /// example to repeat their contents.
  ///
  /// Note: Repeatedly iterating over the same container is expected to return
  /// the same items (collected in similarly sized span instances), but the
  /// returned spans are not guaranteed to be identical. For example, this is
  /// the case with containers that store some of their contents within their
  /// direct representation. Such containers may not always have a unique
  /// address in memory, and so the locations of the spans exposed by this
  /// method may vary between different borrows of the same container.)
  @_lifetime(&self)
  @_lifetime(self: copy self)
  mutating func nextSpan(maximumCount: Int) -> Span<Element>

  /// Advance the position of this iterator by the specified offset, or until
  /// the end of the underlying sequence.
  ///
  /// Returns the number of items that were skipped. If this is less than
  /// `maximumOffset`, then the sequence did not have enough elements left to
  /// skip the requested number of items. In this case, the iterator's current
  /// position is set to the end of the sequence.
  ///
  /// `maximumOffset` must be nonnegative, unless this is a bidirectional
  /// or random-access iterator.
  @_lifetime(self: copy self)
  mutating func skip(by maximumOffset: Int) -> Int
  
  // FIXME: Add BidirectionalBorrowingIteratorProtocol and RandomAccessBorrowingIteratorProtocol.
  // BidirectionalBorrowingIteratorProtocol would need to have a `previousSpan`
  // method, which considerably complicates implementation.
  // Perhaps these would be better left to as variants of protocol Container,
  // which do not need a separate iterator concept.
}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol where Self: ~Copyable & ~Escapable {
  @_lifetime(&self)
  @_lifetime(self: copy self)
  @_transparent
  public mutating func nextSpan() -> Span<Element> {
    nextSpan(maximumCount: Int.max)
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol where Self: ~Copyable & ~Escapable {
  @_lifetime(self: copy self)
  @inlinable
  public mutating func skip(by offset: Int) -> Int {
    var remainder = offset
    while remainder > 0 {
      let span = nextSpan(maximumCount: remainder)
      if span.isEmpty { break }
      remainder &-= span.count
    }
    return offset &- remainder
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol where Self: ~Copyable & ~Escapable {
#if false // FIXME: This doesn't work, but it should?
  @_lifetime(&self)
  @_lifetime(self: copy self)
  public mutating func next() -> Ref<Element>? {
    let span = nextSpan(maximumCount: 1)
    guard !span.isEmpty else { return nil }
    return Ref(_borrowing: span[unchecked: 0])
  }
#endif

  //  @_lifetime(&self)
  //  @_lifetime(self: copy self)
  //  public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
  //    guard let ref = next() else { return Span() }
  //    return ref.span // FIXME
  //  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol
where Self: ~Copyable & ~Escapable, Element: Copyable
{
  @_lifetime(self: copy self)
  @_transparent
  public mutating func copyContents(into target: inout OutputSpan<Element>) {
    target.withUnsafeMutableBufferPointer { dst, dstCount in
      var tail = dst._extracting(droppingFirst: dstCount)
      while !tail.isEmpty {
        let src = nextSpan(maximumCount: tail.count)
        if src.isEmpty { break }
        tail._initializeAndDropPrefix(copying: src)
        dstCount += src.count
      }
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension Span: BorrowingIteratorProtocol where Element: ~Copyable {
  @_lifetime(copy self)
  @_lifetime(self: copy self)
  @inlinable
  public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
    _trim(first: maximumCount)
  }
}

// FIXME: Decide if we want UnsafeBufferPointer types to be borrow iterators

#if false // FIXME: Implement this
@available(SwiftStdlib 5.0, *)
extension MutableSpan: BorrowingIteratorProtocol where Element: ~Copyable {
  @_lifetime(copy self)
  @_lifetime(self: copy self)
  @inlinable
  public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
    //???
  }
}
#endif

#if false // FIXME: Implement this
@available(SwiftStdlib 5.0, *)
extension OutputSpan: BorrowingIteratorProtocol where Element: ~Copyable {
  @_lifetime(copy self)
  @_lifetime(self: copy self)
  @inlinable
  public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
    //???
  }
}
#endif

#endif
