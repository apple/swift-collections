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

extension _BTree {
  /// Filters a B-Tree on a predicate, returning a new tree.
  ///
  /// - Complexity: O(`n log n`) where `n` is the number of key-value pairs in the
  ///   sorted dictionary.
  @inlinable
  @inline(__always)
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> _BTree {
    // TODO: optimize implementation to O(n)
    var newTree: _BTree = _BTree()
    for element in self where try isIncluded(element) {
      newTree.setAnyValue(element.value, forKey: element.key)
    }
    return newTree
  }

  
  // MARK: Last Removal
  
  /// Removes the first element of a tree, if it exists.
  ///
  /// - Returns: The moved first element of the tree.
  @inlinable
  @discardableResult
  internal mutating func popLast() -> Element? {
    invalidateIndices()
    
    if self.count == 0 { return nil }
    
    let removedElement = self.root.update { $0.popLastElement() }
    self._balanceRoot()
    return removedElement
  }
  
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func removeLast() -> Element {
    if let value = self.popLast() {
      return value
    } else {
      preconditionFailure("Can't remove last element from an empty collection")
    }
  }

  @inlinable
  @inline(__always)
  public mutating func removeLast(_ k: Int) {
    assert(0 <= k && k < self.count, "Can't remove more items from a collection than it contains")
    for _ in 0..<k {
      self.removeLast()
    }
  }
  
  // MARK: First Removal
  /// Removes the first element of a tree, if it exists.
  ///
  /// - Returns: The moved first element of the tree.
  @inlinable
  @inline(__always)
  @discardableResult
  internal mutating func popFirst() -> Element? {
    invalidateIndices()
    
    if self.count == 0 { return nil }
    
    let removedElement = self.root.update { $0.popFirstElement() }
    self._balanceRoot()
    return removedElement
  }
  
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func removeFirst() -> Element {
    if let value = self.popFirst() {
      return value
    } else {
      preconditionFailure("Can't remove first element from an empty collection")
    }
  }
  
  @inlinable
  @inline(__always)
  public mutating func removeFirst(_ k: Int) {
    assert(0 <= k && k < self.count, "Can't remove more items from a collection than it contains")
    for _ in 0..<k {
      self.removeFirst()
    }
  }
  
  // MARK: Offset Removal
  /// Removes the element of a tree at a given offset.
  ///
  /// - Parameter offset: the offset which must be in-bounds.
  /// - Returns: The moved element of the tree
  @inlinable
  @inline(__always)
  @discardableResult
  internal mutating func remove(at offset: Int) -> Element {
    invalidateIndices()
    let removedElement = self.root.update { $0.remove(at: offset) }
    self._balanceRoot()
    return removedElement
  }
  
  @inlinable
  @inline(__always)
  internal mutating func removeAll() {
    invalidateIndices()
    // TODO: potentially use empty storage class.
    self.root = _Node(withCapacity: _BTree.defaultLeafCapacity, isLeaf: true)
  }
  
  // MARK: Index Removal
  /// Removes the element of a tree at a given index.
  ///
  /// - Parameter index: a valid index of the tree, not `endIndex`
  /// - Returns: The moved element of the tree
  @inlinable
  @inline(__always)
  @discardableResult
  internal mutating func remove(at index: Index) -> Element {
    invalidateIndices()
    guard let path = index.path else { preconditionFailure("Index out of bounds.") }
    return self.remove(at: path.offset)
  }
  
  /// Removes the elements in the specified subrange from the collection.
  @inlinable
  internal mutating func removeSubrange(_ bounds: Range<Index>) {
    guard let startPath = bounds.lowerBound.path else { preconditionFailure("Index out of bounds.") }
    guard let _ = bounds.upperBound.path else { preconditionFailure("Index out of bounds.") }
    
    let rangeSize = self.distance(from: bounds.lowerBound, to: bounds.upperBound)
    let startOffset = startPath.offset
    
    for _ in 0..<rangeSize {
      self.remove(at: startOffset)
    }
  }

}
