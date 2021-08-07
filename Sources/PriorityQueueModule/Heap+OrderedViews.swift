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
  /// A view of a `Heap`'s elements, as a `Sequence` from the smallest to
  /// largest element.
  public struct AscendingView: Sequence, IteratorProtocol {
    @usableFromInline
    internal var _base: Heap

    /// Creates an ascending-element view from the given heap.
    @inlinable
    init(_base: Heap) {
      self._base = _base
    }

    @inlinable
    public mutating func next() -> Element? {
      return _base.popMin()
    }
  }

  /// A view of a `Heap`'s elements, as a `Sequence` from the largest to
  /// smallest element.
  public struct DescendingView: Sequence, IteratorProtocol {
    @usableFromInline
    internal var _base: Heap

    /// Creates a descending-element view from the given heap.
    @inlinable
    init(_base: Heap) {
      self._base = _base
    }

    @inlinable
    public mutating func next() -> Element? {
      return _base.popMax()
    }
  }

  /// Returns an iterator that orders elements from smallest to largest
  @inlinable
  public var ascending: AscendingView {
    return AscendingView(_base: self)
  }

  /// Returns an iterator that orders elements from largest to smallest
  @inlinable
  public var descending: DescendingView {
    return DescendingView(_base: self)
  }
}
