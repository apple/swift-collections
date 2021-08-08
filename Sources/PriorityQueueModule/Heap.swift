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

/// A [Min-Max Heap](https://en.wikipedia.org/wiki/Min-max_heap) data structure.
///
/// In a min-max heap, each node at an even level in the tree is less than all
/// its descendants, while each node at an odd level in the tree is greater than
/// all of its descendants.
///
/// The implementation is based on [Atkinson 1986]:
///
/// [Atkinson 1986]: https://doi.org/10.1145/6617.6621
///
/// M.D. Atkinson, J.-R. Sack, N. Santoro, T. Strothotte.
/// "Min-Max Heaps and Generalized Priority Queues."
/// *Communications of the ACM*, vol. 29, no. 10, Oct. 1986., pp. 996-1000,
/// doi:[10.1145/6617.6621](https://doi.org/10.1145/6617.6621)
public struct Heap<Element: Comparable> {
  @usableFromInline
  internal var _storage: [Element]

  /// A Boolean value indicating whether or not the heap is empty.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public var isEmpty: Bool {
    _storage.isEmpty
  }

  /// The number of elements in the heap.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public var count: Int {
    _storage.count
  }

  /// A read-only view into the underlying array.
  ///
  /// Note: The elements aren't _arbitrarily_ ordered (it is, after all, a
  /// heap). However, no guarantees are given as to the ordering of the elements
  /// or that this won't change in future versions of the library.
  ///
  /// - Complexity: O(1)
  @inlinable
  public var unordered: [Element] {
    _storage
  }

  /// Creates an empty heap.
  @inlinable
  public init() {
    _storage = []
  }

  /// Inserts the given element into the heap.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func insert(_ element: Element) {
    _storage.append(element)
    _bubbleUp(elementAt: _Node(offset: _storage.endIndex - 1))
    _checkInvariants()
  }

  /// Returns the element with the lowest priority, if available.
  ///
  /// - Complexity: O(1)
  @inlinable
  public func min() -> Element? {
    _storage.first
  }

  /// Returns the element with the highest priority, if available.
  ///
  /// - Complexity: O(1)
  @inlinable
  public func max() -> Element? {
    switch _storage.count {
    case 0, 1, 2:
      // If count is 0, `last` will return `nil`
      // If count is 1, the last (and only) item is the max
      // If count is 2, the last item is the max (as it's the only item in the
      // first max level)
      return _storage.last
    default:
      // We have at least 3 items -- return the larger of the two in the first
      // max level
      return Swift.max(_storage[1], _storage[2])
    }
  }

  /// Removes and returns the element with the lowest priority, if available.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func popMin() -> Element? {
    defer { _checkInvariants() }
    return _remove(at: .root)
  }

  /// Removes and returns the element with the highest priority, if available.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func popMax() -> Element? {
    defer { _checkInvariants() }
    guard count > 2 else {
      // If count is 0, `popLast` will return `nil`
      // If count is 1, the last (and only) item is the max
      // If count is 2, the last item is the max (as it's the only item in the
      // first max level)
      return _storage.popLast()
    }
    // The max item is the larger of the two items in the first max level
    let max = _Node(offset: _storage[2] > _storage[1] ? 2 : 1)
    return _remove(at: max)
  }

  /// Removes and returns the element with the lowest priority.
  ///
  /// The heap *must not* be empty.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func removeMin() -> Element {
    return popMin()!
  }

  /// Removes and returns the element with the highest priority.
  ///
  /// The heap *must not* be empty.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func removeMax() -> Element {
    return popMax()!
  }

  // MARK: -

  @inlinable @inline(__always)
  internal func _element(at index: _Node) -> Element {
    _storage[index.offset]
  }

  @inline(__always)
  @inlinable
  internal mutating func _bubbleUp(elementAt node: _Node) {
    guard let parent = node.parent() else {
      // We're already at the root -- can't go any further
      return
    }

    if node.isMinLevel {
      if _element(at: node) > _element(at: parent) {
        _swapAt(node, parent)
        _bubbleUpMax(elementAt: parent)
      } else {
        _bubbleUpMin(elementAt: node)
      }
    } else {
      if _element(at: node) < _element(at: parent) {
        _swapAt(node, parent)
        _bubbleUpMin(elementAt: parent)
      } else {
        _bubbleUpMax(elementAt: node)
      }
    }
  }

  @inline(__always)
  @inlinable
  internal mutating func _bubbleUpMin(elementAt node: _Node) {
    var node = node

    while let grandparent = node.grandParent(),
          _element(at: node) < _element(at: grandparent) {
      _swapAt(node, grandparent)
      node = grandparent
    }
  }

  @inline(__always)
  @inlinable
  internal mutating func _bubbleUpMax(elementAt node: _Node) {
    var node = node

    while let grandparent = node.grandParent(),
          _element(at: node) > _element(at: grandparent) {
      _swapAt(node, grandparent)
      node = grandparent
    }
  }

  // MARK: -

  @discardableResult
  @inline(__always)
  @inlinable
  internal mutating func _remove(at node: _Node) -> Element? {
    guard _storage.count > node.offset else {
      return nil
    }

    var removed = _storage.removeLast()

    if node.offset < _storage.count {
      swap(&removed, &_storage[node.offset])
      _trickleDown(elementAt: node)
    }

    return removed
  }

  // MARK: -

  @inline(__always)
  @inlinable
  internal mutating func _trickleDown(elementAt node: _Node) {
    if node.isMinLevel {
      _trickleDownMin(elementAt: node)
    } else {
      _trickleDownMax(elementAt: node)
    }
  }
 
  @inline(__always)
  @inlinable
  internal mutating func _trickleDownMin(elementAt node: _Node) {
    var node = node

    while let minDescendant = _minChildOrGrandchild(of: node) {
      guard _element(at: minDescendant) < _element(at: node) else {
        return
      }
      _swapAt(minDescendant, node)

      if minDescendant.level == node.level + 1 {
        return
      }

      // Smallest is a grandchild
      let parent = minDescendant.parent()!
      if _element(at: minDescendant) > _element(at: parent) {
        _swapAt(minDescendant, parent)
      }

      node = minDescendant
    }
  }

  @inline(__always)
  @inlinable
  internal mutating func _trickleDownMax(elementAt node: _Node) {
    var node = node

    while let maxDescendant = _maxChildOrGrandchild(of: node) {
      guard _element(at: maxDescendant) > _element(at: node) else {
        return
      }
      _swapAt(maxDescendant, node)

      if maxDescendant.level == node.level + 1 {
        return
      }

      // Largest is a grandchild
      let parent = maxDescendant.parent()!
      if _element(at: maxDescendant) < _element(at: parent) {
        _swapAt(maxDescendant, parent)
      }

      node = maxDescendant
    }
  }

  /// Returns the lowest priority child or grandchild of the element at the
  /// given index.
  ///
  /// Returns `nil` if the element has no descendants.
  ///
  /// - parameter index: The index of the element whose descendants should be
  ///                    compared.
  @inline(__always)
  @inlinable
  internal func _minChildOrGrandchild(of node: _Node) -> _Node? {
    assert(node.isMinLevel)
    guard let leftChild = node.leftChild(limit: count) else {
      return nil
    }

    guard let rightChild = node.rightChild(limit: count) else {
      return leftChild
    }

    guard let grandchildren = node.grandchildren(limit: count) else {
      // We have no grandchildren -- compare the two children instead
      return (_element(at: rightChild) < _element(at: leftChild)
              ? rightChild
              : leftChild)
    }

    var minValue = _element(at: leftChild)
    var minNode = leftChild

    // If we have at least 3 grandchildren, we can skip comparing the children
    // as the heap invariants will ensure that the grandchildren will be smaller.
    // Otherwise, we need to do the comparison.
    if grandchildren._count < 3 {
      // Compare the two children
      let rightValue = _element(at: rightChild)
      if rightValue < minValue {
        minValue = rightValue
        minNode = rightChild
      }
    }

    // Iterate through the grandchildren
    grandchildren._forEach { grandchild in
      let value = _element(at: grandchild)
      if value < minValue {
        minValue = value
        minNode = grandchild
      }
    }

    return minNode
  }

  /// Returns the highest priority child or grandchild of the element at the
  /// given index.
  ///
  /// Returns `nil` if the element has no descendants.
  ///
  /// - parameter index: The index of the item whose descendants should be
  ///                    compared.
  @inline(__always)
  @inlinable
  internal func _maxChildOrGrandchild(of node: _Node) -> _Node? {
    assert(!node.isMinLevel)
    guard let leftChild = node.leftChild(limit: count) else {
      return nil
    }

    guard let rightChild = node.rightChild(limit: count) else {
      return leftChild
    }

    guard let grandchildren = node.grandchildren(limit: count) else {
      // We have no grandchildren -- compare the two children instead
      return (_element(at: rightChild) > _element(at: leftChild)
              ? rightChild
              : leftChild)
    }

    var maxValue = _element(at: leftChild)
    var maxNode = leftChild

    // If we have 4 grandchildren, we can skip comparing the children as the
    // heap invariants will ensure that the grandchildren will be larger.
    // Otherwise, we need to do the comparison.
    if grandchildren._count < 4 {
      // Compare the two children
      let rightValue = _element(at: rightChild)
      if rightValue > maxValue {
        maxValue = rightValue
        maxNode = rightChild
      }
    }

    // Iterate through the grandchildren
    grandchildren._forEach { grandchild in
      let value = _element(at: grandchild)
      if value > maxValue {
        maxValue = value
        maxNode = grandchild
      }
    }

    return maxNode
  }

  // MARK: - Helpers

  /// Swaps the elements in the heap at the given indices.
  @inlinable @inline(__always)
  internal mutating func _swapAt(_ i: _Node, _ j: _Node) {
    let tmp = _storage[i.offset]
    _storage[i.offset] = _storage[j.offset]
    _storage[j.offset] = tmp
  }
}

