//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview

// Note on protocol conformances
// =============================
//
// `TemporaryArray` is non-escapable (it can hold a dependency on borrowed stack
// memory), and that currently rules out conforming to two protocols it would
// otherwise be a natural fit for:
//
//  * `DynamicContainer` is declared `~Copyable` but *not* `~Escapable`, so it
//    requires escapable conformers. (Its `init()` / `init(minimumCapacity:)`
//    requirements presuppose a self-owning, escapable container.)
//
//  * `RangeReplaceableContainer` *is* `~Escapable`-tolerant, but its
//    `SubrangeConsumer` (a `Drain`) needs to hold a mutable back-reference to
//    the array so it can close the gap when destroyed. The tool for that,
//    `MutableRef`, still requires its pointee to be escapable (there is a
//    `// FIXME: ~Escapable` on its declaration). Until that is generalized, a
//    non-escapable container cannot vend such a consumer.
//
// Rather than conform, `TemporaryArray` therefore offers the same operations
// directly: `replace(...)`, a closure-based `consume(_:consumingWith:)` (which
// needs no stored back-reference), and the usual removal helpers below. The
// read-only `Container` / `BidirectionalContainer` / `RandomAccessContainer`
// conformances are unaffected.

//MARK: - Gap management

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  @_alwaysEmitIntoClient
  internal mutating func _closeGap(at index: Int, count: Int) {
    guard count > 0 else { return }
    let source = unsafe _storage.extracting(
      Range(uncheckedBounds: (index + count, _count)))
    let target = unsafe _storage.extracting(
      Range(uncheckedBounds: (index, index + source.count)))
    let i = unsafe target.moveInitialize(fromContentsOf: source)
    assert(i == target.endIndex)
  }

  @_alwaysEmitIntoClient
  @unsafe
  internal mutating func _openGap(
    at index: Int, count: Int
  ) -> UnsafeMutableBufferPointer<Element> {
    assert(index >= 0 && index <= _count)
    assert(count <= freeCapacity)
    guard count > 0 else {
      return unsafe _storage.extracting(Range(uncheckedBounds: (index, index)))
    }
    let source = unsafe _storage.extracting(
      Range(uncheckedBounds: (index, _count)))
    let target = unsafe _storage.extracting(
      Range(uncheckedBounds: (index + count, _count + count)))
    let i = unsafe target.moveInitialize(fromContentsOf: source)
    assert(i == target.count)
    return unsafe _storage.extracting(
      Range(uncheckedBounds: (index, index + count)))
  }

  /// Resize the gap in `subrange` to hold `newItemCount` items, moving trailing
  /// elements as needed and adjusting `count`. Returns the (uninitialized) gap.
  @_alwaysEmitIntoClient
  @unsafe
  internal mutating func _resizeGap(
    in subrange: Range<Int>, to newItemCount: Int
  ) -> UnsafeMutableBufferPointer<Element> {
    assert(subrange.lowerBound >= 0 && subrange.upperBound <= _count)
    assert(newItemCount >= 0 && newItemCount - subrange.count <= freeCapacity)
    if newItemCount > subrange.count {
      _ = unsafe _openGap(
        at: subrange.upperBound, count: newItemCount - subrange.count)
    } else if newItemCount < subrange.count {
      _closeGap(
        at: subrange.lowerBound + newItemCount,
        count: subrange.count - newItemCount)
    }
    _count += newItemCount - subrange.count
    let gapRange = unsafe Range(
      uncheckedBounds: (subrange.lowerBound, subrange.lowerBound + newItemCount))
    return unsafe _storage.extracting(gapRange)
  }
}

