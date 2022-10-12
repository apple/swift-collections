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
}
