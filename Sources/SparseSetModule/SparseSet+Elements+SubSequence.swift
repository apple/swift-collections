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

extension SparseSet.Elements {
  /// A collection that represents a contiguous slice of a sparse set.
  ///
  /// Sparse set slices are random access collections that support efficient
  /// key-based lookups.
  @frozen
  public struct SubSequence {
    @usableFromInline
    internal var _base: SparseSet
    @usableFromInline
    internal var _bounds: Range<Int>

    @inlinable
    @inline(__always)
    internal init(_base: SparseSet, bounds: Range<Int>) {
      self._base = _base
      self._bounds = bounds
    }
  }
}

extension SparseSet.Elements.SubSequence {
  /// A read-only collection view containing the keys in this slice.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var keys: Array<Key>.SubSequence {
    _base.keys[_bounds]
  }

  /// A read-only collection view containing the values in this slice.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var values: SparseSet.Values.SubSequence {
    _base.values[_bounds]
  }
}

extension SparseSet.Elements.SubSequence {
  /// Returns the index for the given key.
  ///
  /// If the given key is found in the sparse set, this method returns an index
  /// into the sparse set that corresponds with the key-value pair.
  ///
  /// - Parameter key: The key to find in the sparse set.
  ///
  /// - Returns: The index for `key` and its associated value if `key` is in
  ///   the sparse set; otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @inlinable
  public func index(forKey key: Key) -> Int? {
    guard let index = _base.index(forKey: key) else { return nil }
    guard _bounds.contains(index) else { return nil }
    return index
  }
}

extension SparseSet.Elements.SubSequence: Sequence {
  // A type representing the collection’s elements.
  public typealias Element = SparseSet.Element

  /// The type that allows iteration over the collection's elements.
  @frozen
  public struct Iterator: IteratorProtocol {
    @usableFromInline
    internal var _base: SparseSet

    @usableFromInline
    internal var _end: Int

    @usableFromInline
    internal var _index: Int

    @inlinable
    @inline(__always)
    internal init(_base: SparseSet.Elements.SubSequence) {
      self._base = _base._base
      self._end = _base._bounds.upperBound
      self._index = _base._bounds.lowerBound
    }

    /// Advances to the next element and returns it, or `nil` if no next
    /// element exists.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func next() -> Element? {
      guard _index < _end else { return nil }
      defer { _index += 1 }
      return (_base._dense.keys[_index], _base._dense.values[_index])
    }
  }

  /// Returns an iterator over the elements of this sparse set slice.
  @inlinable
  @inline(__always)
  public func makeIterator() -> Iterator {
    Iterator(_base: self)
  }
}

extension SparseSet.Elements.SubSequence: RandomAccessCollection {
  /// The index type for a sparse set: `Int`.
  ///
  /// The indices are integer offsets from the start of the original (unsliced)
  /// collection.
  public typealias Index = Int

  /// The type that represents the indices that are valid for subscripting a
  /// sparse set, in ascending order.
  public typealias Indices = Range<Int>

  /// Sparse set subsequences are self-slicing.
  public typealias SubSequence = Self

  /// The position of the first element in a nonempty sparse set slice.
  ///
  /// Note that instances of `SparseSet.SubSequence` generally don't have a
  /// `startIndex` with an offset of zero.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var startIndex: Int { _bounds.lowerBound }

  /// The "past the end" position---that is, the position one greater than the
  /// last valid subscript argument.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var endIndex: Int { _bounds.upperBound }

  /// The indices that are valid for subscripting the collection, in ascending
  /// order.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var indices: Range<Int> { _bounds }

  /// Returns the position immediately after the given index.
  ///
  /// The specified index must be a valid index less than `endIndex`, or the
  /// returned value won't be a valid index in the sparse set.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Returns: The index immediately after `i`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(after i: Int) -> Int { i + 1 }

  /// Returns the position immediately before the given index.
  ///
  /// The specified index must be a valid index greater than `startIndex`, or
  /// the returned value won't be a valid index in the sparse set.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Returns: The index immediately before `i`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(before i: Int) -> Int { i - 1 }

