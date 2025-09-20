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

/// A collection implementing a double-ended queue. `Deque` (pronounced "deck")
/// implements an ordered random-access collection that supports efficient
/// insertions and removals from both ends.
///
///     var colors: Deque = ["red", "yellow", "blue"]
///     var ringBuffer = Deque<Int>(fixedCapacity: 100)
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
/// ## Fixed-Capacity Deques
///
/// Deques can be created with a fixed maximum capacity, making them ideal for use
/// as ring buffers where memory allocation must be controlled:
///
///     var buffer = Deque<String>(fixedCapacity: 3)
///     buffer.append("A")     // ["A"]
///     buffer.append("B")     // ["A", "B"]
///     buffer.append("C")     // ["A", "B", "C"]
///     buffer.append("D")     // ["B", "C", "D"] - "A" was automatically removed
///
/// When a fixed-capacity deque reaches its maximum size, new elements
/// automatically replace the oldest elements. This makes them particularly
/// useful for audio/video processing, logging systems, and real-time
/// applications requiring predictable memory usage.
///
/// Fixed-capacity deques provide properties to monitor their state:
///
///     print(buffer.isFixedCapacity)      // true
///     print(buffer.maxCapacity)          // Optional(3)
///     print(buffer.isFull)               // true
///     print(buffer.remainingCapacity)    // 0
///
/// Unlike arrays, deques do not currently provide direct unsafe access to their
/// underlying storage. Regular deques lack a `capacity` property since the size of
/// the storage buffer is an implementation detail. However, deques do provide a
/// `reserveCapacity` method, and fixed-capacity deques expose their capacity
/// information through `maxCapacity`, `isFull`, and `remainingCapacity` properties.
@frozen
public struct Deque<Element> {
    
  @usableFromInline
  internal typealias _Slot = _DequeSlot

  @usableFromInline
  internal var _storage: _Storage

  @usableFromInline
    internal let _maxCapacity : Int?
    
  @inlinable
    internal init(_storage: _Storage, maxCapacity: Int? = nil) {
    self._storage = _storage
    self._maxCapacity = maxCapacity
  }

  /// Creates an empty deque with preallocated space for at least the specified
  /// number of elements.
  ///
  /// - Parameter minimumCapacity: The minimum number of elements that the
  ///   newly created deque should be able to store without reallocating its
  ///   storage buffer.
  @inlinable
  public init(minimumCapacity: Int) {
    self._storage = _Storage(minimumCapacity: minimumCapacity)
      self._maxCapacity = nil
  }

  /// Creates an empty deque with a fixed maximum capacity.
  ///
  /// Fixed-capacity deques act as ring buffers, automatically removing the
  /// oldest elements when new elements are added to a full deque. This makes
  /// them ideal for scenarios requiring predictable memory usage, such as
  /// audio processing, logging systems, or real-time applications.
  ///
  /// - Parameter fixedCapacity: The maximum number of elements that the
  ///   deque can hold. Must be greater than zero.
  @inlinable
    public init(fixedCapacity: Int){
        precondition(fixedCapacity > 0, "Fixed capacity must be greater than zero")
        self._storage = _Storage(minimumCapacity: fixedCapacity)
        self._maxCapacity = fixedCapacity
    }
}

extension Deque {
    
    /// A Boolean value that indicates whether this deque was created with a fixed
    /// maximum capacity.
    ///
    /// - Returns: `true` if the deque is a fixed-capacity deque (ring buffer),
    ///   `false` if it can grow without limit.
    ///
    /// ### Example
    ///
    ///     var regular = Deque<Int>()
    ///     print(regular.isFixedCapacity) // false
    ///
    ///     var buffer = Deque<Int>(fixedCapacity: 5)
    ///     print(buffer.isFixedCapacity) // true
    ///
    /// Use this property when you need to distinguish between a
    /// regular deque and a fixed-capacity deque.
    ///
    /// - Complexity: O(1)
    @inlinable
    public var isFixedCapacity: Bool {
        return _maxCapacity != nil
    }
    
    /// The maximum number of elements this deque can hold, or `nil` if it
    /// has no fixed limit.
    ///
    /// Example:
    ///
    ///     var buffer = Deque<Int>(fixedCapacity: 3)
    ///     print(buffer.maxCapacity) // Optional(3)
    ///
    ///     var regular = Deque<Int>()
    ///     print(regular.maxCapacity) // nil
    ///
    /// - Complexity: O(1)
    @inlinable
    public var maxCapacity: Int? {
        return _maxCapacity
    }
    
    /// Returns true if the deque is at its maximum capacity.
    ///
    /// Example:
    ///
    ///     var buffer = Deque<Int>(fixedCapacity: 2)
    ///     buffer.append(1)
    ///     buffer.append(2)
    ///     print(buffer.isFull) // true
    ///
    /// When the deque is full, adding new elements will remove the oldest elements.
    @inlinable
    public var isFull: Bool {
        guard let maxCap = _maxCapacity else { return false }
        return count >= maxCap
    }

    /// The number of additional elements that can be inserted before the deque
    /// becomes full.
    ///
    /// For regular (unlimited) deques, this value is very large (`Int.max`).
    ///
    /// Example:
    ///
    ///     var buffer = Deque<Int>(fixedCapacity: 3)
    ///     print(buffer.remainingCapacity) // 3
    ///     buffer.append(1)
    ///     print(buffer.remainingCapacity) // 2
    ///
    /// - Complexity: O(1)
    @inlinable
    public var remainingCapacity: Int {
        guard let maxCap = _maxCapacity else { return Int.max }
        return Swift.max(0, maxCap - count)
    }
}

extension Deque: @unchecked Sendable where Element: Sendable {}
