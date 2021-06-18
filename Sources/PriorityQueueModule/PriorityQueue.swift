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
/// In a min-max heap, each node at an even level in the tree is less than all its descendants, while each node
/// at an odd level in the tree is greater than all of its descendants.
///
/// The implementation is based off [this paper](http://akira.ruc.dk/~keld/teaching/algoritmedesign_f03/Artikler/02/Atkinson86.pdf).
public struct PriorityQueue<Element: Comparable> {
    private var storage: [Element]

    /// A Boolean value indicating whether or not the queue is empty.
    ///
    /// - Complexity: O(1)
    public var isEmpty: Bool {
        storage.isEmpty
    }

    /// The number of elements in the queue.
    ///
    /// - Complexity: O(1)
    public var count: Int {
        storage.count
    }

    /// A read-only view into the underlying heap.
    ///
    /// In the current implementation, the elements aren't _arbitrarily_ ordered, as a min-max heap
    /// is used for storage. However, no guarantees are given as to the ordering of the elements.
    ///
    /// - Complexity: O(1)
    public var unordered: [Element] {
        storage
    }

    /// Creates an empty queue.
    public init() {
        storage = []
    }

    /// Inserts the given element into the queue.
    ///
    /// - Complexity: O(log `count`) / 2
    public mutating func insert(_ element: Element) {
        storage.append(element)
        _bubbleUp(startingAt: storage.endIndex - 1)
    }

    /// Returns the element with the lowest priority, if available.
    ///
    /// - Complexity: O(1)
    public func min() -> Element? {
        storage.first
    }

    /// Returns the element with the highest priority, if available.
    ///
    /// - Complexity: O(1)
    public func max() -> Element? {
        switch storage.count {
        case 0, 1, 2:
            // If count is 0, `last` will return `nil`
            // If count is 1, the last (and only) item is the max
            // If count is 2, the last item is the max (as it's the only item in the first max level)
            return storage.last
        default:
            // We have at least 3 items -- return the larger of the two in the first max level
            return Swift.max(storage[1], storage[2])
        }
    }

    /// Removes and returns the element with the lowest priority, if available.
    ///
    /// - Complexity: O(log `count`)
    public mutating func popMin() -> Element? {
        return _remove(at: 0)
    }

