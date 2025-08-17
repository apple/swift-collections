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


#if compiler(<6.2)
/// A fixed capacity, heap allocated, noncopyable array of potentially
/// noncopyable elements.
@frozen
@available(*, unavailable, message: "RigidArray requires a Swift 6.2 toolchain")
public struct RigidArray<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: UnsafeMutableBufferPointer<Element>

  @usableFromInline
  internal var _count: Int

  deinit {
    _storage.extracting(0 ..< _count).deinitialize()
    _storage.deallocate()
  }

  public init() {
    fatalError()
  }
}

#else

/// A fixed capacity, heap allocated, noncopyable array of potentially
/// noncopyable elements.
///
/// `RigidArray` instances are created with a certain maximum capacity. Elements
/// can be added to the array up to that capacity, but no more: trying to add an
/// item to a full array results in a runtime trap.
///
///      var items = RigidArray<Int>(capacity: 2)
///      items.append(1)
///      items.append(2)
///      items.append(3) // Runtime error: RigidArray capacity overflow
///
/// Rigid arrays provide convenience properties to help verify that it has
/// enough available capacity: `isFull` and `freeCapacity`.
///
///     guard items.freeCapacity >= 4 else { throw CapacityOverflow() }
///     items.append(copying: newItems)
///
/// It is possible to extend or shrink the capacity of a rigid array instance,
/// but this needs to be done explicitly, with operations dedicated to this
/// purpose (such as ``reserveCapacity`` and ``reallocate(capacity:)``).
/// The array never resizes itself automatically.
///
/// It therefore requires careful manual analysis or up front runtime capacity
/// checks to prevent the array from overflowing its storage. This makes
/// this type more difficult to use than a dynamic array. However, it allows
/// this construct to provide predictably stable performance.
///
/// This trading of usability in favor of stable performance limits `RigidArray`
/// to the most resource-constrained of use cases, such as space-constrained
/// environments that require carefully accounting of every heap allocation, or
/// time-constrained applications that cannot accommodate unexpected latency
/// spikes due to a reallocation getting triggered at an inopportune moment.
///
/// For use cases outside of these narrow domains, we generally recommmend
/// the use of ``DynamicArray`` rather than `RigidArray`.
@safe
@frozen
public struct RigidArray<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: UnsafeMutableBufferPointer<Element>

  @usableFromInline
  internal var _count: Int

  deinit {
    unsafe _storage.extracting(0 ..< _count).deinitialize()
    unsafe _storage.deallocate()
  }

  /// Initializes a new rigid array with the specified capacity and no elements.
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

  /// Initializes a new rigid array with zero capacity and no elements.
  @inlinable
  public init() {
    unsafe _storage = .init(start: nil, count: 0)
    _count = 0
  }
}
extension RigidArray: @unchecked Sendable where Element: Sendable & ~Copyable {}

//MARK: - Initializers

extension RigidArray where Element: ~Copyable {
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

  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    capacity: Int? = nil,
    copying contents: some Collection<Element>
  ) {
    self.init(capacity: capacity ?? contents.count)
    self.append(copying: contents)
  }
}

// FIXME: init(moving:), init(consuming:)

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
  @available(SwiftStdlib 5.0, *)
  public var span: Span<Element> {
    @_lifetime(borrow self)
    @inlinable
    get {
      let result = unsafe Span(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, borrowing: self)
    }
  }

  @available(SwiftStdlib 5.0, *)
  public var mutableSpan: MutableSpan<Element> {
    @_lifetime(&self)
    @inlinable
    mutating get {
      let result = unsafe MutableSpan(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, mutating: &self)
    }
  }

  @available(SwiftStdlib 5.0, *)
  @inlinable
  @_lifetime(borrow self)
  internal func _span(in range: Range<Int>) -> Span<Element> {
    span.extracting(range)
  }

  @available(SwiftStdlib 5.0, *)
  @inlinable
  @_lifetime(&self)
  internal mutating func _mutableSpan(
    in range: Range<Int>
  ) -> MutableSpan<Element> {
    let result = unsafe MutableSpan(_unsafeElements: _items.extracting(range))
    return unsafe _overrideLifetime(result, mutating: &self)
  }
}

