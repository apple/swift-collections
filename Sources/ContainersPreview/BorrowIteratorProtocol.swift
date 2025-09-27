//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
public protocol BorrowIteratorProtocol<Element>: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable /*& ~Escapable*/

  /// Advance the iterator to the next storage chunk, returning a span over it.
  ///
  /// If the iterator has not yet reached the end of the underlying container,
  /// then this method returns a non-empty span over the container's storage
  /// that begins with the element at the iterator's current position and
  /// extends to the end of the contiguous storage chunk that contains that
  /// item, but at most `maximumCount` items. On return, the iterator's current
  /// position is updated to the slot following the last item in the returned
  /// span.
  ///
  /// If the iterator's current position is at the end of the container, then
  /// this method returns an empty span without updating the position.
  ///
  /// This method can be used to efficiently process the items of a container
  /// in bulk, by directly iterating over its piecewise contiguous pieces of
  /// storage:
  ///
  ///     var it = items.startBorrowIteration()
  ///     while true {
  ///       let span = it.nextSpan(after: &index)
  ///       if span.isEmpty { break }
  ///       // Process items in `span`
  ///     }
  ///
  /// Note: The spans returned by this method are not guaranteed to be disjunct.
  /// Some containers may use the same storage chunk (or parts of a storage
  /// chunk) multiple times, for example to repeat their contents.
  ///
  /// Note: Repeatedly iterating over the same container is expected to return
  /// the same items (collected in similarly sized span instances), but the
  /// returned spans are not guaranteed to be identical. (For example, this is
  /// the case with containers that can store contents within their direct
  /// representation. Such containers may not always have a unique address in
  /// memory, and so the locations of the spans exposed by this method may vary
  /// between different borrows of the same container.)
  ///
  /// - Parameter maximumCount: The maximum count of items the caller is ready
  ///    to process, or nil if the caller is prepared to accept an arbitrarily
  ///    large span. If non-nil, the maximum must be greater than zero.
  /// - Returns: A span over a piece of contiguous storage in the underlying
  ///     container. It the iterator is at the end of the container, then
  ///     this returns an empty span. Otherwise the result will contain at least
  ///     one element.
  @_lifetime(copy self)
  @_lifetime(self: copy self)
  mutating func nextSpan(maximumCount: Int?) -> Span<Element>
  
  @_lifetime(self: copy self)
  mutating func skip(by offset: Int) -> Int
}

@available(SwiftStdlib 5.0, *)
extension BorrowIteratorProtocol where Self: ~Copyable & ~Escapable {
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
extension BorrowIteratorProtocol where Self: ~Copyable & ~Escapable {
  @_lifetime(copy self)
  @_lifetime(self: copy self)
  @_transparent
  public mutating func nextSpan() -> Span<Element> {
    nextSpan(maximumCount: nil)
  }
}

@available(SwiftStdlib 5.0, *)
extension Span: BorrowIteratorProtocol where Element: ~Copyable {
  @_lifetime(copy self)
  @_lifetime(self: copy self)
  public mutating func nextSpan(maximumCount: Int?) -> Span<Element> {
    let c = maximumCount ?? self.count
    let result = self.extracting(first: c)
    self = self.extracting(droppingFirst: c)
    return result
  }
}

#endif
