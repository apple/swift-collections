//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@usableFromInline
internal struct _UnsafePath {
  @usableFromInline
  internal var ancestors: _AncestorOffsets

  @usableFromInline
  internal var node: _UnmanagedNode

  @usableFromInline
  internal var _nodeOffset: UInt32

  @usableFromInline
  internal var level: _Level

  @usableFromInline
  internal var _isItem: Bool

  @usableFromInline
  @_effects(releasenone)
  internal init(root: __shared _RawNode) {
    self.level = .top
    self.ancestors = .empty
    self.node = root.unmanaged
    self._nodeOffset = 0
    self._isItem = root.storage.header.hasItems
  }
}

extension _UnsafePath {
  internal init(
    _ level: _Level,
    _ ancestors: _AncestorOffsets,
    _ node: _UnmanagedNode,
    _ childOffset: Int
  ) {
    assert(childOffset >= 0 && childOffset < node.childCount)
    self.level = level
    self.ancestors = ancestors
    self.node = node
    self._nodeOffset = UInt32(truncatingIfNeeded: childOffset)
    self._isItem = false
  }
}

extension _UnsafePath: Equatable {
  @usableFromInline
  @_effects(releasenone)
  internal static func ==(left: Self, right: Self) -> Bool {
    // Note: we don't compare nodes (node equality should follow from the rest)
    left.level == right.level
    && left.ancestors == right.ancestors
    && left._nodeOffset == right._nodeOffset
    && left._isItem == right._isItem
  }
}

extension _UnsafePath: Hashable {
  @usableFromInline
  @_effects(releasenone)
  internal func hash(into hasher: inout Hasher) {
    // Note: we don't hash nodes, as they aren't compared by ==, either.
    hasher.combine(ancestors.path)
    hasher.combine(_nodeOffset)
    hasher.combine(level._shift)
    hasher.combine(_isItem)
  }
}

extension _UnsafePath: Comparable {
  @usableFromInline
  @_effects(releasenone)
  internal static func <(left: Self, right: Self) -> Bool {
    // This implements a total ordering across paths based on the offset
    // sequences they contain, corresponding to a preorder walk of the tree.
    //
    // Paths addressing items within a node are ordered before paths addressing
    // a child node within the same node.

    var level: _Level = .top
    while level < left.level, level < right.level {
      let l = left.ancestors[level]
      let r = right.ancestors[level]
      guard l == r else { return l < r }
      level = level.descend()
    }
    assert(level < left.level || !left.ancestors.hasDataBelow(level))
    assert(level < right.level || !right.ancestors.hasDataBelow(level))
    if level < right.level {
      guard !left._isItem else { return true }
      let l = left._nodeOffset
      let r = right.ancestors[level]
      return l < r
    }
    if level < left.level {
      guard !right._isItem else { return false }
      let l = left.ancestors[level]
      let r = right._nodeOffset
      return l < r
    }
    guard left._isItem == right._isItem else { return left._isItem }
    return left._nodeOffset < right._nodeOffset
  }
}

extension _UnsafePath: CustomStringConvertible {
  @usableFromInline
  internal var description: String {
    var d = "@"
    var l: _Level = .top
    while l < self.level {
      d += ".\(self.ancestors[l])"
      l = l.descend()
    }
    if isPlaceholder {
      d += "[\(self._nodeOffset)]?"
    } else if isOnItem {
      d += "[\(self._nodeOffset)]"
    } else if isOnChild {
      d += ".\(self._nodeOffset)"
    } else if isOnNodeEnd {
      d += ".$(\(self._nodeOffset))"
    }
    return d
  }
}

extension _UnsafePath {
  /// Returns true if this path addresses an item in the tree; otherwise returns
  /// false.
  ///
  /// - Note: This method needs to resolve the unmanaged node reference
  ///   that is stored in the path. It is up to the caller to ensure this will
  ///   never get called when the node is no longer valid; otherwise this will
  ///   trigger undefined behavior.
  @inlinable @inline(__always)
  internal var isOnItem: Bool {
    // Note: this may be true even if nodeOffset == itemCount (insertion paths).
    _isItem
  }

  /// Returns true if this path addresses the position following a node's last
  /// valid item. Such paths can represent the place of an item that might be
  /// inserted later; they do not occur while simply iterating over existing
  /// items.
  internal var isPlaceholder: Bool {
    _isItem && _nodeOffset == node.itemCount
  }