//MARK: - Replacing

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Replaces the elements in `subrange` with `newItemCount` new items,
  /// consuming the removed items in place through an input span and
  /// initializing the replacements through an output span. The array grows
  /// (and spills to the heap if needed) to accommodate a net increase in count.
  ///
  /// - Complexity: O(`count` + `newItemCount`), amortized.
  @_alwaysEmitIntoClient
  public mutating func replace<E: Error>(
    removing subrange: Range<Int>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    _checkValidBounds(subrange)
    precondition(newItemCount >= 0, "Cannot add a negative number of items")
    let netIncrease = newItemCount - subrange.count
    if netIncrease > 0 {
      _ensureFreeCapacity(netIncrease)
    }
    do {
      // Consume the items to be removed.
      let buffer = unsafe _storage.extracting(subrange)
      var span = unsafe InputSpan(buffer: buffer, initializedCount: buffer.count)
      consumer(&span)
      _ = consume span
    }
    do {
      // Open a gap and let the caller initialize the replacements.
      let target = unsafe _resizeGap(in: subrange, to: newItemCount)
      var span = unsafe OutputSpan(buffer: target, initializedCount: 0)
      defer {
        let c = span.finalize(for: target)
        if c < newItemCount {
          self._closeGap(
            at: subrange.lowerBound &+ c, count: newItemCount &- c)
          _count &-= newItemCount &- c
        }
        span = OutputSpan()
      }
      try initializer(&span)
    }
  }

  /// Replaces the elements in `subrange` with `newItemCount` new items
  /// initialized through an output span, destroying the removed items.
  ///
  /// - Complexity: O(`count` + `newItemCount`), amortized.
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange<E: Error>(
    _ subrange: Range<Int>,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    try replace(
      removing: subrange,
      consumingWith: { _ in },
      addingCount: newItemCount,
      initializingWith: initializer)
  }

  /// Replaces the elements in `subrange` by moving the elements of a fully
  /// initialized buffer into their place. On return, the buffer is left
  /// uninitialized. The array grows (and spills to the heap if needed) to
  /// accommodate a net increase in count.
  ///
  /// - Complexity: O(`count` + `newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving newElements: UnsafeMutableBufferPointer<Element>
  ) {
    replaceSubrange(subrange, addingCount: newElements.count) { target in
      target._append(moving: newElements)
    }
  }

  /// Replaces the elements in `subrange` by moving the contents of an output
  /// span into their place. On return, the span is left empty. The array grows
  /// (and spills to the heap if needed) to accommodate a net increase in count.
  ///
  /// - Complexity: O(`count` + `items.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving items: inout OutputSpan<Element>
  ) {
    replaceSubrange(subrange, addingCount: items.count) { target in
      target._append(moving: &items)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension TemporaryArray /*where Element: Copyable*/ {
  /// Replaces the elements in `subrange` by copying the elements of a fully
  /// initialized buffer into their place. The array grows (and spills to the
  /// heap if needed) to accommodate a net increase in count.
  ///
  /// - Complexity: O(`count` + `newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    replaceSubrange(subrange, addingCount: newElements.count) { target in
      target._append(copying: newElements)
    }
  }

  /// Replaces the elements in `subrange` by copying the elements of a fully
  /// initialized buffer into their place.
  ///
  /// - Complexity: O(`count` + `newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe replaceSubrange(subrange, copying: UnsafeBufferPointer(newElements))
  }

  /// Replaces the elements in `subrange` by copying the elements of a span into
  /// their place.
  ///
  /// - Complexity: O(`count` + `newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: Span<Element>
  ) {
    replaceSubrange(subrange, addingCount: newElements.count) { target in
      target._append(copying: newElements)
    }
  }

  /// Replaces the elements in `subrange` by copying the elements of a
  /// collection into their place.
  ///
  /// - Complexity: O(`count` + `newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: some Collection<Element>
  ) {
    let newItemCount = newElements.count
    replaceSubrange(subrange, addingCount: newItemCount) { target in
      let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
        target._append(copying: buffer)
      }
      if done != nil { return }
      for item in newElements { target.append(item) }
    }
  }
}

