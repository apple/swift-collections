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
import ContainersPreview
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
/// `RigidArray` instances are created with a specific maximum capacity. Elements
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
/// the use of ``UniqueArray`` rather than `RigidArray`. (For copyable elements,
/// the standard `Array` is an even more convenient choice.)
@available(SwiftStdlib 5.0, *)
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
  ///
  /// - Complexity: O(1)
  @inlinable
  public init() {
    unsafe _storage = .init(start: nil, count: 0)
    _count = 0
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray: @unchecked Sendable where Element: Sendable & ~Copyable {}


//MARK: - Basics

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// The maximum number of elements this rigid array can hold.
  ///
  /// - Complexity: O(1)
  @inlinable
  @_transparent
  public var capacity: Int { _assumeNonNegative(unsafe _storage.count) }

  /// The number of additional elements that can be added to this array without
  /// exceeding its storage capacity.
  ///
  /// - Complexity: O(1)
  @inlinable
  @_transparent
  public var freeCapacity: Int {
    _assumeNonNegative(capacity &- count)
  }

  /// A Boolean value indicating whether this rigid array is fully populated.
  /// If this property returns true, then the array's storage is at capacity,
  /// and it cannot accommodate any additional elements.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var isFull: Bool { freeCapacity == 0 }
}

@available(SwiftStdlib 5.0, *)
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

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// A span over the elements of this array, providing direct read-only access.
  ///
  /// - Complexity: O(1)
  public var span: Span<Element> {
    @_lifetime(borrow self)
    @inlinable
    get {
      let result = unsafe Span(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, borrowing: self)
    }
  }

  /// A mutable span over the elements of this array, providing direct
  /// mutating access.
  ///
  /// - Complexity: O(1)
  public var mutableSpan: MutableSpan<Element> {
    @_lifetime(&self)
    @inlinable
    mutating get {
      let result = unsafe MutableSpan(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, mutating: &self)
    }
  }

  @inlinable
  @_lifetime(borrow self)
  internal func _span(in range: Range<Int>) -> Span<Element> {
    span.extracting(range)
  }

  @inlinable
  @_lifetime(&self)
  internal mutating func _mutableSpan(
    in range: Range<Int>
  ) -> MutableSpan<Element> {
    let result = unsafe MutableSpan(_unsafeElements: _items.extracting(range))
    return unsafe _overrideLifetime(result, mutating: &self)
  }
}

@available(SwiftStdlib 5.0, *)
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

@available(SwiftStdlib 5.0, *)
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

//MARK: - Container primitives

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// A Boolean value indicating whether this array contains no elements.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { count == 0 }

  /// The number of elements in this array.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var count: Int { _count }
}

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension RigidArray: Container where Element: ~Copyable {
  public typealias BorrowIterator = Span<Element>

  @_alwaysEmitIntoClient
  @inline(__always)
  public func startBorrowIteration() -> Span<Element> {
    self.span
  }
}
#endif

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// A type that represents a position in the array: an integer offset from the
  /// start.
  ///
  /// Valid indices consist of the position of every element and a "past the
  /// end” position that’s not valid for use as a subscript argument.
  public typealias Index = Int

  /// The position of the first element in a nonempty array. This is always zero.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var startIndex: Int { 0 }

  /// The array’s "past the end” position—that is, the position one greater than
  /// the last valid subscript argument. This is always equal to array's count.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var endIndex: Int { count }

  /// The range of indices that are valid for subscripting the array.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var indices: Range<Int> { unsafe Range(uncheckedBounds: (0, count)) }
}

