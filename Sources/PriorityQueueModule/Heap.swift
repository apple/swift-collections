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

import Swift

/// A [Min-Max Heap](https://en.wikipedia.org/wiki/Min-max_heap) data structure.
///
/// In a min-max heap, each node at an even level in the tree is less than all
/// its descendants, while each node at an odd level in the tree is greater than
/// all of its descendants.
///
/// The implementation is based off [Atkinson et al. Min-Max Heaps and
/// Generalized Priority Queues (1986)](http://akira.ruc.dk/~keld/teaching/algoritmedesign_f03/Artikler/02/Atkinson86.pdf).
///
/// M.D. Atkinson, J.-R. Sack, N. Santoro, T. Strothotte. October 1986.
/// Min-Max Heaps and Generalized Priority Queues. Communications of the ACM.
/// 29(10):996-1000.
public struct Heap<Element: Comparable> {
  @usableFromInline
  internal var _storage: [Element]

  /// A Boolean value indicating whether or not the heap is empty.
  ///
  /// - Complexity: O(1)
  @inlinable
  public var isEmpty: Bool {
    _storage.isEmpty
  }

  /// The number of elements in the heap.
  ///
  /// - Complexity: O(1)
  @inlinable
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
    _bubbleUp(elementAt: _storage.endIndex - 1)
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
    return _remove(at: 0)
  }

  /// Removes and returns the element with the highest priority, if available.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func popMax() -> Element? {
    defer { _checkInvariants() }
    switch _storage.count {
    case 0, 1, 2:
      // If count is 0, `popLast` will return `nil`
      // If count is 1, the last (and only) item is the max
      // If count is 2, the last item is the max (as it's the only item in the
      // first max level)
      return _storage.popLast()
    default:
      // The max item is the larger of the two items in the first max level
      let maxIdx = _storage[2] > _storage[1] ? 2 : 1
      return _remove(at: maxIdx)
    }
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

  @inline(__always)
  @inlinable
  internal mutating func _bubbleUp(elementAt index: Int) {
    guard let parentIdx = _parentIndex(of: index) else {
      // We're already at the root -- can't go any further
      return
    }

    // Figure out if `index` is on an even or odd level
    let levelIsMin = _minMaxHeapIsMinLevel(index)

    if levelIsMin {
      if _storage[index] > _storage[parentIdx] {
        _swapAt(index, parentIdx)
        _bubbleUpMax(elementAt: parentIdx)
      } else {
        _bubbleUpMin(elementAt: index)
      }
    } else {
      if _storage[index] < _storage[parentIdx] {
        _swapAt(index, parentIdx)
        _bubbleUpMin(elementAt: parentIdx)
      } else {
        _bubbleUpMax(elementAt: index)
      }
    }
  }

  @inline(__always)
  @inlinable
  internal mutating func _bubbleUpMin(elementAt index: Int) {
    var index = index

    while let grandparentIdx = _grandparentIndex(of: index),
          _storage[index] < _storage[grandparentIdx] {
      _swapAt(index, grandparentIdx)
      index = grandparentIdx
    }
  }

  @inline(__always)
  @inlinable
  internal mutating func _bubbleUpMax(elementAt index: Int) {
    var index = index

    while let grandparentIdx = _grandparentIndex(of: index),
          _storage[index] > _storage[grandparentIdx] {
      _swapAt(index, grandparentIdx)
      index = grandparentIdx
    }
  }

  // MARK: -

  @discardableResult
  @inlinable
  internal mutating func _remove(at index: Int) -> Element? {
    guard _storage.count > index else {
      return nil
    }

    var removed = _storage.removeLast()

    if index < _storage.count {
      swap(&removed, &_storage[index])
      _trickleDown(elementAt: index)
    }

    return removed
  }

  // MARK: -

  @inline(__always)
  @inlinable
  internal mutating func _trickleDown(elementAt index: Int) {
    // Figure out if `index` is on an even or odd level
    let levelIsMin = _minMaxHeapIsMinLevel(index)

    if levelIsMin {
      _trickleDownMin(elementAt: index)
    } else {
      _trickleDownMax(elementAt: index)
    }
  }
 
  @inline(__always)
  @inlinable
  internal mutating func _trickleDownMin(elementAt index: Int) {
    var index = index

    while let (smallestDescendantIdx, isChild) =
            _indexOfLowestPriorityChildOrGrandchild(of: index) {
      if _storage[smallestDescendantIdx] < _storage[index] {
        _swapAt(smallestDescendantIdx, index)

        if isChild {
          return
        }

        // Smallest is a grandchild
        let parentIdx = _parentIndex(of: smallestDescendantIdx)!
        if _storage[smallestDescendantIdx] > _storage[parentIdx] {
          _swapAt(smallestDescendantIdx, parentIdx)
        }

        index = smallestDescendantIdx
      } else {
        return
      }
    }
  }

  @inline(__always)
  @inlinable
  internal mutating func _trickleDownMax(elementAt index: Int) {
    var index = index

    while let (largestDescendantIdx, isChild) =
            _indexOfHighestPriorityChildOrGrandchild(of: index) {
      if _storage[largestDescendantIdx] > _storage[index] {
        _swapAt(largestDescendantIdx, index)

        if isChild {
          return
        }

        // Largest is a grandchild
        let parentIdx = _parentIndex(of: largestDescendantIdx)!
        if _storage[largestDescendantIdx] < _storage[parentIdx] {
          _swapAt(largestDescendantIdx, parentIdx)
        }

        index = largestDescendantIdx
      } else {
        return
      }
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
  internal func _indexOfLowestPriorityChildOrGrandchild(
    of index: Int
  ) -> (index: Int, isChild: Bool)? {
    guard let leftChildIdx = _leftChildIndex(of: index) else {
      return nil
    }

    var result: (index: Int, isChild: Bool) = (leftChildIdx, true)

    guard let rightChildIdx = _rightChildIndex(of: index) else {
      return result
    }

    guard let firstGrandchildIdx = _firstGrandchildIndex(of: index),
          let lastGrandchildIdx = _lastGrandchildIndex(of: index)
    else {
      // We have no grandchildren -- compare the two children instead
      if _storage[rightChildIdx] < _storage[leftChildIdx] {
        result.index = rightChildIdx
      }

      return result
    }

    // If we have 4 grandchildren, we can skip comparing the children as the
    // heap invariants will ensure that the grandchildren will be smaller.
    // Otherwise, we need to do the comparison.
    if lastGrandchildIdx != firstGrandchildIdx + 3 {
      // Compare the two children
      if _storage[rightChildIdx] < _storage[leftChildIdx] {
        result.index = rightChildIdx
      }
    }

    // Iterate through the grandchildren
    for i in firstGrandchildIdx...lastGrandchildIdx {
      if _storage[i] < _storage[result.index] {
        result.index = i
        result.isChild = false
      }
    }

    return result
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
  internal func _indexOfHighestPriorityChildOrGrandchild(
    of index: Int
  ) -> (index: Int, isChild: Bool)? {
    guard let leftChildIdx = _leftChildIndex(of: index) else {
      return nil
    }

    var result: (index: Int, isChild: Bool) = (leftChildIdx, true)

    guard let rightChildIdx = _rightChildIndex(of: index) else {
      return result
    }

    guard let firstGrandchildIdx = _firstGrandchildIndex(of: index),
          let lastGrandchildIdx = _lastGrandchildIndex(of: index)
    else {
      // We have no grandchildren -- compare the two children instead
      if _storage[rightChildIdx] > _storage[leftChildIdx] {
        result.index = rightChildIdx
      }

      return result
    }

    // If we have 4 grandchildren, we can skip comparing the children as the
    // heap invariants will ensure that the grandchildren will be larger.
    // Otherwise, we need to do the comparison.
    if lastGrandchildIdx != firstGrandchildIdx + 3 {
      // Compare the two children
      if _storage[rightChildIdx] > _storage[leftChildIdx] {
        result.index = rightChildIdx
      }
    }

    // Iterate through the grandchildren
    for i in firstGrandchildIdx...lastGrandchildIdx {
      if _storage[i] > _storage[result.index] {
        result.index = i
        result.isChild = false
      }
    }

    return result
  }

  // MARK: - Helpers

  /// Returns `true` if `index` falls on a min level in a min-max heap.
  ///
  /// - Precondition: `index` must be non-negative.
  @inline(__always)
  @inlinable
  internal func _minMaxHeapIsMinLevel(_ index: Int) -> Bool {
    precondition(index >= 0)

    return (index + 1)._binaryLogarithm() & 0b1 == 0
  }

  /// Swaps the elements in the heap at the given indices.
  @inline(__always)
  @inlinable
  internal mutating func _swapAt(_ i: Int, _ j: Int) {
    let tmp = _storage[i]
    _storage[i] = _storage[j]
    _storage[j] = tmp
  }

  /// Returns the parent index of the given `index`
  /// or `nil` if the index has no parent (i.e. `index == 0`).
  @inline(__always)
  @inlinable
  internal func _parentIndex(of index: Int) -> Int? {
    guard index > 0 else {
      return nil
    }

    return (index - 1) / 2
  }

  /// Returns the grandparent index of the given `index`
  /// or `nil` if the index has no grandparent.
  @inline(__always)
  @inlinable
  internal func _grandparentIndex(of index: Int) -> Int? {
    guard index > 2 else {
      return nil
    }

    return (index - 3) / 4
  }

  /// Returns the first child index of the given `index`
  /// or `nil` if the index has no children.
  @inline(__always)
  @inlinable
  internal func _leftChildIndex(of index: Int) -> Int? {
    let childIdx = index * 2 + 1
    guard childIdx < _storage.count else {
      return nil
    }

    return childIdx
  }

  /// Returns the right child index of the given `index`
  /// or `nil` if the index has no right child.
  @inline(__always)
  @inlinable
  internal func _rightChildIndex(of index: Int) -> Int? {
    let childIdx = index * 2 + 2
    guard childIdx < _storage.count else {
      return nil
    }

    return childIdx
  }

  /// Returns the first grandchild index of the given `index`
  /// or `nil` if the index has no grandchildren.
  @inline(__always)
  @inlinable
  internal func _firstGrandchildIndex(of index: Int) -> Int? {
    let grandchildIdx = index * 4 + 3
    guard grandchildIdx < _storage.count else {
      return nil
    }

    return grandchildIdx
  }

  /// Returns the last valid grandchild index of the given `index`
  /// or `nil` if the index has no grandchildren.
  ///
  /// In cases where the given index only has one grandchild, the index
  /// returned by this function is the same as that returned by
  /// `_firstGrandchildIndex`.
  @inline(__always)
  @inlinable
  internal func _lastGrandchildIndex(of index: Int) -> Int? {
    guard _firstGrandchildIndex(of: index) != nil else {
      // There are no grandchildren of the node at `index`
      return nil
    }

    return Swift.min(index * 4 + 6, _storage.count - 1)
  }
}

// MARK: -

extension Heap {
  /// Initializes a heap from a sequence.
  ///
  /// Utilizes [Floyd's linear-time heap construction algorithm](https://en.wikipedia.org/wiki/Heapsort#Floyd's_heap_construction).
  ///
  /// - Complexity: O(n), where `n` is the length of `elements`.
  @inlinable
  public init<S: Sequence>(_ elements: S) where S.Element == Element {
    _storage = Array(elements)

    for idx in (0 ..< (_storage.count / 2)).reversed() {
      _trickleDown(elementAt: idx)
    }

    _checkInvariants()
  }

  /// Inserts the elements in the given sequence into the heap.
  ///
  /// - Parameter newElements: The new elements to insert into the heap.
  ///
  /// - Complexity: O(n * log `count`), where `n` is the length of `newElements`.
  @inlinable
  public mutating func insert<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
    for element in newElements {
      insert(element)
    }
  }
}
