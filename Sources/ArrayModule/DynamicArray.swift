//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(<6.2) || (compiler(<6.3) && os(Windows)) // FIXME: [2025-08-17] Windows has no 6.2 snapshot with OutputSpan

/// A dynamically self-resizing, heap allocated, noncopyable array
/// of potentially noncopyable elements.
@frozen
@available(*, unavailable, message: "DynamicArray requires a Swift 6.2 toolchain")
public struct DynamicArray<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: RigidArray<Element>

  @inlinable
  public init() {
    fatalError()
  }
}

#else

/// A dynamically self-resizing, heap allocated, noncopyable array of
/// potentially noncopyable elements.
///
/// `DynamicArray` instances automatically resize their underlying storage as
/// needed to accommodate newly inserted items, using a geometric growth curve.
/// This frees code using `DynamicArray` from having to allocate enough
/// capacity in advance; on the other hand, it makes it difficult to tell
/// when and where such reallocations may happen.
///
/// For example, appending an element to a dynamic array has highly variable
/// complexity; often, it runs at a constant cost, but if the operation has to
/// resize storage, then the cost of an individual append suddenly becomes
/// proportional to the size of the whole array.
///
/// The geometric growth curve allows the cost of such latency spikes to
/// get amortized across repeated invocations, bringing the average cost back
/// to O(1); but they make this construct less suitable for use cases that
/// expect predictable, consistent performance on every operation.
///
/// Implicit growth also makes it more difficult to predict/analyze the amount
/// of memory an algorithm would need. Developers targeting environments with
/// stringent limits on heap allocations may prefer to avoid using dynamically
/// resizing array types as a matter of policy. The type `RigidArray` provides
/// a fixed-capacity array variant that caters specifically for these use cases,
/// trading ease-of-use for more consistent/predictable execution.
@frozen
public struct DynamicArray<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: RigidArray<Element>

  @inlinable
  public init() {
    _storage = .init(capacity: 0)
  }
}
extension DynamicArray: Sendable where Element: Sendable & ~Copyable {}

//MARK: - Initializers

extension DynamicArray where Element: ~Copyable {
  @inlinable
  public init(capacity: Int) {
    _storage = .init(capacity: capacity)
  }
}

extension DynamicArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @inlinable
  public init<E: Error>(
    capacity: Int,
    initializedWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init(capacity: capacity)
    try edit(body)
  }
}

extension DynamicArray where Element: ~Copyable {
  @inlinable
  public init(consuming storage: consuming RigidArray<Element>) {
    self._storage = storage
  }
}

extension DynamicArray /*where Element: Copyable*/ {
  /// Creates a new array containing the specified number of a single,
  /// repeated value.
  ///
  /// - Parameters:
  ///   - repeatedValue: The element to repeat.
  ///   - count: The number of times to repeat the value passed in the
  ///     `repeating` parameter. `count` must be zero or greater.
  public init(repeating repeatedValue: Element, count: Int) {
    self.init(consuming: RigidArray(repeating: repeatedValue, count: count))
  }
}

extension DynamicArray /*where Element: Copyable*/ {
  @_alwaysEmitIntoClient
  @inline(__always)
  public init(capacity: Int? = nil, copying contents: some Sequence<Element>) {
    self.init(capacity: capacity ?? 0)
    self.append(copying: contents)
  }
}

//MARK: - Basics

extension DynamicArray where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public var capacity: Int { _storage.capacity }

  @inlinable
  @inline(__always)
  public var freeCapacity: Int { _storage.capacity - _storage.count }
}

//MARK: - Span creation

extension DynamicArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  public var span: Span<Element> {
    @_lifetime(borrow self)
    @inlinable
    get {
      _storage.span
    }
  }

  @available(SwiftStdlib 5.0, *)
  public var mutableSpan: MutableSpan<Element> {
    @_lifetime(&self)
    @inlinable
    mutating get {
      _storage.mutableSpan
    }
  }
}

