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
/// potentially noncopyable elements.
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
  internal mutating func _takeHandle() -> _UnsafeHandle {
    exchange(&_handle, with: .allocate(capacity: 0))
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque: @unchecked Sendable where Element: Sendable & ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
#if COLLECTIONS_INTERNAL_CHECKS
  @usableFromInline @inline(never) @_effects(releasenone)
  internal func _checkInvariants() {
    _handle._checkInvariants()
  }
#else
  @inlinable @inline(__always)
  internal func _checkInvariants() {}
#endif // COLLECTIONS_INTERNAL_CHECKS
}


//MARK: - Basics

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public var capacity: Int { _assumeNonNegative(_handle.capacity) }
  
  @_alwaysEmitIntoClient
  @_transparent
  public var freeCapacity: Int { _assumeNonNegative(capacity &- count) }
  
  @_alwaysEmitIntoClient
  @_transparent
  public var isFull: Bool { count == capacity }
}

//MARK: - Span creation

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(borrow self)
  internal func _span(over slots: Range<_DequeSlot>) -> Span<Element> {
    let span = Span(_unsafeElements: _handle.buffer(for: slots))
    return _overrideLifetime(span, borrowing: self)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(&self)
  internal mutating func _mutableSpan(over slots: Range<_DequeSlot>) -> MutableSpan<Element> {
    let span = MutableSpan(_unsafeElements: _handle.mutableBuffer(for: slots))
    return _overrideLifetime(span, mutating: &self)
  }
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
  public subscript(position: Int) -> Element {
    // FIXME: Replace with borrow/mutate accessors
    @inline(__always)
    @_transparent
    unsafeAddress {
      precondition(position >= 0 && position < count, "Index out of bounds")
      let slot = _handle.slot(forOffset: position)
      return _handle.ptr(at: slot)
    }
    @inline(__always)
    @_transparent
    unsafeMutableAddress {
      precondition(position >= 0 && position < count, "Index out of bounds")
      let slot = _handle.slot(forOffset: position)
      return _handle.mutablePtr(at: slot)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
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
      i >= 0 && i < count && j >= 0 && j < count,
      "Index out of bounds")
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
  public func _clone() -> Self {
    RigidDeque(_handle: _handle.allocateCopy())
  }

  /// Copy the contents of this deque into a newly allocated rigid deque
  /// instance with the specified capacity.
  ///
  /// - Parameter capacity: The desired capacity of the resulting rigid deque.
  ///    `capacity` must be greater than or equal to `count`.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public func _clone(capacity: Int) -> Self {
    RigidDeque(_handle: _handle.allocateCopy(capacity: capacity))
  }
}

#endif // compiler(<6.2)
