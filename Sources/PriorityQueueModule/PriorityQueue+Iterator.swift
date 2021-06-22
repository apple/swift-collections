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

extension PriorityQueue {

  /// Adds sequence conformance to both the min and max view of the priority queue
  public struct Iterator: Sequence, IteratorProtocol {

    public enum IterationDirection {
      case ascending
      case descending
    }

    @usableFromInline
    internal var _base: PriorityQueue

    @usableFromInline
    internal let _direction: IterationDirection

    @inlinable
    public init(_base: PriorityQueue, _direction:IterationDirection) {
      self._base = _base
      self._direction = _direction
    }

    // Returns the next element in the priority queue depending on the iteration direction
    @inlinable
    public mutating func next() -> Element? {
      if(_direction == .ascending){
        return _base.popMin()
      }
      return _base.popMax()
    }
  }

  /// Returns an iterator that orders elements from lowest to highest priority
  @inlinable
  public var ascending: Iterator {
    return Iterator(_base: self, _direction: .ascending)
  }

  /// Returns an iterator that orders elements from highest to lowest priority
  @inlinable
  public var descending: Iterator {
    return Iterator(_base: self, _direction: .descending)
  }
}
