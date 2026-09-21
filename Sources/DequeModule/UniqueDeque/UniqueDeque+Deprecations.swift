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

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// Creates an empty unique deque with the specified capacity.
  @available(*, deprecated, renamed: "init(minimumCapacity:)")
  @_alwaysEmitIntoClient
  @_transparent
  public init(capacity: Int) {
    _storage = .init(capacity: capacity)
  }

  /// Grow or shrink the capacity of this deque instance without discarding
  /// its contents.
  ///
  /// This operation replaces the deque's storage buffer with a newly allocated
  /// buffer of the specified capacity, moving all existing elements
  /// to its new storage. The old storage is then deallocated.
  ///
  /// - Parameter capacity: The desired new capacity. `capacity` must be
  ///    greater than or equal to the current count.
  ///
  /// - Complexity: O(`count`)
  @available(*, deprecated, renamed: "setCapacity(_:)")
  @inlinable
  public mutating func reallocate(capacity: Int) {
    _storage.setCapacity(capacity)
  }

  /// Replaces the specified range of elements by a given count of new items,
  /// using a callback to directly initialize deque storage by populating
  /// a series of output spans.
  ///
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// This method has the same overall effect as calling
  ///
  ///     try deque.consume(subrange, consumingWith: consumer)
  ///     try deque.insert(
  ///       addingCount: newItemCount,
  ///       at: subrange.lowerBound,
  ///       initializingWith: initializer)
  ///
  /// Except it performs faster (by a constant factor), by avoiding moving
  /// some items in the deque twice.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// Neither the removed nor the newly inserted items are guaranteed to form a
  /// single contiguous storage region. Therefore, the supplied callbacks may be
  /// invoked multiple times to consume, then initialize successive chunks of
  /// storage. Calls to `consumer` do not get interleaved with calls to
  /// `initializer`: no new item is inserted until every replaced item has been
  /// fully consumed.
  ///
  /// The `consumer` callback is not required to fully depopulate its input
  /// span. Any items the callback leaves in the span still get removed and
  /// discarded from the deque before insertions begin. If there are more
  /// spans to consume, the callback will get called again after such a partial
  /// consumption.
  ///
  /// The `initializer` callback is not required to fully populate its
  /// output span, and it is allowed to throw an error. In such cases, the
  /// replacement operation ends, and the deque keeps all items that were
  /// successfully initialized before the callback terminated.
  ///
  /// Partial insertions create a gap in ring buffer storage that needs to be
  /// closed by moving newly inserted items to their correct positions given
  /// the adjusted count. This adds some overhead compared to adding exactly as
  /// many items as promised.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the deque to replace. The bounds of
  ///      the range must be valid indices in the deque.
  ///   - newItemCount: the maximum number of items to replace the old subrange.
  ///   - initializer: A callback that gets called at most twice to directly
  ///      populate newly reserved storage within the deque. The function
  ///      is always called with an empty output span.
  ///
  /// - Complexity: O(`self.count` + `newCount`)
  @available(*, deprecated, renamed: "replaceSubrange(_:addingCount:initializingWith:)")
  @inlinable
  public mutating func replace<E: Error>(
    removing subrange: Range<Int>,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    try replaceSubrange(
      subrange, addingCount: newItemCount, initializingWith: initializer)
  }

  /// Replaces the specified range of elements by moving the elements of a
  /// fully initialized buffer into their place. On return, the buffer is left
  /// in an uninitialized state.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the deque and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `items` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(moving:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `items`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the deque to replace. The bounds of
  ///     the range must be valid indices in the deque.
  ///   - items: A fully initialized buffer whose contents to move into
  ///     the deque.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @available(*, deprecated, renamed: "replaceSubrange(_:moving:)")
  @_alwaysEmitIntoClient
  public mutating func replace(
    removing subrange: Range<Int>,
    moving items: UnsafeMutableBufferPointer<Element>,
  ) {
    replaceSubrange(subrange, moving: items)
  }

  /// Replaces the specified range of elements by moving the contents of an
  /// output span into their place. On return, the span is left empty.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the deque and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `items` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(moving:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `items`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the deque.
  ///   - items: An output span whose contents are to be moved into the deque.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @available(*, deprecated, renamed: "replaceSubrange(_:moving:)")
  @_alwaysEmitIntoClient
  public mutating func replace(
    removing subrange: Range<Int>,
    moving items: inout OutputSpan<Element>
  ) {
    replaceSubrange(subrange, moving: &items)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque /* where Element: Copyable */ {
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the deque and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `items` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(copying:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `items`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the deque to replace. The bounds of
  ///     the range must be valid indices in the deque.
  ///   - items: The new elements to copy into the collection.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @available(*, deprecated, renamed: "replaceSubrange(_:copying:)")
  @inlinable
  public mutating func replace(
    removing subrange: Range<Int>,
    copying items: UnsafeBufferPointer<Element>
  ) {
    replaceSubrange(subrange, copying: items)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the deque and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `items` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(copying:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `items`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the deque to replace. The bounds of
  ///     the range must be valid indices in the deque.
  ///   - items: The new elements to copy into the collection.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @available(*, deprecated, renamed: "replaceSubrange(_:copying:)")
  @inlinable
  public mutating func replace(
    removing subrange: Range<Int>,
    copying items: UnsafeMutableBufferPointer<Element>
  ) {
    replaceSubrange(subrange, copying: items)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given span.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the deque and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `items` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(copying:at:)`.
  ///
  /// Likewise, if you pass a zero-length span as the `items`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the deque to replace. The bounds of
  ///     the range must be valid indices in the deque.
  ///   - items: The new elements to copy into the collection.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @available(*, deprecated, renamed: "replaceSubrange(_:copying:)")
  @inlinable
  public mutating func replace(
    removing subrange: Range<Int>,
    copying items: Span<Element>
  ) {
    replaceSubrange(subrange, copying: items)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given collection.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `items` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(copying:at:)`.
  ///
  /// Likewise, if you pass a zero-length collection as the `items`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the deque to replace. The bounds of
  ///     the range must be valid indices in the deque.
  ///   - items: The new elements to copy into the collection.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @available(*, deprecated, renamed: "replaceSubrange(_:copying:)")
  @inlinable
  @inline(__always)
  public mutating func replace(
    removing subrange: Range<Int>,
    copying items: __owned some Collection<Element>
  ) {
    replaceSubrange(subrange, copying: items)
  }

}
