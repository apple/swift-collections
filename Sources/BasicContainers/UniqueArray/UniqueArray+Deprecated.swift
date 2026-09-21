//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import SpanPreview
#endif

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  @available(*, deprecated, renamed: "nextSpan(after:maxCount:)")
  @inlinable
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Int, maximumCount: Int
  ) -> Span<Element> {
    self.nextSpan(
      after: &index,
      maxCount: maximumCount,
      limitedBy: self.endIndex)
  }

  @available(*, deprecated, renamed: "nextMutableSpan(after:maxCount:)")
  @inlinable
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int, maximumCount: Int
  ) -> MutableSpan<Element> {
    self.nextMutableSpan(
      after: &index,
      maxCount: maximumCount,
      limitedBy: self.endIndex)
  }

  @available(*, deprecated, renamed: "previousSpan(before:maxCount:)")
  @inlinable
  @_lifetime(borrow self)
  public func previousSpan(
    before index: inout Int, maximumCount: Int
  ) -> Span<Element> {
    self.previousSpan(before: &index, maxCount: maximumCount)
  }

  /// Initializes a new unique array with the specified capacity and no elements.
  @available(*, deprecated, renamed: "init(minimumCapacity:)")
  @inlinable
  public init(capacity: Int) {
    self.init(minimumCapacity: capacity)
  }

  @available(*, deprecated)
  @inlinable
  @inline(__always)
  public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
    if keepCapacity {
      _storage.removeAll()
    } else {
      _storage = RigidArray(capacity: 0)
    }
  }

  /// Append a given number of items to the end of this array by populating
  /// an output span.
  ///
  /// If the array does not have sufficient capacity to hold the requested
  /// number of new elements, then this reallocates the array's storage to
  /// grow its capacity, using a geometric growth rate.
  ///
  /// - Parameters:
  ///    - count: The number of items to append to the array.
  ///    - initializer: A callback that gets called exactly once to directly
  ///       populate newly reserved storage within the array. The function
  ///       is allowed to initialize fewer than `count` items. The array is
  ///       appended however many items the callback adds to the output span
  ///       before it returns (or before it throws an error).
  ///
  /// - Complexity: O(`count`)
  @available(*, deprecated, renamed: "append(addingCount:initializingWith:)")
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append<E: Error, Result: ~Copyable>(
    count: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    var result: Result? = nil
    try append(addingCount: count) { target throws(E) in
      result = try initializer(&target)
    }
    return result.take()!
  }

  /// Inserts a given number of new items into this array at the specified
  /// position, using a callback to directly initialize array storage by
  /// populating an output span.
  ///
  /// All existing elements at or following the specified position are moved to
  /// make room for the new items.
  ///
  /// If the array does not have sufficient capacity to hold the new elements,
  /// then this reallocates storage to extend its capacity, using a geometric
  /// growth rate.
  ///
  /// - Parameters:
  ///    - count: The number of items to insert into the array.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the array.
  ///    - body: A callback that gets called exactly once to directly
  ///       populate newly reserved storage within the array. The function
  ///       is called with an empty output span of capacity matching the
  ///       supplied count, and it must fully populate it before returning.
  ///
  /// - Complexity: O(`self.count` + `count`)
  @available(*, deprecated, renamed: "insert(addingCount:at:initializingWith:)")
  @inlinable
  public mutating func insert<Result: ~Copyable>(
    count: Int,
    at index: Int,
    initializingWith body: (inout OutputSpan<Element>) -> Result
  ) -> Result {
    var result: Result? = nil
    self.insert(addingCount: count, at: index) { target in
      result = body(&target)
    }
    return result!
  }

  /// Grow or shrink the capacity of a unique array instance without discarding
  /// its contents.
  ///
  /// This operation replaces the array's storage buffer with a newly allocated
  /// buffer of the specified capacity, moving all existing elements
  /// to its new storage. The old storage is then deallocated.
  ///
  /// - Parameter capacity: The desired new capacity. `capacity` must be
  ///    greater than or equal to the current count.
  ///
  /// - Complexity: O(`count`)
  @available(*, deprecated, renamed: "setCapacity(_:)")
  @inlinable
  public mutating func reallocate(capacity: Int) {
    _storage.reallocate(capacity: capacity)
  }

  @available(*, deprecated, renamed: "replaceSubrange(_:addingCount:initializingWith:)")
  @inlinable
  public mutating func replace<E: Error>(
    removing subrange: Range<Int>,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    try replaceSubrange(
      subrange, addingCount: newItemCount, initializingWith: initializer)
  }

