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

@usableFromInline @frozen
internal struct _Node {
  @usableFromInline
  internal var offset: Int

  @usableFromInline
  internal var level: Int

  @inlinable
  internal init(offset: Int, level: Int) {
    assert(offset >= 0)
#if COLLECTIONS_INTERNAL_CHECKS
    assert(level == Self.level(forOffset: offset))
#endif
    self.offset = offset
    self.level = level
  }

  @inlinable
  internal init(offset: Int) {
    self.init(offset: offset, level: Self.level(forOffset: offset))
  }
}

extension _Node: Comparable {
  @inlinable @inline(__always)
  internal static func ==(left: Self, right: Self) -> Bool {
    left.offset == right.offset
  }

  @inlinable @inline(__always)
  internal static func <(left: Self, right: Self) -> Bool {
    left.offset < right.offset
  }
}

extension _Node: CustomStringConvertible {
  @usableFromInline
  internal var description: String {
    "(offset: \(offset), level: \(level))"
  }
}

extension _Node {
  @inlinable @inline(__always)
  internal static func level(forOffset offset: Int) -> Int {
    (offset &+ 1)._binaryLogarithm()
  }

  @inlinable @inline(__always)
  internal static func firstNode(onLevel level: Int) -> _Node {
    assert(level >= 0)
    return _Node(offset: (1 &<< level) &- 1, level: level)
  }

  @inlinable @inline(__always)
  internal static func lastNode(onLevel level: Int) -> _Node {
    assert(level >= 0)
    return _Node(offset: (1 &<< (level &+ 1)) &- 2, level: level)
  }

  @inlinable @inline(__always)
  internal static func isMinLevel(_ level: Int) -> Bool {
    level & 0b1 == 0
  }
}

extension _Node {
  /// The root node in the heap.
  @inlinable @inline(__always)
  internal static var root: Self {
    Self.init(offset: 0, level: 0)
  }

  /// The first max node in the heap. (I.e., the left child of the root.)
  @inlinable @inline(__always)
  internal static var leftMax: Self {
    Self.init(offset: 1, level: 1)
  }

  /// The second max node in the heap. (I.e., the right child of the root.)
  @inlinable @inline(__always)
  internal static var rightMax: Self {
    Self.init(offset: 2, level: 1)
  }

  @inlinable
  internal var isMinLevel: Bool {
    Self.isMinLevel(level)
  }
}

extension _Node {
  /// Returns the parent of this index, or `nil` if the index has no parent
  /// (i.e. when this is the root index).
  @inlinable @inline(__always)
  internal func parent() -> Self? {
    guard offset > 0 else { return nil }
    return Self(offset: (offset &- 1) / 2, level: level &- 1)
  }

  /// Returns the grandparent of this index, or `nil` if the index has
  /// no grandparent.
  @inlinable @inline(__always)
  internal func grandParent() -> Self? {
    guard offset > 2 else { return nil }
    return Self(offset: (offset &- 3) / 4, level: level &- 2)
  }

  /// Returns the left child of this index or `nil` if the index has no
  /// children.
  @inlinable @inline(__always)
  internal func leftChild(limit: Int) -> Self? {
    let left = offset * 2 &+ 1
    guard left < limit else { return nil }
    return Self(offset: left, level: level &+ 1)
  }

  /// Returns the right child of this index or `nil` if the index has no
  /// right child.
  @inlinable @inline(__always)
  internal func rightChild(limit: Int) -> Self? {
    let right = offset * 2 &+ 2
    guard right < limit else { return nil }
    return Self(offset: right, level: level &+ 1)
  }

  /// Returns the grandchildren of this index or `nil` if the index has no
  /// grandchildren.
  @inlinable
  internal func grandchildren(limit: Int) -> ClosedRange<Self>? {
    let start = offset * 4 &+ 3
    guard start < limit else { return nil }
    let end = min(offset * 4 &+ 6, limit &- 1)
    return ClosedRange(
      uncheckedBounds: (
        lower: Self(offset: start, level: level &+ 2),
        upper: Self(offset: end, level: level &+ 2)))
  }

  @inlinable
  internal static func allNodes(
    onLevel level: Int,
    limit: Int
  ) -> ClosedRange<Self>? {
    let first = Self.firstNode(onLevel: level)
    guard first.offset < limit else { return nil }
    var last = self.lastNode(onLevel: level)
    if last.offset >= limit {
      last = _Node(offset: limit &- 1, level: level)
    }
    return ClosedRange(uncheckedBounds: (first, last))
  }
}

extension ClosedRange where Bound == _Node {
  @inlinable @inline(__always)
  internal var _count: Int {
    upperBound.offset - lowerBound.offset + 1
  }

  @inlinable @inline(__always)
  internal func _forEach(_ body: (_Node) -> Void) {
    assert(
      isEmpty || _Node.level(forOffset: upperBound.offset) == lowerBound.level)
    var node = self.lowerBound
    while node.offset <= self.upperBound.offset {
      body(node)
      node.offset &+= 1
    }
  }
}
