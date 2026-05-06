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

  /// Returns the index of the smallest element that is strictly greater than
  /// the given element, or `nil` if no such element exists.
  ///
  /// The element itself does not need to be a member of the set.
  ///
  /// - Parameter element: The element to look after.
  /// - Complexity: O(`log n`)
  @inlinable
  public func firstIndex(after element: Element) -> Index? {
    let i = self._root.startIndex(forKey: element)
    if i == self._root.endIndex { return nil }
    if self._root[i].key == element {
      let next = self._root.index(after: i)
      return next == self._root.endIndex ? nil : Index(next)
    }
    return Index(i)
  }

  /// Returns the index of the largest element that is strictly less than the
  /// given element, or `nil` if no such element exists.
  ///
  /// The element itself does not need to be a member of the set.
  ///
  /// - Parameter element: The element to look before.
  /// - Complexity: O(`log n`)
  @inlinable
  public func lastIndex(before element: Element) -> Index? {
    let i = self._root.startIndex(forKey: element)
    if i == self._root.startIndex { return nil }
    return Index(self._root.index(before: i))
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

#endif
