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

extension SortedDictionary: BidirectionalCollection {
  /// The number of elements in the sorted dictionary.
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var count: Int { self._root.count }
  
  /// A Boolean value that indicates whether the dictionary is empty.
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { self._root.isEmpty }
  
  /// The position of the first element in a nonempty dictionary.
  ///
  /// If the collection is empty, `startIndex` is equal to `endIndex`.
  ///
  /// - Complexity: O(`log n`)
  @inlinable
  @inline(__always)
  public var startIndex: Index { Index(self._root.startIndex) }
  
  /// The dictionary's "past the end" position---that is, the position one
  /// greater than the last valid subscript argument.
  ///
  /// If the collection is empty, `endIndex` is equal to `startIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var endIndex: Index { Index(self._root.endIndex) }
  
  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    return self._root.distance(from: start._index, to: end._index)
  }
  
  @inlinable
  public func formIndex(after index: inout Index) {
    index._index.ensureValid(for: self._root)
    self._root.formIndex(after: &index._index)
  }
  
  @inlinable
  public func index(after index: Index) -> Index {
    index._index.ensureValid(for: self._root)
    return Index(self._root.index(after: index._index))
  }
  
  @inlinable
  public func formIndex(before index: inout Index) {
    index._index.ensureValid(for: self._root)
    self._root.formIndex(before: &index._index)
  }
  
  @inlinable
  public func index(before index: Index) -> Index {
    index._index.ensureValid(for: self._root)
    return Index(self._root.index(before: index._index))
  }
  
  @inlinable
  public func formIndex(_ i: inout Index, offsetBy distance: Int) {
    i._index.ensureValid(for: self._root)
    self._root.formIndex(&i._index, offsetBy: distance)
  }
  
  @inlinable
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    i._index.ensureValid(for: self._root)
    return Index(self._root.index(i._index, offsetBy: distance))
  }
  
  @inlinable
  public subscript(position: Index) -> Element {
    position._index.ensureValid(for: self._root)
    return self._root[position._index]
  }
}
