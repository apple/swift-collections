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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import SpanPreview
#endif

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// Replaces the specified range of elements by a given count of new items,
  /// using a callback to directly initialize array storage by populating
  /// an output span.
  ///
  /// The number of new items need not match the number of elements being
  /// removed.
  ///
  /// This method has the same overall effect as calling
  ///
  ///     try array.removeSubrange(subrange)
  ///     try array.insert(
  ///       addingCount: newItemCount,
  ///       at: subrange.lowerBound,
  ///       initializingWith: initializer)
  ///
  /// Except it performs faster (by a constant factor), by avoiding moving
  /// some items in the array twice.
  ///
  /// If the array does not have sufficient capacity to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// If the callback fails to fully populate its output span or if
  /// it throws an error, then the array keeps all items that were
  /// successfully initialized before the callback terminated the prepend.
  ///
  /// Partial insertions create a gap in array storage that needs to be
  /// closed by moving newly inserted items to their correct positions given
  /// the adjusted count. This adds some overhead compared to adding exactly as
  /// many items as promised.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///      the range must be valid indices in the array.
  ///   - newItemCount: the maximum number of items to replace the old subrange.
  ///   - initializer: A callback that gets called at most once to directly
  ///      populate newly reserved storage within the array. The function
  ///      is always called with an empty output span.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `newItemCount`) in addition to the complexity
  ///    of the callback invocations.
  @inlinable
  @discardableResult
  public mutating func replaceSubrange<E: Error>(
    _ subrange: Range<Int>,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Int> {
    _checkValidBounds(subrange)
    precondition(newItemCount >= 0, "Cannot add a negative number of items")
    precondition(
      newItemCount - subrange.count <= freeCapacity,
      "RigidArray capacity overflow")
    return try _uncheckedReplaceSubrange(
      subrange, addingCount: newItemCount, initializingWith: initializer)
  }

  @_alwaysEmitIntoClient
  internal mutating func _uncheckedReplaceSubrange<E: Error>(
    _ subrange: Range<Int>,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Int> {
    // Destroy removed items
    unsafe _items.extracting(subrange).deinitialize()
    let target = _resizeGap(in: subrange, to: newItemCount)
    var span = OutputSpan(buffer: target, initializedCount: 0)
    defer {
      let c = span.finalize(for: target)
      if c < newItemCount {
        self._closeGap(
          at: subrange.lowerBound &+ c,
          count: newItemCount &- c)
        _count &-= newItemCount &- c
      }
      span = OutputSpan()
    }
    try initializer(&span)
    return Range(uncheckedBounds: (
      subrange.lowerBound, subrange.lowerBound + newItemCount))
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
#if UnstableContainersPreview
  /// Replaces the specified range of elements by a given count of new items,
  /// using callbacks to consume old items, and to then insert new ones.
  ///
  /// The number of new items need not match the number of elements being
  /// removed.
  ///
  /// This method has the same overall effect as calling
  ///
  ///     try array.consume(subrange, consumingWith: consumer)
  ///     try array.insert(
  ///       addingCount: newItemCount,
  ///       at: subrange.lowerBound,
  ///       initializingWith: initializer)
  ///
  /// Except it performs faster (by a constant factor), by avoiding moving
  /// some items in the deque twice.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the specified
  /// number of new elements, then this method triggers a runtime error.
  ///
  /// The `consumer` callback is not required to fully depopulate its input
  /// span. Any items the callback leaves in the span still get removed and
  /// discarded from the array before insertions begin.
  ///
  /// The `initializer` callback is not required to fully populate its
  /// output span, and it is allowed to throw an error. In such cases, the
  /// deque keeps all items that were successfully initialized before the
  /// callback terminated.
  ///
  /// Partial insertions create a gap in array storage that needs to be
  /// closed by moving newly inserted items to their correct positions given
  /// the adjusted count. This adds some overhead compared to adding exactly as
  /// many items as promised.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the deque to replace. The bounds of
  ///      the range must be valid indices in the deque.
  ///   - newItemCount: the maximum number of items to replace the old subrange.
  ///   - consumer: A callback that gets called at most once to consume
  ///      the elements to be removed directly from the deque's storage. The
  ///      function is always called with a non-empty input span.
  ///   - initializer: A callback that gets called at most once to directly
  ///      populate newly reserved storage within the deque. The function
  ///      is always called with an empty output span.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `newItemCount`) in addition to the
  ///    complexity of the callback invocations.
  @inlinable
  @discardableResult
  public mutating func replaceSubrange<E: Error>(
    _ subrange: Range<Int>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Int> {
    _checkValidBounds(subrange)
    precondition(newItemCount >= 0, "Cannot add a negative number of items")
    precondition(
      newItemCount - subrange.count <= freeCapacity,
      "RigidArray capacity overflow")
    return try _uncheckedReplaceSubrange(
      subrange,
      consumingWith: consumer,
      addingCount: newItemCount,
      initializingWith: initializer)
  }

  @_alwaysEmitIntoClient
  internal mutating func _uncheckedReplaceSubrange<E: Error>(
    _ subrange: Range<Int>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) ->Range<Int> {
    do {
      // Consume items to be removed
      let buffer = unsafe _storage.extracting(subrange)
      var span = InputSpan(buffer: buffer, initializedCount: buffer.count)
      consumer(&span)
      _ = consume span
    }
    do {
      // Insert new items
      let target = _resizeGap(in: subrange, to: newItemCount)
      var span = OutputSpan(buffer: target, initializedCount: 0)
      defer {
        let c = span.finalize(for: target)
        if c < newItemCount {
          self._closeGap(
            at: subrange.lowerBound &+ c,
            count: newItemCount &- c)
          _count &-= newItemCount &- c
        }
        span = OutputSpan()
      }
      try initializer(&span)
    }
    return Range(uncheckedBounds: (
      subrange.lowerBound, subrange.lowerBound + newItemCount))
  }
#endif
}


@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// Replaces the specified range of elements by moving the elements of a
  /// fully initialized buffer into their place. On return, the buffer is left
  /// in an uninitialized state.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(moving:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: A fully initialized buffer whose contents to move into
  ///     the array.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving newElements: UnsafeMutableBufferPointer<Element>,
  ) -> Range<Int> {
    replaceSubrange(subrange, addingCount: newElements.count) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        count = unsafe buffer._moveInitializePrefix(from: newElements)
      }
    }
  }

