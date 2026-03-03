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
  /// Inserts a new element into the deque at the specified position.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// The new element is inserted before the element currently at the specified
  /// index. If you pass the deque's `endIndex` as the `index` parameter, then
  /// the new element is appended to the container.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new item. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// - Parameter item: The new element to insert into the deque.
  /// - Parameter index: The position at which to insert the new element.
  ///   `index` must be a valid index in the deque.
  ///
  /// - Complexity: O(`self.count`) when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func insert(_ item: consuming Element, at index: Int) {
    _storage._checkValidIndex(index)
    _ensureFreeCapacity(1)
    _storage._handle.uncheckedInsert(item, at: index)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// Inserts a given number of new items into this deque at the specified
  /// position, using a callback to directly initialize deque storage by
  /// populating a series of output spans.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough elements,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  ///     var buffer = UniqueDeque<Int>(capacity: 20)
  ///     buffer.append([-999, 999])
  ///     var i = 0
  ///     buffer.insert(addingCount: 3, at: 1) { target in
  ///       while !target.isFull {
  ///         target.append(i)
  ///         i += 1
  ///       }
  ///     }
  ///     // `buffer` now contains [-999, 0, 1, 2, 999]
  ///
  /// The newly inserted items are not guaranteed to form a single contiguous
  /// storage region. Therefore, the supplied callback may be invoked multiple
  /// times to initialize each successive chunk of storage. However, invocations
  /// cease if the callback fails to fully populate its output span or if
  /// it throws an error. In such cases, the deque keeps all items that were
  /// successfully initialized before the callback terminated the prepend.
  ///
  /// Partial insertions create a gap in ring buffer storage that needs to be
  /// closed by moving already inserted items to their correct positions given
  /// the adjusted count. This adds some overhead compared to adding exactly as
  /// many items as promised.
  ///
  /// - Parameters:
  ///    - newItemCount: The maximum number of items to insert into the deque.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the deque.
  ///    - initializer: A callback that gets called at most twice to directly
  ///       populate newly reserved storage within the deque. The function
  ///      is always called with an empty output span.
  ///
  /// - Complexity: O(`self.count` + `newItemCount`) in addition to the complexity
  ///    of the callback invocations when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<E: Error>(
    addingCount newItemCount: Int,
    at index: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    _storage._checkValidIndex(index)
    precondition(newItemCount >= 0, "Cannot add a negative number of items")
    _ensureFreeCapacity(newItemCount)
    try _storage._handle.uncheckedInsert(
      addingCount: newItemCount, at: index, initializingWith: initializer)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// Inserts the elements of a fully initialized buffer by moving them into
  /// this deque, starting at the specified position. After this operation,
  /// the supplied buffer becomes uninitialized.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough elements,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the deque.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the array.
  ///
  /// - Complexity: O(`self.count` + `items.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) {
    guard !items.isEmpty else { return }
    var remainder = items
    insert(addingCount: items.count, at: index) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        buffer.moveInitializeAll(
          fromContentsOf: remainder._trim(first: buffer.count))
        count = buffer.count
      }
    }
    assert(remainder.isEmpty)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Moves the elements of an input span into this deque,
  /// starting at the specified position, and leaving the span empty.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough elements,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: An input span whose contents to move into
  ///        the deque.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the deque.
  ///
  /// - Complexity: O(`self.count` + `items.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout InputSpan<Element>,
    at index: Int
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(last: count)
      unsafe self.insert(moving: source, at: index)
      count = 0
    }
  }
