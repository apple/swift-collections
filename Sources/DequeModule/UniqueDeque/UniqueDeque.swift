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

@frozen
@available(*, unavailable, message: "UniqueDeque requires a Swift 6.2 toolchain")
public struct UniqueDeque<Element: ~Copyable>: ~Copyable {
  public init() {
    fatalError()
  }
}

#else

@available(SwiftStdlib 5.0, *)
@frozen
@safe
public struct UniqueDeque<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  package var _storage: RigidDeque<Element>
  
  @_alwaysEmitIntoClient
  @inline(__always)
  package init(_storage: consuming RigidDeque<Element>) {
    self._storage = _storage
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque: @unchecked Sendable where Element: Sendable & ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
#if COLLECTIONS_INTERNAL_CHECKS
  @usableFromInline @inline(never) @_effects(releasenone)
  package func _checkInvariants() {
    _storage._handle._checkInvariants()
  }
#else
  @_transparent
  package func _checkInvariants() {}
#endif // COLLECTIONS_INTERNAL_CHECKS
}

//MARK: - Basics

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// The maximum number of elements this array can hold without reallocating
  /// its storage.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var capacity: Int { _assumeNonNegative(_storage.capacity) }
  
  /// The number of additional elements that can be added to this array without
  /// reallocating its storage.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var freeCapacity: Int { _assumeNonNegative(_storage.freeCapacity) }
  
  @_alwaysEmitIntoClient
  @_transparent
  public var _isFull: Bool { _storage.isFull }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  public typealias Index = Int

  /// A Boolean value indicating whether this deque contains no elements.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var isEmpty: Bool { _storage.isEmpty }

  /// The number of elements in this deque.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var count: Int { _storage.count }

  /// The position of the first element in a nonempty deque. This is always zero.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var startIndex: Int { _storage.startIndex }

  /// The deque’s "past the end” position—that is, the position one greater than
  /// the last valid subscript argument. This is always equal to deque's count.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var endIndex: Int { _storage.endIndex }

  /// The range of indices that are valid for subscripting the deque.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var indices: Range<Int> { unsafe Range(uncheckedBounds: (0, count)) }

  @_alwaysEmitIntoClient
  public subscript(position: Int) -> Element {
    @inline(__always)
    @_transparent
    unsafeAddress {
      precondition(position >= 0 && position < count, "Index out of bounds")
      let slot = _storage._handle.slot(forOffset: position)
      return _storage._handle.ptr(at: slot)
    }
    @inline(__always)
    @_transparent
    unsafeMutableAddress {
      precondition(position >= 0 && position < count, "Index out of bounds")
      let slot = _storage._handle.slot(forOffset: position)
      return _storage._handle.mutablePtr(at: slot)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// Exchanges the values at the specified indices of the deque.
  ///
  /// Both parameters must be valid indices of the deque and not equal to
  /// `endIndex`. Passing the same index as both `i` and `j` has no effect.
  ///
  /// - Parameter i: The index of the first value to swap.
  /// - Parameter j: The index of the second valud to swap.
  ///
  /// - Complexity: O(1)
  @_transparent
  public mutating func swapAt(_ i: Int, _ j: Int) {
    _storage.swapAt(i, j)
  }
}

//MARK: - Resizing

@_alwaysEmitIntoClient
@_transparent
internal func _growUniqueDequeCapacity(_ capacity: Int) -> Int {
  // A growth factor of 1.5 seems like a reasonable compromise between
  // over-allocating memory and wasting cycles on repeatedly resizing storage.
  let c = (3 &* UInt(bitPattern: capacity) &+ 1) / 2
  return Int(bitPattern: c)
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  /// Grow or shrink the capacity of this deque instance without discarding
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
  @inlinable
  public mutating func reallocate(capacity: Int) {
    _storage.reallocate(capacity: capacity)
  }

  /// Ensure that the array has capacity to store the specified number of
  /// elements, by growing its storage buffer if necessary.
  ///
  /// If `capacity < n`, then this operation reallocates the unique array's
  /// storage to grow it; on return, the array's capacity becomes `n`.
  /// Otherwise the array is left as is.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func reserveCapacity(_ n: Int) {
    _storage.reserveCapacity(n)
  }

  
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func _ensureFreeCapacity(_ freeCapacity: Int) {
    guard _storage.freeCapacity < freeCapacity else { return }
    _ensureFreeCapacitySlow(freeCapacity)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  internal func _grow(freeCapacity: Int) -> Int {
    Swift.max(
      count + freeCapacity,
      _growUniqueDequeCapacity(capacity))
  }

  @inlinable
  internal mutating func _ensureFreeCapacitySlow(_ freeCapacity: Int) {
    let newCapacity = _grow(freeCapacity: freeCapacity)
    reallocate(capacity: newCapacity)
  }
}

//MARK: - Copying helpers

@available(SwiftStdlib 5.0, *)
extension UniqueDeque {
  /// Copy the contents of this deque into a newly allocated deque
  /// instance with just enough capacity to hold all its elements.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public func clone() -> Self {
    UniqueDeque(_storage: _storage.clone())
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
    UniqueDeque(_storage: _storage.clone(capacity: capacity))
  }
}


#endif // compiler(<6.2)
