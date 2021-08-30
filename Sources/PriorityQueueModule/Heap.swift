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
/// In a min-max heap, each node at an even level in the tree is less than or
/// equal to all its descendants, while each node at an odd level in the tree is
/// greater than or equal to all of its descendants.
///
/// The implementation is based on [Atkinson et al. 1986]:
///
/// [Atkinson et al. 1986]: https://doi.org/10.1145/6617.6621
///
/// M.D. Atkinson, J.-R. Sack, N. Santoro, T. Strothotte.
/// "Min-Max Heaps and Generalized Priority Queues."
/// *Communications of the ACM*, vol. 29, no. 10, Oct. 1986., pp. 996-1000,
/// doi:[10.1145/6617.6621](https://doi.org/10.1145/6617.6621)
@frozen
public struct Heap<Element: Comparable> {
  @usableFromInline
  internal var _storage: ContiguousArray<Element>

  /// Creates an empty heap.
  @inlinable
  public init() {
    _storage = []
  }
}

extension Heap {
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
    Array(_storage)
  }

  /// Inserts the given element into the heap.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func insert(_ element: Element) {
    _storage.append(element)

    _update { handle in
      handle.bubbleUp(_Node(offset: handle.count - 1))
    }
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
    _storage.withUnsafeBufferPointer { buffer in
      guard buffer.count > 2 else {
        // If count is 0, `last` will return `nil`
        // If count is 1, the last (and only) item is the max
        // If count is 2, the last item is the max (as it's the only item in the
        // first max level)
        return buffer.last
      }
      // We have at least 3 items -- return the larger of the two in the first
      // max level
      return Swift.max(buffer[1], buffer[2])
    }
  }

  /// Removes and returns the element with the lowest priority, if available.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func popMin() -> Element? {
    guard _storage.count > 0 else { return nil }

    var removed = _storage.removeLast()

    if _storage.count > 0 {
      _update { handle in
        let minNode = _Node.root
        handle.swapAt(minNode, with: &removed)
        handle.trickleDownMin(minNode)
      }
    }

    _checkInvariants()
    return removed
  }

  /// Removes and returns the element with the highest priority, if available.
  ///
  /// - Complexity: O(log `count`)
  @inlinable
  public mutating func popMax() -> Element? {
    guard _storage.count > 2 else { return _storage.popLast() }

    var removed = _storage.removeLast()

    _update { handle in
      if handle.count == 2 {
        if handle[.leftMax] > removed {
          handle.swapAt(.leftMax, with: &removed)
        }
      } else {
        let maxNode = handle.maxValue(.rightMax, .leftMax)
        handle.swapAt(maxNode, with: &removed)
        handle.trickleDownMax(maxNode)
      }
    }

    _checkInvariants()
    return removed
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

    _storage = ContiguousArray(elements)
    guard _storage.count > 1 else { return }

    _update { handle in
      handle.heapify()
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
    if count == 0 {
      self = Self(newElements)
      return
    }
    _storage.reserveCapacity(count + newElements.underestimatedCount)
    for element in newElements {
      insert(element)
    }
  }
}