#endif
  
  /// Moves the elements of an output span into this deque,
  /// starting at the specified position, and leaving the span empty.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough elements,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: An output span whose contents to move into
  ///        the deque.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the deque.
  ///
  /// - Complexity: O(`self.count` + `items.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout OutputSpan<Element>,
    at index: Int
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.insert(moving: source, at: index)
      count = 0
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Inserts at most `newItemCount` items generated by a producer into this
  /// deque, starting at the given index.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough items,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// This operation inserts as many items as the producer can generate before
  /// either reaching `newItemCount`, or the producer hitting its end, or
  /// throwing an error. If the producer has more than `newItemCount` items
  /// left in its underlying sequence, then extra items remain available after
  /// this method returns.
  ///
  /// If the operation inserts fewer than `newItemCount` items, then it results
  /// in a gap in ring buffer storage that needs to be closed by moving some
  /// items to their correct positions given the adjusted count. This adds some
  /// overhead compared to adding exactly as many items as promised.
  ///
  /// - Parameters:
  ///    - newItemCount: The maximum number of items to insert into the deque.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the deque.
  ///    - producer: A producer that generates the items to append.
  ///
  /// - Complexity: O(`self.count` + `newItemCount`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  public mutating func insert<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    addingCount newItemCount: Int,
    from producer: inout P,
    at index: Int
  ) throws(E) {
    try insert(addingCount: newItemCount, at: index) { target throws(E) in
      while !target.isFull, try producer.generate(into: &target) {
        // Do nothing
      }
    }
  }
  #endif
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque /* where Element: Copyable */ {
  /// Copies the elements of a fully initialized buffer pointer into this
  /// deque at the specified position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the deque’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the array.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough items,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: The new elements to insert into the deque. The buffer
  ///       must be fully initialized.
  ///    - index: The position at which to insert the new elements. It must be
  ///       a valid index of `self`.
  ///
  /// - Complexity: O(`count` + `newElements.count`) when amortized over many
  ///     similar invocations on the same deque.
  @inlinable
  public mutating func insert(
    copying items: UnsafeBufferPointer<Element>, at index: Int
  ) {
    guard items.count > 0 else { return }
    var remainder = items
    insert(addingCount: remainder.count, at: index) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        buffer.initializeAll(
          fromContentsOf: remainder._extracting(first: buffer.count))
        remainder = remainder._extracting(droppingFirst: buffer.count)
        count = buffer.count
      }
    }
    assert(remainder.isEmpty)
  }

  /// Copies the elements of a fully initialized buffer pointer into this
  /// deque at the specified position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the deque’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the deque.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough items,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: The new elements to insert into the deque. The buffer
  ///       must be fully initialized.
  ///    - index: The position at which to insert the new elements. It must be
  ///       a valid index of `self`.
  ///
  /// - Complexity: O(`count` + `newElements.count`) when amortized over many
  ///     similar invocations on the same deque.
  @inlinable
  public mutating func insert(
    copying items: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) {
    unsafe self.insert(copying: UnsafeBufferPointer(items), at: index)
  }

  /// Copies the elements of a span into this deque at the specified position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the deque’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the deque.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough items,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: The new elements to insert into the deque.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the deque.
  ///
  /// - Complexity: O(`count` + `items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @inlinable
  public mutating func insert(
    copying items: Span<Element>, at index: Int
  ) {
    unsafe items.withUnsafeBufferPointer {
      unsafe self.insert(copying: $0, at: index)
    }
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  internal mutating func _insertContainer<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    at index: Int,
    copying items: borrowing C,
    newCount: Int
  ) {
    let expectedCount = self.count + newCount
    var it = items.makeBorrowingIterator()
    insert(addingCount: newCount, at: index) { target in
      it.copyContents(into: &target)
    }
    precondition(
      it.nextSpan().isEmpty && count == expectedCount,
      "Broken Container: count doesn't match contents")
  }
#endif

  @inlinable
  internal mutating func _insertCollection(
    at index: Int,
    copying items: some Collection<Element>,
    newCount: Int
  ) {
    let done: Void? = items.withContiguousStorageIfAvailable { src in
      self.insert(copying: src, at: index)
    }
    if done != nil { return }

    var i = items.startIndex
    self.insert(addingCount: newCount, at: index) { target in
      while !target.isFull {
        target.append(items[i])
        items.formIndex(after: &i)
      }
    }
    precondition(
      i == items.endIndex,
      "Broken Collection: count doesn't match contents")
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Copies the elements of a container into this deque at the specified
  /// position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the deque’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the deque.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough items,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameters:
  ///    - newElements: The new elements to insert into the deque.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the deque.
  ///
  /// - Complexity: O(`self.count` + `items.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying items: borrowing C, at index: Int
  ) {
    _insertContainer(
      at: index, copying: items, newCount: items.count)
  }
#endif

  /// Copies the elements of a collection into this deque at the specified
  /// position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the deque’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the deque.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough items,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: The new elements to insert into the deque.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the deque.
  ///
  /// - Complexity: O(`count` + `newElements.count`) when amortized over many
  ///     similar invocations on the same deque.
  @inlinable
  @inline(__always)
  public mutating func insert(
    copying items: some Collection<Element>, at index: Int
  ) {
    _insertCollection(
      at: index, copying: items, newCount: items.count)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Copies the elements of a container into this deque at the specified
  /// position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the deque's `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the deque.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the deque does not have sufficient capacity to hold enough items,
  /// then this reallocates the deque's storage to grow its capacity, using a
  /// geometric growth rate.
  ///
  /// - Parameters:
  ///    - items: The new elements to insert into the deque.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the deque.
  ///
  /// - Complexity: O(`self.count` + `items.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & Collection<Element>
  >(
    copying items: borrowing C, at index: Int
  ) {
    _insertContainer(
      at: index, copying: items, newCount: items.count)
  }
#endif
}

#endif
