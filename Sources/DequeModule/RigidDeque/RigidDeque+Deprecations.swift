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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import SpanPreview
#endif

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Grow or shrink the capacity of a rigid deque instance without discarding
  /// its contents.
  ///
  /// This operation replaces the deque's storage buffer with a newly allocated
  /// buffer of the specified capacity, moving all existing elements
  /// to its new storage. The old storage is then deallocated.
  ///
  /// - Parameter newCapacity: The desired new capacity. `newCapacity` must be
  ///    greater than or equal to the current count.
  ///
  /// - Complexity: O(`count`)
  @available(*, deprecated, renamed: "setCapacity(_:)")
  @_alwaysEmitIntoClient
  public mutating func reallocate(capacity newCapacity: Int) {
    _handle.reallocate(capacity: newCapacity)
  }

  /// Replaces the specified range of elements by a given count of new items,
  /// using a callback to directly initialize deque storage by populating
  /// a series of output spans.
  ///
  /// This method has the same overall effect as calling
  ///
  ///     try deque.removeSubrange(subrange)
  ///     try deque.insert(
  ///       addingCount: newItemCount,
  ///       at: subrange.lowerBound,
  ///       initializingWith: initializer)
  ///
  /// Except it performs faster (by a constant factor), by avoiding moving
  /// some items in the deque twice.
  ///
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// The newly inserted items are not guaranteed to form a single contiguous
  /// storage region. Therefore, the supplied callback may be invoked multiple
  /// times to initialize each successive chunk of storage. However, invocations
  /// cease if the callback fails to fully populate its output span or if
  /// it throws an error. In such cases, the deque keeps all items that were
  /// successfully initialized before the callback terminated the replacement.
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
  /// - Complexity: O(`self.count` + `newItemCount`) in addition to the complexity
  ///    of the callback invocations.
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque /* where Element: Copyable */ {
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the deque and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