extension DynamicArray where Element: ~Copyable {
  /// Arbitrarily edit the storage underlying this array by invoking a
  /// user-supplied closure with a mutable `OutputSpan` view over it.
  /// This method calls its function argument precisely once, allowing it to
  /// arbitrarily modify the contents of the output span it is given.
  /// The argument is free to add, remove or reorder any items; however,
  /// it is not allowed to replace the span or change its capacity.
  ///
  /// When the function argument finishes (whether by returning or throwing an
  /// error) the rigid array instance is updated to match the final contents of
  /// the output span.
  ///
  /// - Parameter body: A function that edits the contents of this array through
  ///    an `OutputSpan` argument. This method invokes this function
  ///    precisely once.
  /// - Returns: This method returns the result of its function argument.
  /// - Complexity: Adds O(1) overhead to the complexity of the function
  ///    argument.
  @available(SwiftStdlib 5.0, *)
  @inlinable @inline(__always)
  public mutating func edit<E: Error, R: ~Copyable>(
    _ body: (inout OutputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    try _storage.edit(body)
  }
}

//MARK: - Random-access & mutable container primitives

extension DynamicArray where Element: ~Copyable {
  public typealias Index = Int

  @inlinable
  @inline(__always)
  public var isEmpty: Bool { _storage.isEmpty }

  @inlinable
  @inline(__always)
  public var count: Int { _storage.count }

  @inlinable
  @inline(__always)
  public var startIndex: Int { _storage.startIndex }

  @inlinable
  @inline(__always)
  public var endIndex: Int { _storage.count }

  @inlinable
  @inline(__always)
  public var indices: Range<Int> { _storage.indices }

  @inlinable
  public subscript(position: Int) -> Element {
    unsafeAddress {
      _storage._ptr(to: position)
    }
    unsafeMutableAddress {
      _storage._mutablePtr(to: position)
    }
  }
}

extension DynamicArray where Element: ~Copyable {
  @inlinable
  public mutating func swapAt(_ i: Int, _ j: Int) {
    _storage.swapAt(i, j)
  }
}

extension DynamicArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @inlinable
  @_lifetime(borrow self)
  public func span(after index: inout Int) -> Span<Element> {
    _storage.span(after: &index)
  }

  @available(SwiftStdlib 5.0, *)
  @inlinable
  @_lifetime(borrow self)
  public func span(before index: inout Int) -> Span<Element> {
    _storage.span(before: &index)
  }
}

extension DynamicArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @_lifetime(&self)
  public mutating func mutableSpan(
    after index: inout Int
  ) -> MutableSpan<Element> {
    _storage.mutableSpan(after: &index)
  }

  @available(SwiftStdlib 5.0, *)
  @_lifetime(&self)
  public mutating func mutableSpan(
    before index: inout Int
  ) -> MutableSpan<Element> {
    _storage.mutableSpan(before: &index)
  }
}

//MARK: - Resizing

@inlinable
@_transparent
internal func _growDynamicArrayCapacity(_ capacity: Int) -> Int {
  2 * capacity
}

extension DynamicArray where Element: ~Copyable {
  @inlinable @inline(never)
  public mutating func reallocate(capacity: Int) {
    _storage.reallocate(capacity: capacity)
  }

  @inlinable @inline(never)
  public mutating func reserveCapacity(_ n: Int) {
    _storage.reserveCapacity(n)
  }

  @inlinable
  @_transparent
  public mutating func _ensureFreeCapacity(_ freeCapacity: Int) {
    guard _storage.freeCapacity < freeCapacity else { return }
    _ensureFreeCapacitySlow(freeCapacity)
  }

  @inlinable
  @_transparent
  internal func _grow(freeCapacity: Int) -> Int {
    Swift.max(
      count + freeCapacity,
      _growDynamicArrayCapacity(capacity))
  }

  @inlinable
  internal mutating func _ensureFreeCapacitySlow(_ freeCapacity: Int) {
    let newCapacity = _grow(freeCapacity: freeCapacity)
    reallocate(capacity: newCapacity)
  }
}

