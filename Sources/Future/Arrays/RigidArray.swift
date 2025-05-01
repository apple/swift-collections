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

/// A manually resizable, heap allocated, noncopyable array of
/// potentially noncopyable elements.
@safe
@frozen
public struct RigidArray<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: UnsafeMutableBufferPointer<Element>

  @usableFromInline
  internal var _count: Int

  deinit {
    unsafe _storage.extracting(0 ..< count).deinitialize()
    unsafe _storage.deallocate()
  }

  @inlinable
  public init(capacity: Int) {
    precondition(capacity >= 0, "Array capacity must be nonnegative")
    if capacity > 0 {
      unsafe _storage = .allocate(capacity: capacity)
    } else {
      unsafe _storage = .init(start: nil, count: 0)
    }
    _count = 0
  }
}
extension RigidArray: @unchecked Sendable where Element: Sendable & ~Copyable {}

//MARK: - Initializers

extension RigidArray where Element: ~Copyable {
  // FIXME: Remove in favor of an OutputSpan-based initializer
  @inlinable
  public init(
    capacity: Int,
    count: Int,
    initializedWith generator: (Int) -> Element
  ) {
    precondition(
      count >= 0 && count <= capacity,
      "RigidArray capacity overflow")
    unsafe _storage = .allocate(capacity: capacity)
    for i in 0 ..< count {
      unsafe _storage.initializeElement(at: i, to: generator(i))
    }
    _count = count
  }

  // FIXME: Remove in favor of an OutputSpan-based initializer
  @inlinable
  public init(count: Int, initializedWith generator: (Int) -> Element) {
    self.init(capacity: count, count: count, initializedWith: generator)
  }
}

extension RigidArray /*where Element: Copyable*/ {
  /// Creates a new array containing the specified number of a single,
  /// repeated value.
  ///
  /// - Parameters:
  ///   - repeatedValue: The element to repeat.
  ///   - count: The number of times to repeat the value passed in the
  ///     `repeating` parameter. `count` must be zero or greater.
  public init(repeating repeatedValue: Element, count: Int) {
    self.init(capacity: count)
    unsafe _freeSpace.initialize(repeating: repeatedValue)
    _count = count
  }
}