  /// Returns true if this path addresses a node in the tree; otherwise returns
  /// false.
  ///
  /// - Note: This method needs to resolve the unmanaged node reference
  ///   that is stored in the path. It is up to the caller to ensure this will
  ///   never get called when the node is no longer valid; otherwise this will
  ///   trigger undefined behavior.
  internal var isOnChild: Bool {
    !_isItem && _nodeOffset < node.childCount
  }

  /// Returns true if this path addresses an empty slot within a node in a tree;
  /// otherwise returns false.
  ///
  /// - Note: This method needs to resolve the unmanaged node reference
  ///   that is stored in the path. It is up to the caller to ensure this will
  ///   never get called when the node is no longer valid; otherwise this will
  ///   trigger undefined behavior.
  internal var isOnNodeEnd: Bool {
    !_isItem && _nodeOffset == node.childCount
  }

  @inlinable
  internal var isOnLeftmostItem: Bool {
    // We are on the leftmost item in the tree if we are currently
    // addressing an item and the ancestors path is all zero bits.
    _isItem && ancestors == .empty && _nodeOffset == 0
  }
}

extension _UnsafePath {
  @inlinable @inline(__always)
  internal var nodeOffset: Int {
    get {
      Int(truncatingIfNeeded: _nodeOffset)
    }
    set {
      assert(newValue >= 0 && newValue <= UInt32.max)
      _nodeOffset = UInt32(truncatingIfNeeded: newValue)
    }
  }

  /// Returns an unmanaged reference to the child node this path is currently
  /// addressing.
  ///
  /// - Note: This method needs to resolve the unmanaged node reference
  ///   that is stored in the path. It is up to the caller to ensure this will
  ///   never get called when the node is no longer valid; otherwise this will
  ///   trigger undefined behavior.
  internal var currentChild: _UnmanagedNode {
    assert(isOnChild)
    return node.unmanagedChild(at: nodeOffset)
  }

  internal func childOffset(at level: _Level) -> Int {
    assert(level < self.level)
    return ancestors[level]
  }
  /// Returns the offset to the currently addressed item.
  ///
  /// - Note: This method needs to resolve the unmanaged node reference
  ///   that is stored in the path. It is up to the caller to ensure this will
  ///   never get called when the node is no longer valid; otherwise this will
  ///   trigger undefined behavior.
  @inlinable @inline(__always)
  internal var currentItemOffset: Int {
    assert(isOnItem)
    return nodeOffset
  }
}

extension _UnsafePath {
  /// Positions this path on the item with the specified offset within its
  /// current node.
  ///
  /// - Note: This method needs to resolve the unmanaged node reference
  ///   that is stored in the path. It is up to the caller to ensure this will
  ///   never get called when the node is no longer valid; otherwise this will
  ///   trigger undefined behavior.
  @inlinable
  internal mutating func selectItem(at offset: Int) {
    // As a special exception, this allows offset to equal the item count.
    // This can happen for paths that address the position a new item might be
    // inserted later.
    assert(offset >= 0 && offset <= node.itemCount)
    nodeOffset = offset
    _isItem = true
  }

  /// Positions this path on the child with the specified offset within its
  /// current node, without descending into it.
  ///
  /// - Note: This method needs to resolve the unmanaged node reference
  ///   that is stored in the path. It is up to the caller to ensure this will
  ///   never get called when the node is no longer valid; otherwise this will
  ///   trigger undefined behavior.
  @inlinable
  internal mutating func selectChild(at offset: Int) {
    // As a special exception, this allows offset to equal the child count.
    // This is equivalent to a call to `selectEnd()`.
    assert(offset >= 0 && offset <= node.childCount)
    nodeOffset = offset
    _isItem = false
  }

  /// Positions this path on the empty slot at the end of its current node.
  ///
  /// - Note: This method needs to resolve the unmanaged node reference
  ///   that is stored in the path. It is up to the caller to ensure this will
  ///   never get called when the node is no longer valid; otherwise this will
  ///   trigger undefined behavior.
  @usableFromInline
  @_effects(releasenone)
  internal mutating func selectEnd() {
    nodeOffset = node.childCount
    _isItem = false
  }