  /// Replaces the given index with its successor.
  ///
  /// The specified index must be a valid index less than `endIndex`, or the
  /// returned value won't be a valid index in the sparse set.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func formIndex(after i: inout Int) { i += 1 }

  /// Replaces the given index with its predecessor.
  ///
  /// The specified index must be a valid index greater than `startIndex`, or
  /// the returned value won't be a valid index in the sparse set.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func formIndex(before i: inout Int) { i -= 1 }

  /// Returns an index that is the specified distance from the given index.
  ///
  /// The value passed as `distance` must not offset `i` beyond the bounds of
  /// the collection, or the returned value will not be a valid index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the sparse set.
  ///   - distance: The distance to offset `i`.
  ///
  /// - Returns: An index offset by `distance` from the index `i`. If `distance`
  ///   is positive, this is the same value as the result of `distance` calls to
  ///   `index(after:)`. If `distance` is negative, this is the same value as
  ///   the result of `abs(distance)` calls to `index(before:)`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(_ i: Int, offsetBy distance: Int) -> Int {
    i + distance
  }

  /// Returns an index that is the specified distance from the given index,
  /// unless that distance is beyond a given limiting index.
  ///
  /// The value passed as `distance` must not offset `i` beyond the bounds of
  /// the collection, unless the index passed as `limit` prevents offsetting
  /// beyond those bounds. (Otherwise the returned value won't be a valid index
  /// in the set.)
  ///
  /// - Parameters:
  ///   - i: A valid index of the sparse set.
  ///   - distance: The distance to offset `i`.
  ///   - limit: A valid index of the collection to use as a limit. If
  ///     `distance > 0`, `limit` has no effect if it is less than `i`.
  ///     Likewise, if `distance < 0`, `limit` has no effect if it is greater
  ///     than `i`.
  ///     
  /// - Returns: An index offset by `distance` from the index `i`, unless that
  ///   index would be beyond `limit` in the direction of movement. In that
  ///   case, the method returns `nil`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(
    _ i: Int,
    offsetBy distance: Int,
    limitedBy limit: Int
  ) -> Int? {
    _base._dense.keys.index(i, offsetBy: distance, limitedBy: limit)
  }

  /// Returns the distance between two indices.
  ///
  /// - Parameters:
  ///   - start: A valid index of the collection.
  ///   - end: Another valid index of the collection. If `end` is equal to
  ///     `start`, the result is zero.
  ///
  /// - Returns: The distance between `start` and `end`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func distance(from start: Int, to end: Int) -> Int {
    end - start
  }

  /// Accesses the element at the specified position.
  ///
  /// - Parameter index: The position of the element to access. `index` must be
  ///   greater than or equal to `startIndex` and less than `endIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  public subscript(position: Int) -> Element {
    precondition(_bounds.contains(position), "Index out of range")
    return _base[offset: position]
  }

  /// Accesses a contiguous subrange of the sparse set's elements.
  ///
  /// The returned `Subsequence` instance uses the same indices for the same
  /// elements as the original sparse set. In particular, that slice, unlike a
  /// `SparseSet`, may have a nonzero `startIndex.offset` and an
  /// `endIndex.offset` that is not equal to `count`. Always use the slice's
  /// `startIndex` and `endIndex` properties instead of assuming that its
  /// indices start or end at a particular value.
  ///
  /// - Parameter bounds: A range of valid indices in the sparse set.
  ///
  /// - Complexity: O(1)
  @inlinable
  public subscript(bounds: Range<Int>) -> SubSequence {
    precondition(
      bounds.lowerBound >= _bounds.lowerBound
      && bounds.upperBound <= _bounds.upperBound,
      "Index out of range")
    return Self(_base: _base, bounds: bounds)
  }

  /// A Boolean value indicating whether the collection is empty.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { _bounds.isEmpty }

  /// The number of elements in the sparse set.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var count: Int { _bounds.count }
}