extension RigidArray /*where Element: Copyable*/ {
  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    capacity: Int,
    copying contents: some Sequence<Element>
  ) {
    self.init(capacity: capacity)
    self.append(copying: contents)
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & Sequence<Element>>(
    capacity: Int,
    copying contents: C
  ) {
    self.init(capacity: capacity)
    self.append(copying: contents)
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    capacity: Int? = nil,
    copying contents: some Collection<Element>
  ) {
    self.init(capacity: capacity ?? contents.count)
    self.append(copying: contents)
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & ~Copyable & ~Escapable>(
    capacity: Int? = nil,
    copying contents: borrowing C
  ) {
    self.init(capacity: capacity ?? contents.count)
    self.append(copying: contents)
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & Collection<Element>>(
    capacity: Int? = nil,
    copying contents: C
  ) {
    self.init(capacity: capacity ?? contents.count)
    self.append(copying: contents)
  }
}

//MARK: - Basics

extension RigidArray where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public var capacity: Int { unsafe _storage.count }

  @inlinable
  @inline(__always)
  public var freeCapacity: Int { capacity - count }

  @inlinable
  @inline(__always)
  public var isFull: Bool { freeCapacity == 0 }
}

extension RigidArray where Element: ~Copyable {
  @inlinable
  internal var _items: UnsafeMutableBufferPointer<Element> {
    unsafe _storage.extracting(Range(uncheckedBounds: (0, _count)))
  }

  @inlinable
  internal var _freeSpace: UnsafeMutableBufferPointer<Element> {
    unsafe _storage.extracting(Range(uncheckedBounds: (_count, capacity)))
  }
}

//MARK: - Span creation

extension RigidArray where Element: ~Copyable {
  @available(SwiftCompatibilitySpan 5.0, *)
  public var span: Span<Element> {
    @lifetime(borrow self)
    @inlinable
    get {
      let result = unsafe Span(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, borrowing: self)
    }
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  public var mutableSpan: MutableSpan<Element> {
    @lifetime(&self)
    @inlinable
    mutating get {
      let result = unsafe MutableSpan(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, mutating: &self)
    }
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  @lifetime(borrow self)
  internal func _span(in range: Range<Int>) -> Span<Element> {
    span._extracting(range)
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  @lifetime(&self)
  internal mutating func _mutableSpan(
    in range: Range<Int>
  ) -> MutableSpan<Element> {
    let result = unsafe MutableSpan(_unsafeElements: _items.extracting(range))
    return unsafe _overrideLifetime(result, mutating: &self)
  }
}

extension RigidArray where Element: ~Copyable {
  @inlinable
  internal func _contiguousSubrange(following index: inout Int) -> Range<Int> {
    precondition(index >= 0 && index <= _count, "Index out of bounds")
    defer { index = _count }
    return unsafe Range(uncheckedBounds: (index, _count))
  }

  @inlinable
  internal func _contiguousSubrange(preceding index: inout Int) -> Range<Int> {
    precondition(index >= 0 && index <= _count, "Index out of bounds")
    defer { index = 0 }
    return unsafe Range(uncheckedBounds: (0, index))
  }
}

//MARK: - RandomAccessContainer and MutableContainer conformance

extension RigidArray where Element: ~Copyable {
  public typealias Index = Int

  @inlinable
  @inline(__always)
  public var isEmpty: Bool { count == 0 }

  @inlinable
  @inline(__always)
  public var count: Int { _count }

  @inlinable
  @inline(__always)
  public var startIndex: Int { 0 }

  @inlinable
  @inline(__always)
  public var endIndex: Int { count }

  @inlinable
  @inline(__always)
  public var indices: Range<Int> { unsafe Range(uncheckedBounds: (0, count)) }

  @inlinable
  @lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    precondition(index >= 0 && index < _count, "Index out of bounds")
    return unsafe Borrow(
      unsafeAddress: _storage.baseAddress.unsafelyUnwrapped.advanced(by: index),
      borrowing: self
    )
  }
}

@available(SwiftCompatibilitySpan 5.0, *)
extension RigidArray: RandomAccessContainer where Element: ~Copyable {
  @inlinable
  @lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Span<Element> {
    _span(in: _contiguousSubrange(following: &index))
  }

  @inlinable
  @lifetime(borrow self)
  public func previousSpan(before index: inout Int) -> Span<Element> {
    _span(in: _contiguousSubrange(preceding: &index))
  }
}

extension RigidArray where Element: ~Copyable {
  @inlinable
  @lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Inout<Element> {
    precondition(index >= 0 && index < _count)
    return unsafe Inout(
      unsafeAddress: _storage.baseAddress.unsafelyUnwrapped.advanced(by: index),
      mutating: &self
    )
  }

  @inlinable
  public mutating func swapAt(_ i: Int, _ j: Int) {
    precondition(
      i >= 0 && i < _count && j >= 0 && j < _count,
      "Index out of bounds")
    unsafe _items.swapAt(i, j)
  }
}

@available(SwiftCompatibilitySpan 5.0, *)
extension RigidArray: MutableContainer where Element: ~Copyable {
  @lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int
  ) -> MutableSpan<Element> {
    _mutableSpan(in: _contiguousSubrange(following: &index))
  }
}

//MARK: Unsafe access

extension RigidArray where Element: ~Copyable {
  // FIXME: Replace this with an OutputSpan-based mutator
  @inlinable
  public mutating func withUnsafeMutableBufferPointer<E: Error, R: ~Copyable>(
    _ body: (UnsafeMutableBufferPointer<Element>, inout Int) throws(E) -> R
  ) throws(E) -> R {
    defer { precondition(_count >= 0 && _count <= capacity) }
    return unsafe try body(_storage, &_count)
  }
}

//MARK: - Resizing

extension RigidArray where Element: ~Copyable {
  @inlinable
  public mutating func reallocate(capacity newCapacity: Int) {
    precondition(newCapacity >= count, "RigidArray capacity overflow")
    guard newCapacity != capacity else { return }
    let newStorage: UnsafeMutableBufferPointer<Element> = .allocate(
      capacity: newCapacity)
    let i = unsafe newStorage.moveInitialize(fromContentsOf: self._items)
    assert(i == count)
    unsafe _storage.deallocate()
    unsafe _storage = newStorage
  }

  @inlinable
  public mutating func reserveCapacity(_ n: Int) {
    guard capacity < n else { return }
    reallocate(capacity: n)
  }
}

//MARK: - Copying helpers

extension RigidArray {
  @inlinable
  public func copy() -> Self {
    copy(capacity: capacity)
  }

  @inlinable
  public func copy(capacity: Int) -> Self {
    precondition(capacity >= count, "RigidArray capacity overflow")
    var result = RigidArray<Element>(capacity: capacity)
    let initialized = unsafe result._storage.initialize(fromContentsOf: _items)
    precondition(initialized == count)
    result._count = count
    return result
  }
}


//MARK: - Opening and closing gaps

extension RigidArray where Element: ~Copyable {
  @inlinable
  internal mutating func _closeGap(
    at index: Int, count: Int
  ) {
    guard count > 0 else { return }
    let source = unsafe _storage.extracting(
      Range(uncheckedBounds: (index + count, _count)))
    let target = unsafe _storage.extracting(
      Range(uncheckedBounds: (index, index + source.count)))
    let i = unsafe target.moveInitialize(fromContentsOf: source)
    assert(i == target.endIndex)
  }

  @inlinable
  internal mutating func _openGap(
    at index: Int, count: Int
  ) -> UnsafeMutableBufferPointer<Element> {
    assert(index >= 0 && index <= _count)
    assert(count <= freeCapacity)
    guard count > 0 else { return unsafe _storage.extracting(index ..< index) }
    let source = unsafe _storage.extracting(
      Range(uncheckedBounds: (index, _count)))
    let target = unsafe _storage.extracting(
      Range(uncheckedBounds: (index + count, _count + count)))
    let i = unsafe target.moveInitialize(fromContentsOf: source)
    assert(i == target.count)
    return unsafe _storage.extracting(
      Range(uncheckedBounds: (index, index + count)))
  }
}

//MARK: - Removal operations

extension RigidArray where Element: ~Copyable {
  /// Removes all elements from the array, preserving its allocated capacity.
  ///
  /// - Complexity: O(*n*), where *n* is the original count of the array.
  @inlinable
  public mutating func removeAll() {
    unsafe _items.deinitialize()
    _count = 0
  }

  /// Removes and returns the last element of the array.
  ///
  /// The array must not be empty.
  ///
  /// - Returns: The last element of the original array.
  ///
  /// - Complexity: O(1)
  @inlinable
  @discardableResult
  public mutating func removeLast() -> Element {
    precondition(!isEmpty, "Cannot remove last element from an empty array")
    let old = unsafe _storage.moveElement(from: _count - 1)
    _count -= 1
    return old
  }

  /// Removes the specified number of elements from the end of the array.
  ///
  /// Attempting to remove more elements than exist in the array
  /// triggers a runtime error.
  ///
  /// - Parameter k: The number of elements to remove from the array.
  ///   `k` must be greater than or equal to zero and must not exceed
  ///   the count of the array.
  ///
  /// - Complexity: O(`k`)
  @inlinable
  public mutating func removeLast(_ k: Int) {
    if k == 0 { return }
    precondition(
      k >= 0 && k <= _count,
      "Count of elements to remove is out of bounds")
    unsafe _storage.extracting(
      Range(uncheckedBounds: (_count - k, _count))
    ).deinitialize()
    _count &-= k
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
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    precondition(index >= 0 && index < _count, "Index out of bounds")
    let old = unsafe _storage.moveElement(from: index)
    _closeGap(at: index, count: 1)
    _count -= 1
    return old
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
    precondition(
      bounds.lowerBound >= 0 && bounds.upperBound <= _count,
      "Subrange out of bounds")
    guard !bounds.isEmpty else { return }
    unsafe _storage.extracting(bounds).deinitialize()
    _closeGap(at: bounds.lowerBound, count: bounds.count)
    _count -= bounds.count
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds of the
  ///   range must be valid indices of the array.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func removeSubrange(_  bounds: some RangeExpression<Int>) {
    // FIXME: Remove this in favor of a standard algorithm.
    removeSubrange(bounds.relative(to: indices))
  }
}

extension RigidArray where Element: ~Copyable {
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
  @available(SwiftCompatibilitySpan 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func removeAll<E: Error>(
    where shouldBeRemoved: (borrowing Element) throws(E) -> Bool
  ) throws(E) {
    // FIXME: Remove this in favor of a standard algorithm.
    let suffixStart = try _halfStablePartition(isSuffixElement: shouldBeRemoved)
    removeSubrange(suffixStart...)
  }
}

extension RigidArray where Element: ~Copyable {
  /// Removes and returns the last element of the array, if there is one.
  ///
  /// - Returns: The last element of the array if the array is not empty;
  ///     otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func popLast() -> Element? {
    // FIXME: Remove this in favor of a standard algorithm.
    if isEmpty { return nil }
    return removeLast()
  }
}

//MARK: - Insertion operations

extension RigidArray where Element: ~Copyable {
  /// Adds an element to the end of the array.
  ///
  /// If the array does not have sufficient capacity to hold any more elements,
  /// then this triggers a runtime error.
  ///
  /// - Parameter item: The element to append to the collection.
  ///
  /// - Complexity: O(1)
  @inlinable
  public mutating func append(_ item: consuming Element) {
    precondition(!isFull, "RigidArray capacity overflow")
    unsafe _storage.initializeElement(at: _count, to: item)
    _count &+= 1
  }
}

extension RigidArray {
  /// Copies the elements of a buffer to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the array.
  ///
  /// - Complexity: O(`newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    precondition(
      newElements.count <= freeCapacity,
      "RigidArray capacity overflow")
    guard newElements.count > 0 else { return }
    unsafe _freeSpace.baseAddress.unsafelyUnwrapped.initialize(
      from: newElements.baseAddress.unsafelyUnwrapped, count: newElements.count)
    _count &+= newElements.count
  }

  /// Copies the elements of a buffer to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///        the array.
  ///
  /// - Complexity: O(`newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func append(
    copying items: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.append(copying: UnsafeBufferPointer(items))
  }

  /// Copies the elements of a span to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// span, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A span whose contents to copy into the array.
  ///
  /// - Complexity: O(`newElements.count`)
  @available(SwiftCompatibilitySpan 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func append(copying items: Span<Element>) {
    unsafe items.withUnsafeBufferPointer { source in
      unsafe self.append(copying: source)
    }
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  internal mutating func _append<S: Sequence<Element>>(
    prefixOf items: S
  ) -> S.Iterator {
    let (it, c) = unsafe items._copyContents(initializing: _freeSpace)
    _count += c
    return it
  }

  /// Copies the elements of a sequence to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// sequence, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the array.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
      unsafe self.append(copying: buffer)
      return
    }
    if done != nil { return }

    var it = self._append(prefixOf: newElements)
    precondition(it.next() == nil, "RigidArray capacity overflow")
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  internal mutating func _appendContainer<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C
  ) {
    let (copied, end) = unsafe _freeSpace._initializePrefix(
      copying: newElements)
    precondition(end == newElements.endIndex, "RigidArray capacity overflow")
    _count += copied
  }

  /// Copies the elements of a container to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// container, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A container whose contents to copy into the array.
  ///
  /// - Complexity: O(`newElements.count`)
  @available(SwiftCompatibilitySpan 5.0, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append<C: Container<Element> & ~Copyable & ~Escapable>(
    copying newElements: borrowing C
  ) {
    _appendContainer(copying: newElements)
  }

  /// Copies the elements of a container to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// container, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the array.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @available(SwiftCompatibilitySpan 5.0, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append<
    C: Container<Element> & Sequence<Element>
  >(copying newElements: C) {
    _appendContainer(copying: newElements)
  }
}

