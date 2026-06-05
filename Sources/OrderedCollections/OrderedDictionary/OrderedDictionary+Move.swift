//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// Reordering implementation.
//
// The keys are an `OrderedSet`. Its move relocates the keys (rearranging the
// element storage and patching the hash table) and calls back with the
// resolved plan; the dictionary uses that callback to apply the same
// rearrangement to the parallel `_values` buffer.

extension OrderedDictionary {
  /// Moves the key-value pairs in the given range to the given index,
  /// preserving their relative order.
  ///
  ///     var d: OrderedDictionary = [0: "a", 1: "b", 2: "c", 3: "d"]
  ///     d.moveSubrange(2 ..< 4, to: 0)
  ///     // d is now [2: "c", 3: "d", 0: "a", 1: "b"]
  ///
  /// - Parameters:
  ///    - range: The range of indices addressing the pairs to move.
  ///    - destination: The index at which the moved pairs should start in the
  ///       resulting dictionary. Must be in the range
  ///       `0 ... count - range.count`.
  ///
  /// - Complexity: O(*d* + *k*) where *d* is the distance between the source
  ///    and destination, and *k* is the number of pairs moved. Falls back
  ///    to O(`count`) for large moves.
  #if compiler(>=6.3)
  @inline(always)
  #else
  @inline(__always)
  #endif
  @inlinable
  public mutating func moveSubrange(
    _ range: some RangeExpression<Index>,
    to destination: Index
  ) {
    _moveSubrange(range.relative(to: elements), to: destination)
  }

  @inlinable
  internal mutating func _moveSubrange(
    _ range: Range<Index>,
    to destination: Index
  ) {
    _keys._moveSubrange(range, to: destination)
    // Apply the same rotation to the values, under the guards the keys use.
    let c = range.count
    if c > 0, range.lowerBound != destination {
      _values.withUnsafeMutableBufferPointer { values in
        values._moveSubrange(
          range.lowerBound ..< range.lowerBound + c, toOffset: destination)
      }
    }
    _checkInvariants()
  }

  /// Moves the pairs with the given keys to the given index, keeping them in
  /// the order the keys appear in `keys`.
  ///
  /// Keys in `keys` that are not present in the dictionary are ignored; only
  /// the pairs whose keys are present are relocated. `keys` must not contain
  /// duplicates.
  ///
  ///     var d: OrderedDictionary = [0: "a", 1: "b", 2: "c", 3: "d"]
  ///     d.move(keys: [3, 0], to: 1)
  ///     // d is now [1: "b", 3: "d", 0: "a", 2: "c"]
  ///
  /// - Parameters:
  ///    - keys: The keys of the pairs to move. Keys that are not present in
  ///       the dictionary are ignored.
  ///    - destination: The index at which the moved pairs should start in the
  ///       resulting dictionary. Must be in the range `0 ... count - k`, where
  ///       `k` is the number of `keys` that are present in the dictionary.
  ///
  /// - Complexity: O(`count`) in the worst case. When the pairs form a
  ///    contiguous range or are moved a short distance, the operation is
  ///    proportional to the distance moved.
  @inlinable
  public mutating func move(
    keys: some Sequence<Key>,
    to destination: Index
  ) {
    _values.withUnsafeMutableBufferPointer { values in
      _keys._move(members: keys, to: destination) {
        sourceOffsets, sortedSources, isContiguousRange in
        values._move(
          sourceOffsets: sourceOffsets,
          sortedSources: sortedSources,
          isContiguousRange: isContiguousRange,
          to: destination)
      }
    }
    _checkInvariants()
  }

  /// Moves the pairs at the given indices to the given index, keeping them in
  /// the order the indices appear in `indices`.
  ///
  /// `indices` must contain distinct, valid indices of the dictionary.
  ///
  ///     var d: OrderedDictionary = [0: "a", 1: "b", 2: "c", 3: "d", 4: "e"]
  ///     d.move(indices: [4, 1], to: 0)
  ///     // d is now [4: "e", 1: "b", 0: "a", 2: "c", 3: "d"]
  ///
  /// - Parameters:
  ///    - indices: The indices of the pairs to move.
  ///    - destination: The index at which the moved pairs should start in the
  ///       resulting dictionary. Must be in the range `0 ... count - k`, where
  ///       `k` is the number of pairs being moved.
  ///
  /// - Complexity: O(`count`) in the worst case. When the pairs form a
  ///    contiguous range or are moved a short distance, the operation is
  ///    proportional to the distance moved.
  @inlinable
  public mutating func move(
    indices: some Sequence<Index>,
    to destination: Index
  ) {
    _values.withUnsafeMutableBufferPointer { values in
      _keys._move(indices: indices, to: destination) {
        sourceOffsets, sortedSources, isContiguousRange in
        values._move(
          sourceOffsets: sourceOffsets,
          sortedSources: sortedSources,
          isContiguousRange: isContiguousRange,
          to: destination)
      }
    }
    _checkInvariants()
  }
}