//MARK: - Inserting

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Inserts `newItemCount` items at `index`, initialized through an output
  /// span, growing (and spilling to the heap if needed) to make room.
  ///
  /// - Complexity: O(`count` + `newItemCount`), amortized.
  @_alwaysEmitIntoClient
  public mutating func insert<E: Error>(
    addingCount newItemCount: Int,
    at index: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    try replaceSubrange(
      Range(uncheckedBounds: (index, index)),
      addingCount: newItemCount,
      initializingWith: initializer)
  }

  /// Inserts a single element at `index`, growing as needed.
  ///
  /// - Complexity: O(`count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func insert(_ item: consuming Element, at index: Int) {
    var item: Element? = item
    insert(addingCount: 1, at: index) { target in
      target.append(item.take()!)
    }
  }

  /// Moves the elements of a fully initialized buffer into this array at
  /// `index`, leaving the buffer uninitialized.
  ///
  /// - Complexity: O(`count` + `items.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) {
    insert(addingCount: items.count, at: index) { target in
      target._append(moving: items)
    }
  }

  /// Moves the elements of an output span into this array at `index`, leaving
  /// the span empty.
  ///
  /// - Complexity: O(`count` + `items.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout OutputSpan<Element>,
    at index: Int
  ) {
    insert(addingCount: items.count, at: index) { target in
      target._append(moving: &items)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension TemporaryArray /*where Element: Copyable*/ {
  /// Copies the elements of a fully initialized buffer into this array at
  /// `index`.
  ///
  /// - Complexity: O(`count` + `newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func insert(
    copying newElements: UnsafeBufferPointer<Element>, at index: Int
  ) {
    insert(addingCount: newElements.count, at: index) { target in
      target._append(copying: newElements)
    }
  }

  /// Copies the elements of a fully initialized buffer into this array at
  /// `index`.
  ///
  /// - Complexity: O(`count` + `newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func insert(
    copying newElements: UnsafeMutableBufferPointer<Element>, at index: Int
  ) {
    unsafe self.insert(copying: UnsafeBufferPointer(newElements), at: index)
  }

  /// Copies the elements of a span into this array at `index`.
  ///
  /// - Complexity: O(`count` + `newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func insert(
    copying newElements: Span<Element>, at index: Int
  ) {
    insert(addingCount: newElements.count, at: index) { target in
      target._append(copying: newElements)
    }
  }

  /// Copies the elements of a collection into this array at `index`.
  ///
  /// - Complexity: O(`count` + `newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func insert(
    copying newElements: some Collection<Element>, at index: Int
  ) {
    insert(addingCount: newElements.count, at: index) { target in
      let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
        target._append(copying: buffer)
      }
      if done != nil { return }
      for item in newElements { target.append(item) }
    }
  }
}

//MARK: - Removing

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Removes the elements in `subrange`, passing an input span to `consumer` so
  /// they can be consumed in place. Any items the consumer leaves behind are
  /// destroyed. This needs no stored back-reference, so unlike a `Drain`-based
  /// consumer it works on this non-escapable type.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func consume(
    _ subrange: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    _checkValidBounds(subrange)
    guard !subrange.isEmpty else {
      var span = InputSpan<Element>()
      consumer(&span)
      return
    }
    let buffer = unsafe _storage.extracting(subrange)
    var span = unsafe InputSpan(buffer: buffer, initializedCount: buffer.count)
    consumer(&span)
    _ = consume span
    _closeGap(at: subrange.lowerBound, count: subrange.count)
    _count -= subrange.count
  }

  /// Removes and destroys the elements in `subrange`.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func removeSubrange(_ subrange: Range<Index>) {
    consume(subrange) { _ in }
  }

  /// Removes and destroys the elements in `subrange`.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func removeSubrange(_ subrange: some RangeExpression<Index>) {
    removeSubrange(subrange.relative(to: indices))
  }

  /// Removes and returns the element at the specified position, closing the gap.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    _checkItemIndex(index)
    let old = unsafe _storage.moveElement(from: index)
    _closeGap(at: index, count: 1)
    _count &-= 1
    return old
  }

  /// Removes and destroys the last `k` elements of the array.
  ///
  /// - Complexity: O(`k`)
  @_alwaysEmitIntoClient
  public mutating func removeLast(_ k: Int) {
    if k == 0 { return }
    precondition(
      k >= 0 && k <= _count,
      "Count of elements to remove is out of bounds")
    unsafe _storage.extracting(
      Range(uncheckedBounds: (_count &- k, _count))
    ).deinitialize()
    _count &-= k
  }

  /// Removes and destroys all elements, optionally keeping the current storage.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    unsafe _items.deinitialize()
    _count = 0
    if !keepCapacity, _ownsStorage {
      unsafe _storage.deallocate()
      unsafe _storage = .init(start: nil, count: 0)
    }
  }

  /// Removes and returns the last element.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func removeLast() -> Element {
    precondition(_count > 0, "Cannot remove last element from an empty array")
    _count &-= 1
    return unsafe _storage.moveElement(from: _count)
  }

  /// Removes and returns the last element, or returns `nil` if empty.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func popLast() -> Element? {
    guard _count > 0 else { return nil }
    return removeLast()
  }
}

#endif
