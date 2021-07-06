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
  /// A view of a `PriorityQueue`'s elements, as a `Sequence` from the element
  /// with the lowest priority to the highest.
  public struct AscendingView: Sequence, IteratorProtocol {
    @usableFromInline
    internal var _base: PriorityQueue

    @inlinable
    init(_base: PriorityQueue) {
      self._base = _base
    }

    public mutating func next() -> Value? {
      _base.popMin()
    }
  }

  /// A view of a `PriorityQueue`'s elements, as a `Sequence` from the element
  /// with the highest priority to the lowest.
  public struct DescendingView: Sequence, IteratorProtocol {
    @usableFromInline
    internal var _base: PriorityQueue

    @inlinable
    init(_base: PriorityQueue) {
      self._base = _base
    }

    public mutating func next() -> Value? {
      _base.popMax()
    }
  }

  /// Returns an iterator that orders elements from lowest to highest priority.
  @inlinable
  public var ascending: AscendingView {
    AscendingView(_base: self)
  }

  /// Returns an iterator that orders elements from highest to lowest priority.
  @inlinable
  public var descending: DescendingView {
    DescendingView(_base: self)
  }
}
