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
    /// - Complexity: O(log n)
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
            let leftIdx = _leftChildIndex(of: 0)
            let rightIdx = _rightChildIndex(of: 0)

            let left = storage[leftIdx]
            let right = storage[rightIdx]

            // Both indexes are valid -- return the larger of the two
            return Swift.max(left, right)
        }
    }

    /// Removes and returns the element with the lowest priority, if available.
    ///
    /// - Complexity: O(log n)
    public mutating func popMin() -> Element? {
        return _remove(at: 0)
    }

    /// Removes and returns the element with the highest priority, if available.
    ///
    /// - Complexity: O(log n)
    public mutating func popMax() -> Element? {
        switch storage.count {
        case 0, 1, 2:
            // If count is 0, `popLast` will return `nil`
            // If count is 1, the last (and only) item is the max
            // If count is 2, the last item is the max (as it's the only item in the first max level)
            return storage.popLast()
        default:
            // The max item is the larger of the two items in the first max level
            let maxIdx = 1 + (storage[1] < storage[2] ? 1 : 0)
            return _remove(at: maxIdx)
        }
    }

    // MARK: -

    private mutating func _bubbleUp(startingAt index: Int) {
        guard index > 0 else {
            // We're already at the root -- can't go any further
            return
        }

        // Figure out if `index` is on an even or odd level
        let levelIsMin = _minMaxHeapIsMinLevel(index + 1)

        if levelIsMin {
            let parentIdx = _parentIndex(of: index)
            if storage[index] > storage[parentIdx] {
                _swapAt(index, parentIdx)
                _bubbleUpMax(startingAt: parentIdx)
            } else {
                _bubbleUpMin(startingAt: index)
            }
        } else {
            let parentIdx = _parentIndex(of: index)
            if storage[index] < storage[parentIdx] {
                _swapAt(index, parentIdx)
                _bubbleUpMin(startingAt: parentIdx)
            } else {
                _bubbleUpMax(startingAt: index)
            }
        }
    }

    private mutating func _bubbleUpMin(startingAt index: Int) {
        guard index > 2 else { return }

        let grandparentIdx = _grandparentIndex(of: index)
        if storage[index] < storage[grandparentIdx] {
            _swapAt(index, grandparentIdx)
            _bubbleUpMin(startingAt: grandparentIdx)
        }
    }

    private mutating func _bubbleUpMax(startingAt index: Int) {
        guard index > 2 else { return }

        let grandparentIdx = _grandparentIndex(of: index)
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

        guard storage.count > 1 else {
            // The element to remove is the only element
            return storage.removeLast()
        }

        _swapAt(index, storage.endIndex - 1)
        let removed = storage.removeLast()

        _trickleDown(startingAt: index)

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
        let leftIdx = _leftChildIndex(of: index)

        guard leftIdx < storage.count else {
            // We have no descendants -- no need to trickle down further
            return
        }

        guard let (smallestDescendantIdx, isChild) = _indexOfChildOrGrandchild(of: index, sortedUsing: <) else {
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

                let parentIdx = _parentIndex(of: smallestDescendantIdx)
                if storage[smallestDescendantIdx] > storage[parentIdx] {
                    _swapAt(smallestDescendantIdx, parentIdx)
                }

                _trickleDownMin(startingAt: smallestDescendantIdx)
            }
        }
    }

    private mutating func _trickleDownMax(startingAt index: Int) {
        let leftIdx = _leftChildIndex(of: index)

        guard leftIdx < storage.count else {
            // We have no descendants -- no need to trickle down further
            return
        }

        guard let (largestDescendantIdx, isChild) = _indexOfChildOrGrandchild(of: index, sortedUsing: >) else {
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

                let parentIdx = _parentIndex(of: largestDescendantIdx)
                if storage[largestDescendantIdx] < storage[parentIdx] {
                    _swapAt(largestDescendantIdx, parentIdx)
                }

                _trickleDownMax(startingAt: largestDescendantIdx)
            }
        }
    }

    /// Returns the smallest or largest child or grandchild of the element at the given index,
    /// as determined by the predicate.
    ///
    /// - parameter index: The index of the item whose descendants should be compared.
    /// - parameter predicate: Returns `true` if its first argument should be ordered before its second argument.
    private func _indexOfChildOrGrandchild(
        of index: Int,
        sortedUsing predicate: (Element, Element) -> Bool
    ) -> (index: Int, isChild: Bool)? {
        let leftChildIdx = _leftChildIndex(of: index)
        guard leftChildIdx < storage.count else {
            return nil
        }

        var result: (index: Int, isChild: Bool) = (leftChildIdx, true)

        let rightChildIdx = _rightChildIndex(of: index)
        guard rightChildIdx < storage.count else {
            return result
        }

        // Compare the two children
        if predicate(storage[rightChildIdx], storage[leftChildIdx]) {
            result.index = rightChildIdx
        }

        let firstGrandchildIdx = _firstGrandchildIndex(of: index)
        guard firstGrandchildIdx < storage.count else {
            return result
        }

        // Iterate through the grandchildren
        for i in firstGrandchildIdx..._lastGrandchildIndex(of: index) {
            guard i < storage.count else {
                return result
            }

            if predicate(storage[i], storage[result.index]) {
                result.index = i
                result.isChild = false
            }
        }

        return result
    }

    // MARK: - Helpers

    @inline(__always)
    private mutating func _swapAt(_ i: Int, _ j: Int) {
        let tmp = storage[i]
        storage[i] = storage[j]
        storage[j] = tmp
    }

    @inline(__always)
    private func _parentIndex(of index: Int) -> Int {
        (index - 1) / 2
    }

    @inline(__always)
    private func _grandparentIndex(of index: Int) -> Int {
        (index - 3) / 4
    }

    @inline(__always)
    private func _leftChildIndex(of index: Int) -> Int {
        index * 2 + 1
    }

    @inline(__always)
    private func _rightChildIndex(of index: Int) -> Int {
        index * 2 + 2
    }

    @inline(__always)
    private func _firstGrandchildIndex(of index: Int) -> Int {
        index * 4 + 3
    }

    @inline(__always)
    private func _lastGrandchildIndex(of index: Int) -> Int {
        index * 4 + 6
    }
}

/// Returns `true` if `count` elements falls on a min level in a min-max heap.
///
/// - Precondition: `count` must be > 0.
@inline(__always)
func _minMaxHeapIsMinLevel(_ count: Int) -> Bool {
    precondition(count > 0)

    return count._binaryLogarithm() & 0b1 == 0
}

// MARK: -

extension PriorityQueue {
    /// Initializes a queue from a collection.
    ///
    /// Utilizes [Floyd's linear-time heap construction algorithm](https://en.wikipedia.org/wiki/Heapsort#Floyd's_heap_construction).
    public init<C: Collection>(_ collection: C) where C.Element == Element {
        storage = Array(collection)

        for idx in (0...(storage.count / 2)).reversed() {
            _trickleDown(startingAt: idx)
        }
    }
}
