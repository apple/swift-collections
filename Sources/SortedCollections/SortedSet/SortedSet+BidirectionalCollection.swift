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

extension SortedSet: BidirectionalCollection {
  /// The number of elements in the sorted set.
  /// 
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var count: Int { self._root.count }
  
  /// A Boolean value that indicates whether the set is empty.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { self._root.isEmpty }
  
  /// The position of the first element in a nonempty set.
  ///
  /// If the collection is empty, `startIndex` is equal to `endIndex`.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  public var startIndex: Index { Index(self._root.startIndex) }
  
  /// The set's "past the end" position---that is, the position one
  /// greater than the last valid subscript argument.
  ///
  /// If the collection is empty, `endIndex` is equal to `startIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var endIndex: Index { Index(self._root.endIndex) }
  
  /// Returns the distance between two indices.
  ///
  /// - Parameters:
  ///   - start: A valid index of the collection.
  ///   - end: Another valid index of the collection. If end is equal to start, the result is zero.
  /// - Returns: The distance between start and end. The result can be negative.
  /// - Complexity: O(1)
  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    start._index.ensureValid(forTree: self._root)
    end._index.ensureValid(forTree: self._root)
    return self._root.distance(from: start._index, to: end._index)
  }
  
  /// Replaces the given index with its successor.
  ///
  /// - Parameter index: A valid index of the collection. `index` must be less than `endIndex`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  public func formIndex(after index: inout Index) {
    index._index.ensureValid(forTree: self._root)
    self._root.formIndex(after: &index._index)
  }
  
  /// Returns the position immediately after the given index.
  ///
  /// - Parameter index: A valid index of the collection. `index` must be less than `endIndex`.
  /// - Returns: The index value immediately after `index`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  public func index(after index: Index) -> Index {
    index._index.ensureValid(forTree: self._root)
    return Index(self._root.index(after: index._index))
  }
  
  /// Replaces the given index with its predecessor.
  ///
  /// - Parameter index: A valid index of the collection. `index` must be greater
  ///     than `startIndex`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  public func formIndex(before index: inout Index) {
    index._index.ensureValid(forTree: self._root)
    self._root.formIndex(before: &index._index)
  }
  
  /// Returns the position immediately before the given index.
  ///
  /// - Parameter index: A valid index of the collection. `index` must be greater
  ///     than `startIndex`.
  /// - Returns: The index value immediately before `index`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  public func index(before index: Index) -> Index {
    index._index.ensureValid(forTree: self._root)
    return Index(self._root.index(before: index._index))
  }
  
  /// Offsets the given index by the specified distance.
  ///
  /// The value passed as distance must not offset i beyond the bounds of the collection.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  public func formIndex(_ i: inout Index, offsetBy distance: Int) {
    i._index.ensureValid(forTree: self._root)
    self._root.formIndex(&i._index, offsetBy: distance)
  }
  
  /// Returns an index that is the specified distance from the given index.
  /// 
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  /// - Returns: An index offset by `distance` from the index `i`. If `distance`
  ///     is positive, this is the same value as the result of `distance` calls to
  ///     `index(after:)`. If `distance` is negative, this is the same value as the
  ///     result of `abs(distance)` calls to `index(before:)`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    i._index.ensureValid(forTree: self._root)
    return Index(self._root.index(i._index, offsetBy: distance))
  }
  
  /// Returns an index that is the specified distance from the given index, unless that distance is beyond
  /// a given limiting index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  ///   - limit: A valid index of the collection to use as a limit. If `distance > 0`, a limit that is less
  ///       than `i` has no effect. Likewise, if `distance < 0`, a limit that is greater than `i` has
  ///       no effect.
  /// - Returns: An index offset by `distance` from the index `i`, unless that index would be
  ///     beyond `limit` in the direction of movement. In that case, the method returns `nil`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    i._index.ensureValid(forTree: self._root)
    limit._index.ensureValid(forTree: self._root)
    if let i = self._root.index(i._index, offsetBy: distance, limitedBy: limit._index) {
      return Index(i)
    } else {
      return nil
    }
  }
  
  /// Offsets the given index by the specified distance, or so that it equals the given limiting index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  ///   - limit: A valid index of the collection to use as a limit. If `distance > 0`, a limit that is less
  ///       than `i` has no effect. Likewise, if `distance < 0`, a limit that is greater than `i` has
  ///       no effect.
  /// - Returns: `true` if `i` has been offset by exactly `distance` steps without going beyond
  ///     `limit`; otherwise, `false`. When the return value is `false`, the value of `i` is
  ///     equal to `limit`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  internal func formIndex(_ i: inout Index, offsetBy distance: Int, limitedBy limit: Self.Index) -> Bool {
    i._index.ensureValid(forTree: self._root)
    limit._index.ensureValid(forTree: self._root)
    return self._root.formIndex(&i._index, offsetBy: distance, limitedBy: limit._index)
  }
}