//MARK: - Removal operations

extension DynamicArray where Element: ~Copyable {
  /// Removes all elements from the array, optionally preserving its
  /// allocated capacity.
  ///
  /// - Complexity: O(*n*), where *n* is the original count of the array.
  @inlinable
  @inline(__always)
  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    if keepCapacity {
      _storage.removeAll()
    } else {
      _storage = RigidArray(capacity: 0)
    }
  }

  /// Removes and returns the last element of the array.
  ///
  /// The array must not be empty.
  ///
  /// - Returns: The last element of the original array.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func removeLast() -> Element {
    _storage.removeLast()
  }

  /// Removes and discards the specified number of elements from the end of the
  /// array.
  ///
  /// Attempting to remove more elements than exist in the array triggers a
  /// runtime error.
  ///
  /// - Parameter k: The number of elements to remove from the array.
  ///   `k` must be greater than or equal to zero and must not exceed
  ///    the count of the array.
  ///
  /// - Complexity: O(`k`)
  @inlinable
  public mutating func removeLast(_ k: Int) {
    _storage.removeLast(k)
  }

  /// Removes and returns the element at the specified position.
  ///
  /// All the elements following the specified position are moved to close the
  /// gap.
  ///
  /// - Parameter i: The position of the element to remove. `index` must be
  ///   a valid index of the array that is not equal to the end index.
  /// - Returns: The removed element.
  ///
  /// - Complexity: O(`self.count`)
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    _storage.remove(at: index)
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// All the elements following the specified subrange are moved to close the
  /// resulting gap.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds
  ///   of the range must be valid indices of the array.
  ///
  /// - Complexity: O(`self.count`)
  @inlinable
  public mutating func removeSubrange(_  bounds: Range<Int>) {
    _storage.removeSubrange(bounds)
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds
  ///   of the range must be valid indices of the array.
  ///
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  public mutating func removeSubrange(_  bounds: some RangeExpression<Int>) {
    // FIXME: Remove this in favor of a standard algorithm.
    removeSubrange(bounds.relative(to: indices))
  }
}

extension DynamicArray where Element: ~Copyable {
  /// Removes and returns the last element of the array, if there is one.
  ///
  /// - Returns: The last element of the array if the array is not empty;
  ///    otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func popLast() -> Element? {
    if isEmpty { return nil }
    return removeLast()
  }
}

//MARK: - Append operations

extension DynamicArray where Element: ~Copyable {
  /// Adds an element to the end of the array.
  ///
  /// If the array does not have sufficient capacity to hold any more elements,
  /// then this reallocates the array's storage to grow its capacity.
  ///
  /// - Parameter item: The element to append to the collection.
  ///
  /// - Complexity: O(1) when amortized over many invocations on the same array
  @inlinable
  public mutating func append(_ item: consuming Element) {
    _ensureFreeCapacity(1)
    _storage.append(item)
  }
}

extension DynamicArray where Element: ~Copyable {
  /// Moves the elements of a buffer to the end of this array, leaving the
  /// buffer uninitialized.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// buffer, then this reallocates the array's storage to grow its capacity.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
  ///
  /// - Complexity: O(`items.count`) when amortized over many invocations on
  ///     the same array
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    _ensureFreeCapacity(items.count)
    _storage.append(moving: items)
  }

  /// Appends the elements of a given array to the end of this array by moving
  /// them between the containers. On return, the input array becomes empty, but
  /// it is not destroyed, and it preserves its original storage capacity.
  ///
  /// If the target array does not have sufficient capacity to hold all items
  /// in the source array, then this automatically grows the target array's
  /// capacity.
  ///
  /// - Parameters
  ///    - items: An array whose items to move to the end of this array.
  ///
  /// - Complexity: O(`items.count`) when amortized over many invocations on
  ///     the same array
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout RigidArray<Element>
  ) {
    // FIXME: Remove this in favor of a generic algorithm over range-replaceable containers
    _ensureFreeCapacity(items.count)
    _storage.append(moving: &items)
  }
}

