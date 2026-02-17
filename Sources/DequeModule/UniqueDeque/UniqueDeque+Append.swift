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
  /// Adds an element to the end of the deque.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameter item: The element to append to the collection.
  ///
  /// - Complexity: O(1) as amortized over many invocations on the same deque.
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func append(_ newElement: consuming Element) {
    _ensureFreeCapacity(1)
    _storage._handle.uncheckedAppend(newElement)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// Efficiently append a given number of items to the back of this deque by
  /// populating a series of storage regions through repeated calls of the
  /// specified callback function.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the specified
  /// number of new elements, then this method reallocates the deque's storage
  /// to grow it, using a geometric growth rate.
  ///
  ///     var buffer = UniqueDeque<Int>()
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
  ///     var buffer = UniqueDeque<Int>()
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
  /// - Parameters:
  ///    - maximumCount: The maximum number of items to append to the deque.
  ///    - body: A callback that gets called at most twice to directly
  ///       populate newly reserved storage within the deque.
  ///
  /// - Complexity: O(`maximumCount`) in addition to the complexity of the callback
  ///    invocations, when amortized over many similar invocations on the same
  ///    deque.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append<E: Error>(
    maximumCount: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    guard maximumCount > 0 else { return }
    _ensureFreeCapacity(maximumCount)
    try _storage._handle.uncheckedAppend(
      maximumCount: maximumCount, initializingWith: body)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// Moves the elements of a buffer to the end of this deque, leaving the
  /// buffer uninitialized.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    _ensureFreeCapacity(items.count)
    _storage._handle.uncheckedAppend(moving: items)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Moves the elements of an input span by appending them to the end of
  /// this deque, leaving the span empty.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: An input span whose contents need to be appended to this deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
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
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: An output span whose contents need to be appended to this deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
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
  /// this deque. If `maximumCount` is nil, this appends every item the producer
  /// can generate.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the specified
  /// number of new elements, then this method reallocates the deque's storage
  /// to grow it, using a geometric growth rate.
  ///
  /// This operation appends as many items as the producer can generate before
  /// either reaching its end (or throwing an error), or filling the specified
  /// capacity. This operation only consumes the first `maximumCount` items in the
  /// producer; if the producer has more, then they remain available after this
  /// method returns.
  ///
  /// - Parameters:
  ///    - maximumCount: The maximum number of items to append to the deque, or
  ///       nil to append every item the producer generates.
  ///    - producer: A producer that generates the items to append.
  ///
  /// - Complexity: O(*n*) where *n* is the number of new items, when
  ///     amortized over many similar invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func append<
    P: Producer<Element> & ~Copyable & ~Escapable
  >(
    maximumCount: Int? = nil,
    from producer: inout P
  ) throws(P.ProducerError) {
    if let maximumCount {
      _ensureFreeCapacity(maximumCount)
      try _storage._handle.uncheckedAppend(
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
  /// Copies the elements of a buffer and append them to the end of this
  /// deque.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the specified
  /// number of new elements, then this method reallocates the deque's storage
  /// to grow it, using a geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: A fully initialized buffer whose contents to copy into
  ///       the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func append(
    copying items: UnsafeBufferPointer<Element>
  ) {
    _ensureFreeCapacity(items.count)
    unsafe _storage.append(copying: items)
  }

  /// Copies the elements of a buffer to the end of this deque.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the specified
  /// number of new elements, then this method reallocates the deque's storage
  /// to grow it, using a geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: A fully initialized buffer whose contents to copy into
  ///       the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func append(
    copying items: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.append(copying: UnsafeBufferPointer(items))
  }

  /// Copies the elements of a span to the end of this deque.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the specified
  /// number of new elements, then this method reallocates the deque's storage
  /// to grow it, using a geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: A span whose contents to copy into the deque.
  ///
  /// - Complexity: O(`items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func append(copying items: Span<Element>) {
    _ensureFreeCapacity(items.count)
    _storage.append(copying: items)
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
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `items`, when amortized
  ///    over many similar invocations on the same deque
  @_alwaysEmitIntoClient
  public mutating func append<S: BorrowingSequence<Element> & ~Copyable & ~Escapable>(
    copying items: borrowing S
  ) {
    self._append(copying: items)
  }
#endif

  /// Copies the elements of a sequence to the end of this deque.
  ///
  /// If the deque does not have sufficient capacity to hold enough elements,
  /// then this reallocates the deque's storage to extend its capacity, using
  /// a geometric growth rate. If the input sequence does not provide a correct
  /// estimate of its count, then the deque's storage may need to be resized
  /// more than once.
  ///
  /// - Parameters:
  ///    - items: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `items`, when
  ///     amortized over many similar invocations over the same deque.
  @_alwaysEmitIntoClient
  public mutating func append(copying items: some Sequence<Element>) {
    let done: Void? = items.withContiguousStorageIfAvailable { buffer in
      _ensureFreeCapacity(buffer.count)
      unsafe _storage.append(copying: buffer)
      return
    }
    if done != nil { return }

    _ensureFreeCapacity(items.underestimatedCount)
    var it = _storage._handle.uncheckedAppend(copyingPrefixOf: items)
    while let item = it.next() {
      _ensureFreeCapacity(1)
      _storage.append(item)
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Copies the elements of a borrowing sequence to the end of this deque.
  ///
  /// If the deque doesn't have sufficient capacity to accommodate the new
  /// elements, then this method reallocates the deque's storage to grow it,
  /// using a geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: The new elements to copy into the deque.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `items`, when
  ///     amortized over many similar invocations over the same deque.
  @_alwaysEmitIntoClient
  public mutating func append<
    S: BorrowingSequence<Element> & Sequence<Element>
   >(
    copying items: S
   ) {
    self._append(copying: items)
  }
#endif

}

#endif
