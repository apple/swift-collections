//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Deque: RandomAccessCollection {
  public typealias Index = Int
  public typealias SubSequence = Slice<Self>

  /// The number of elements in the deque.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var count: Int { _storage.count }

  /// The position of the first element in a nonempty deque.
  ///
  /// For an instance of `Deque`, `startIndex` is always zero. If the deque is
  /// empty, `startIndex` is equal to `endIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var startIndex: Int { 0 }

  /// The deque’s “past the end” position—that is, the position one greater than
  /// the last valid subscript argument.
  ///
  /// For an instance of `Deque`, `endIndex` is always equal to its `count`. If
  /// the deque is empty, `endIndex` is equal to `startIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var endIndex: Int { count }

  /// Returns the position immediately after the given index.
  ///
  /// - Parameter `i`: A valid index of the deque. `i` must be less than
  ///    `endIndex`.
  ///
  /// - Returns: The next valid index immediately after `i`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(after i: Int) -> Int {
    // Note: Like `Array`, index manipulation methods on deques don't trap on
    // invalid indices. (Indices are still validated on element access.)
    return i + 1
  }

  /// Replaces the given index with its successor.
  ///
  /// - Parameter `i`: A valid index of the deque. `i` must be less than
  ///    `endIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func formIndex(after i: inout Int) {
    // Note: Like `Array`, index manipulation methods on deques
    // don't trap on invalid indices.
    // (Indices are still validated on element access.)
    i += 1
  }

  /// Returns the position immediately before the given index.
  ///
  /// - Parameter `i`: A valid index of the deque. `i` must be greater than
  ///    `startIndex`.
  ///
  /// - Returns: The preceding valid index immediately before `i`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(before i: Int) -> Int {
    // Note: Like `Array`, index manipulation methods on deques don't trap on
    // invalid indices. (Indices are still validated on element access.)
    return i - 1
  }

  /// Replaces the given index with its predecessor.
  ///
  /// - Parameter `i`: A valid index of the deque. `i` must be greater than `startIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func formIndex(before i: inout Int) {
    // Note: Like `Array`, index manipulation methods on deques don't trap on
    // invalid indices. (Indices are still validated on element access.)
    i -= 1
  }

  /// Returns an index that is the specified distance from the given index.
  ///
  /// The value passed as `distance` must not offset `i` beyond the bounds of
  /// the collection.
  ///
  /// - Parameters:
  ///   - i: A valid index of the deque.
  ///   - `distance`: The distance by which to offset `i`.
  ///
  /// - Returns: An index offset by `distance` from the index `i`. If `distance`
  ///    is positive, this is the same value as the result of `distance` calls
  ///    to `index(after:)`. If `distance` is negative, this is the same value
  ///    as the result of `abs(distance)` calls to `index(before:)`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(_ i: Int, offsetBy distance: Int) -> Int {
    // Note: Like `Array`, index manipulation methods on deques don't trap on
    // invalid indices. (Indices are still validated on element access.)
    return i + distance
  }

  /// Returns an index that is the specified distance from the given index,
  /// unless that distance is beyond a given limiting index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the array.
  ///   - distance: The distance to offset `i`.
  ///   - limit: A valid index of the deque to use as a limit.
  ///      If `distance > 0`, then `limit` has no effect it is less than `i`.
  ///      Likewise, if `distance < 0`, then `limit` has no effect if it is
  ///      greater than `i`.
  ///
  /// - Returns: An index offset by `distance` from the index `i`, unless that
  ///    index would be beyond `limit` in the direction of movement. In that
  ///    case, the method returns `nil`.
  ///
  /// - Complexity: O(1)
  @inlinable
  public func index(
    _ i: Int,
    offsetBy distance: Int,
    limitedBy limit: Int
  ) -> Int? {
    // Note: Like `Array`, index manipulation methods on deques
    // don't trap on invalid indices.
    // (Indices are still validated on element access.)
    let l = limit - i
    if distance > 0 ? l >= 0 && l < distance : l <= 0 && distance < l {
      return nil
    }
    return i + distance
  }


  /// Returns the distance between two indices.
  ///
  /// - Parameters:
  ///   - start: A valid index of the collection.
  ///   - end: Another valid index of the collection.
  ///
  /// - Returns: The distance between `start` and `end`. If `end` is equal to
  ///    `start`, the result is zero. Otherwise the result is positive if `end`
  ///    is greater than `start`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func distance(from start: Int, to end: Int) -> Int {
    // Note: Like `Array`, index manipulation method on deques
    // don't trap on invalid indices.
    // (Indices are still validated on element access.)
    return end - start
  }

  /// Accesses the element at the specified position.
  ///
  /// - Parameters:
  ///   - index: The position of the element to access. `index` must be greater
  ///      than or equal to `startIndex` and less than `endIndex`.
  ///
  /// - Complexity: Reading an element from a deque is O(1). Writing is O(1)
  ///    unless the deque’s storage is shared with another deque, in which case
  ///    writing is O(`count`).
  @inlinable
  public subscript(index: Int) -> Element {
    get {
      precondition(index >= 0 && index < count, "Index out of bounds")
      return _storage.read { $0.ptr(at: $0.slot(forOffset: index)).pointee }
    }
    set {
      precondition(index >= 0 && index < count, "Index out of bounds")
      _storage.ensureUnique()
      _storage.update { handle in
        let slot = handle.slot(forOffset: index)
        handle.ptr(at: slot).pointee = newValue
      }
    }
    _modify {
      precondition(index >= 0 && index < count, "Index out of bounds")
      _storage.ensureUnique()
      // We technically aren't supposed to escape storage pointers out of a
      // managed buffer, so we escape a `(slot, value)` pair instead, leaving
      // the corresponding slot temporarily uninitialized.
      var (slot, value) = _storage.update { handle -> (_Slot, Element) in
        let slot = handle.slot(forOffset: index)
        return (slot, handle.ptr(at: slot).move())
      }
      defer {
        _storage.update { handle in
          handle.ptr(at: slot).initialize(to: value)
        }
      }
      yield &value
    }
  }

  /// Accesses a contiguous subrange of the deque's elements.
  ///
  /// - Parameters:
  ///   - bounds: A range of the deque's indices. The bounds of the range must
  ///      be valid indices of the deque (including the `endIndex`).
  ///
  /// The accessed slice uses the same indices for the same elements as the
  /// original collection.
  @inlinable
  public subscript(bounds: Range<Int>) -> Slice<Self> {
    get {
      precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count,
                   "Invalid bounds")
      return Slice(base: self, bounds: bounds)
    }
    set(source) {
      precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count,
                   "Invalid bounds")
      self.replaceSubrange(bounds, with: source)
    }
  }
}
