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
  @inlinable
  public init(count: Int, initializedWith generator: (Int) -> Element) {
    unsafe _storage = .allocate(capacity: count)
    for i in 0 ..< count {
      unsafe _storage.initializeElement(at: i, to: generator(i))
    }
    _count = count
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
  public init(capacity: Int? = nil, copying contents: some Collection<Element>) {
    self.init(capacity: capacity ?? contents.count)
    self.append(contentsOf: contents)
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
  internal mutating func _mutableSpan(in range: Range<Int>) -> MutableSpan<Element> {
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

//MARK: - RandomAccessContainer conformance

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
  public typealias Index = Int

  @inlinable
  public var isEmpty: Bool { count == 0 }

  @inlinable
  public var count: Int { _count }

  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { count }

  @inlinable
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

  @inlinable
  public mutating func swapAt(_ i: Int, _ j: Int) {
    precondition(i >= 0 && i < _count && j >= 0 && j < _count, "Index out of bounds")
    unsafe _items.swapAt(i, j)
  }
}

//MARK: - MutableContainer conformance

@available(SwiftCompatibilitySpan 5.0, *)
extension RigidArray: MutableContainer where Element: ~Copyable {
  @lifetime(&self)
  public mutating func nextMutableSpan(after index: inout Int) -> MutableSpan<Element> {
    _mutableSpan(in: _contiguousSubrange(following: &index))
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
  public mutating func setCapacity(_ newCapacity: Int) {
    precondition(newCapacity >= count, "RigidArray capacity overflow")
    guard newCapacity != capacity else { return }
    let newStorage: UnsafeMutableBufferPointer<Element> = .allocate(capacity: newCapacity)
    let i = unsafe newStorage.moveInitialize(fromContentsOf: self._items)
    assert(i == count)
    unsafe _storage.deallocate()
    unsafe _storage = newStorage
  }

  @inlinable
  public mutating func reserveCapacity(_ n: Int) {
    guard capacity < n else { return }
    setCapacity(n)
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
    let source = unsafe _storage.extracting(Range(uncheckedBounds: (index + count, _count)))
    let target = unsafe _storage.extracting(Range(uncheckedBounds: (index, index + source.count)))
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
    let source = unsafe _storage.extracting(Range(uncheckedBounds: (index, _count)))
    let target = unsafe _storage.extracting(Range(uncheckedBounds: (index + count, _count + count)))
    let i = unsafe target.moveInitialize(fromContentsOf: source)
    assert(i == target.count)
    return unsafe _storage.extracting(Range(uncheckedBounds: (index, index + count)))
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
  /// Attempting to remove more elements than exist in the array triggers a runtime error.
  ///
  /// - Parameter k: The number of elements to remove from the array.
  ///   `k` must be greater than or equal to zero and must not exceed the count of the array.
  ///
  /// - Complexity: O(`k`)
  @inlinable
  public mutating func removeLast(_ k: Int) {
    if k == 0 { return }
    precondition(k >= 0 && k <= _count, "Count of elements to remove is out of bounds")
    unsafe _storage.extracting(Range(uncheckedBounds: (_count - k, _count))).deinitialize()
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
  /// All the elements following the specified subrange are moved to close the resulting
  /// gap.
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
    let suffixStart = try _halfStablePartition(isSuffixElement: shouldBeRemoved)
    removeSubrange(suffixStart...)
  }

  /// Removes and returns the last element of the array.
  ///
  /// - Returns: The last element of the array if the array is not empty; otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func popLast() -> Element? {
    if isEmpty { return nil }
    return removeLast()
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds
  ///   of the range must be valid indices of the array.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func removeSubrange(_  bounds: some RangeExpression<Int>) {
    removeSubrange(bounds.relative(to: indices))
  }
}

//MARK: - Insertion operations


extension RigidArray where Element: ~Copyable {
  /// Adds an element to the end of the array.
  ///
  /// If the array does not have sufficient capacity to hold any more elements, then this
  /// triggers a runtime error.
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
  @_alwaysEmitIntoClient
  public mutating func append(contentsOf items: some Sequence<Element>) {
    var (it, c) = unsafe items._copyContents(initializing: _freeSpace)
    precondition(it.next() == nil, "RigidArray capacity overflow")
    _count += c
  }

  // FIXME: We need to nail the naming of this: we'll have consuming variants, too, and we need to interoperate with Collection's methods.
  @available(SwiftCompatibilitySpan 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func append(copying items: Span<Element>) {
    precondition(items.count <= freeCapacity, "RigidArray capacity overflow")
    unsafe items.withUnsafeBufferPointer { source in
      let c = unsafe source._copyContents(initializing: _freeSpace).1
      _count &+= c
    }
  }

  // FIXME: We need to nail the naming of this: we'll have consuming variants, too, and we need to interoperate with Collection's methods.
  @available(SwiftCompatibilitySpan 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func append<C: Container<Element> & ~Copyable & ~Escapable>(
    copying items: borrowing C
  ) {
    let (copied, end) =  unsafe _freeSpace._initializePrefix(copying: items)
    precondition(end == items.endIndex, "RigidArray capacity overflow")
    _count += copied
  }
}

extension RigidArray where Element: ~Copyable {
  /// Inserts a new element into the array at the specified position.
  ///
  /// If the array does not have sufficient capacity to hold any more elements, then this
  /// triggers a runtime error.
  ///
  /// The new element is inserted before the element currently at the specified index. If you pass
  /// the array's `endIndex` as the `index` parameter, then the new element is appended to the
  /// collection.
  ///
  /// All existing elements at or following the specified position are moved to make room for the
  /// new item.
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
  @inlinable
  public mutating func insert(contentsOf items: some Collection<Element>, at index: Int) {
    precondition(index >= 0 && index <= _count, "Index out of bounds")
    let c = items.count
    precondition(c <= freeCapacity, "RigidArray capacity overflow")
    let gap = unsafe _openGap(at: index, count: c)
    var (it, copied) = unsafe items._copyContents(initializing: gap)
    precondition(it.next() == nil && copied == c, "Broken Collection: count doesn't match contents")
    _count += c
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  internal mutating func _insert(copying items: UnsafeBufferPointer<Element>, at index: Int) {
    guard items.count > 0 else { return }
    precondition(items.count <= freeCapacity, "RigidArray capacity overflow")
    let gap = unsafe _openGap(at: index, count: items.count)
    unsafe gap.baseAddress.unsafelyUnwrapped.initialize(
      from: items.baseAddress.unsafelyUnwrapped, count: items.count)
    _count += items.count
  }

  // FIXME: We need to nail the naming of this: we'll have consuming variants, too, and we need to interoperate with Collection's methods.
  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  public mutating func insert(copying items: Span<Element>, at index: Int) {
    precondition(items.count <= freeCapacity, "RigidArray capacity overflow")
    unsafe items.withUnsafeBufferPointer { unsafe self._insert(copying: $0, at: index) }
  }

  // FIXME: We need to nail the naming of this: we'll have consuming variants, too, and we need to interoperate with Collection's methods.
  @available(SwiftCompatibilitySpan 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func insert<C: Container<Element> & ~Copyable & ~Escapable>(
    copying items: borrowing C, at index: Int
  ) {
    precondition(index >= 0 && index <= _count, "Index out of bounds")
    let c = items.count
    precondition(c <= freeCapacity, "RigidArray capacity overflow")
    let target = unsafe _openGap(at: index, count: c)
    let (copied, end) = unsafe target._initializePrefix(copying: items)
    precondition(
      copied == c && end == items.endIndex,
      "Broken Container: count doesn't match contents")
    _count += c
  }
}

//MARK: - Range replacement

extension RigidArray {
  /// Perform a range replacement up to populating the newly opened gap. This deinitializes removed content, rearranges trailing
  /// elements to be at their final size, and sets the container's new count.
  ///
  /// - Returns: A buffer pointer addressing the newly opened gap, to be initialized by the caller.
  @inlinable
  internal mutating func _gapForReplacement(
    of subrange: Range<Int>, withNewCount newCount: Int
  ) -> UnsafeMutableBufferPointer<Element> {
    precondition(
      subrange.lowerBound >= 0 && subrange.upperBound <= _count,
      "Index range out of bounds")
    precondition(newCount - subrange.count <= freeCapacity, "RigidArray capacity overflow")
    unsafe _items.extracting(subrange).deinitialize()
    if newCount > subrange.count {
      _ = unsafe _openGap(at: subrange.upperBound, count: newCount - subrange.count)
    } else if newCount < subrange.count {
      _closeGap(at: subrange.lowerBound + newCount, count: subrange.count - newCount)
    }
    _count += newCount - subrange.count
    let gapRange = unsafe Range(
      uncheckedBounds: (subrange.lowerBound, subrange.lowerBound + newCount))
    return unsafe _storage.extracting(gapRange)
  }

  /// Replaces the specified subrange of elements by copying the elements of the given collection.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(contentsOf:at:)` method instead is preferred in this case.
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
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    with newElements: __owned some Collection<Element>
  ) {
    let c = newElements.count
    let gap = unsafe _gapForReplacement(of: subrange, withNewCount: c)
    var (it, copied) = unsafe newElements._copyContents(initializing: gap)
    precondition(it.next() == nil && copied == c, "Broken Collection: count doesn't match contents")
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
  /// the `insert(contentsOf:at:)` method instead is preferred in this case.
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
    with newElements: UnsafeBufferPointer<Element>
  ) {
    let gap = unsafe _gapForReplacement(of: subrange, withNewCount: newElements.count)
    unsafe gap.initializeAll(fromContentsOf: newElements)
  }

  /// Replaces the specified subrange of elements by copying the elements of the given span.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(contentsOf:at:)` method instead is preferred in this case.
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
  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: Span<Element>
  ) {
    unsafe newElements.withUnsafeBufferPointer { buffer in
      unsafe self.replaceSubrange(subrange, with: buffer)
    }
  }

  /// Replaces the specified subrange of elements by copying the elements of the given container.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(contentsOf:at:)` method instead is preferred in this case.
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
  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  public mutating func replaceSubrange<C: Container<Element> & ~Copyable & ~Escapable>(
    _ subrange: Range<Int>,
    copying newElements: borrowing C
  ) {
    let c = newElements.count
    let gap = unsafe _gapForReplacement(of: subrange, withNewCount: c)
    let (copied, end) = unsafe gap._initializePrefix(copying: newElements)
    precondition(
      copied == c && end == newElements.endIndex,
      "Broken Container: count doesn't match contents")
  }
}
