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
  
  //// Creates an empty set.
  ///
  /// This initializer is equivalent to initializing with an empty array
  /// literal.
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

// MARK: Adding Elements
extension SortedSet {
  // TODO: document
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func remove(atOffset offset: Int) -> Element {
    return self._root.remove(atOffset: offset).key
  }
  
  // TODO: document
  @inlinable
  @inline(__always)
  public subscript(offset absoluteOffset: Int) -> Element {
    return self._root.index(atOffset: absoluteOffset).element.key
  }
}
