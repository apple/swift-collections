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

/// A double-ended priority queue built on top of a [Min-Max Heap](https://en.wikipedia.org/wiki/Min-max_heap)
/// data structure.
///
/// In a min-max heap, each node at an even level in the tree is less than all
/// its descendants, while each node at an odd level in the tree is greater than
/// all of its descendants.
///
/// The implementation is based off [this paper](http://akira.ruc.dk/~keld/teaching/algoritmedesign_f03/Artikler/02/Atkinson86.pdf).
public struct PriorityQueue<Element: Comparable> {
  @usableFromInline
  internal var storage: [Element]

  /// A Boolean value indicating whether or not the queue is empty.
  ///
  /// - Complexity: O(1)
  @inlinable
  public var isEmpty: Bool {
    storage.isEmpty
  }

  /// The number of elements in the queue.
  ///
  /// - Complexity: O(1)
  @inlinable
  public var count: Int {
    storage.count
  }

  /// A read-only view into the underlying heap.
  ///
  /// In the current implementation, the elements aren't _arbitrarily_ ordered,
  /// as a min-max heap is used for storage. However, no guarantees are given as
  /// to the ordering of the elements.
  ///
  /// - Complexity: O(1)
  @inlinable
  public var unordered: [Element] {
    storage
  }

  /// Creates an empty queue.
  @inlinable
  public init() {
    storage = []
  }

  /// Inserts the given element into the queue.
  ///
  /// - Complexity: O(log `count`) / 2
  @inlinable
  public mutating func insert(_ element: Element) {
    storage.append(element)
    _bubbleUp(startingAt: storage.endIndex - 1)
    _checkInvariants()
  }

  /// Returns the element with the lowest priority, if available.
  ///
  /// - Complexity: O(1)
  @inlinable
  public func min() -> Element? {
    storage.first
  }

  /// Returns the element with the highest priority, if available.
  ///
  /// - Complexity: O(1)
  @inlinable
  public func max() -> Element? {
    switch storage.count {
    case 0, 1, 2:
      // If count is 0, `last` will return `nil`
      // If count is 1, the last (and only) item is the max
      // If count is 2, the last item is the max (as it's the only item in the
      // first max level)
      return storage.last
    default:
      // We have at least 3 items -- return the larger of the two in the first
      // max level
      return Swift.max(storage[1], storage[2])
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
    switch storage.count {
    case 0, 1, 2:
      // If count is 0, `popLast` will return `nil`
      // If count is 1, the last (and only) item is the max
      // If count is 2, the last item is the max (as it's the only item in the
      // first max level)
      return storage.popLast()
    default:
      // The max item is the larger of the two items in the first max level
      let maxIdx = storage[2] > storage[1] ? 2 : 1
      return _remove(at: maxIdx)
    }
  }

  /// Removes and returns the element with the lowest priority.
  ///
  /// The queue *must not* be empty.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func removeMin() -> Element {
    precondition(!isEmpty)

    return popMin()!
  }

  /// Removes and returns the element with the highest priority.
  ///
  /// The queue *must not* be empty.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func removeMax() -> Element {
    precondition(!isEmpty)

