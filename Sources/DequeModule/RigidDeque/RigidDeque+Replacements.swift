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

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
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
  /// successfully initialized before the callback terminated the prepend.
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
  @inlinable
  public mutating func replace<E: Error>(
    removing subrange: Range<Int>,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    _checkValidBounds(subrange)
    precondition(newItemCount >= 0, "Cannot add a negative number of items")
    precondition(
      count - subrange.count + newItemCount <= capacity,
      "RigidDeque capacity overflow")
    try _handle.uncheckedReplace(
      removing: subrange,
      addingCount: newItemCount,
      initializingWith: initializer)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Replaces the specified range of elements by a given count of new items,
  /// using callbacks to consume old items, and to then insert new ones.
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
  /// If the deque doesn't have sufficient capacity to accommodate the specified
  /// number of new elements, then this method triggers a runtime error.
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
  ///   - consumer: A callback that gets called at most twice to consume
  ///      the elements to be removed directly from the deque's storage. The
  ///      function is always called with a non-empty input span.
  ///   - initializer: A callback that gets called at most twice to directly
  ///      populate newly reserved storage within the deque. The function
  ///      is always called with an empty output span.
  ///
  /// - Complexity: O(`self.count` + `newItemCount`) in addition to the
  ///    complexity of the callback invocations.
  @inlinable
  public mutating func replace<E: Error>(
    removing subrange: Range<Int>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    _checkValidBounds(subrange)
    precondition(newItemCount >= 0, "Cannot add a negative number of items")
    precondition(
      count - subrange.count + newItemCount <= capacity,
      "RigidDeque capacity overflow")
    try _handle.uncheckedReplace(
      removing: subrange,
      consumingWith: consumer,
      addingCount: newItemCount,
      initializingWith: initializer)
  }
#endif
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
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
  @_alwaysEmitIntoClient
  public mutating func replace(
    removing subrange: Range<Int>,
    moving items: UnsafeMutableBufferPointer<Element>,
  ) {
    var remainder = items
    replace(removing: subrange, addingCount: remainder.count) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        buffer.moveInitializeAll(
          fromContentsOf: remainder._trim(first: buffer.count))
        count = buffer.count
      }
    }
    assert(remainder.isEmpty)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Replaces the specified range of elements by moving the contents of an
  /// input span into their place. On return, the span is left empty.
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
  ///   - items: An input span whose contents are to be moved into the deque.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func replace(
    removing subrange: Range<Int>,
    moving items: inout InputSpan<Element>
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(last: count)
      unsafe self.replace(removing: subrange, moving: source)
      count = 0
    }
  }
#endif

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
  @_alwaysEmitIntoClient
  public mutating func replace(
    removing subrange: Range<Int>,
    moving items: inout OutputSpan<Element>
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.replace(removing: subrange, moving: source)
      count = 0
    }
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Replaces the specified range of elements by at most `newItemCount` items
  /// generated by a producer.
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
  /// inserts the items generated by `producer` at `subrange.lowerBound`. This
  /// case is more directly expressed by calling `insert(moving:at:)`.
  ///
  /// Likewise, if the given producer is empty, then this method removes the
  /// elements in the given subrange without replacement. This case is more
  /// directly expressed by calling `removeSubrange`.
  ///
  /// This operation inserts as many items as the producer can generate before
  /// either reaching `newItemCount`, or the producer hitting its end, or
  /// throwing an error. If the producer has more than `newItemCount` items left in
  /// its underlying sequence, then extra items remain available after this
  /// method returns.
  ///
  /// If the operation inserts fewer than `newItemCount` items, then it results in
  /// a gap in ring buffer storage that needs to be closed by moving some
  /// items to their correct positions given the adjusted count. This adds some
  /// overhead compared to adding exactly as many items as promised.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the deque to replace. The bounds of
  ///     the range must be valid indices in the deque.
  ///   - newItemCount: The maximum number of items to insert into the deque.
  ///   - producer: A producer that generates the items to append.
  ///
  /// - Complexity: O(`self.count` + `maximumCount`)
  @_alwaysEmitIntoClient
  public mutating func replace<
    P: Producer<Element> & ~Copyable & ~Escapable
  >(
    removing subrange: Range<Int>,
    addingCount newItemCount: Int,
    from producer: inout P
  ) throws(P.ProducerError) {
    try replace(
      removing: subrange,
      addingCount: newItemCount
    ) { target throws(P.ProducerError) in
      try producer.generate(into: &target)
    }
  }
#endif
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
  @inlinable
  public mutating func replace(
    removing subrange: Range<Int>,
    copying items: UnsafeBufferPointer<Element>
  ) {
    var remainder = items
    replace(removing: subrange, addingCount: remainder.count) { target in
      target.withUnsafeMutableBufferPointer { dst, dstCount in
        dst.initializeAll(fromContentsOf: remainder._trim(first: dst.count))
        dstCount += dst.count
      }
    }
    assert(remainder.isEmpty)
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
  @inlinable
  public mutating func replace(
    removing subrange: Range<Int>,
    copying items: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.replace(
      removing: subrange,
      copying: UnsafeBufferPointer(items))
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
  @inlinable
  public mutating func replace(
    removing subrange: Range<Int>,
    copying items: Span<Element>
  ) {
    unsafe items.withUnsafeBufferPointer { buffer in
      unsafe self.replace(removing: subrange, copying: buffer)
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  internal mutating func _replace<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    removing subrange: Range<Int>,
    copyingContainer items: borrowing C,
    newCount: Int
  ) {

    let expectedCount = self.count - subrange.count + newCount
    var it = items.makeBorrowingIterator()
    self.replace(removing: subrange, addingCount: newCount) { target in
      it.copyContents(into: &target)
    }
    precondition(
      it.nextSpan().isEmpty && count == expectedCount,
      "Broken Container: count doesn't match contents")
  }
#endif

  @inlinable
  internal mutating func _replace(
    removing subrange: Range<Int>,
    copyingCollection items: __owned some Collection<Element>,
    newCount: Int
  ) {
    let done: Void? = items.withContiguousStorageIfAvailable { src in
      precondition(
        src.count == newCount,
        "Broken Collection: count doesn't match contents")
      self.replace(removing: subrange, copying: src)
    }
    if done != nil { return }

    var i = items.startIndex
    self.replace(removing: subrange, addingCount: newCount) { target in
      while !target.isFull {
        target.append(items[i])
        items.formIndex(after: &i)
      }
    }
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
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
  /// Likewise, if you pass a zero-length container as the `items`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the deque to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - items: The new elements to copy into the collection.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @inlinable
  @inline(__always)
  public mutating func replace<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    removing subrange: Range<Int>,
    copying items: borrowing C
  ) {
    _replace(
      removing: subrange, copyingContainer: items, newCount: items.count)
  }
#endif

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
  @inlinable
  @inline(__always)
  public mutating func replace(
    removing subrange: Range<Int>,
    copying items: __owned some Collection<Element>
  ) {
    _replace(
      removing: subrange, copyingCollection: items, newCount: items.count)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
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
  /// Likewise, if you pass a zero-length container as the `items`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the deque to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - items: The new elements to copy into the collection.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this deque and
  ///   *m* is the count of `items`.
  @inlinable
  @inline(__always)
  public mutating func replace<
    C: Container<Element> & Collection<Element>
  >(
    removing subrange: Range<Int>,
    copying items: C
  ) {
    _replace(
      removing: subrange, copyingContainer: items, newCount: items.count)
  }
#endif
}

#endif
