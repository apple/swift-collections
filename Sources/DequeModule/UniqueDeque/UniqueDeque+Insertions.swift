//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
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
  /// - Returns: A valid index addressing the newly inserted element.
  /// - Complexity: O(`self.count`) when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  @_transparent
  @discardableResult
  public mutating func insert(_ item: consuming Element, at index: Int) -> Int {
    _storage._checkValidIndex(index)
    _ensureFreeCapacity(1)
    return _storage._handle.uncheckedInsert(item, at: index)
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
  /// successfully initialized before the callback terminated the insertion.
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
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `newItemCount`) in addition to the complexity
  ///    of the callback invocations when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  @inline(__always)
  @discardableResult
  public mutating func insert<E: Error>(
    addingCount newItemCount: Int,
    at index: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Int> {
    _storage._checkValidIndex(index)
    precondition(newItemCount >= 0, "Cannot add a negative number of items")
    guard newItemCount > 0 else { return index ..< index }
    _ensureFreeCapacity(newItemCount)
    return try _storage._handle.uncheckedInsert(
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
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `items.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func insert(
    moving items: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) -> Range<Int> {
    guard !items.isEmpty else { return index ..< index }
    var remainder = items
    let range = insert(addingCount: items.count, at: index) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        buffer.moveInitializeAll(
          fromContentsOf: remainder._trim(first: buffer.count))
        count = buffer.count
      }
    }
    assert(remainder.isEmpty)
    return range
  }

#if UnstableContainersPreview
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
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `items.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func insert(
    moving items: inout InputSpan<Element>,
    at index: Int
  ) -> Range<Int> {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(last: count)
      count = 0
      return unsafe self.insert(moving: source, at: index)
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
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`self.count` + `items.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func insert(
    moving items: inout OutputSpan<Element>,
    at index: Int
  ) -> Range<Int> {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(first: count)
      count = 0
      return unsafe self.insert(moving: source, at: index)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque /* where Element: Copyable */ {
  /// Copies the elements of a fully initialized buffer pointer into this
  /// deque at the specified position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the deque's `endIndex` as the `index`
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
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`count` + `newElements.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func insert(
    copying items: UnsafeBufferPointer<Element>, at index: Int
  ) -> Range<Int> {
    guard items.count > 0 else { return index ..< index }
    var remainder = items
    let range = insert(addingCount: remainder.count, at: index) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        buffer.initializeAll(
          fromContentsOf: remainder._extracting(first: buffer.count))
        remainder = remainder._extracting(droppingFirst: buffer.count)
        count = buffer.count
      }
    }
    assert(remainder.isEmpty)
    return range
  }

  /// Copies the elements of a fully initialized buffer pointer into this
  /// deque at the specified position.
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
  ///    - items: The new elements to insert into the deque. The buffer
  ///       must be fully initialized.
  ///    - index: The position at which to insert the new elements. It must be
  ///       a valid index of `self`.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`count` + `newElements.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func insert(
    copying items: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) -> Range<Int> {
    unsafe self.insert(copying: UnsafeBufferPointer(items), at: index)
  }

  /// Copies the elements of a span into this deque at the specified position.
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
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(`count` + `items.count`) when amortized over many similar
  ///     invocations on the same deque.
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func insert(
    copying items: Span<Element>, at index: Int
  ) -> Range<Int> {
    items.withUnsafeBufferPointer {
      unsafe self.insert(copying: $0, at: index)
    }
  }

  @_alwaysEmitIntoClient
  package mutating func _insertCollection(
    at index: Int,
    copying items: some Collection<Element>,
    newCount: Int
  ) -> Range<Int> {
    let done: Range<Int>? = items.withContiguousStorageIfAvailable { src in
      self.insert(copying: src, at: index)
    }
    if let done { return done }

    var i = items.startIndex
    let range = self.insert(addingCount: newCount, at: index) { target in
      while !target.isFull {
        target.append(items[i])
        items.formIndex(after: &i)
      }
    }
    precondition(
      i == items.endIndex,
      "Broken Collection: count doesn't match contents")
    return range
  }

  /// Copies the elements of a collection into this deque at the specified
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
  /// - Complexity: O(`count` + `newElements.count`) when amortized over many
  ///     similar invocations on the same deque.
  @_alwaysEmitIntoClient
  @inline(__always)
  @discardableResult
  public mutating func insert(
    copying items: some Collection<Element>, at index: Int
  ) -> Range<Int> {
    _insertCollection(
      at: index, copying: items, newCount: items.count)
  }
}
