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
  /// Adds an element to the end of the deque.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this triggers a runtime error.
  ///
  /// - Parameter item: The element to append to the deque.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append(_ newElement: consuming Element) {
    precondition(!isFull, "RigidDeque capacity overflow")
    _handle.uncheckedAppend(newElement)
  }

  /// Adds an element to the end of the deque, if possible.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this returns the given item without appending it; otherwise it
  /// returns nil.
  ///
  /// - Parameter item: The element to append to the deque.
  /// - Returns: `item` if the deque is full; otherwise nil.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func pushLast(_ item: consuming Element) -> Element? {
    // FIXME: Remove this in favor of a standard algorithm.
    if isFull { return item }
    append(item)
    return nil
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Efficiently append a given number of items to the back of this deque by
  /// populating a series of storage regions through repeated calls of the
  /// specified callback function.
  ///
  /// If the capacity of the deque isn't sufficient to accommodate the specified
  /// number of new elements, then this method triggers a runtime error.
  ///
  ///     var buffer = RigidDeque<Int>(capacity: 20)
  ///     buffer.append(999)
  ///     var i = 0
  ///     buffer.append(maximumCount: 6) { target in
  ///       while !target.isFull {
  ///         target.append(i)
  ///         i += 1
  ///       }
  ///     }
  ///     // `buffer` now contains [999, 0, 1, 2, 3, 4, 5, 6]
  ///
  /// The newly appended items are not guaranteed to form a single contiguous
  /// storage region. Therefore, the supplied callback may be invoked multiple
  /// times to initialize each successive chunk of storage. However, invocations
  /// cease when the callback fails to fully populate its output span or if
  /// it throws an error. In such cases, the deque keeps all items that were
  /// successfully initialized before the callback terminated the append.
  ///
  ///     var buffer = RigidDeque<Int>(capacity: 20)
  ///     buffer.append(999)
  ///     var i = 0
  ///     buffer.append(maximumCount: 6) { target in
  ///       while !target.isFull, i <= 3 {
  ///         target.append(i)
  ///         i += 1
  ///       }
  ///     }
  ///     // `buffer` now contains [999, 0, 1, 2, 3]
  ///
  /// - Parameters
  ///    - maximumCount: The maximum number of items to append to the deque.
  ///    - body: A callback that gets called at most twice to directly
  ///       populate newly reserved storage within the deque.
  ///
  /// - Complexity: O(`maximumCount`) in addition to the complexity of the callback
  ///    invocations.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append<E: Error>(
    maximumCount: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    precondition(count >= 0, "Negative count")
    precondition(freeCapacity >= maximumCount, "RigidDeque capacity overflow")
    try _handle.uncheckedAppend(capacity: maximumCount, initializingWith: body)
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
  public mutating func append(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    precondition(items.count <= freeCapacity, "RigidDeque capacity overflow")
    _handle.uncheckedAppend(moving: items)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Moves the elements of an input span by appending them to the end of
  /// this deque, leaving the span empty.
  ///
  /// If the deque does not have sufficient capacity to hold all items in its
  /// storage, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An input span whose contents need to be appended to this deque.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout InputSpan<Element>
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(last: count)
      unsafe self.append(moving: source)
      count = 0
    }
  }
#endif
  
  /// Moves the elements of an output span by appending them to the end of
  /// this deque, leaving the span empty.
  ///
  /// If the deque does not have sufficient capacity to hold all items in its
  /// storage, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An output span whose contents need to be appended to this deque.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout OutputSpan<Element>
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.append(moving: source)
      count = 0
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Appends at most `maximumCount` items generated by a producer to the end of
  /// this deque.
  ///
  /// If the target deque does not have sufficient capacity to hold the
  /// specified number of new items, then this triggers a runtime error.
  ///
  /// This operation appends as many items as the producer can generate before
  /// either reaching its end (or throwing an error), or filling the specified
  /// capacity. This operation only consumes the first `maximumCount` items in the
  /// producer; if the producer has more, then they remain available after this
  /// method returns.
  ///
  /// - Parameters
  ///    - maximumCount: The maximum number of items to append to the deque.
  ///    - producer: A producer that generates the items to append.
  ///
  /// - Complexity: O(*n*), where *n* is the number of items
  @_alwaysEmitIntoClient
  public mutating func append<
    P: Producer<Element> & ~Copyable & ~Escapable
  >(
    maximumCount: Int,
    from producer: inout P
  ) throws(P.ProducerError) {
    try self.append(
      maximumCount: maximumCount
    ) { target throws(P.ProducerError) in
      try producer.generate(into: &target)
    }
  }
#endif
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Appends items generated by a producer to the end of this deque until
  /// the deque becomes full or until the producer reaches its end or fails.
  ///
  /// - Parameters
  ///    - producer: A producer that generates the items to append.
  ///
  /// - Complexity: O(*n*), where *n* is the number of items appended.
  @_alwaysEmitIntoClient
  public mutating func append<
    P: Producer<Element> & ~Copyable & ~Escapable
  >(
    from producer: inout P
  ) throws(P.ProducerError) {
    try self.append(
      maximumCount: freeCapacity
    ) { target throws(P.ProducerError) in
      try producer.generate(into: &target)
    }
  }
#endif

}

@available(SwiftStdlib 5.0, *)
extension RigidDeque /*where Element: Copyable*/ {
  /// Copies the elements of a buffer and append them to the end of this
  /// deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    precondition(
      newElements.count <= freeCapacity,
      "RigidDeque capacity overflow")
    _handle.uncheckedAppend(copying: newElements)
  }
  
  /// Copies the elements of a buffer and append them to the end of this
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
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.append(copying: UnsafeBufferPointer(newElements))
  }
  
  /// Copies the elements of a span and append them to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// span, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A span whose contents to copy into the deque.
  ///
  /// - Complexity: O(`newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: Span<Element>) {
    unsafe newElements.withUnsafeBufferPointer { source in
      unsafe self.append(copying: source)
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  internal mutating func _append<
    S: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(copying items: borrowing S) {
    var it = items.makeBorrowingIterator()
    while true {
      let span = it.nextSpan()
      if span.isEmpty { break }
      self.append(copying: span)
    }
  }
  
  /// Copies the elements of a borrowing sequence and append them to the end of
  /// this deque.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func append<S: BorrowingSequence<Element> & ~Copyable & ~Escapable>(
    copying newElements: borrowing S
  ) {
    self._append(copying: newElements)
  }
#endif
  
  /// Append the elements of a sequence to the end of this deque by copying
  /// them.
  ///
  /// If the deque does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
      unsafe self.append(copying: buffer)
      return
    }
    if done != nil { return }
    
    var it = _handle.uncheckedAppend(copyingPrefixOf: newElements)
    precondition(it.next() == nil, "RigidDeque capacity overflow")
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
  public mutating func append<
    S: BorrowingSequence<Element> & Sequence<Element>
   >(
    copying newElements: S
   ) {
    self._append(copying: newElements)
  }
#endif
}

#endif
