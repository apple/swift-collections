//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
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

/// A fixed capacity, heap allocated, noncopyable double-ended queue of
/// potentially noncopyable elements.
@frozen
@available(*, unavailable, message: "RigidDeque requires a Swift 6.2 toolchain")
public struct RigidDeque<Element: ~Copyable>: ~Copyable {
  public init() {
    fatalError()
  }
}

#else

/// A fixed capacity, heap allocated, noncopyable double-ended queue of
/// potentially noncopyable elements. A deque (pronounced "deck")
/// is an ordered random-access container that supports efficient
/// insertions and removals from both ends.
///
/// Deques implement the same indexing semantics as arrays: they use integer
/// indices, and the first element of a nonempty deque is always at logical
/// index zero.
///
///     var colors = RigidDeque<String>(capacity: 5)
///     colors.append("red")
///     colors.prepend("yellow")
///     colors.append("blue")
///     // `colors` now contains "yellow", "red", "blue"
///
///     print(colors[0])            // prints "yellow"
///     print(colors[1])            // prints "red"
///
///     print(colors.removeFirst()) // prints "yellow"
///     print(colors.removeLast())  // prints "blue"
///     // `colors` now contains "red"
///
/// This double-ended nature makes deques particularly well-suited for
/// representing first-in-first-out (FIFO) buffers, where new items are
/// inserted at one end, and old items are retrieved from the other.
/// For example, they are ideal for modeling buffered data streams, such as
/// networking channels, or other producer/consumer scenarios.
///
/// ### Implementation Notes
///
/// `RigidDeque` implements a ring buffer. It stores its elements in a
/// single heap-allocated buffer, and to allow fast insertions and removals
/// from both ends, the buffer behaves as if its ends were glued together into
/// a ring shape. This comes at the cost of potentially discontiguous storage, as
/// the contents of the ring buffer sometimes wrap around the edges.
///
/// While the first item in the deque is always addressed by the logical index
/// zero, its physical location can be anywhere in the underlying ring buffer.
/// Compare this with `RigidArray`'s contiguous storage, where the first item
/// is always stored at the start of the buffer, so new data can always be
/// efficiently appended to the end, but inserting at the front is relatively
/// slow, as existing elements need to be shifted to make room.
///
/// ### Fixed Storage Capacity
///
/// `RigidDeque` instances are created with a specific maximum capacity.
/// Elements can be added to the deque up to that capacity, but no more: trying
/// to add an item to a full deque results in a runtime trap.
///
///      var items = RigidDeque<Int>(capacity: 2)
///      items.prepend(1)
///      items.prepend(2)
///      items.prepend(3) // Runtime error: RigidDeque capacity overflow
///
/// Rigid deques provide convenience properties to help verify that it has
/// enough available capacity: `isFull` and `freeCapacity`.
///
///     guard items.freeCapacity >= 4 else { throw CapacityOverflow() }
///     items.append(copying: newItems)
///
/// It is possible to extend or shrink the capacity of a rigid deque instance,
/// but this needs to be done explicitly, with operations dedicated to this
/// purpose (such as ``reserveCapacity`` and ``reallocate(capacity:)``).
/// The deque never resizes itself automatically.
///
/// Therefore, it is necessary to perform careful manual analysis (or up front
/// runtime capacity checks) to prevent the deque from overflowing its storage.
/// This makes this type more difficult to use than a dynamically resizing
/// container. However, it allows this construct to provide predictably stable
/// performance.
///
/// This trading of usability in favor of stable performance limits `RigidDeque`
/// to the most resource-constrained of use cases, such as space-constrained
/// environments that require carefully accounting of every heap allocation, or
/// time-constrained applications that cannot accommodate unexpected latency
/// spikes due to a reallocation getting triggered at an inopportune moment.
///
/// For use cases outside of these narrow domains, we generally recommmend
/// to use the dynamically resizing ``UniqueDeque`` type rather than
/// `RigidDeque`. For copyable elements, the copy-on-write `Deque` type is an
/// even more convenient and expressive choice.
@available(SwiftStdlib 5.0, *)
@frozen
@safe
public struct RigidDeque<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal typealias _Slot = _DequeSlot

  @usableFromInline
  package typealias _UnsafeHandle = _UnsafeDequeHandle<Element>

  @usableFromInline
  package var _handle: _UnsafeHandle

  @_alwaysEmitIntoClient
  @inline(__always)
  package init(_handle: consuming _UnsafeHandle) {
    self._handle = _handle
  }

  @inlinable
  @inline(__always)
  deinit {
    _handle.dispose()
  }
  
  @inlinable @inline(__always)
  package mutating func _takeHandle() -> _UnsafeHandle {
    exchange(&_handle, with: .allocate(capacity: 0))
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque: @unchecked Sendable where Element: Sendable & ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
#if COLLECTIONS_INTERNAL_CHECKS
  @usableFromInline @inline(never) @_effects(releasenone)
  package func _checkInvariants() {
    _handle._checkInvariants()
  }
#else
  @_transparent
  package func _checkInvariants() {}
#endif // COLLECTIONS_INTERNAL_CHECKS
}


