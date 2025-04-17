//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Future

/// A collection implementing a double-ended queue. `Deque` (pronounced "deck")
/// implements an ordered random-access collection that supports efficient
/// insertions and removals from both ends.
///
///     var colors: Deque = ["red", "yellow", "blue"]
///
/// Deques implement the same indexing semantics as arrays: they use integer
/// indices, and the first element of a nonempty deque is always at index zero.
/// Like arrays, deques conform to `RangeReplaceableCollection`,
/// `MutableCollection` and `RandomAccessCollection`, providing a familiar
/// interface for manipulating their contents:
///
///     print(colors[1]) // "yellow"
///     print(colors[3]) // Runtime error: Index out of range
///
///     colors.insert("green", at: 1)
///     // ["red", "green", "yellow", "blue"]
///
///     colors.remove(at: 2) // "yellow"
///     // ["red", "green", "blue"]
///
/// Like all variable-size collections on the standard library, `Deque`
/// implements value semantics: each deque has an independent value that
/// includes the values of its elements. Modifying one deque does not affect any
/// others:
///
///     var copy = deque
///     copy[1] = "violet"
///     print(copy)  // ["red", "violet", "blue"]
///     print(deque) // ["red", "green", "blue"]
///
/// This is implemented with the copy-on-write optimization. Multiple copies of
/// a deque share the same underlying storage until you modify one of the
/// copies. When that happens, the deque being modified replaces its storage
/// with a uniquely owned copy of itself, which is then modified in place.
///
/// `Deque` stores its elements in a circular buffer, which allows efficient
/// insertions and removals at both ends of the collection; however, this comes
/// at the cost of potentially discontiguous storage. In contrast, `Array` is
/// (usually) backed by a contiguous buffer, where new data can be efficiently
/// appended to the end, but inserting at the front is relatively slow, as
/// existing elements need to be shifted to make room.
///
/// This difference in implementation means that while the interface of a deque
/// is very similar to an array, the operations have different performance
/// characteristics. Mutations near the front are expected to be significantly
/// faster in deques, but arrays may measure slightly faster for general
/// random-access lookups.
///
/// Deques provide a handful of additional operations that make it easier to
/// insert and remove elements at the front. This includes queue operations such
/// as `popFirst` and `prepend`, including the ability to directly prepend a
/// sequence of elements:
///
///     colors.append("green")
///     colors.prepend("orange")
///     // colors: ["orange", "red", "blue", "yellow", "green"]
///
///     colors.popLast() // "green"
///     colors.popFirst() // "orange"
///     // colors: ["red", "blue", "yellow"]
///
///     colors.prepend(contentsOf: ["purple", "teal"])
///     // colors: ["purple", "teal", "red", "blue", "yellow"]
///
/// Unlike arrays, deques do not currently provide direct unsafe access to their
/// underlying storage. They also lack a `capacity` property -- the size of the
/// storage buffer at any given point is an unstable implementation detail that
/// should not affect application logic. (However, deques do provide a
/// `reserveCapacity` method.)
@frozen
public struct Deque<Element> {
  @usableFromInline
  internal typealias _Slot = _DequeSlot

  @usableFromInline
  internal var _storage: Shared<RigidDeque<Element>>

  @inlinable
  internal init(_storage: consuming RigidDeque<Element>) {
    self._storage = Shared(_storage)
  }

  /// Creates and empty deque with preallocated space for at least the specified
  /// number of elements.
  ///
  /// - Parameter minimumCapacity: The minimum number of elements that the
  ///   newly created deque should be able to store without reallocating its
  ///   storage buffer.
  @inlinable
  public init(minimumCapacity: Int) {
    self.init(_storage: RigidDeque(capacity: minimumCapacity))
  }
}

extension Deque: @unchecked Sendable where Element: Sendable {}

extension Deque {
  @usableFromInline
  internal typealias _UnsafeHandle = _UnsafeDequeHandle<Element>

  @inlinable
  @inline(__always)
  internal func _read<E: Error, R: ~Copyable>(
    _ body: (borrowing _UnsafeHandle) throws(E) -> R
  ) throws(E) -> R {
    return try body(_storage.value._handle)
  }

  @inlinable
  @inline(__always)
  internal mutating func _update<E: Error, R: ~Copyable>(
    _ body: (inout _UnsafeHandle) throws(E) -> R
  ) throws(E) -> R {
    _ensureUnique()
    var rigid = _storage.mutate()
    defer { extendLifetime(rigid) }
    return try body(&rigid[]._handle)
  }
}

extension Deque {
  /// Return a boolean indicating whether this storage instance is known to have
  /// a single unique reference. If this method returns true, then it is safe to
  /// perform in-place mutations on the deque.
  @inlinable
  internal mutating func _isUnique() -> Bool {
    _storage.isUnique()
  }

  /// Ensure that this storage refers to a uniquely held buffer by copying
  /// elements if necessary.
  @inlinable
  @inline(__always)
  internal mutating func _ensureUnique() {
    _storage.ensureUnique(cloner: { $0._copy() })
  }

  /// Copy elements into a new storage instance without changing capacity or
  /// layout.
  @inlinable
  @inline(never)
  internal func _makeUniqueCopy() -> Self {
    Deque(_storage: _storage.value._copy())
  }

  @inlinable
  @inline(never)
  internal func _makeUniqueCopy(capacity: Int) -> Self {
    Deque(_storage: _storage.value._copy(capacity: capacity))
  }

  @inlinable
  internal var _capacity: Int {
    _storage.value.capacity
  }

  @usableFromInline
  internal func _growCapacity(
    to minimumCapacity: Int,
    linearly: Bool
  ) -> Int {
    if linearly {
      return Swift.max(_capacity, minimumCapacity)
    }
    let next = (3 * _capacity + 1) / 2
    return Swift.max(next, minimumCapacity)
  }

  /// Ensure that we have a uniquely referenced buffer with enough space to
  /// store at least `minimumCapacity` elements.
  ///
  /// - Parameter minimumCapacity: The minimum number of elements the buffer
  ///    needs to be able to hold on return.
  ///
  /// - Parameter linearGrowth: If true, then don't use an exponential growth
  ///    factor when reallocating the buffer -- just allocate space for the
  ///    requested number of elements
  @inlinable
  @inline(__always)
  internal mutating func _ensureUnique(
    minimumCapacity: Int,
    linearGrowth: Bool = false
  ) {
    let unique = _isUnique()
    if _slowPath(_capacity < minimumCapacity || !unique) {
      __ensureUnique(
        isUnique: unique,
        minimumCapacity: minimumCapacity,
        linearGrowth: linearGrowth)
    }
  }

  @inlinable
  @inline(never)
  internal mutating func __ensureUnique(
    isUnique: Bool,
    minimumCapacity: Int,
    linearGrowth: Bool
  ) {
    if _capacity >= minimumCapacity {
      assert(!isUnique)
      self = self._makeUniqueCopy()
      return
    }

    let c = _growCapacity(to: minimumCapacity, linearly: linearGrowth)
    if isUnique {
      self._storage.value.resize(to: c)
    } else {
      self = self._makeUniqueCopy(capacity: c)
    }
  }
}

extension Deque {
  @inlinable
  @inline(__always)
  internal func _isIdentical(to other: Self) -> Bool {
    self._storage.isIdentical(to: other._storage)
  }
}

