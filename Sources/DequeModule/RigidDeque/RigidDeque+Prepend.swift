//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
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
  /// Adds an element to the front of the deque.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this triggers a runtime error.
  ///
  /// - Parameter item: The element to prepend to the deque.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func prepend(_ newElement: consuming Element) {
    precondition(!isFull, "RigidDeque capacity overflow")
    _handle.uncheckedPrepend(newElement)
  }
  
  /// Adds an element to the front of the deque, if possible.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this returns the given item without prepending it; otherwise it
  /// returns nil.
  ///
  /// - Parameter item: The element to prepend to the deque.
  /// - Returns: `item` if the deque is full; otherwise nil.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func pushFirst(_ item: consuming Element) -> Element? {
    // FIXME: Remove this in favor of a standard algorithm.
    if isFull { return item }
    prepend(item)
    return nil
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Efficiently prepend a given number of items to the front of this deque by
  /// populating a series of storage regions through repeated calls of the
  /// specified callback function.
  ///
  /// If the deque does not have sufficient capacity to store the new items,
  /// then this triggers a runtime error.
  ///
  ///     var buffer = RigidDeque<Int>(capacity: 20)
  ///     buffer.append(999)
  ///     var i = 0
  ///     buffer.prepend(count: 6) { target in
  ///       while !target.isFull {
  ///         target.append(i)
  ///         i += 1
  ///       }
  ///     }
  ///     // `buffer` now contains [0, 1, 2, 3, 4, 5, 6, 999]
  ///
  /// The newly prepended items are not guaranteed to form a single contiguous
  /// storage region. Therefore, the supplied callback may be invoked multiple
  /// times to initialize each successive chunk of storage. However, invocations
  /// cease if the callback fails to fully populate its output span or if
  /// it throws an error. In such cases, the deque keeps all items that were
  /// successfully initialized before the callback terminated the prepend.
  /// (Partial prepends create a gap in ring buffer storage that needs to be
  /// closed by moving newly prepended items to their correct positions given
  /// the adjusted count. This adds some overhead compared to adding exactly as
  /// many items as promised.)
  ///
  ///     var buffer = RigidDeque<Int>(capacity: 20)
  ///     buffer.append(999)
  ///     var i = 0
  ///     buffer.prepend(count: 6) { target in
  ///       while !target.isFull, i <= 3 {
  ///         target.append(i)
  ///         i += 1
  ///       }
  ///     }
  ///     // `buffer` now contains [0, 1, 2, 3, 999]
  ///
  /// - Parameters
  ///    - count: The number of items to append to the deque.
  ///    - body: A callback that gets called at most twice to directly
  ///       populate newly reserved storage within the deque.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func prepend<E: Error>(
    count: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    precondition(count >= 0, "Negative count")
    precondition(freeCapacity >= count, "RigidDeque capacity overflow")
    try _handle.uncheckedPrepend(count: count, initializingWith: body)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Moves the elements of a buffer to the end of this deque, leaving the
  /// buffer uninitialized.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the deque.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func prepend(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    precondition(items.count <= freeCapacity, "RigidDeque capacity overflow")
    _handle.uncheckedPrepend(moving: items)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Moves the elements of a input span to the end of this deque, leaving the
  /// span empty.
  ///
  /// If the deque does not have sufficient capacity to hold all items in its
  /// storage, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An input span whose contents need to be appended to this deque.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  public mutating func prepend(
    moving items: inout InputSpan<Element>
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(last: count)
      unsafe self.prepend(moving: source)
      count = 0
    }
  }
#endif

  /// Moves the elements of an output span to the end of this deque, leaving the
  /// span empty.
  ///
  /// If the deque does not have sufficient capacity to hold all items in its
  /// storage, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An output span whose contents need to be appended to this deque.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  public mutating func prepend(
    moving items: inout OutputSpan<Element>
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.prepend(moving: source)
      count = 0
    }
  }

  /// Appends the elements of a given deque to the end of this array by moving
  /// them between the containers. On return, the input deque becomes empty, but
  /// it is not destroyed, and it preserves its original storage capacity.
  ///
  /// If the target deque does not have sufficient capacity to hold all items
  /// in the source deque, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: A deque whose items to move to the end of this deque.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  public mutating func prepend(
    moving items: inout RigidDeque<Element>
  ) {
    // FIXME: Remove this in favor of a generic algorithm over range-replaceable containers
    precondition(items.count <= freeCapacity, "RigidDeque capacity overflow")
    items._handle.unsafeConsumeAll { source in
      self._handle.uncheckedAppend(moving: source)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Appends the elements of a given container to the end of this deque by
  /// consuming the source container.
  ///
  /// If the target deque does not have sufficient capacity to hold all items,
  /// then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: A container whose contents to move into this deque.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  public mutating func prepend(
    consuming items: consuming RigidDeque<Element>
  ) {
    // FIXME: Remove this in favor of a generic algorithm over consumable containers
    var items = items
    self.append(moving: &items)
  }
#endif
}


