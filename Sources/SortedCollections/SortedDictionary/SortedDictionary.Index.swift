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

extension SortedDictionary {
  /// Returns the index for a given key, if it exists
  /// - Complexity: O(`log n`)
  @inlinable
  public func index(forKey key: Key) -> Index? {
    if let index = self._root.anyIndex(forKey: key) {
      return Index(index)
    } else {
      return nil
    }
  }
  
  /// The position of an element within a sorted dictionary
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

// MARK: Equatable
extension SortedDictionary.Index: Equatable {
  // TODO: Potentially validate if lhs & rhs aren't pointing to deallocated dictionaries.
  @inlinable
  public static func ==(lhs: SortedDictionary.Index, rhs: SortedDictionary.Index) -> Bool {
    lhs._index.ensureValid(with: rhs._index)
    return lhs._index == rhs._index
  }
}

// MARK: Comparable
extension SortedDictionary.Index: Comparable {
  @inlinable
  public static func <(lhs: SortedDictionary.Index, rhs: SortedDictionary.Index) -> Bool {
    lhs._index.ensureValid(with: rhs._index)
    return lhs._index < rhs._index
  }
}
