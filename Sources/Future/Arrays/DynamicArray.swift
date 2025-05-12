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

/// A dynamically self-resizing, heap allocated, noncopyable array
/// of potentially noncopyable elements.
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
  public init(consuming storage: consuming RigidArray<Element>) {
    self._storage = storage
  }

  @inlinable
  public init(capacity: Int) {
    _storage = .init(capacity: capacity)
  }

  // FIXME: Remove in favor of an OutputSpan-based initializer
  @inlinable
  public init(count: Int, initializedWith generator: (Int) -> Element) {
    self.init(capacity: count, count: count, initializedWith: generator)
  }

  // FIXME: Remove in favor of an OutputSpan-based initializer
  @inlinable
  public init(
    capacity: Int, count: Int, initializedWith generator: (Int) -> Element
  ) {
    _storage = .init(
      capacity: capacity, count: count, initializedWith: generator)
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

  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & ~Copyable & ~Escapable>(
    capacity: Int? = nil,
    copying contents: borrowing C
  ) {
    self.init(consuming: RigidArray(capacity: capacity, copying: contents))
  }

  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & Sequence<Element>>(
    capacity: Int? = nil,
    copying contents: C
  ) {
    self.init(consuming: RigidArray(capacity: capacity, copying: contents))
  }
}

//MARK: - Basics

extension DynamicArray where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public var capacity: Int { _storage.capacity }

  @inlinable
  @inline(__always)
  public var freeCapacity: Int { capacity - count }
}

//MARK: - Span creation

extension DynamicArray where Element: ~Copyable {
  @available(SwiftStdlib 6.2, *)
  public var span: Span<Element> {
    @lifetime(borrow self)
    @inlinable
    get {
      _storage.span
    }
  }

#if compiler(>=6.2) && $InoutLifetimeDependence
  @available(SwiftStdlib 6.2, *)
  public var mutableSpan: MutableSpan<Element> {
    @lifetime(&self)
    @inlinable
    mutating get {
      _storage.mutableSpan
    }
  }
#else
  @available(SwiftStdlib 6.2, *)
  public var mutableSpan: MutableSpan<Element> {
    @lifetime(borrow self)
    @inlinable
    mutating get {
      _storage.mutableSpan
    }
  }
#endif
}

//MARK: RandomAccessContainer conformance

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
  public var indices: Range<Int> { _storage.indices}

  @inlinable
  @inline(__always)
  @lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    _storage.borrowElement(at: index)
  }
}

@available(SwiftStdlib 6.2, *)
extension DynamicArray: RandomAccessContainer where Element: ~Copyable {
  @inlinable
  @lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Span<Element> {
    _storage.nextSpan(after: &index)
  }

  @inlinable
  @lifetime(borrow self)
  public func previousSpan(before index: inout Int) -> Span<Element> {
    _storage.previousSpan(before: &index)
  }
}

// MARK: - MutableContainer conformance

extension DynamicArray where Element: ~Copyable {
  @inlinable
#if compiler(>=6.2) && $InoutLifetimeDependence
  @lifetime(&self)
#else
  @lifetime(borrow self)
#endif
  public mutating func mutateElement(at index: Int) -> Inout<Element> {
    _storage.mutateElement(at: index)
  }

  @inlinable
  public mutating func swapAt(_ i: Int, _ j: Int) {
    _storage.swapAt(i, j)
  }
}

extension DynamicArray: MutableContainer where Element: ~Copyable {
  @available(SwiftStdlib 6.2, *)
#if compiler(>=6.2) && $InoutLifetimeDependence
  @lifetime(&self)
#else
  @lifetime(borrow self)
#endif
  public mutating func nextMutableSpan(after index: inout Int) -> MutableSpan<Element> {
    _storage.nextMutableSpan(after: &index)
  }
}

//MARK: Unsafe access

extension DynamicArray where Element: ~Copyable {
  // FIXME: Replace this with an OutputSpan-based mutator
  @inlinable
  public mutating func withUnsafeMutableBufferPointer<E: Error, R: ~Copyable>(
    _ body: (UnsafeMutableBufferPointer<Element>, inout Int) throws(E) -> R
  ) throws(E) -> R {
    unsafe try _storage.withUnsafeMutableBufferPointer(body)
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
  internal mutating func _ensureFreeCapacitySlow(_ freeCapacity: Int) {
    let newCapacity = Swift.max(
      count + freeCapacity,
      _growDynamicArrayCapacity(capacity))
    reallocate(capacity: newCapacity)
  }
}

//MARK: - Removal operations

extension DynamicArray where Element: ~Copyable {
  /// Removes all elements from the array, preserving its allocated capacity.
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