extension RigidArray where Element: ~Copyable {
  /// Inserts a new element into the array at the specified position.
  ///
  /// If the array does not have sufficient capacity to hold any more elements,
  /// then this triggers a runtime error.
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
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(!isFull, "RigidArray capacity overflow")
    if index < count {
      let source = unsafe _storage.extracting(index ..< count)
      let target = unsafe _storage.extracting(index + 1 ..< count + 1)
      let last = unsafe target.moveInitialize(fromContentsOf: source)
      assert(last == target.endIndex)
    }
    unsafe _storage.initializeElement(at: index, to: item)
    _count += 1
  }
}

extension RigidArray {
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
    guard newElements.count > 0 else { return }
    precondition(
      newElements.count <= freeCapacity,
      "RigidArray capacity overflow")
    let gap = unsafe _openGap(at: index, count: newElements.count)
    unsafe gap.baseAddress.unsafelyUnwrapped.initialize(
      from: newElements.baseAddress.unsafelyUnwrapped, count: newElements.count)
    _count += newElements.count
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///     *m* is the count of `newElements`.
  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  public mutating func insert(
    copying newElements: Span<Element>, at index: Int
  ) {
    precondition(
      newElements.count <= freeCapacity,
      "RigidArray capacity overflow")
    unsafe newElements.withUnsafeBufferPointer {
      unsafe self.insert(copying: $0, at: index)
    }
  }

