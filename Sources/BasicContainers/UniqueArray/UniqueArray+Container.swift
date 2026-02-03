//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2)

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension RigidArray: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = Span<Element>.BorrowingIterator
  
  @_alwaysEmitIntoClient
  @inline(__always)
  public var estimatedCount: EstimatedCount {
    self._storage.estimatedCount
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  public func makeBorrowingIterator() -> BorrowingIterator {
    self._storage.makeBorrowingIterator()
  }
}
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension UniqueArray: Container where Element: ~Copyable {
}
#endif

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Returns the position immediately after the given index.
  ///
  /// - Note: To improve performance, this method does not validate that the
  ///    index is valid before incrementing it. Index validation is
  ///    deferred until the resulting index is used to access an element.
  ///    This optimization may be removed in future versions; do not rely on it.
  ///
  /// - Parameter index: A valid index of the array. `i` must be less
  ///     than `endIndex`.
  /// - Returns: The index immediately following `i`.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(after index: Int) -> Int { index + 1 }
  
  /// Returns the position immediately before the given index.
  ///
  /// - Note: To improve performance, this method does not validate that the
  ///    index is valid before decrementing it. Index validation is
  ///    deferred until the resulting index is used to access an element.
  ///    This optimization may be removed in future versions; do not rely on it.
  ///
  /// - Parameter index: A valid index of the array. `i` must be greater
  ///     than `startIndex`.
  /// - Returns: The index immediately preceding `i`.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(before index: Int) -> Int { index - 1 }

  /// Replaces the given index with its successor.
  ///
  /// - Note: To improve performance, this method does not validate that the
  ///    given index is valid before incrementing it. Index validation is
  ///    deferred until the resulting index is used to access an element.
  ///    This optimization may be removed in future versions; do not rely on it.
  ///
  /// - Parameter index: A valid index of the array. `i` must be less
  ///     than `endIndex`.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(after index: inout Int) { index += 1 }

  /// Returns an index that is the specified distance from the given index.
  ///
  /// The value passed as `n` must not offset `index` beyond the bounds of the
  /// array.
  ///
  /// - Note: To improve performance, this method does not validate that the
  ///    given index is valid before offseting it. Index validation is
  ///    deferred until the resulting index is used to access an element.
  ///    This optimization may be removed in future versions; do not rely on it.
  ///
  /// - Parameter index: A valid index of the array.
  /// - Parameter n: The distance by which to offset `index`.
  /// - Returns: An index offset by distance from `index`. If `n` is positive,
  ///    this is the same value as the result of `n` calls to `index(after:)`.
  ///    If `n` is negative, this is the same value as the result of `abs(n)`
  ///    calls to `index(before:)`.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(_ index: Int, offsetBy n: Int) -> Int {
    index + n
  }
  
  /// Returns the distance between two indices.
  ///
  /// - Note: To improve performance, this method does not validate that the
  ///    given index is valid before offseting it. Index validation is
  ///    deferred until the resulting index is used to access an element.
  ///    This optimization may be removed in future versions; do not rely on it.
  ///
  /// - Parameter start: A valid index of the collection.
  /// - Parameter end: Another valid index of the collection. If end is equal
  ///    to start, the result is zero.
  /// - Returns: The distance between `start` and `end`.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public func distance(from start: Index, to end: Index) -> Int {
    end - start
  }
  
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
  /// - Note: To improve performance, this method does not validate that the
  ///    given index is valid before offseting it. Index validation is
  ///    deferred until the resulting index is used to access an element.
  ///    This optimization may be removed in future versions; do not rely on it.
  ///
  /// - Parameter index: A valid index of the array. On return, `index` is
  ///    set to `limit` if
  /// - Parameter n: The distance to offset `index`.
  ///    On return, `n` is set to zero if the operation succeeded without
  ///    hitting the limit; otherwise, `n` reflects the number of steps that
  ///    couldn't be taken.
  /// - Parameter limit: A valid index of the array to use as a limit.
  ///    If `n > 0`, a limit that is less than `index` has no effect.
  ///    Likewise, if `n < 0`, a limit that is greater than `index` has no
  ///    effect.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    _storage.formIndex(&index, offsetBy: &n, limitedBy: limit)
  }

  /// Return a span over the array's storage that begins with the element at the given index,
  /// and extends to the end of the contiguous storage chunk that contains it. On return, the index
  /// is updated to address the next item following the end of the returned span.
  ///
  /// This method can be used to efficiently process the items of a container in bulk, by
  /// directly iterating over its piecewise contiguous pieces of storage:
  ///
  ///     var index = items.startIndex
  ///     while true {
  ///       let span = items.nextSpan(after: &index)
  ///       if span.isEmpty { break }
  ///       // Process items in `span`
  ///     }
  ///
  /// - Parameter index: A valid index in the array, including the end index. On return, this
  ///     index is advanced by the count of the resulting span, to simplify iteration.
  /// - Returns: A span over contiguous storage that starts at the given index. If the input index
  ///     is the end index, then this returns an empty span. Otherwise the result is non-empty,
  ///     with its first element matching the element at the input index.
  /// - Complexity: O(1)
  @inlinable
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Int, maximumCount: Int
  ) -> Span<Element> {
    _storage.nextSpan(after: &index, maximumCount: maximumCount)
  }
}

#endif
