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

/// An sorted collection of unique elements.
public struct SortedSet<Element: Comparable> {
  @usableFromInline
  internal typealias _Tree = _BTree<Element, ()>
  
  @usableFromInline
  internal var _root: _Tree
  
  /// Creates an empty set.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public init() {
    self._root = _Tree()
  }
  
  /// Creates a set rooted at a given B-Tree.
  @inlinable
  internal init(_rootedAt tree: _Tree) {
    self._root = tree
  }
}

// MARK: Testing for Membership
extension SortedSet {
  /// Returns a Boolean value that indicates whether the given element exists in the set.
  /// - Complexity: O(`log n`) where `n` is the number of key-value pairs in the
  ///   dictionary.
  @inlinable
  @inline(__always)
  public func contains(_ member: Element) -> Bool {
    self._root.contains(key: member)
  }
}

// MARK: Adding Elements
extension SortedSet {
  /// Inserts the given element in the set if it is not already present.
  ///
  /// - Parameter newMember:
  /// - Returns: `(true, newMember)` if `newMember` was not contained in the
  ///     set. If an element equal to `newMember` was already contained in the set, the
  ///     method returns `(false, oldMember)`, where `oldMember` is the element
  ///     that was equal to `newMember`. In some cases, `oldMember` may be
  ///     distinguishable from `newMember` by identity comparison or some other means.
  /// - Complexity: O(`log n`) where `n` is the number of key-value pairs in the
  ///     dictionary.
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func insert(
    _ newMember: Element
  ) -> (inserted: Bool, memberAfterInsert: Element) {
    if let oldKey = self._root.setAnyValue((), forKey: newMember, updatingKey: false)?.key {
      return (inserted: false, memberAfterInsert: oldKey)
    } else {
      return (inserted: true, memberAfterInsert: newMember)
    }
  }
  
  /// Inserts the given element into the set unconditionally.
  ///
  /// - Parameter newMember: An element to insert into the set.
  /// - Returns: An element equal to `newMember` if the set already contained such a
  ///     member; otherwise, `nil`. In some cases, the returned element may be distinguishable
  ///     from `newMember` by identity comparison or some other means.
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func update(with newMember: Element) -> Element? {
    return self._root.setAnyValue((), forKey: newMember, updatingKey: true)?.key
  }
}