  @inlinable
  internal mutating func _insertCollection(
    at index: Int,
    copying items: some Collection<Element>,
    newCount: Int
  ) {
    precondition(index >= 0 && index <= _count, "Index out of bounds")
    precondition(newCount <= freeCapacity, "RigidArray capacity overflow")
    let gap = unsafe _openGap(at: index, count: newCount)

    let done: Void? = items.withContiguousStorageIfAvailable { buffer in
      let i = unsafe gap._initializePrefix(copying: buffer)
      precondition(
        i == newCount,
        "Broken Collection: count doesn't match contents")
      _count += newCount
    }
    if done != nil { return }

    var (it, copied) = unsafe items._copyContents(initializing: gap)
    precondition(
      it.next() == nil && copied == newCount,
      "Broken Collection: count doesn't match contents")
    _count += newCount
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  internal mutating func _insertContainer<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    at index: Int,
    copying items: borrowing C,
    newCount: Int
  ) {
    precondition(index >= 0 && index <= _count, "Index out of bounds")
    precondition(newCount <= freeCapacity, "RigidArray capacity overflow")
    let target = unsafe _openGap(at: index, count: newCount)
    let (copied, end) = unsafe target._initializePrefix(copying: items)
    precondition(
      copied == newCount && end == items.endIndex,
      "Broken Container: count doesn't match contents")
    _count += newCount
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///     *m* is the count of `newElements`.
  @inlinable
  @inline(__always)
  public mutating func insert(
    copying newElements: some Collection<Element>, at index: Int
  ) {
    _insertCollection(
      at: index, copying: newElements, newCount: newElements.count)
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///    *m* is the count of `newElements`.
  @available(SwiftCompatibilitySpan 5.0, *)
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///    *m* is the count of `newElements`.
  @available(SwiftCompatibilitySpan 5.0, *)
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
}

//MARK: - Range replacement

extension RigidArray where Element: ~Copyable {
  /// Perform a range replacement up to populating the newly opened gap. This
  /// deinitializes existing elements in the specified subrange, rearranges
  /// following elements to be at their final location, and sets the container's
  /// new count.
  ///
  /// - Returns: A buffer pointer addressing the newly opened gap, to be
  ///     initialized by the caller.
  @inlinable
  internal mutating func _gapForReplacement(
    of subrange: Range<Int>, withNewCount newCount: Int
  ) -> UnsafeMutableBufferPointer<Element> {
    // FIXME: Replace this with a public variant based on OutputSpan.
    precondition(
      subrange.lowerBound >= 0 && subrange.upperBound <= _count,
      "Index range out of bounds")
    precondition(
      newCount - subrange.count <= freeCapacity,
      "RigidArray capacity overflow")
    unsafe _items.extracting(subrange).deinitialize()
    if newCount > subrange.count {
      _ = unsafe _openGap(
        at: subrange.upperBound, count: newCount - subrange.count)
    } else if newCount < subrange.count {
      _closeGap(
        at: subrange.lowerBound + newCount, count: subrange.count - newCount)
    }
    _count += newCount - subrange.count
    let gapRange = unsafe Range(
      uncheckedBounds: (subrange.lowerBound, subrange.lowerBound + newCount))
    return unsafe _storage.extracting(gapRange)
  }
}

extension RigidArray {
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    let gap = unsafe _gapForReplacement(
      of: subrange, withNewCount: newElements.count)
    let i = unsafe gap._initializePrefix(copying: newElements)
    assert(i == gap.count)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.replaceSubrange(
      subrange,
      copying: UnsafeBufferPointer(newElements))
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given span.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: Span<Element>
  ) {
    unsafe newElements.withUnsafeBufferPointer { buffer in
      unsafe self.replaceSubrange(subrange, copying: buffer)
    }
  }

  @inlinable
  internal mutating func _replaceSubrange(
    _ subrange: Range<Int>,
    copyingCollection newElements: __owned some Collection<Element>,
    newCount: Int
  ) {
    let gap = unsafe _gapForReplacement(of: subrange, withNewCount: newCount)

    let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
      let i = unsafe gap._initializePrefix(copying: buffer)
      precondition(
        i == newCount,
        "Broken Collection: count doesn't match contents")
    }
    if done != nil { return }

    var (it, copied) = unsafe newElements._copyContents(initializing: gap)
    precondition(
      it.next() == nil && copied == newCount,
      "Broken Collection: count doesn't match contents")
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given collection.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
    _replaceSubrange(
      subrange, copyingCollection: newElements, newCount: newElements.count)
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  public mutating func _replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copyingContainer newElements: borrowing C,
    newCount: Int
  ) {
    let gap = unsafe _gapForReplacement(of: subrange, withNewCount: newCount)
    let (copied, end) = unsafe gap._initializePrefix(copying: newElements)
    precondition(
      copied == newCount && end == newElements.endIndex,
      "Broken Container: count doesn't match contents")
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copying newElements: borrowing C
  ) {
    _replaceSubrange(
      subrange, copyingContainer: newElements, newCount: newElements.count)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange<
    C: Container<Element> & Collection<Element>
  >(
    _ subrange: Range<Int>,
    copying newElements: C
  ) {
    _replaceSubrange(
      subrange, copyingContainer: newElements, newCount: newElements.count)
  }
}