#if UnstableContainersPreview
  /// Replaces the specified range of elements by moving the contents of an
  /// input span into their place. On return, the span is left empty.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(moving:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - items: An input span whose contents are to be moved into the array.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving items: inout InputSpan<Element>
  ) -> Range<Int> {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(last: count)
      count = 0
      return unsafe self.replaceSubrange(subrange, moving: source)
    }
  }
#endif

  /// Replaces the specified range of elements by moving the contents of an
  /// output span into their place. On return, the span is left empty.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(moving:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - items: An output span whose contents are to be moved into the array.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving items: inout OutputSpan<Element>
  ) -> Range<Int> {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(first: count)
      count = 0
      return unsafe self.replaceSubrange(subrange, moving: source)
    }
  }

  /// Replaces the specified range of elements by moving the elements of a
  /// another array into their place.  On return, the source array
  /// becomes empty, but it is not destroyed, and it preserves its original
  /// storage capacity.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(moving:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: An array whose contents to move into `self`.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving newElements: inout RigidArray<Element>,
  ) -> Range<Int> {
    // FIXME: Remove this in favor of the generic algorithm over DrainableContainer
    unsafe newElements._unsafeEdit { buffer, count in
      let source = buffer._extracting(first: count)
      count = 0
      return unsafe self.replaceSubrange(subrange, moving: source)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// Replaces the specified range of elements by moving the elements of a
  /// given array into their place, consuming it in the process.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(consuming:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: An array whose contents to move into `self`.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    consuming newElements: consuming RigidArray<Element>,
  ) -> Range<Int> {
    // FIXME: Remove this in favor of the generic algorithm over DrainableContainer
    replaceSubrange(subrange, moving: &newElements)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray {
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(copying:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeBufferPointer<Element>
  ) -> Range<Int> {
    replaceSubrange(subrange, addingCount: newElements.count) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        count = unsafe buffer._initializePrefix(copying: newElements)
      }
    }
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(copying:at:)`.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) -> Range<Int> {
    unsafe self.replaceSubrange(
      subrange,
      copying: UnsafeBufferPointer(newElements))
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given span.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(copying:at:)`.
  ///
  /// Likewise, if you pass a zero-length span as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: Span<Element>
  ) -> Range<Int> {
    newElements.withUnsafeBufferPointer { buffer in
      unsafe self.replaceSubrange(subrange, copying: buffer)
    }
  }

  @inlinable
  internal mutating func _replaceSubrange(
    _ subrange: Range<Int>,
    copyingCollection newElements: __owned some Collection<Element>,
    newCount: Int
  ) -> Range<Int> {
    self.replaceSubrange(subrange, addingCount: newCount) { target in
      target.withUnsafeMutableBufferPointer { dst, dstCount in
        let done: Void? = newElements.withContiguousStorageIfAvailable { src in
          let i = unsafe dst._initializePrefix(copying: src)
          precondition(
            i == newCount,
            "Broken Collection: count doesn't match contents")
          dstCount = i
        }
        if done != nil { return }

        var (it, copied) = unsafe newElements._copyContents(initializing: dst)
        dstCount = copied
        precondition(
          it.next() == nil && copied == newCount,
          "Broken Collection: count doesn't match contents")
      }
    }

  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given collection.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(copying:at:)`.
  ///
  /// Likewise, if you pass a zero-length collection as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  @discardableResult
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: __owned some Collection<Element>
  ) -> Range<Int> {
    _replaceSubrange(
      subrange,
      copyingCollection: newElements,
      newCount: newElements.count)
  }
}