//MARK: - Basics

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// The maximum number of elements this rigid deque can hold.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var capacity: Int { _assumeNonNegative(_handle.capacity) }
  
  /// The number of additional elements that can be added to this deque without
  /// exceeding its storage capacity.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var freeCapacity: Int { _assumeNonNegative(capacity &- count) }
  
  /// A Boolean value indicating whether this rigid deque is fully populated.
  /// If this property returns true, then the array's storage is at capacity,
  /// and it cannot accommodate any additional elements.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var isFull: Bool { count == capacity }
}

//MARK: - Container primitives

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// A type that represents a position in the deque: an integer offset from its
  /// logical start position.
  ///
  /// Valid indices consist of the position of every element and a "past the
  /// end" position that’s not valid for use as a subscript argument.
  public typealias Index = Int
  
  /// A Boolean value indicating whether this deque contains no elements.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var isEmpty: Bool { _handle.count == 0 }
  
  /// The number of elements in this deque.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var count: Int { _handle.count }
  
  /// The position of the first element in a nonempty deque. This is always zero.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var startIndex: Int { 0 }
  
  /// The deque’s "past the end” position—that is, the position one greater than
  /// the last valid subscript argument. This is always equal to the deque's
  /// count.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var endIndex: Int { _handle.count }
  
  /// The range of indices that are valid for subscripting this deque.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var indices: Range<Int> { unsafe Range(uncheckedBounds: (0, count)) }

  @_alwaysEmitIntoClient
  @_transparent
  package func _checkItemIndex(_ index: Int) {
    precondition(
      UInt(bitPattern: index) < UInt(bitPattern: _handle.count),
      "Index out of bounds")
  }

  @_alwaysEmitIntoClient
  @_transparent
  package func _checkValidIndex(_ index: Int) {
    precondition(
      UInt(bitPattern: index) <= UInt(bitPattern: _handle.count),
      "Index out of bounds")
  }

  @_alwaysEmitIntoClient
  @_transparent
  package func _checkValidBounds(_ subrange: Range<Int>) {
    precondition(
      subrange.lowerBound >= 0 && subrange.upperBound <= _handle.count,
      "Index range out of bounds")
  }

  @_alwaysEmitIntoClient
  public subscript(position: Int) -> Element {
    // FIXME: Replace with borrow/mutate accessors
    @inline(__always)
    @_transparent
    unsafeAddress {
      _checkItemIndex(position)
      let slot = _handle.slot(forOffset: position)
      return _handle.ptr(at: slot)
    }
    @inline(__always)
    @_transparent
    unsafeMutableAddress {
      _checkItemIndex(position)
      let slot = _handle.slot(forOffset: position)
      return _handle.mutablePtr(at: slot)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Exchanges the values at the specified indices of the deque.
  ///
  /// Both parameters must be valid indices of the deque and not equal to
  /// `endIndex`. Passing the same index as both `i` and `j` has no effect.
  ///
  /// - Parameter i: The index of the first value to swap.
  /// - Parameter j: The index of the second valud to swap.
  ///
  /// - Complexity: O(1)
  @inlinable
  public mutating func swapAt(_ i: Int, _ j: Int) {
    _checkItemIndex(i)
    _checkItemIndex(j)
    _handle.uncheckedSwapAt(i, j)
  }
}

//MARK: - Resizing

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  /// Grow or shrink the capacity of a rigid deque instance without discarding
  /// its contents.
  ///
  /// This operation replaces the deque's storage buffer with a newly allocated
  /// buffer of the specified capacity, moving all existing elements
  /// to its new storage. The old storage is then deallocated.
  ///
  /// - Parameter newCapacity: The desired new capacity. `newCapacity` must be
  ///    greater than or equal to the current count.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public mutating func reallocate(capacity newCapacity: Int) {
    _handle.reallocate(capacity: newCapacity)
  }
  
  /// Ensure that the deque has capacity to store the specified number of
  /// elements, by growing its storage buffer if necessary.
  ///
  /// If `capacity < n`, then this operation reallocates the rigid deque's
  /// storage to grow it; on return, the deque's capacity becomes `n`.
  /// Otherwise the deque is left as is.
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
extension RigidDeque {
  /// Copy the contents of this deque into a newly allocated rigid deque
  /// instance with just enough capacity to hold all its elements.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public func clone() -> Self {
    RigidDeque(_handle: _handle.allocateCopy(capacity: count))
  }

  /// Copy the contents of this deque into a newly allocated rigid deque
  /// instance with the specified capacity.
  ///
  /// - Parameter capacity: The desired capacity of the resulting rigid deque.
  ///    `capacity` must be greater than or equal to `count`.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public func clone(capacity: Int) -> Self {
    RigidDeque(_handle: _handle.allocateCopy(capacity: capacity))
  }
}

#endif // compiler(<6.2)
