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
    // FIXME: Remove this in favor of a standard algorithm. (Or not -- prependable containers may not be worth a protocol)
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
  /// If the capacity of the deque isn't sufficient to accommodate the specified
  /// number of new elements, then this method triggers a runtime error.
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
  ///
  /// Note: Partial prepends create a gap in ring buffer storage that needs to
  /// be closed by moving newly prepended items to their correct positions given
  /// the adjusted count. This adds some overhead compared to adding exactly as
  /// many items as promised.
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
  ///    - maximumCount: The maximum number of items to prepend to the deque.
  ///    - body: A callback that gets called at most twice to directly
  ///       populate newly reserved storage within the deque.
  ///
  /// - Complexity: O(`maximumCount`) in addition to the complexity of the callback
  ///    invocations.
  @_alwaysEmitIntoClient
  public mutating func prepend<E: Error>(
    maximumCount: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    precondition(maximumCount >= 0, "Cannot prepend a negative number of items")
    precondition(freeCapacity >= maximumCount, "RigidDeque capacity overflow")
    try _handle.uncheckedPrepend(maximumCount: maximumCount, initializingWith: body)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Moves the elements of a buffer to the front of this deque, leaving the
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
  /// Moves the elements of an input span by prepending them to the front of
  /// this deque, leaving the span empty.
  ///
  /// If the deque does not have sufficient capacity to hold all items in its
  /// storage, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An input span whose contents need to be prepended to this deque.
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
  
  /// Moves the elements of an output span by prepending them to the front of
  /// this deque, leaving the span empty.
  ///
  /// If the deque does not have sufficient capacity to hold all items in its
  /// storage, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An output span whose contents need to be prepended to this deque.
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
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Prepends at most `maximumCount` items generated by a producer to the front of
  /// this deque.
  ///
  /// If the target deque does not have sufficient capacity to hold the
  /// specified number of new items, then this triggers a runtime error.
  ///
  /// This operation prepends as many items as the producer can generate before
  /// either reaching its end (or throwing an error), or filling the specified
  /// capacity. This operation only consumes the first `maximumCount` items in the
  /// producer; if the producer has more, then they remain available after this
  /// method returns.
  ///
  /// Note: Partial prepends create a gap in ring buffer storage that needs to
  /// be closed by moving newly prepended items to their correct positions given
  /// the adjusted count. This adds some overhead compared to adding exactly as
  /// many items as promised.
  ///
  /// - Parameters
  ///    - maximumCount: The maximum number of items to prepend to the deque, or
  ///       nil to use all available capacity.

  ///    - producer: A producer that generates the items to prepend.
  ///
  /// - Complexity: O(`maximumCount ?? self.freeCapacity`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func prepend<
    P: Producer<Element> & ~Copyable & ~Escapable
  >(
    maximumCount: Int? = nil,
    from producer: inout P
  ) throws(P.ProducerError) {
    try self.prepend(
      maximumCount: maximumCount ?? freeCapacity
    ) { target throws(P.ProducerError) in
      try producer.generate(into: &target)
    }
  }
#endif
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque /*where Element: Copyable*/ {
  /// Copies the elements of a buffer and prepend them to the front of this
  /// rigid deque.
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
  
  /// Copies the elements of a buffer and prepend them to the front of this
  /// deque.
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
  
  /// Copy the elements of a span and prepend them to the front of this deque.
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
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  internal mutating func _prepend<
    S: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(copying items: borrowing S) {
    // We don't know the exact count of new elements, so we cannot initialize
    // them in place. Append them to the end of the deque first, then rotate
    // them to their correct location.
    //
    // FIXME: If we get a BorrowingSequence.estimatedCount with an exact case,
    // then we should use that when possible to copy items to their final
    // location in a single pass.
    let oldEndSlot = _handle.endSlot
    self._append(copying: items) // Not a typo!
    _handle.rotate(toStartAt: oldEndSlot)
  }

  @inlinable
  internal mutating func _prepend<
    S: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(
    copying items: borrowing S,
    exactCount: Int
  ) {
    var it = items.makeBorrowingIterator()
    self.prepend(maximumCount: exactCount) { target in
      let span = it.nextSpan(maximumCount: target.freeCapacity)
      target._append(copying: span)
    }
  }
  
  /// Copies the elements of a borrowing sequence and prepend them to the front
  /// of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// As borrowing sequences do not necessarily provide an exact count, this
  /// operation works by first appending the items, then finalizing the
  /// prepend by rotating them in place as a postprocessing step.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func prepend<S: BorrowingSequence<Element> & ~Copyable & ~Escapable>(
    copying newElements: borrowing S
  ) {
    self._prepend(copying: newElements)
  }

  /// Copies the elements of a container and prepends them to the front
  /// of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// container, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func prepend<C: Container<Element> & ~Copyable & ~Escapable>(
    copying newElements: borrowing C
  ) {
    self._prepend(copying: newElements, exactCount: newElements.count)
  }
#endif

  /// Prepend the elements of a sequence to the front of this deque by copying
  /// them.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// This example prepends the elements of a `Range<Int>` instance
  /// to a rigid deque of integers.
  ///
  ///     var numbers = RigidDeque<Int>(capacity: 10)
  ///     numbers.append(copying: [1, 2, 3, 4, 5])
  ///     numbers.prepend(copying: 10...15)
  ///     // `numbers` now contains [10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5]
  ///
  /// As borrowing sequences do not necessarily provide an exact count, this
  /// operation works by first appending the items, then finalizing the
  /// prepend by rotating them in place as a postprocessing step.
  ///
  /// - Parameter newElements: The elements to prepend to the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying newElements: some Sequence<Element>
  ) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { source in
      unsafe self.prepend(copying: source)
      return
    }
    guard done == nil else { return }
    let oldEndSlot = _handle.endSlot
    self.append(copying: newElements) // Not a typo!
    _handle.rotate(toStartAt: oldEndSlot)
  }

  /// Prepend the elements of a collection to the front of this deque by copying
  /// them.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// This example prepends the elements of a `Range<Int>` instance
  /// to a rigid deque of integers.
  ///
  ///     var numbers = RigidDeque<Int>(capacity: 10)
  ///     numbers.append(copying: [1, 2, 3, 4, 5])
  ///     numbers.prepend(copying: 10...15)
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
  /// Copies the elements of a borrowing sequence to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func prepend<S: BorrowingSequence<Element> & Sequence<Element>>(
    copying newElements: borrowing S
  ) {
    self._prepend(copying: newElements)
  }

  /// Copies the elements of a borrowing sequence to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func prepend<S: BorrowingSequence<Element> & Collection<Element>>(
    copying newElements: borrowing S
  ) {
    self._prepend(copying: newElements, exactCount: newElements.count)
  }

  /// Copies the elements of a container to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func prepend<C: Container<Element> & Sequence<Element>>(
    copying newElements: borrowing C
  ) {
    self._prepend(copying: newElements, exactCount: newElements.count)
  }

  /// Copies the elements of a container to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func prepend<C: Container<Element> & Collection<Element>>(
    copying newElements: borrowing C
  ) {
    self._prepend(copying: newElements, exactCount: newElements.count)
  }
#endif
}
#endif