  /// Descend onto the first path within the currently selected child.
  /// (Either the first item if it exists, or the first child. If the child
  /// is an empty node (which should not happen in a hash tree), then this
  /// selects the empty slot at the end of it.
  ///
  /// - Note: This method needs to resolve the unmanaged node reference
  ///   that is stored in the path. It is up to the caller to ensure this will
  ///   never get called when the node is no longer valid; otherwise this will
  ///   trigger undefined behavior.
  @usableFromInline
  @_effects(releasenone)
  internal mutating func descend() {
    self.node = currentChild
    self.ancestors[level] = nodeOffset
    self.nodeOffset = 0
    self._isItem = node.hasItems
    self.level = level.descend()
  }

  internal mutating func ascendToNearestAncestor(
    under root: _RawNode,
    where test: (_UnmanagedNode, Int) -> Bool
  ) -> Bool {
    if self.level.isAtRoot { return false }
    var best: _UnsafePath? = nil
    var n = root.unmanaged
    var l: _Level = .top
    while l < self.level {
      let offset = self.ancestors[l]
      if test(n, offset) {
        best = _UnsafePath(l, self.ancestors.truncating(to: l), n, offset)
      }
      n = n.unmanagedChild(at: offset)
      l = l.descend()
    }
    guard let best = best else { return false }
    self = best
    return true
  }

  internal mutating func ascend(under root: _RawNode) {
    assert(!self.level.isAtRoot)
    var n = root.unmanaged
    var l: _Level = .top
    while l.descend() < self.level {
      n = n.unmanagedChild(at: self.ancestors[l])
      l = l.descend()
    }
    assert(l.descend() == self.level)
    self._isItem = false
    self.nodeOffset = self.ancestors[l]
    let oldNode = self.node
    self.node = n
    self.ancestors.clear(l)
    self.level = l
    assert(self.currentChild == oldNode)
  }
}

extension _UnsafePath {
  mutating func selectNextItem() -> Bool {
    assert(isOnItem)
    _nodeOffset &+= 1
    if _nodeOffset < node.itemCount { return true }
    _nodeOffset = 0
    _isItem = false
    return false
  }

  mutating func selectNextChild() -> Bool {
    assert(!isOnItem)
    let childCount = node.childCount
    guard _nodeOffset < childCount else { return false }
    _nodeOffset &+= 1
    return _nodeOffset < childCount
  }
}

extension _UnsafePath {
  @usableFromInline
  @_effects(releasenone)
  internal mutating func descendToLeftMostItem() {
    while isOnChild {
      descend()
    }
  }

  internal mutating func descendToRightMostItem() {
    assert(isOnChild)
    while true {
      descend()
      let childCount = node.childCount
      guard childCount > 0 else { break }
      selectChild(at: childCount - 1)
    }
    let itemCount = node.itemCount
    assert(itemCount > 0)
    selectItem(at: itemCount - 1)
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func findSuccessorItem(under root: _RawNode) -> Bool {
    guard isOnItem else { return false }
    if selectNextItem() { return true }
    if node.hasChildren {
      descendToLeftMostItem()
      assert(isOnItem)
      return true
    }
    if ascendToNearestAncestor(
      under: root, where: { $1 &+ 1 < $0.childCount }
    ) {
      let r = selectNextChild()
      assert(r)
      descendToLeftMostItem()
      assert(isOnItem)
      return true
    }
    self = _UnsafePath(root: root)
    self.selectEnd()
    return true
  }

  @usableFromInline
  @_effects(releasenone)
  internal mutating func findPredecessorItem(under root: _RawNode) -> Bool {
    switch (isOnItem, nodeOffset > 0) {
    case (true, true):
      selectItem(at: nodeOffset &- 1)
      return true
    case (false, true):
      selectChild(at: nodeOffset &- 1)
      descendToRightMostItem()
      return true
    case (false, false):
      if node.hasItems {
        selectItem(at: node.itemCount &- 1)
        return true
      }
    case (true, false):
      break
    }
    guard
      ascendToNearestAncestor(under: root, where: { $0.hasItems || $1 > 0 })
    else { return false }

    if nodeOffset > 0 {
      selectChild(at: nodeOffset &- 1)
      descendToRightMostItem()
      return true
    }
    if node.hasItems {
      selectItem(at: node.itemCount &- 1)
      return true
    }
    return false
  }
}

extension _RawNode {
  internal func preorderPosition(_ level: _Level, of path: _UnsafePath) -> Int {
    if path.isOnNodeEnd { return count }
    assert(path.isOnItem)
    if level < path.level {
      let childOffset = path.childOffset(at: level)
      return read {
        let prefix = $0._children[..<childOffset]
          .reduce($0.itemCount) { $0 + $1.count }
        let positionWithinChild = $0[child: childOffset]
          .preorderPosition(level.descend(), of: path)
        return prefix + positionWithinChild
      }
    }
    assert(path.level == level)
    return path.nodeOffset
  }