  /// Removes the specified number of elements from the end of the array.
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
  /// - Complexity: O(`count`)
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
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func removeSubrange(_  bounds: Range<Int>) {
    _storage.removeSubrange(bounds)
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds
  ///   of the range must be valid indices of the array.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func removeSubrange(_  bounds: some RangeExpression<Int>) {
    // FIXME: Remove this in favor of a standard algorithm.
    removeSubrange(bounds.relative(to: indices))
  }
}

extension DynamicArray where Element: ~Copyable {
  /// Removes all the elements that satisfy the given predicate.
  ///
  /// Use this method to remove every element in a container that meets
  /// particular criteria. The order of the remaining elements is preserved.
  ///
  /// - Parameter shouldBeRemoved: A closure that takes an element of the
  ///   sequence as its argument and returns a Boolean value indicating
  ///   whether the element should be removed from the array.
  ///
  /// - Complexity: O(`count`)
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public mutating func removeAll<E: Error>(
    where shouldBeRemoved: (borrowing Element) throws(E) -> Bool
  ) throws(E) {
    // FIXME: Remove this in favor of a standard algorithm.
    let suffixStart = try _halfStablePartition(isSuffixElement: shouldBeRemoved)
    removeSubrange(suffixStart...)
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


//MARK: - Insertion operations

extension DynamicArray where Element: ~Copyable {
  /// Adds an element to the end of the array.
  ///
  /// If the array does not have sufficient capacity to hold any more elements,
  /// then this reallocates the array's storage to extend its capacity.
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

  @available(SwiftStdlib 6.2, *)
  public mutating func _appendContainer<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C
  ) {
    var i = newElements.startIndex
    while true {
      let span = newElements.nextSpan(after: &i)
      if span.isEmpty { break }
      self.append(copying: span)
    }
  }

  /// Copies the elements of a container to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: A container whose contents to copy into the array.
  ///
  /// - Complexity: O(`newElements.count`), when amortized over many invocations
  ///    over the same array.
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public mutating func append<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C
  ) {
    _appendContainer(copying: newElements)
  }

  /// Copies the elements of a container to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: A container whose contents to copy into the array.
  ///
  /// - Complexity: O(`newElements.count`), when amortized over many invocations
  ///    over the same array.
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public mutating func append<
    C: Container<Element> & Sequence<Element>
  >(
    copying newElements: borrowing C
  ) {
    _appendContainer(copying: newElements)
  }
}

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
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func insert(_ item: consuming Element, at index: Int) {
    precondition(index >= 0 && index <= count)
    // FIXME: Avoiding moving the subsequent elements twice.
    _ensureFreeCapacity(1)
    _storage.insert(item, at: index)
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
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///     *m* is the count of `newElements`.
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
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///     *m* is the count of `newElements`.
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
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///     *m* is the count of `newElements`.
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
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///     *m* is the count of `newElements`.
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

  @available(SwiftStdlib 6.2, *)
  @inlinable
  internal mutating func _insertContainer<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    let newCount = newElements.count
    _ensureFreeCapacity(newCount)
    _storage._insertContainer(
      at: index, copying: newElements, newCount: newCount)
  }

  /// Copies the elements of a container into this array at the specified
  /// position.
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
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///    *m* is the count of `newElements`.
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    _insertContainer(copying: newElements, at: index)
  }

  /// Copies the elements of a container into this array at the specified
  /// position.
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
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///    *m* is the count of `newElements`.
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & Collection<Element>
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    _insertContainer(copying: newElements, at: index)
  }
}

//MARK: - Range replacement

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

  @available(SwiftStdlib 6.2, *)
  @inlinable
  public mutating func _replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copyingContainer newElements: borrowing C
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    let c = newElements.count
    _ensureFreeCapacity(c)
    _storage._replaceSubrange(
      subrange, copyingContainer: newElements, newCount: c)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
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
  /// Likewise, if you pass a zero-length container as the `newElements`
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
  @inline(__always)
  public mutating func replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copying newElements: borrowing C
  ) {
    _replaceSubrange(subrange, copyingContainer: newElements)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
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
  /// Likewise, if you pass a zero-length container as the `newElements`
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
  @inline(__always)
  public mutating func replaceSubrange<
    C: Container<Element> & Collection<Element>
  >(
    _ subrange: Range<Int>,
    copying newElements: borrowing C
  ) {
    _replaceSubrange(subrange, copyingContainer: newElements)
  }
}