extension RigidArray where Element: ~Copyable {
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
  @inlinable
  public mutating func edit<E: Error, R: ~Copyable>(
    _ body: (inout OutputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    var span = OutputSpan(buffer: _storage, initializedCount: _count)
    defer {
      _count = span.finalize(for: _storage)
      span = OutputSpan()
    }
    return try body(&span)
  }

  // FIXME: Stop using and remove this in favor of `edit`
  @unsafe
  @inlinable
  internal mutating func _unsafeEdit<E: Error, R: ~Copyable>(
    _ body: (UnsafeMutableBufferPointer<Element>, inout Int) throws(E) -> R
  ) throws(E) -> R {
    defer { precondition(_count >= 0 && _count <= capacity) }
    return unsafe try body(_storage, &_count)
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

//MARK: - Random-access & mutable container primitives

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
}

extension RigidArray where Element: ~Copyable {
  @inlinable @inline(__always)
  internal func _ptr(to index: Int) -> UnsafePointer<Element> {
    precondition(index >= 0 && index < _count, "Index out of bounds")
    let p = _storage.baseAddress.unsafelyUnwrapped.advanced(by: index)
    return UnsafePointer(p)
  }

  @inlinable @inline(__always)
  internal mutating func _mutablePtr(
    to index: Int
  ) -> UnsafeMutablePointer<Element> {
    precondition(index >= 0 && index < _count, "Index out of bounds")
    return _storage.baseAddress.unsafelyUnwrapped.advanced(by: index)
  }

  @inlinable
  public subscript(position: Int) -> Element {
    unsafeAddress {
      _ptr(to: position)
    }
    unsafeMutableAddress {
      _mutablePtr(to: position)
    }
  }
}

extension RigidArray where Element: ~Copyable {
  @inlinable
  public mutating func swapAt(_ i: Int, _ j: Int) {
    precondition(
      i >= 0 && i < _count && j >= 0 && j < _count,
      "Index out of bounds")
    unsafe _items.swapAt(i, j)
  }
}

extension RigidArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @inlinable
  @_lifetime(borrow self)
  public func span(after index: inout Int) -> Span<Element> {
    _span(in: _contiguousSubrange(following: &index))
  }

  @available(SwiftStdlib 5.0, *)
  @inlinable
  @_lifetime(borrow self)
  public func span(before index: inout Int) -> Span<Element> {
    _span(in: _contiguousSubrange(preceding: &index))
  }
}

extension RigidArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @_lifetime(&self)
  public mutating func mutableSpan(
    after index: inout Int
  ) -> MutableSpan<Element> {
    _mutableSpan(in: _contiguousSubrange(following: &index))
  }

  @available(SwiftStdlib 5.0, *)
  @_lifetime(&self)
  public mutating func mutableSpan(
    before index: inout Int
  ) -> MutableSpan<Element> {
    _mutableSpan(in: _contiguousSubrange(preceding: &index))
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
  @unsafe
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

  /// Removes and discards the specified number of elements from the end of the
  /// array.
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

//MARK: - Append operations

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

  /// Adds an element to the end of the array, if possible.
  ///
  /// If the array does not have sufficient capacity to hold any more elements,
  /// then this returns the given item without appending it; otherwise it
  /// returns nil.
  ///
  /// - Parameter item: The element to append to the collection.
  /// - Returns: `item` if the array is full; otherwise nil.
  ///
  /// - Complexity: O(1)
  @inlinable
  public mutating func pushLast(_ item: consuming Element) -> Element? {
    // FIXME: Remove this in favor of a standard algorithm.
    if isFull { return item }
    append(item)
    return nil
  }
}

extension RigidArray where Element: ~Copyable {
  /// Moves the elements of a buffer to the end of this array, leaving the
  /// buffer uninitialized.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    precondition(items.count <= freeCapacity, "RigidArray capacity overflow")
    guard items.count > 0 else { return }
    let c = unsafe _freeSpace._moveInitializePrefix(from: items)
    assert(c == items.count)
    _count &+= items.count
  }