extension DynamicArray where Element: ~Copyable {
  /// Appends the elements of a given container to the end of this array by
  /// consuming the source container.
  ///
  /// If the target array does not have sufficient capacity to hold all items
  /// in the source array, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An array whose items to move to the end of this array.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  public mutating func append(
    consuming items: consuming RigidArray<Element>
  ) {
    // FIXME: Remove this in favor of a generic algorithm over consumable containers
    var items = items
    self.append(moving: &items)
  }
}

extension DynamicArray {
  /// Copies the elements of a buffer to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the array.
  ///
  /// - Complexity: O(`newElements.count`) when amortized over many
  ///     invocations on the same array.
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    _ensureFreeCapacity(newElements.count)
    unsafe _storage.append(copying: newElements)
  }

  /// Copies the elements of a buffer to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the array.
  ///
  /// - Complexity: O(`newElements.count`) when amortized over many
  ///     invocations on the same array.
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.append(copying: UnsafeBufferPointer(newElements))
  }

  /// Copies the elements of a span to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: A span whose contents to copy into the array.
  ///
  /// - Complexity: O(`newElements.count`) when amortized over many
  ///     invocations on the same array.
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: Span<Element>) {
    _ensureFreeCapacity(newElements.count)
    _storage.append(copying: newElements)
  }

  /// Copies the elements of a sequence to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity. This
  /// reallocation can happen multiple times.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the array.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`, when
  ///     amortized over many invocations over the same array.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
      _ensureFreeCapacity(buffer.count)
      unsafe _storage.append(copying: buffer)
      return
    }
    if done != nil { return }

    _ensureFreeCapacity(newElements.underestimatedCount)
    var it = _storage._append(prefixOf: newElements)
    while let item = it.next() {
      _ensureFreeCapacity(1)
      _storage.append(item)
    }
  }
}

//MARK: - Insert operations

extension DynamicArray where Element: ~Copyable {
  /// Inserts a new element into the array at the specified position.
  ///
  /// If the array does not have sufficient capacity to hold any more elements,
  /// then this reallocates storage to extend its capacity.
  ///
  /// The new element is inserted before the element currently at the specified
  /// index. If you pass the array's `endIndex` as the `index` parameter, then
  /// the new element is appended to the container.
  ///
  /// All existing elements at or following the specified position are moved to
  /// make room for the new item.
  ///
  /// - Parameter item: The new element to insert into the array.
  /// - Parameter i: The position at which to insert the new element.
  ///   `index` must be a valid index in the array.
  ///
  /// - Complexity: O(`self.count`)
  @inlinable
  public mutating func insert(_ item: consuming Element, at index: Int) {
    precondition(index >= 0 && index <= count)
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(1)
    _storage.insert(item, at: index)
  }
}

extension DynamicArray where Element: ~Copyable {
  /// Moves the elements of a fully initialized buffer into this array,
  /// starting at the specified position, and leaving the buffer
  /// uninitialized.
  ///
  /// If the array does not have sufficient capacity to hold all elements,
  /// then this reallocates storage to extend its capacity.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(items.count)
    _storage.insert(moving: items, at: index)
  }

  /// Inserts the elements of a given array into the given position in this
  /// array by moving them between the containers. On return, the input array
  /// becomes empty, but it is not destroyed, and it preserves its original
  /// storage capacity.
  ///
  /// If the array does not have sufficient capacity to hold all elements,
  /// then this reallocates storage to extend its capacity.
  ///
  /// - Parameters
  ///    - items: An array whose contents to move into `self`.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout RigidArray<Element>,
    at index: Int
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(items.count)
    _storage.insert(moving: &items, at: index)
  }
}

extension DynamicArray where Element: ~Copyable {
  /// Inserts the elements of a given array into the given position in this
  /// array by consuming the source container.
  ///
  /// If the array does not have sufficient capacity to hold all elements,
  /// then this reallocates storage to extend its capacity.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    consuming items: consuming RigidArray<Element>,
    at index: Int
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(items.count)
    _storage.insert(consuming: items, at: index)
  }
}

