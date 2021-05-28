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

/// A double-ended priority queue.
public struct PriorityQueue<Element: Comparable> {
    private var storage: MinMaxHeap<Element>

    /// Returns `true` if the `PriorityQueue` is empty.
    ///
    /// - Complexity: O(1)
    public var isEmpty: Bool {
        storage.isEmpty
    }

    /// Returns the number of elements in the `PriorityQueue`.
    ///
    /// - Complexity: O(1)
    public var count: Int {
        storage.count
    }

    /// Creates an empty `PriorityQueue`.
    public init() {
        storage = MinMaxHeap()
    }

    /// Adds the given element to the `PriorityQueue`.
    ///
    /// - Complexity: O(log n)
    public mutating func insert(_ element: Element) {
        storage.insert(element)
    }

    /// Removes and returns the element with the lowest priority, if available.
    ///
    /// - Complexity: O(log n)
    public mutating func removeMin() -> Element? {
        storage.removeMin()
    }

    /// Removes and returns the element with the highest priority, if available.
    ///
    /// - Complexity: O(log n)
    public mutating func removeMax() -> Element? {
        storage.removeMax()
    }

    /// Returns the element with the lowest priority, if available.
    ///
    /// - Complexity: O(1)
    public func min() -> Element? {
        storage.min()
    }

    /// Returns the element with the highest priority, if available.
    ///
    /// - Complexity: O(1)
    public func max() -> Element? {
        storage.max()
    }
}
