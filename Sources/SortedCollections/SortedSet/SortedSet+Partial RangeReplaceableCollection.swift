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

extension SortedSet {
  /// Returns a new sorted set containing the members of the set that satisfy the given
  /// predicate.
  /// - Complexity: O(`n log n`) where `n` is the number of members in the
  ///   sorted set.
  @inlinable
  @inline(__always)
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> SortedSet {
    let newTree: _Tree = try self._root.filter({ try isIncluded($0.key) })
    return SortedSet(_rootedAt: newTree)
  }
  
  /// Removes and returns the first element of the collection.
  ///
  /// Calling this method may invalidate all saved indices of this collection. Do not rely on a
  /// previously stored index value after altering a collection with any operation that can change
  /// its length.
  ///
  /// - Returns: The first element of the collection if the collection is not empty; otherwise, nil.
  /// - Complexity: O(`log n`) where `n` is the number of members in the
  ///   sorted set.
  @inlinable
  @inline(__always)
  public mutating func popFirst() -> Element? {
    self._root.popFirst()?.key
  }
  
  /// Removes and returns the last element of the collection.
  ///
  /// Calling this method may invalidate all saved indices of this collection. Do not rely on a
  /// previously stored index value after altering a collection with any operation that can change
  /// its length.
  ///
  /// - Returns: The last element of the collection if the collection is not empty; otherwise, nil.
  /// - Complexity: O(`log n`) where `n` is the number of members in the
  ///   sorted set.
  @inlinable
  @inline(__always)
  public mutating func popLast() -> Element? {
    self._root.popLast()?.key
  }
  
  /// Removes and returns the first element of the collection.
  ///
  /// The collection must not be empty.
  ///
  /// Calling this method may invalidate all saved indices of this collection. Do not rely on a
  /// previously stored index value after altering a collection with any operation that can change
  /// its length.
  ///
  /// - Returns: The first element of the collection if the collection is not empty; otherwise, nil.
  /// - Complexity: O(`log n`) where `n` is the number of members in the
  ///   sorted set.
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func removeFirst() -> Element {
    self._root.removeFirst().key
  }
  
  /// Removes and returns the last element of the collection.
  ///
  /// The collection must not be empty.
  ///
  /// Calling this method may invalidate all saved indices of this collection. Do not rely on a
  /// previously stored index value after altering a collection with any operation that can change
  /// its length.
  ///
  /// - Returns: The last element of the collection if the collection is not empty; otherwise, nil.
  /// - Complexity: O(`log n`) where `n` is the number of members in the
  ///   sorted set.
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func removeLast() -> Element {
    self._root.removeLast().key
  }
  
  /// Removes the specified number of elements from the beginning of the collection.
  ///
  /// Calling this method may invalidate all saved indices of this collection. Do not rely on a
  /// previously stored index value after altering a collection with any operation that can change
  /// its length.
  ///
  /// - Parameter k: The number of elements to remove from the collection. `k` must be greater
  ///     than or equal to zero and must not exceed the number of elements in the collection.
  /// - Complexity: O(`k log n`) where `n` is the number of members in the
  ///   sorted set.
  @inlinable
  @inline(__always)
  public mutating func removeFirst(_ k: Int) {
    self._root.removeFirst(k)
  }
  
  /// Removes the specified number of elements from the end of the collection.
  ///
  /// Calling this method may invalidate all saved indices of this collection. Do not rely on a
  /// previously stored index value after altering a collection with any operation that can change
  /// its length.
  ///
  /// - Parameter k: The number of elements to remove from the collection. `k` must be greater
  ///     than or equal to zero and must not exceed the number of elements in the collection.
  /// - Complexity: O(`k log n`) where `n` is the number of members in the
  ///   sorted set.
  @inlinable
  @inline(__always)
  public mutating func removeLast(_ k: Int) {
    self._root.removeLast(k)
  }

  
  /// Removes and returns the key-value pair at the specified index.
  ///
  /// Calling this method invalidates any existing indices for use with this sorted dictionary.
  ///
  /// - Parameter index: The position of the key-value pair to remove. `index`
  ///     must be a valid index of the sorted dictionary, and must not equal the sorted
  ///     dictionary’s end index.
  /// - Returns: The key-value pair that correspond to `index`.
  /// - Complexity: O(`log n`) where `n` is the number of members in the
  ///   sorted set.
  @inlinable
  @inline(__always)
  public mutating func remove(at index: Index) -> Element {
    index._index.ensureValid(forTree: self._root)
    return self._root.remove(at: index._index).key
  }
  
  /// Removes the specified subrange of elements from the collection.
  ///
  /// - Parameter bounds: The subrange of the collection to remove. The bounds of the
  ///     range must be valid indices of the collection.
  /// - Returns: The key-value pair that correspond to `index`.
  /// - Complexity: O(`m log n`) where `n` is the number of elements in the
  ///   sorted set, and `m` is the size of `bounds`
  @inlinable
  @inline(__always)
  internal mutating func removeSubrange<R: RangeExpression>(
    _ bounds: R
  ) where R.Bound == Index {
    // TODO: optimize to not perform excessive traversals
    let bounds = bounds.relative(to: self)
    
    bounds.upperBound._index.ensureValid(forTree: self._root)
    bounds.lowerBound._index.ensureValid(forTree: self._root)
    
    return self._root.removeSubrange(Range(uncheckedBounds: (bounds.lowerBound._index, bounds.upperBound._index)))
  }
  
  /// Removes all elements from the set.
  ///
  /// Calling this method invalidates all indices with respect to the set.
  ///
  /// - Complexity: O(`n`)
  @inlinable
  @inline(__always)
  public mutating func removeAll() {
    self._root.removeAll()
  }
}

