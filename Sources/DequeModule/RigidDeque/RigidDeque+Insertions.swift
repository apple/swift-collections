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
  /// Inserts a new element into the deque at the specified position.
  ///
  /// If the deque does not have sufficient capacity to hold any more elements,
  /// then this triggers a runtime error.
  ///
  /// The new element is inserted before the element currently at the specified
  /// index. If you pass the deque's `endIndex` as the `index` parameter, then
  /// the new element is appended to the container.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new item. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// - Parameter item: The new element to insert into the array.
  /// - Parameter index: The position at which to insert the new element.
  ///   `index` must be a valid index in the array.
  ///
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func insert(_ newElement: consuming Element, at index: Int) {
    precondition(!isFull, "RigidDeque capacity overflow")
    precondition(index >= 0 && index <= count, "Index out of bounds")
    _handle.uncheckedInsert(newElement, at: index)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Inserts a given number of new items into this deque at the specified
  /// position, using a callback to directly initialize deque storage by
  /// populating a series of output spans.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  ///     var buffer = RigidDeque<Int>(capacity: 20)
  ///     buffer.append([-999, 999])
  ///     var i = 0
  ///     buffer.insert(count: 3, at: 1) { target in
  ///       while !target.isFull {
  ///         target.append(i)
  ///         i += 1
  ///       }
  ///     }
  ///     // `buffer` now contains [-999, 0, 1, 2, 999]
  ///
  /// The newly prepended items are not guaranteed to form a single contiguous
  /// storage region. Therefore, the supplied callback may be invoked multiple
  /// times to initialize each successive chunk of storage. However, invocations
  /// cease if the callback fails to fully populate its output span or if
  /// it throws an error. In such cases, the deque keeps all items that were
  /// successfully initialized before the callback terminated the prepend.
  /// (Partial insertions create a gap in ring buffer storage that needs to be
  /// closed by moving already inserted items to their correct positions given
  /// the adjusted count. This adds some overhead compared to adding exactly as
  /// many items as promised.)
  ///
  /// - Parameters:
  ///    - count: The number of items to insert into the deque.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the deque.
  ///    - body: A callback that gets called at most twice to directly
  ///       populate newly reserved storage within the deque. The function
  ///      is always called with an empty output span.
  ///
  /// - Complexity: O(`self.count` + `count`)
  @inlinable
  public mutating func insert<E: Error>(
    count: Int,
    at index: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    // FIXME: This does not allow `body` to throw, to prevent having to move the tail twice. Is that okay?
    precondition(index >= 0 && index <= self.count, "Index out of bounds")
    precondition(count >= 0, "Negative count")
    precondition(count <= freeCapacity, "RigidDeque capacity overflow")
    try _handle.uncheckedInsert(count: count, at: index, initializingWith: body)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Inserts the elements of a fully initialized buffer by moving them into
  /// this deque, starting at the specified position. After this operation,
  /// the supplied buffer becomes uninitialized.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the deque.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the array.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) {
    guard !items.isEmpty else { return }
    var remainder = items
    insert(count: items.count, at: index) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        buffer.moveInitializeAll(
          fromContentsOf: remainder._extracting(first: buffer.count))
        remainder = remainder._extracting(droppingFirst: buffer.count)
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An input span whose contents to move into
  ///        the deque.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the deque.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An output span whose contents to move into
  ///        the deque.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the deque.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
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

  /// Inserts the elements of a given deque into the given position in this
  /// deque by moving them between the containers. On return, the input deque
  /// becomes empty, but it is not destroyed, and it preserves its original
  /// storage capacity.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: A deque whose contents to move into `self`.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the deque.
  ///
  /// - Complexity: O(`count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout RigidDeque<Element>,
    at index: Int
  ) {
    // FIXME: Remove this in favor of a generic algorithm over consumable containers
    insert(count: items.count, at: index) { target in
      target.withUnsafeMutableBufferPointer { dst, dstCount in
        var remainder = dst
        items._handle.unsafeConsumePrefix(upTo: remainder.count) { src in
          let c = remainder._moveInitializePrefix(from: src)
          dstCount += c
          remainder = remainder._extracting(last: c)
        }
        assert(remainder.isEmpty)
      }
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Inserts the elements of a given deque into the given position in this
  /// deque by consuming the source container.
  ///
  /// Existing elements in the deque's storage are moved as needed to make room
  /// for the new items. (The direction of the move depends on the location of
  /// the insertion, minimizing the cost.)
  ///
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: The deque whose contents to move into `self`.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the deque.
  ///
  /// - Complexity: O(`count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    consuming items: consuming RigidDeque<Element>,
    at index: Int
  ) {
    // FIXME: Remove this in favor of a generic algorithm over consumable containers
    var items = items
    self.insert(moving: &items, at: index)
  }
#endif
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque /* where Element: Copyable */ {
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the deque. The buffer
  ///       must be fully initialized.
  ///    - index: The position at which to insert the new elements. It must be
  ///       a valid index of `self`.
  ///
  /// - Complexity: O(`count` + `newElements.count`)
  @inlinable
  public mutating func insert(
    copying newElements: UnsafeBufferPointer<Element>, at index: Int
  ) {
    guard newElements.count > 0 else { return }
    var remainder = newElements
    insert(count: remainder.count, at: index) { target in
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the deque. The buffer
  ///       must be fully initialized.
  ///    - index: The position at which to insert the new elements. It must be
  ///       a valid index of `self`.
  ///
  /// - Complexity: O(`count` + `newElements.count`)
  @inlinable
  public mutating func insert(
    copying newElements: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) {
    unsafe self.insert(copying: UnsafeBufferPointer(newElements), at: index)
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the deque.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the deque.
  ///
  /// - Complexity: O(`count` + `newElements.count`)
  @inlinable
  public mutating func insert(
    copying newElements: Span<Element>, at index: Int
  ) {
    unsafe newElements.withUnsafeBufferPointer {
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
    let expectedCount = self.count - subrange.count + newCount
    var it = newElements.startBorrowIteration()
    insert(count: newCount, at: index) { target in
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

    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(newCount <= freeCapacity, "RigidDeque capacity overflow")
    var i = items.startIndex
    self._handle.uncheckedInsert(count: newCount, at: index) { target in
      while !target.isFull {
        target.append(items[i])
        items.formIndex(after: &i)
      }
    }
    precondition(i == items.endIndex,
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the deque.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the deque.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`).
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    _insertContainer(
      at: index, copying: newElements, newCount: newElements.count)
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the deque.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the deque.
  ///
  /// - Complexity: O(`count` + `newElements.count`)
  @inlinable
  @inline(__always)
  public mutating func insert(
    copying newElements: some Collection<Element>, at index: Int
  ) {
    _insertCollection(
      at: index, copying: newElements, newCount: newElements.count)
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
  /// If the capacity of the deque isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the deque.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the deque.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & Collection<Element>
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    _insertContainer(
      at: index, copying: newElements, newCount: newElements.count)
  }
#endif
}

#endif
