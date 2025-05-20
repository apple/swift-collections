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
  /// Returns the index for a given element, if it exists
  /// - Complexity: O(`log n`)
  @inlinable
  public func index(of element: Element) -> Index? {
    if let index = self._root.findAnyIndex(forKey: element) {
      return Index(index)
    } else {
      return nil
    }
  }
  
  /// The position of an element within a sorted set
  public struct Index {
    @usableFromInline
    internal var _index: _Tree.Index
    
    @inlinable
    @inline(__always)
    internal init(_ _index: _Tree.Index) {
      self._index = _index
    }
  }
}

extension SortedSet.Index: @unchecked Sendable
where Element: Sendable {}

// MARK: Equatable
extension SortedSet.Index: Equatable {
  @inlinable
  public static func ==(lhs: SortedSet.Index, rhs: SortedSet.Index) -> Bool {
    lhs._index.ensureValid(with: rhs._index)
    return lhs._index == rhs._index
  }
}

// MARK: Comparable
extension SortedSet.Index: Comparable {
  @inlinable
  public static func <(lhs: SortedSet.Index, rhs: SortedSet.Index) -> Bool {
    lhs._index.ensureValid(with: rhs._index)
    return lhs._index < rhs._index
  }
}