  /// Appends the elements of a given array to the end of this array by moving
  /// them between the containers. On return, the input array becomes empty, but
  /// it is not destroyed, and it preserves its original storage capacity.
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
    moving items: inout RigidArray<Element>
  ) {
    // FIXME: Remove this in favor of a generic algorithm over range-replaceable containers
    unsafe items._unsafeEdit { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.append(moving: source)
      count = 0
    }
  }
}

extension RigidArray where Element: ~Copyable {
  /// Appends the elements of a given container to the end of this array by
  /// consuming the source container.
  ///
  /// If the target array does not have sufficient capacity to hold all items
  /// in the source array, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
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
  @available(SwiftStdlib 5.0, *)
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
}

//MARK: - Insert operations


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

extension RigidArray where Element: ~Copyable {
  /// Moves the elements of a fully initialized buffer into this array,
  /// starting at the specified position, and leaving the buffer
  /// uninitialized.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
  ///
  /// - Complexity: O(`count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) {
    precondition(items.count <= freeCapacity, "RigidArray capacity overflow")
    guard items.count > 0 else { return }
    let target = unsafe _openGap(at: index, count: items.count)
    let c = unsafe target._moveInitializePrefix(from: items)
    assert(c == items.count)
    _count &+= items.count
  }

  /// Inserts the elements of a given array into the given position in this
  /// array by moving them between the containers. On return, the input array
  /// becomes empty, but it is not destroyed, and it preserves its original
  /// storage capacity.
  ///
  /// If the target array does not have sufficient capacity to hold all items
  /// in the source array, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An array whose contents to move into `self`.
  ///
  /// - Complexity: O(`count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout RigidArray<Element>,
    at index: Int
  ) {
    precondition(items.count <= freeCapacity, "RigidArray capacity overflow")
    guard items.count > 0 else { return }
    unsafe items._unsafeEdit { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.insert(moving: source, at: index)
      count = 0
    }
  }
}

extension RigidArray where Element: ~Copyable {
  /// Inserts the elements of a given array into the given position in this
  /// array by consuming the source container.
  ///
  /// If the target array does not have sufficient capacity to hold all items
  /// in the source array, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
  ///
  /// - Complexity: O(`count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    consuming items: consuming RigidArray<Element>,
    at index: Int
  ) {
    var items = items
    self.insert(moving: &items, at: index)
  }
}

extension RigidArray {
  /// Copies the elements of a fully initialized buffer pointer into this
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
  /// - Complexity: O(`count` + `newElements.count`)
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

  /// Copies the elements of a fully initialized buffer pointer into this
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
  /// - Complexity: O(`count` + `newElements.count`)
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
  /// - Complexity: O(`count` + `newElements.count`)
  @available(SwiftStdlib 5.0, *)
  @inlinable
  public mutating func insert(
    copying newElements: Span<Element>, at index: Int
  ) {
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
  /// - Complexity: O(`count` + `newElements.count`)
  @inlinable
  @inline(__always)
  public mutating func insert(
    copying newElements: some Collection<Element>, at index: Int
  ) {
    _insertCollection(
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
  @unsafe
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

extension RigidArray where Element: ~Copyable {
  /// Replaces the specified range of elements by moving the elements of a
  /// fully initialized buffer into their place. On return, the buffer is left
  /// in an uninitialized state.
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
    let gap = unsafe _gapForReplacement(
      of: subrange, withNewCount: newElements.count)
    let c = unsafe gap._moveInitializePrefix(from: newElements)
    assert(c == newElements.count)
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
    unsafe newElements._unsafeEdit { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.replaceSubrange(subrange, moving: source)
      count = 0
    }
  }
}

extension RigidArray where Element: ~Copyable {
  /// Replaces the specified range of elements by moving the elements of a
  /// given array into their place, consuming it in the process.
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
  /// - Complexity: O(`self.count` + `newElements.count`)
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
  /// - Complexity: O(`self.count` + `newElements.count`)
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
  /// - Complexity: O(`self.count` + `newElements.count`)
  @available(SwiftStdlib 5.0, *)
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
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: __owned some Collection<Element>
  ) {
    _replaceSubrange(
      subrange, copyingCollection: newElements, newCount: newElements.count)
  }
}
#endif
