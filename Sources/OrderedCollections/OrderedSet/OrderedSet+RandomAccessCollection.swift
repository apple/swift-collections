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

extension OrderedSet: RandomAccessCollection {
  /// The index type for ordered sets, `Int`.
  ///
  /// `OrderedSet` indices are integer offsets from the start of the collection,
  /// starting at zero for the first element (if exists).
  public typealias Index = Int

  /// The type that represents the indices that are valid for subscripting an
  /// ordered set, in ascending order.
  public typealias Indices = Range<Int>

  // For SubSequence, see OrderedSet+SubSequence.swift.

  /// The position of the first element in a nonempty ordered set.
  ///
  /// For an instance of `OrderedSet`, `startIndex` is always zero. If the set
  /// is empty, `startIndex` is equal to `endIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var startIndex: Index { _elements.startIndex }

  /// The set's "past the end" position---that is, the position one greater
  /// than the last valid subscript argument.
  ///
  /// In an `OrderedSet`, `endIndex` always equals the count of elements.
  /// If the set is empty, `endIndex` is equal to `startIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var endIndex: Index { _elements.endIndex }

  /// The indices that are valid for subscripting the collection, in ascending
  /// order.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var indices: Indices { _elements.indices }

  /// Returns the position immediately after the given index.
  ///
  /// The specified index must be a valid index less than `endIndex`, or the
  /// returned value won't be a valid index in the set.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Returns: The index immediately after `i`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(after i: Index) -> Index { i + 1 }

  /// Returns the position immediately before the given index.
  ///
  /// The specified index must be a valid index greater than `startIndex`, or
  /// the returned value won't be a valid index in the set.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Returns: The index immediately before `i`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(before i: Index) -> Index { i - 1 }

  /// Replaces the given index with its successor.
  ///
  /// The specified index must be a valid index less than `endIndex`, or the
  /// returned value won't be a valid index in the set.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func formIndex(after i: inout Index) { i += 1 }

  /// Replaces the given index with its predecessor.
  ///
  /// The specified index must be a valid index greater than `startIndex`, or
  /// the returned value won't be a valid index in the set.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func formIndex(before i: inout Index) { i -= 1 }

  /// Returns an index that is the specified distance from the given index.
  ///
  /// The value passed as `distance` must not offset `i` beyond the bounds of
  /// the collection, or the returned value will not be a valid index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the set.
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
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
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
  ///   - i: A valid index of the set.
  ///   - distance: The distance to offset `i`.
  ///   - limit: A valid index of the collection to use as a limit. If
  ///     `distance > 0`, `limit` has no effect if it is less than `i`.
  ///     Likewise, if `distance < 0`, `limit` has no effect if it is greater
  ///     than `i`.
  /// - Returns: An index offset by `distance` from the index `i`, unless that
  ///   index would be beyond `limit` in the direction of movement. In that
  ///   case, the method returns `nil`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(
    _ i: Index,
    offsetBy distance: Int,
    limitedBy limit: Index
  ) -> Index? {
    _elements.index(i, offsetBy: distance, limitedBy: limit)
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
  public func distance(from start: Index, to end: Index) -> Int {
    end - start
  }

  /// Accesses the element at the specified position.
  ///
  /// - Parameter index: The position of the element to access. `index` must be
  ///   greater than or equal to `startIndex` and less than `endIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public subscript(position: Index) -> Element {
    _elements[position]
  }

  /// Accesses a contiguous subrange of the set's elements.
  ///
  /// The returned `Subsequence` instance uses the same indices for the same
  /// elements as the original set. In particular, that slice, unlike an
  /// `OrderedSet`, may have a nonzero `startIndex` and an `endIndex` that is
  /// not equal to `count`. Always use the slice's `startIndex` and `endIndex`
  /// properties instead of assuming that its indices start or end at a
  /// particular value.
  ///
  /// - Parameter bounds: A range of valid indices in the set.
  ///
  /// - Complexity: O(1)
  @inlinable
  public subscript(bounds: Range<Index>) -> SubSequence {
    _failEarlyRangeCheck(bounds, bounds: startIndex ..< endIndex)
    return SubSequence(base: self, bounds: bounds)
  }

  /// A Boolean value indicating whether the collection is empty.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { _elements.isEmpty }

  /// The number of elements in the set.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var count: Int { _elements.count }

  @inlinable
  public func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    guard let table = _table else {
      return _elements._customIndexOfEquatableElement(element)
    }
    return table.read { hashTable in
      let (o, _) = hashTable._find(element, in: _elements)
      guard let offset = o else { return .some(nil) }
      return offset
    }
  }

  @inlinable
  @inline(__always)
  public func _customLastIndexOfEquatableElement(_ element: Element) -> Index?? {
    // OrderedSet holds unique elements.
    _customIndexOfEquatableElement(element)
  }

  @inlinable
  @inline(__always)
  public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {
    _elements._failEarlyRangeCheck(index, bounds: bounds)
  }

  @inlinable
  @inline(__always)
  public func _failEarlyRangeCheck(_ index: Index, bounds: ClosedRange<Index>) {
    _elements._failEarlyRangeCheck(index, bounds: bounds)
  }

  @inlinable
  @inline(__always)
  public func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>) {
    _elements._failEarlyRangeCheck(range, bounds: bounds)
  }
}
