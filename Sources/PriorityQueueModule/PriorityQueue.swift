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

/// A double-ended priority queue built on top of `Heap`.
public struct PriorityQueue<Value, Priority: Comparable> {
  public typealias Pair = (value: Value, priority: Priority)

  @usableFromInline
  struct Element: Comparable {
    @usableFromInline let value: Value
    let priority: Priority
    let insertionCounter: UInt64

    @usableFromInline
    init(value: Value, priority: Priority, insertionCounter: UInt64) {
      self.value = value
      self.priority = priority
      self.insertionCounter = insertionCounter
    }

    @usableFromInline
    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.priority == rhs.priority
    }

    @usableFromInline
    static func < (lhs: Self, rhs: Self) -> Bool {
      if lhs.priority < rhs.priority {
        return true
      } else if lhs.priority == rhs.priority {
        return lhs.insertionCounter < rhs.insertionCounter
      } else {
        return false
      }
    }
  }

  @usableFromInline
  internal var _base: Heap<Element>

  @usableFromInline
  internal var _insertionCounter: UInt64 = 0

  /// A Boolean value indicating whether or not the queue is empty.
  ///
  /// - Complexity: O(1)
  @inlinable
  public var isEmpty: Bool {
    _base.isEmpty
  }

  /// The number of items in the queue.
  ///
  /// - Complexity: O(1)
  @inlinable
  public var count: Int {
    _base.count
  }

  /// Creates an empty queue.
  @inlinable
  public init() {
    _base = Heap()
  }

  // MARK: -

  /// Inserts the given item into the queue.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func insert(_ value: Value, priority: Priority) {
    defer { _insertionCounter += 1 }

    let pair = Element(
      value: value,
      priority: priority,
      insertionCounter: _insertionCounter
    )

    _base.insert(pair)
  }

  /// Returns the item with the lowest priority, if available.
  ///
  /// - Complexity: O(1)
  @inlinable
  public func min() -> Value? {
    _base.min()?.value
  }

  /// Returns the item with the highest priority, if available.
  ///
  /// - Complexity: O(1)
  @inlinable
  public func max() -> Value? {
    _base.max()?.value
  }

  /// Removes and returns the item with the lowest priority, if available.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func popMin() -> Value? {
    _base.popMin()?.value
  }

  /// Removes and returns the item with the highest priority, if available.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func popMax() -> Value? {
    _base.popMax()?.value
  }

  /// Removes and returns the element with the lowest priority.
  ///
  /// The queue *must not* be empty.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func removeMin() -> Value {
    _base.removeMin().value
  }

  /// Removes and returns the element with the highest priority.
  ///
  /// The queue *must not* be empty.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func removeMax() -> Value {
    _base.removeMax().value
  }
}

// MARK: -

extension PriorityQueue {
  /// Initializes a queue from a sequence.
  ///
  /// - Complexity: O(n), where `n` is the length of `elements`.
  @inlinable
  public init<S: Sequence>(_ elements: S) where S.Element == Pair {
    _base = Heap(
      elements
        .enumerated()
        .map({
          Element(
            value: $0.element.value,
            priority: $0.element.priority,
            insertionCounter: UInt64($0.offset)
          )
        })
    )
    _insertionCounter = UInt64(_base.count)
  }
}