    return popMax()!
  }

  // MARK: -

  @inline(__always)
  @inlinable
  internal mutating func _bubbleUp(startingAt index: Int) {
    guard let parentIdx = _parentIndex(of: index) else {
      // We're already at the root -- can't go any further
      return
    }

    // Figure out if `index` is on an even or odd level
    let levelIsMin = _minMaxHeapIsMinLevel(index + 1)

    if levelIsMin {
      if storage[index] > storage[parentIdx] {
        _swapAt(index, parentIdx)
        _bubbleUpMax(startingAt: parentIdx)
      } else {
        _bubbleUpMin(startingAt: index)
      }
    } else {
      if storage[index] < storage[parentIdx] {
        _swapAt(index, parentIdx)
        _bubbleUpMin(startingAt: parentIdx)
      } else {
        _bubbleUpMax(startingAt: index)
      }
    }
  }

  @inline(__always)
  @inlinable
  internal mutating func _bubbleUpMin(startingAt index: Int) {
    var index = index
      
    while let grandparentIdx = _grandparentIndex(of: index),
          storage[index] < storage[grandparentIdx] {
      _swapAt(index, grandparentIdx)
      index = grandparentIdx
    }
  }

  @inline(__always)
  @inlinable
  internal mutating func _bubbleUpMax(startingAt index: Int) {
    var index = index
      
    while let grandparentIdx = _grandparentIndex(of: index),
          storage[index] > storage[grandparentIdx] {
      _swapAt(index, grandparentIdx)
      index = grandparentIdx
    }
  }

  // MARK: -

  @discardableResult
  @inlinable
  internal mutating func _remove(at index: Int) -> Element? {
    guard storage.count > index else {
      return nil
    }

    var removed = storage.removeLast()

    if index < storage.count {
      swap(&removed, &storage[index])
      _trickleDown(startingAt: index)
    }

    return removed
  }

  // MARK: -

  @inline(__always)
  @inlinable
  internal mutating func _trickleDown(startingAt index: Int) {
    // Figure out if `index` is on an even or odd level
    let levelIsMin = _minMaxHeapIsMinLevel(index + 1)

    if levelIsMin {
      _trickleDownMin(startingAt: index)
    } else {
      _trickleDownMax(startingAt: index)
    }
  }
 
  @inline(__always)
  @inlinable
  internal mutating func _trickleDownMin(startingAt index: Int) {
    var index = index

    while let (smallestDescendantIdx, isChild) =
          _indexOfLowestPriorityChildOrGrandchild(of: index) {

      if storage[smallestDescendantIdx] < storage[index] {
        _swapAt(smallestDescendantIdx, index)

        if isChild {
          return
        }
          
        // Smallest is a grandchild
        let parentIdx = _parentIndex(of: smallestDescendantIdx)!
        if storage[smallestDescendantIdx] > storage[parentIdx] {
          _swapAt(smallestDescendantIdx, parentIdx)
        }

        index = smallestDescendantIdx
      } else { return }
    }
  }

  @inline(__always)
  @inlinable
  internal mutating func _trickleDownMax(startingAt index: Int) {
    var index = index
      
    while let (largestDescendantIdx, isChild) =
          _indexOfHighestPriorityChildOrGrandchild(of: index) {

      if storage[largestDescendantIdx] > storage[index] {
        _swapAt(largestDescendantIdx, index)
        
        if isChild {
          return
        }

        // Largest is a grandchild
        let parentIdx = _parentIndex(of: largestDescendantIdx)!
        if storage[largestDescendantIdx] < storage[parentIdx] {
          _swapAt(largestDescendantIdx, parentIdx)
        }

        index = largestDescendantIdx
      } else { return }
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
      if storage[rightChildIdx] < storage[leftChildIdx] {
        result.index = rightChildIdx
      }

      return result
    }

    // If we have 4 grandchildren, we can skip comparing the children as the
    // heap invariants will ensure that the grandchildren will be smaller.
    // Otherwise, we need to do the comparison.
    if lastGrandchildIdx != firstGrandchildIdx + 3 {
      // Compare the two children
      if storage[rightChildIdx] < storage[leftChildIdx] {
        result.index = rightChildIdx
      }
    }

    // Iterate through the grandchildren
    for i in firstGrandchildIdx...lastGrandchildIdx {
      if storage[i] < storage[result.index] {
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
      if storage[rightChildIdx] > storage[leftChildIdx] {
        result.index = rightChildIdx
      }

      return result
    }

    // If we have 4 grandchildren, we can skip comparing the children as the
    // heap invariants will ensure that the grandchildren will be larger.
    // Otherwise, we need to do the comparison.
    if lastGrandchildIdx != firstGrandchildIdx + 3 {
      // Compare the two children
      if storage[rightChildIdx] > storage[leftChildIdx] {
        result.index = rightChildIdx
      }
    }

    // Iterate through the grandchildren
    for i in firstGrandchildIdx...lastGrandchildIdx {
      if storage[i] > storage[result.index] {
        result.index = i
        result.isChild = false
      }
    }

    return result
  }

  // MARK: - Helpers

  /// Returns `true` if `count` elements falls on a min level in a min-max heap.
  ///
  /// - Precondition: `count` must be > 0.
  @inline(__always)
  @inlinable
  internal func _minMaxHeapIsMinLevel(_ count: Int) -> Bool {
    precondition(count > 0)

    return count._binaryLogarithm() & 0b1 == 0
  }

  /// Swaps the elements in the heap at the given indices.
  @inline(__always)
  @inlinable
  internal mutating func _swapAt(_ i: Int, _ j: Int) {
    let tmp = storage[i]
    storage[i] = storage[j]
    storage[j] = tmp
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
    guard childIdx < storage.count else {
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
    guard childIdx < storage.count else {
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
    guard grandchildIdx < storage.count else {
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

    return Swift.min(index * 4 + 6, storage.count - 1)
  }
}

// MARK: -

extension PriorityQueue {
  /// Initializes a queue from a sequence.
  ///
  /// Utilizes [Floyd's linear-time heap construction algorithm](https://en.wikipedia.org/wiki/Heapsort#Floyd's_heap_construction).
  @inlinable
  public init<S: Sequence>(_ elements: S) where S.Element == Element {
    storage = Array(elements)

    for idx in (0..<(storage.count / 2)).reversed() {
      _trickleDown(startingAt: idx)
    }

    _checkInvariants()
  }
}
