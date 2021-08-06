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

extension Heap {
  /// Adds sequence conformance to both the min and max view of the heap
  public struct Iterator: Sequence, IteratorProtocol {

    @usableFromInline
    enum IterationDirection {
      case ascending
      case descending
    }

    @usableFromInline
    internal var _base: Heap

    @usableFromInline
    internal let _direction: IterationDirection

    @inlinable
    init(_base: Heap, direction: IterationDirection) {
      self._base = _base
      self._direction = direction
    }

    // Returns the next element in the heap depending on the iteration direction
    @inlinable
    public mutating func next() -> Element? {
      if _direction == .ascending {
        return _base.popMin()
      }
      return _base.popMax()
    }
  }

  /// Returns an iterator that orders elements from lowest to highest priority
  @inlinable
  public var ascending: Iterator {
    return Iterator(_base: self, direction: .ascending)
  }

  /// Returns an iterator that orders elements from highest to lowest priority
  @inlinable
  public var descending: Iterator {
    return Iterator(_base: self, direction: .descending)
  }
}