extension DynamicArray {
  /// Copyies the elements of a fully initialized buffer pointer into this
  /// array at the specified position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the array’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the array.
  ///
  /// All existing elements at or following the specified position are moved to
  /// make room for the new item.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array. The buffer
  ///       must be fully initialized.
  ///    - index: The position at which to insert the new elements. It must be
  ///       a valid index of the array.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  public mutating func insert(
    copying newElements: UnsafeBufferPointer<Element>, at index: Int
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count)
    unsafe _storage.insert(copying: newElements, at: index)
  }

  /// Copyies the elements of a fully initialized buffer pointer into this
  /// array at the specified position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the array’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the array.
  ///
  /// All existing elements at or following the specified position are moved to
  /// make room for the new item.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array. The buffer
  ///       must be fully initialized.
  ///    - index: The position at which to insert the new elements. It must be
  ///       a valid index of the array.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  public mutating func insert(
    copying newElements: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) {
    unsafe self.insert(copying: UnsafeBufferPointer(newElements), at: index)
  }

  /// Copies the elements of a span into this array at the specified position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the array’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the array.
  ///
  /// All existing elements at or following the specified position are moved to
  /// make room for the new item.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @available(SwiftStdlib 6.2, *)
  @inlinable
  public mutating func insert(
    copying newElements: Span<Element>, at index: Int
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count)
    _storage.insert(copying: newElements, at: index)
  }

  /// Copies the elements of a collection into this array at the specified
  /// position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the array’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the array.
  ///
  /// All existing elements at or following the specified position are moved
  /// to make room for the new item.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  public mutating func insert(
    copying newElements: some Collection<Element>, at index: Int
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    let newCount = newElements.count
    _ensureFreeCapacity(newCount)
    _storage._insertCollection(
      at: index, copying: newElements, newCount: newCount)
  }
}

//MARK: - Range replacement

extension DynamicArray where Element: ~Copyable {
  /// Replaces the specified range of elements by moving the elements of a
  /// fully initialized buffer into their place. On return, the buffer is left
  /// in an uninitialized state.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: A fully initialized buffer whose contents to move into
  ///     the array.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving newElements: UnsafeMutableBufferPointer<Element>,
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count - subrange.count)
    _storage.replaceSubrange(subrange, moving: newElements)
  }

  /// Replaces the specified range of elements by moving the elements of a
  /// another array into their place.  On return, the source array
  /// becomes empty, but it is not destroyed, and it preserves its original
  /// storage capacity.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: An array whose contents to move into `self`.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving newElements: inout RigidArray<Element>,
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count - subrange.count)
    _storage.replaceSubrange(subrange, moving: &newElements)
  }
}

extension DynamicArray where Element: ~Copyable {
  /// Replaces the specified range of elements by moving the elements of a
  /// given array into their place, consuming it in the process.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: An array whose contents to move into `self`.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    consuming newElements: consuming RigidArray<Element>,
  ) {
    replaceSubrange(subrange, moving: &newElements)
  }
}

extension DynamicArray {
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///   *m* is the count of `newElements`.
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count)
    unsafe _storage.replaceSubrange(subrange, copying: newElements)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///   *m* is the count of `newElements`.
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.replaceSubrange(
      subrange, copying: UnsafeBufferPointer(newElements))
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given span.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length span as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///   *m* is the count of `newElements`.
  @available(SwiftStdlib 6.2, *)
  @inlinable
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: Span<Element>
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count)
    _storage.replaceSubrange(subrange, copying: newElements)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given collection.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length collection as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///   *m* is the count of `newElements`.
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: __owned some Collection<Element>
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    let c = newElements.count
    _ensureFreeCapacity(c)
    _storage._replaceSubrange(
      subrange, copyingCollection: newElements, newCount: c)
  }
}
#endif
