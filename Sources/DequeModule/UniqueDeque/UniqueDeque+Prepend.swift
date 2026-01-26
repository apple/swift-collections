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
extension UniqueDeque where Element: ~Copyable {
  /// Adds an element to the front of the deque.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameter item: The element to prepend to the deque.
  ///
  /// - Complexity: O(1) when amortized over many invocations on the same deque.
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func prepend(_ newElement: consuming Element) {
    _ensureFreeCapacity(1)
    _storage._handle.uncheckedPrepend(newElement)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// Efficiently prepend a given number of items to the front of this deque by
  /// populating a series of storage regions through repeated calls of the
  /// specified callback function.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the specified
  /// number of new elements, then this method reallocates the deque's storage
  /// to grow it, using a geometric growth rate.
  ///
  ///     var buffer = RigidDeque<Int>()
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
  ///     var buffer = RigidDeque<Int>()
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
  ///    invocations, when amortized over many similar invocations on the same
  ///    deque.
  @_alwaysEmitIntoClient
  public mutating func prepend<E: Error>(
    maximumCount: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    guard maximumCount > 0 else { return }
    _ensureFreeCapacity(maximumCount)
    try _storage._handle.uncheckedPrepend(
      maximumCount: maximumCount, initializingWith: body)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// Moves the elements of a buffer to the front of this deque, leaving the
  /// buffer uninitialized.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func prepend(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    _ensureFreeCapacity(items.count)
    _storage._handle.uncheckedPrepend(moving: items)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Moves the elements of an input span by prepending them to the front of
  /// this deque, leaving the span empty.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// - Parameters
  ///    - items: An input span whose contents need to be prepended to this deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
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
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// - Parameters
  ///    - items: An output span whose contents need to be prepended to this deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
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
  /// this deque. If `maximumCount` is nil, this appends every item the producer
  /// can generate.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the specified
  /// number of new elements, then this method reallocates the deque's storage
  /// to grow it, using a geometric growth rate.
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
  /// - Complexity: O(*n*) where *n* is the number of new items, when
  ///     amortized over many similar invocations on the same deque.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func prepend<
    P: Producer<Element> & ~Copyable & ~Escapable
  >(
    maximumCount: Int? = nil,
    from producer: inout P
  ) throws(P.ProducerError) {
    if let maximumCount {
      _ensureFreeCapacity(maximumCount)
      try _storage._handle.uncheckedPrepend(
        maximumCount: maximumCount
      ) { target throws(P.ProducerError) in
        while !target.isFull, try producer.generate(into: &target) {
          // Do nothing
        }
      }
      return
    }

    while true {
      _ensureFreeCapacity(1)
      try _storage._handle.uncheckedAppend(
        maximumCount: freeCapacity
      ) { target throws(P.ProducerError) in
        while !target.isFull, try producer.generate(into: &target) {
          // Do nothing
        }
      }
    }
  }
#endif
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque /*where Element: Copyable*/ {
  /// Copies the elements of a buffer and prepend them to the front of this
  /// rigid deque.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the specified
  /// number of new elements, then this method reallocates the deque's storage
  /// to grow it, using a geometric growth rate.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to copy into
  ///       the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying items: UnsafeBufferPointer<Element>
  ) {
    _ensureFreeCapacity(items.count)
    _storage._handle.uncheckedPrepend(copying: items)
  }
  
  /// Copies the elements of a buffer and prepend them to the front of this
  /// deque.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the specified
  /// number of new elements, then this method reallocates the deque's storage
  /// to grow it, using a geometric growth rate.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to copy into
  ///        the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying items: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.prepend(copying: UnsafeBufferPointer(items))
  }
  
  /// Copy the elements of a span and prepend them to the front of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// span, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: A span whose contents to copy into the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(copying items: Span<Element>) {
    unsafe items.withUnsafeBufferPointer { source in
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
    let oldCount = self.count
    self._append(copying: items) // Not a typo!
    _storage._handle.rotate(toStartAtOffset: oldCount)
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
  ///    - items: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `items`, as amortized
  ///     over many similar invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func prepend<S: BorrowingSequence<Element> & ~Copyable & ~Escapable>(
    copying items: borrowing S
  ) {
    self._prepend(copying: items)
  }

  /// Copies the elements of a container and prepends them to the front
  /// of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// container, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: The new elements to copy into the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func prepend<C: Container<Element> & ~Copyable & ~Escapable>(
    copying items: borrowing C
  ) {
    self._prepend(copying: items, exactCount: items.count)
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
  /// - Parameter items: The elements to prepend to the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying items: some Sequence<Element>
  ) {
    let done: Void? = items.withContiguousStorageIfAvailable { source in
      unsafe self.prepend(copying: source)
      return
    }
    guard done == nil else { return }
    let oldCount = self.count
    self.append(copying: items) // Not a typo!
    _storage._handle.rotate(toStartAtOffset: oldCount)
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
  /// - Parameter items: The elements to prepend to the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @inlinable
  @_alwaysEmitIntoClient
  public mutating func prepend(
    copying items: some Collection<Element>
  ) {
    let done: Void? = items.withContiguousStorageIfAvailable { source in
      unsafe self.prepend(copying: source)
      return
    }
    guard done == nil else { return }
    let c = items.count
    guard c > 0 else { return }
    _ensureFreeCapacity(c)
    _storage._handle.uncheckedPrepend(copying: items, exactCount: c)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Copies the elements of a borrowing sequence to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `items`, as amortized
  ///     over many similar invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func prepend<S: BorrowingSequence<Element> & Sequence<Element>>(
    copying items: borrowing S
  ) {
    self._prepend(copying: items)
  }

  /// Copies the elements of a borrowing sequence to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `items` when amortized
  ///     over many similar invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func prepend<S: BorrowingSequence<Element> & Collection<Element>>(
    copying items: borrowing S
  ) {
    self._prepend(copying: items, exactCount: items.count)
  }

  /// Copies the elements of a container to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `items` when amortized
  ///     over many similar invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func prepend<C: Container<Element> & Sequence<Element>>(
    copying items: borrowing C
  ) {
    self._prepend(copying: items, exactCount: items.count)
  }

  /// Copies the elements of a container to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `items` when amortized
  ///     over many similar invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func prepend<C: Container<Element> & Collection<Element>>(
    copying items: C
  ) {
    self._prepend(copying: items, exactCount: items.count)
  }
#endif
}
#endif