// MARK: -

extension Heap {
  /// Initializes a heap from a sequence.
  ///
  /// - Complexity: O(*n*), where *n* is the length of `elements`.
  @inlinable
  public init<S: Sequence>(_ elements: S) where S.Element == Element {
    // This is Floyd's linear-time heap construction algorithm.
    // (https://en.wikipedia.org/wiki/Heapsort#Floyd's_heap_construction).
    //
    // FIXME: See if a more cache friendly algorithm would be faster.

    _storage = Array(elements)
    guard _storage.count > 1 else { return }

    let limit = _storage.count / 2 // The first offset without a left child
    var level = _Node.level(forOffset: limit &- 1)
    while level >= 0 {
      let nodes = _Node.allNodes(onLevel: level, limit: limit)
      if _Node.isMinLevel(level) {
        nodes?._forEach { node in
          _trickleDownMin(elementAt: node)
        }
      } else {
        nodes?._forEach { node in
          _trickleDownMax(elementAt: node)
        }
      }
      level &-= 1
    }

    _checkInvariants()
  }

  /// Inserts the elements in the given sequence into the heap.
  ///
  /// - Parameter newElements: The new elements to insert into the heap.
  ///
  /// - Complexity: O(*n* * log(`count`)), where *n* is the length of `newElements`.
  @inlinable
  public mutating func insert<S: Sequence>(
    contentsOf newElements: S
  ) where S.Element == Element {
    _storage.reserveCapacity(count + newElements.underestimatedCount)
    for element in newElements {
      insert(element)
    }
  }
}