@available(SwiftStdlib 5.0, *)
extension RigidDeque /*where Element: Copyable*/ {
  /// Copies the elements of a buffer to the front of this rigid deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    precondition(
      newElements.count <= freeCapacity,
      "RigidDeque capacity overflow")
    _handle.uncheckedPrepend(copying: newElements)
  }
  
  /// Copies the elements of a buffer to the front of this rigid deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///        the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.prepend(copying: UnsafeBufferPointer(newElements))
  }
  
  /// Copies the elements of a span to the front of this rigid deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// span, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A span whose contents to copy into the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(copying newElements: Span<Element>) {
    unsafe newElements.withUnsafeBufferPointer { source in
      unsafe self.prepend(copying: source)
    }
  }
  
  /// Copies the elements of a collection to the front of the rigid deque.
  ///
  /// Use this method to prepend the elements of a collection to the front of
  /// this deque. This example prepends the elements of a `Range<Int>` instance
  /// to a rigid deque of integers.
  ///
  ///     var numbers = RigidDeque<Int>(capacity: 10)
  ///     numbers.append(contentsOf: [1, 2, 3, 4, 5])
  ///     numbers.prepend(contentsOf: 10...15)
  ///     // `numbers` now contains [10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5]
  ///
  /// - Parameter newElements: The elements to prepend to the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying newElements: some Collection<Element>
  ) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { source in
      unsafe self.prepend(copying: source)
      return
    }
    guard done == nil else { return }
    let c = newElements.count
    guard c > 0 else { return }
    precondition(c <= freeCapacity, "RigidDeque capacity overflow")
    _handle.uncheckedPrepend(copying: newElements, exactCount: c)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  internal mutating func _prependIterable<
    I: Iterable<Element> & ~Copyable & ~Escapable
  >(copying items: borrowing I) {
    // We don't know the exact count of new elements, so we cannot initialize
    // them in place. Append them to the end of the deque first, then rotate
    // them to their correct location.
    let oldEndSlot = _handle.endSlot
    var it = items.startBorrowIteration()
    while true {
      let span = it.nextSpan()
      if span.isEmpty { break }
      prepend(copying: span)
    }
    _handle.rotate(toStartAt: oldEndSlot)
  }
  
  /// Copies the elements of an iterable to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func prepend<I: Iterable<Element> & ~Copyable & ~Escapable>(
    copying newElements: borrowing I
  ) {
    self._prependIterable(copying: newElements)
  }
#endif
  
  /// Copies the elements of a sequence to the front of the rigid deque.
  ///
  /// Use this method to prepend the elements of a sequence to the front of this
  /// deque. This example prepends the elements of a `Range<Int>` instance to a
  /// rigid deque of integers.
  ///
  ///     var numbers = RigidDeque<Int>(capacity: 10)
  ///     numbers.append(contentsOf: [1, 2, 3, 4, 5])
  ///     numbers.prepend(contentsOf: 10...15)
  ///     print(numbers)
  ///     // Prints "[10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5]"
  ///
  /// - Parameter newElements: The elements to prepend to the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(copying newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { source in
      unsafe self.prepend(copying: source)
      return
    }
    guard done == nil else { return }
    
    // We don't know the exact count of new elements, so we cannot initialize
    // them in place. Append them to the end of the deque first, then rotate
    // them to their correct location.
    let oldEndSlot = _handle.endSlot
    var it = _handle.uncheckedAppend(copyingPrefixOf: newElements)
    precondition(it.next() == nil, "RigidDeque capacity overflow")
    _handle.rotate(toStartAt: oldEndSlot)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Copies the elements of an iterable to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func prepend<I: Iterable<Element> & Sequence<Element>>(
    copying newElements: borrowing I
  ) {
    self._prependIterable(copying: newElements)
  }
#endif
}
#endif