@available(SwiftStdlib 5.0, *)
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

  /// Accesses the element at the specified position.
  ///
  /// - Parameter position: The position of the element to access.
  ///     The position must be a valid index of the array that is not equal
  ///     to the `endIndex` property.
  ///
  /// - Complexity: O(1)
  @inlinable
  public subscript(position: Int) -> Element {
    @inline(__always)
    unsafeAddress {
      _ptr(to: position)
    }
    @inline(__always)
    unsafeMutableAddress {
      _mutablePtr(to: position)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// Exchanges the values at the specified indices of the array.
  ///
  /// Both parameters must be valid indices of the array and not equal to
  /// endIndex. Passing the same index as both `i` and `j` has no effect.
  ///
  /// - Parameter i: The index of the first value to swap.
  /// - Parameter j: The index of the second valud to swap.
  ///
  /// - Complexity: O(1)
  @inlinable
  public mutating func swapAt(_ i: Int, _ j: Int) {
    precondition(
      i >= 0 && i < _count && j >= 0 && j < _count,
      "Index out of bounds")
    unsafe _items.swapAt(i, j)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// Return a borrowing span over the maximal storage chunk following the
  /// specified position in the array. The span provides direct read-only access
  /// to all array elements in the range `index ..< count`.
  ///
  /// - Parameter index: A valid index in the array, including the end index.
  ///
  /// - Complexity: O(1)
  @inlinable
  @_lifetime(borrow self)
  public func span(after index: inout Int) -> Span<Element> {
    _span(in: _contiguousSubrange(following: &index))
  }

  /// Return a borrowing span over the maximal storage chunk preceding the
  /// specified position in the array. The span provides direct read-only access
  /// to all array elements in the range `0 ..< index`.
  ///
  /// - Parameter index: A valid index in the array, including the end index.
  ///
  /// - Complexity: O(1)
  @inlinable
  @_lifetime(borrow self)
  public func span(before index: inout Int) -> Span<Element> {
    _span(in: _contiguousSubrange(preceding: &index))
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// Return a mutable span over the maximal storage chunk following the
  /// specified position in the array. The span provides direct mutating access
  /// to all array elements in the range `index ..< count`.
  ///
  /// - Parameter index: A valid index in the array, including the end index.
  ///
  /// - Complexity: O(1)
  @_lifetime(&self)
  public mutating func mutableSpan(
    after index: inout Int
  ) -> MutableSpan<Element> {
    _mutableSpan(in: _contiguousSubrange(following: &index))
  }

  /// Return a mutable span over the maximal storage chunk preceding the specified
  /// position in the array. The span provides direct mutating access to all
  /// array elements in the range `0 ..< index`.
  ///
  /// - Parameter index: A valid index in the array, including the end index.
  ///
  /// - Complexity: O(1)
  @_lifetime(&self)
  public mutating func mutableSpan(
    before index: inout Int
  ) -> MutableSpan<Element> {
    _mutableSpan(in: _contiguousSubrange(preceding: &index))
  }
}

//MARK: - Resizing

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// Grow or shrink the capacity of a rigid array instance without discarding
  /// its contents.
  ///
  /// This operation replaces the array's storage buffer with a newly allocated
  /// buffer of the specified capacity, moving all existing elements
  /// to its new storage. The old storage is then deallocated.
  ///
  /// - Parameter newCapacity: The desired new capacity. `newCapacity` must be
  ///    greater than or equal to the current count.
  ///
  /// - Complexity: O(`count`)
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

  /// Ensure that the array has capacity to store the specified number of
  /// elements, by growing its storage buffer if necessary.
  ///
  /// If `capacity < n`, then this operation reallocates the rigid array's
  /// storage to grow it; on return, the array's capacity becomes `n`.
  /// Otherwise the array is left as is.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func reserveCapacity(_ n: Int) {
    guard capacity < n else { return }
    reallocate(capacity: n)
  }
}

//MARK: - Copying helpers

@available(SwiftStdlib 5.0, *)
extension RigidArray {
  /// Copy the contents of this array into a newly allocated rigid array
  /// instance with just enough capacity to hold all its elements.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func copy() -> Self {
    copy(capacity: count)
  }

  /// Copy the contents of this array into a newly allocated rigid array
  /// instance with the specified capacity.
  ///
  /// - Parameter capacity: The desired capacity of the resulting rigid array.
  ///    `capacity` must be greater than or equal to `count`.
  ///
  /// - Complexity: O(`count`)
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

@available(SwiftStdlib 5.0, *)
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

#endif