#if UnstableContainersPreview
  @available(*, deprecated, renamed: "replaceSubrange(_:consumingWith:addingCount:initializingWith:)")
  @inlinable
  public mutating func replace<E: Error>(
    removing subrange: Range<Int>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    try replaceSubrange(
      subrange,
      consumingWith: consumer,
      addingCount: newItemCount,
      initializingWith: initializer)
  }
#endif

  @available(*, deprecated, renamed: "replaceSubrange(_:moving:)")
  @_alwaysEmitIntoClient
  public mutating func replace(
    removing subrange: Range<Int>,
    moving newElements: UnsafeMutableBufferPointer<Element>,
  ) {
    replaceSubrange(subrange, moving: newElements)
  }

#if UnstableContainersPreview
  @available(*, deprecated, renamed: "replaceSubrange(_:moving:)")
  @_alwaysEmitIntoClient
  public mutating func replace(
    removing subrange: Range<Int>,
    moving items: inout InputSpan<Element>
  ) {
    replaceSubrange(subrange, moving: &items)
  }
#endif

  @available(*, deprecated, renamed: "replaceSubrange(_:moving:)")
  @_alwaysEmitIntoClient
  public mutating func replace(
    removing subrange: Range<Int>,
    moving items: inout OutputSpan<Element>
  ) {
    replaceSubrange(subrange, moving: &items)
  }

  @available(*, deprecated, renamed: "replaceSubrange(_:moving:)")
  @_alwaysEmitIntoClient
  public mutating func replace(
    removing subrange: Range<Int>,
    moving newElements: inout RigidArray<Element>,
  ) {
    replaceSubrange(subrange, moving: &newElements)
  }

  @available(*, deprecated, renamed: "replaceSubrange(_:consuming:)")
  @_alwaysEmitIntoClient
  public mutating func replace(
    removing subrange: Range<Int>,
    consuming newElements: consuming RigidArray<Element>,
  ) {
    replaceSubrange(subrange, consuming: newElements)
  }

}

@available(SwiftStdlib 5.0, *)
extension UniqueArray {
  /// Copy the contents of this array into a newly allocated unique array
  /// instance with just enough capacity to hold all its elements.
  ///
  /// - Complexity: O(`count`)
  @available(*, deprecated, renamed: "clone()")
  @inlinable
  public func copy() -> Self {
    self.clone()
  }

  /// Copy the contents of this array into a newly allocated unique array
  /// instance with the specified capacity.
  ///
  /// - Parameter capacity: The desired capacity of the resulting unique array.
  ///    `capacity` must be greater than or equal to `count`.
  ///
  /// - Complexity: O(`count`)
  @available(*, deprecated, renamed: "clone(capacity:)")
  @inlinable
  public func copy(capacity: Int) -> Self {
    clone(capacity: capacity)
  }

  @available(*, deprecated, renamed: "replace(_:copying:)")
  @inlinable
  public mutating func replace(
    removing subrange: Range<Int>,
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    replaceSubrange(subrange, copying: newElements)
  }

  @available(*, deprecated, renamed: "replace(_:copying:)")
  @inlinable
  public mutating func replace(
    removing subrange: Range<Int>,
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    self.replaceSubrange(subrange, copying: newElements)
  }

  @available(*, deprecated, renamed: "replace(_:copying:)")
  @inlinable
  public mutating func replace(
    removing subrange: Range<Int>,
    copying newElements: Span<Element>
  ) {
    replaceSubrange(subrange, copying: newElements)
  }

  @available(*, deprecated, renamed: "replace(_:copying:)")
  @inlinable
  public mutating func replace(
    removing subrange: Range<Int>,
    copying newElements: __owned some Collection<Element>
  ) {
    replaceSubrange(subrange, copying: newElements)
  }
}