    /// Removes and returns the element with the highest priority, if available.
    ///
    /// - Complexity: O(log `count`)
    public mutating func popMax() -> Element? {
        switch storage.count {
        case 0, 1, 2:
            // If count is 0, `popLast` will return `nil`
            // If count is 1, the last (and only) item is the max
            // If count is 2, the last item is the max (as it's the only item in the first max level)
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
    public mutating func removeMin() -> Element {
        precondition(!isEmpty)

        return popMin()!
    }

    /// Removes and returns the element with the highest priority.
    ///
    /// The queue *must not* be empty.
    ///
    /// - Complexity: O(log `count`)
    public mutating func removeMax() -> Element {
        precondition(!isEmpty)

        return popMax()!
    }

    // MARK: -

    private mutating func _bubbleUp(startingAt index: Int) {
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

    private mutating func _bubbleUpMin(startingAt index: Int) {
        guard let grandparentIdx = _grandparentIndex(of: index) else { return }

        if storage[index] < storage[grandparentIdx] {
            _swapAt(index, grandparentIdx)
            _bubbleUpMin(startingAt: grandparentIdx)
        }
    }

    private mutating func _bubbleUpMax(startingAt index: Int) {
        guard let grandparentIdx = _grandparentIndex(of: index) else { return }

        if storage[index] > storage[grandparentIdx] {
            _swapAt(index, grandparentIdx)
            _bubbleUpMax(startingAt: grandparentIdx)
        }
    }

    // MARK: -

    @discardableResult
    private mutating func _remove(at index: Int) -> Element? {
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

    private mutating func _trickleDown(startingAt index: Int) {
        // Figure out if `index` is on an even or odd level
        let levelIsMin = _minMaxHeapIsMinLevel(index + 1)

        if levelIsMin {
            _trickleDownMin(startingAt: index)
        } else {
            _trickleDownMax(startingAt: index)
        }
    }

    private mutating func _trickleDownMin(startingAt index: Int) {
        guard let (smallestDescendantIdx, isChild) = _indexOfLowestPriorityChildOrGrandchild(of: index) else {
            // We have no descendants -- no need to trickle down further
            return
        }

        if isChild {
            if storage[smallestDescendantIdx] < storage[index] {
                _swapAt(smallestDescendantIdx, index)
            }
        } else {
            // Smallest is a grandchild
            if storage[smallestDescendantIdx] < storage[index] {
                _swapAt(smallestDescendantIdx, index)

                let parentIdx = _parentIndex(of: smallestDescendantIdx)!
                if storage[smallestDescendantIdx] > storage[parentIdx] {
                    _swapAt(smallestDescendantIdx, parentIdx)
                }

                _trickleDownMin(startingAt: smallestDescendantIdx)
            }
        }
    }

    private mutating func _trickleDownMax(startingAt index: Int) {
        guard let (largestDescendantIdx, isChild) = _indexOfHighestPriorityChildOrGrandchild(of: index) else {
            // We have no descendants -- no need to trickle down further
            return
        }

        if isChild {
            if storage[largestDescendantIdx] > storage[index] {
                _swapAt(largestDescendantIdx, index)
            }
        } else {
            // Largest is a grandchild
            if storage[largestDescendantIdx] > storage[index] {
                _swapAt(largestDescendantIdx, index)

                let parentIdx = _parentIndex(of: largestDescendantIdx)!
                if storage[largestDescendantIdx] < storage[parentIdx] {
                    _swapAt(largestDescendantIdx, parentIdx)
                }

                _trickleDownMax(startingAt: largestDescendantIdx)
            }
        }
    }

    /// Returns the lowest priority child or grandchild of the element at the given index.
    ///
    /// Returns `nil` if the element has no descendants.
    ///
    /// - parameter index: The index of the element whose descendants should be compared.
    private func _indexOfLowestPriorityChildOrGrandchild(
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

    /// Returns the highest priority child or grandchild of the element at the given index.
    ///
    /// Returns `nil` if the element has no descendants.
    ///
    /// - parameter index: The index of the item whose descendants should be compared.
    private func _indexOfHighestPriorityChildOrGrandchild(
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
    internal func _minMaxHeapIsMinLevel(_ count: Int) -> Bool {
        precondition(count > 0)

        return count._binaryLogarithm() & 0b1 == 0
    }

    /// Swaps the elements in the heap at the given indices.
    @inline(__always)
    private mutating func _swapAt(_ i: Int, _ j: Int) {
        let tmp = storage[i]
        storage[i] = storage[j]
        storage[j] = tmp
    }

    /// Returns the parent index of the given `index`
    /// or `nil` if the index has no parent (i.e. `index == 0`).
    @inline(__always)
    private func _parentIndex(of index: Int) -> Int? {
        guard index > 0 else {
            return nil
        }

        return (index - 1) / 2
    }

    /// Returns the grandparent index of the given `index`
    /// or `nil` if the index has no grandparent.
    @inline(__always)
    private func _grandparentIndex(of index: Int) -> Int? {
        guard index > 2 else {
            return nil
        }

        return (index - 3) / 4
    }

    /// Returns the first child index of the given `index`
    /// or `nil` if the index has no children.
    @inline(__always)
    private func _leftChildIndex(of index: Int) -> Int? {
        let childIdx = index * 2 + 1
        guard childIdx < storage.count else {
            return nil
        }

        return childIdx
    }

    /// Returns the right child index of the given `index`
    /// or `nil` if the index has no right child.
    @inline(__always)
    private func _rightChildIndex(of index: Int) -> Int? {
        let childIdx = index * 2 + 2
        guard childIdx < storage.count else {
            return nil
        }

        return childIdx
    }

    /// Returns the first grandchild index of the given `index`
    /// or `nil` if the index has no grandchildren.
    @inline(__always)
    private func _firstGrandchildIndex(of index: Int) -> Int? {
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
    private func _lastGrandchildIndex(of index: Int) -> Int? {
        guard _firstGrandchildIndex(of: index) != nil else {
            // There are no grandchildren of the node at `index`
            return nil
        }

        return Swift.min(index * 4 + 6, storage.count - 1)
    }
}

// MARK: -

extension PriorityQueue {
    /// Initializes a queue from a collection.
    ///
    /// Utilizes [Floyd's linear-time heap construction algorithm](https://en.wikipedia.org/wiki/Heapsort#Floyd's_heap_construction).
    public init<C: Collection>(_ collection: C) where C.Element == Element {
        storage = Array(collection)

        for idx in (0..<(storage.count / 2)).reversed() {
            _trickleDown(startingAt: idx)
        }
    }
}