  @usableFromInline
  @_effects(releasenone)
  internal func distance(
    _ level: _Level, from start: _UnsafePath, to end: _UnsafePath
  ) -> Int {
    assert(level.isAtRoot)
    if start.isOnNodeEnd {
      // Shortcut: distance from end.
      return preorderPosition(level, of: end) - count
    }
    if end.isOnNodeEnd {
      // Shortcut: distance to end.
      return count - preorderPosition(level, of: start)
    }
    assert(start.isOnItem)
    assert(end.isOnItem)
    if start.level == end.level, start.ancestors == end.ancestors {
      // Shortcut: the paths are under the same node.
      precondition(start.node == end.node, "Internal index validation error")
      return end.currentItemOffset - start.currentItemOffset
    }
    if
      start.level < end.level,
      start.ancestors.isEqual(to: end.ancestors, upTo: start.level)
    {
      // Shortcut: start's node is an ancestor of end's position.
      return start.node._distance(
        start.level, fromItemAtOffset: start.currentItemOffset, to: end)
    }
    if start.ancestors.isEqual(to: end.ancestors, upTo: end.level) {
      // Shortcut: end's node is an ancestor of start's position.
      return -end.node._distance(
        end.level, fromItemAtOffset: end.currentItemOffset, to: start)
    }
    // No shortcuts -- the two paths are in different subtrees.
    // Start descending from the root to look for the closest common
    // ancestor.
    if start < end {
      return _distance(level, from: start, to: end)
    }
    return -_distance(level, from: end, to: start)
  }

  internal func _distance(
    _ level: _Level, from start: _UnsafePath, to end: _UnsafePath
  ) -> Int {
    assert(start < end)
    assert(level < start.level)
    assert(level < end.level)
    let offset1 = start.childOffset(at: level)
    let offset2 = end.childOffset(at: level)
    if offset1 == offset2 {
      return read {
        $0[child: offset1]._distance(level.descend(), from: start, to: end)
      }
    }
    return read {
      let children = $0._children
      let d1 = children[offset1].preorderPosition(level.descend(), of: start)
      let d2 = children[offset1 &+ 1 ..< offset2].reduce(0) { $0 + $1.count }
      let d3 = children[offset2].preorderPosition(level.descend(), of: end)
      return (children[offset1].count - d1) + d2 + d3
    }
  }
}

extension _UnmanagedNode {
  internal func _distance(
    _ level: _Level, fromItemAtOffset start: Int, to end: _UnsafePath
  ) -> Int {
    read {
      assert(start >= 0 && start < $0.itemCount)
      assert(level < end.level)
      let childOffset = end.childOffset(at: level)
      let children = $0._children
      let prefix = children[..<childOffset]
        .reduce($0.itemCount - start) { $0 + $1.count }
      let positionWithinChild = children[childOffset]
        .preorderPosition(level.descend(), of: end)
      return prefix + positionWithinChild
    }
  }
}

extension _Node {
  @inlinable
  internal func path(
    to key: Key, hash: _Hash
  ) -> (found: Bool, path: _UnsafePath) {
    var path = _UnsafePath(root: raw)
    while true {
      let r = UnsafeHandle.read(path.node) {
        $0.find(path.level, key, hash, forInsert: false)
      }
      switch r {
      case .found(_, let offset):
        path.selectItem(at: offset)
        return (true, path)
      case .notFound(_, let offset), .newCollision(_, let offset):
        path.selectItem(at: offset)
        return (false, path)
      case .expansion:
        return (false, path)
      case .descend(_, let offset):
        path.selectChild(at: offset)
        path.descend()
      }
    }
  }
}
