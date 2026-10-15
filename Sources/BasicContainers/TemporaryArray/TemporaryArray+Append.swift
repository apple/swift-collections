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

#if compiler(>=6.3)

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Adds an element to the end of the array, growing (and, if needed, spilling
  /// to the heap) to make room.
  ///
  /// - Complexity: O(1), amortized over many invocations on the same array.
  @_alwaysEmitIntoClient
  public mutating func append(_ item: consuming Element) {
    _ensureFreeCapacity(1)
    unsafe _storage.initializeElement(at: _count, to: item)
    _count &+= 1
  }

  /// Appends a given number of items to the end of the array by populating an
  /// output span, growing (and, if needed, spilling to the heap) to make room.
  ///
  /// The closure may initialize fewer than `newItemCount` items; the array
  /// gains exactly as many as the closure adds before it returns or throws.
  ///
  /// - Complexity: O(`newItemCount`), amortized.
  @_alwaysEmitIntoClient
  public mutating func append<E: Error>(
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    precondition(newItemCount >= 0, "Cannot add a negative number of items")
    _ensureFreeCapacity(newItemCount)
    let buffer = unsafe _freeSpace.extracting(
      Range(uncheckedBounds: (0, newItemCount)))
    var span = unsafe OutputSpan(buffer: buffer, initializedCount: 0)
    defer {
      _count &+= span.finalize(for: buffer)
      span = OutputSpan()
    }
    return try initializer(&span)
  }
}

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Moves the elements of a buffer to the end of this array, leaving the
  /// buffer uninitialized.
  ///
  /// - Complexity: O(`items.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    guard items.count > 0 else { return }
    _ensureFreeCapacity(items.count)
    let target = unsafe _freeSpace.extracting(
      Range(uncheckedBounds: (0, items.count)))
    let i = unsafe target.moveInitialize(fromContentsOf: items)
    assert(i == items.count)
    _count &+= items.count
  }

  /// Moves the elements of an output span to the end of this array, leaving the
  /// span empty.
  ///
  /// - Complexity: O(`items.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout OutputSpan<Element>
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = unsafe buffer.extracting(Range(uncheckedBounds: (0, count)))
      unsafe self.append(moving: source)
      count = 0
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension TemporaryArray /*where Element: Copyable*/ {
  /// Appends `count` copies of `repeatedValue` to the end of the array, growing
  /// (and, if needed, spilling to the heap) to make room.
  ///
  /// This is `TemporaryArray`'s analogue of `UniqueArray`'s
  /// `init(repeating:count:)`: it's an append rather than an initializer,
  /// because a `TemporaryArray` is meant to be seeded (typically on the stack)
  /// via `withTemporaryArray` and then filled.
  ///
  /// - Complexity: O(`count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func append(repeating repeatedValue: Element, count: Int) {
    precondition(count >= 0, "Cannot add a negative number of items")
    guard count > 0 else { return }
    _ensureFreeCapacity(count)
    let target = unsafe _freeSpace.extracting(
      Range(uncheckedBounds: (0, count)))
    unsafe target.initialize(repeating: repeatedValue)
    _count &+= count
  }

  /// Copies the elements of a buffer to the end of this array.
  ///
  /// - Complexity: O(`newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    guard newElements.count > 0 else { return }
    _ensureFreeCapacity(newElements.count)
    let target = unsafe _freeSpace.extracting(
      Range(uncheckedBounds: (0, newElements.count)))
    _ = unsafe target.initialize(fromContentsOf: newElements)
    _count &+= newElements.count
  }

  /// Copies the elements of a buffer to the end of this array.
  ///
  /// - Complexity: O(`newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func append(
    copying items: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.append(copying: UnsafeBufferPointer(items))
  }

  /// Copies the elements of a span to the end of this array.
  ///
  /// - Complexity: O(`newElements.count`), amortized.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: Span<Element>) {
    guard newElements.count > 0 else { return }
    _ensureFreeCapacity(newElements.count)
    let target = unsafe _freeSpace.extracting(
      Range(uncheckedBounds: (0, newElements.count)))
    unsafe newElements.withUnsafeBufferPointer { source in
      _ = unsafe target.initialize(fromContentsOf: source)
    }
    _count &+= newElements.count
  }

  /// Copies the elements of a sequence to the end of this array.
  ///
  /// If the sequence provides only a loose `underestimatedCount`, the array's
  /// storage may need to be resized more than once (potentially spilling to the
  /// heap along the way).
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`, amortized.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
      _ensureFreeCapacity(buffer.count)
      let target = unsafe _freeSpace.extracting(
        Range(uncheckedBounds: (0, buffer.count)))
      _ = unsafe target.initialize(fromContentsOf: buffer)
      _count &+= buffer.count
      return
    }
    if done != nil { return }

    _ensureFreeCapacity(newElements.underestimatedCount)
    for item in newElements {
      append(item)
    }
  }
}

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Appends all the items generated by a producer to the end of this array,
  /// growing (and, if needed, spilling to the heap) as it goes.
  ///
  /// This is the building block for collecting the result of mapping, filtering
  /// or otherwise transforming an arbitrary generative sequence whose final
  /// length isn't known in advance. The producer's `underestimatedCount` is
  /// used to size each bulk append.
  ///
  /// - Complexity: O(*n*) where *n* is the number of generated items, amortized.
  @_alwaysEmitIntoClient
  public mutating func append<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    from producer: inout P
  ) throws(E)
  where P.Element: ~Copyable {
    var done = false
    while !done {
      let c = Swift.max(producer.underestimatedCount, 1)
      _ensureFreeCapacity(c)
      try self.append(addingCount: freeCapacity) { target throws(E) in
        while !target.isFull, !done {
          done = try !producer.generate(into: &target)
        }
      }
    }
  }
}
#endif

#endif
