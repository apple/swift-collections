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

#if UnstableSortedCollections

extension SortedSet {
  @inlinable
  public subscript(position: Index) -> Element {
    position._index.ensureValid(forTree: self._root)
    return self._root[position._index].key
  }

  @inlinable
  public subscript(bounds: Range<Index>) -> SubSequence {
    bounds.lowerBound._index.ensureValid(forTree: self._root)
    bounds.upperBound._index.ensureValid(forTree: self._root)
    let bounds = bounds.lowerBound._index ..< bounds.upperBound._index
    return SubSequence(_root[bounds])
  }


  /// Returns a sequence of elements in the collection bounded by the provided
  /// range.
  ///
  /// This is particularly useful when applied with a bound corresponding to some
  /// group of elements.
  ///
  ///     let students: SortedSet = ...
  ///     students["A"..<"B"]  // Sequence of students with names beginning with "A"
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  public subscript(range: Range<Element>) -> SubSequence {
    let start = _root.startIndex(forKey: range.lowerBound)
    let end = _root.startIndex(forKey: range.upperBound)
    let range = _Tree.SubSequence(base: _root, bounds: start..<end)
    return SubSequence(range)
  }

  /// Returns the elements in the closed value range `range.lowerBound` through
  /// `range.upperBound`, inclusive.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  public subscript(range: ClosedRange<Element>) -> SubSequence {
    let start = _root.startIndex(forKey: range.lowerBound)
    let end = _firstTreeIndex(after: range.upperBound)
    return SubSequence(_root[start..<end])
  }

  /// Returns the elements whose value is greater than or equal to
  /// `range.lowerBound`.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  public subscript(range: PartialRangeFrom<Element>) -> SubSequence {
    let start = _root.startIndex(forKey: range.lowerBound)
    return SubSequence(_root[start..<_root.endIndex])
  }

  /// Returns the elements whose value is strictly less than `range.upperBound`.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  public subscript(range: PartialRangeUpTo<Element>) -> SubSequence {
    let end = _root.startIndex(forKey: range.upperBound)
    return SubSequence(_root[_root.startIndex..<end])
  }

  /// Returns the elements whose value is less than or equal to
  /// `range.upperBound`.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  public subscript(range: PartialRangeThrough<Element>) -> SubSequence {
    let end = _firstTreeIndex(after: range.upperBound)
    return SubSequence(_root[_root.startIndex..<end])
  }

  /// Returns the first `_BTree` index whose element is strictly greater than
  /// `element`, or the tree's `endIndex` if no such element exists.
  @inlinable
  internal func _firstTreeIndex(after element: Element) -> _Tree.Index {
    let i = _root.startIndex(forKey: element)
    if i == _root.endIndex { return i }
    if _root[i].key == element {
      return _root.index(after: i)
    }
    return i
  }
}

#endif
