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

/// A non-owning, mutable construct representing a path to an item or child node
/// within a hash tree (or the virtual slot addressing the end of the
/// items or children region within a node).
///
/// Path values provide mutating methods to freely navigate around in the tree,
/// including basics such as descending into a child node, ascending to a
/// parent or selecting a particular item within the current node; as well as
/// more complicated methods such as finding the next/previous item in a
/// preorder walk of the tree.
///
/// Paths are, for the most part, represented by a series of slot values
/// identifying a particular branch within each level in the tree up to and
/// including the final node on the path.
///
/// However, to speed up common operations, path values also include a single
/// `_UnmanagedNode` reference to their final node. This reference does not
/// keep the targeted node alive -- it is the use site's responsibility to
/// ensure that the path is still valid before calling most of its operations.
///
/// Note: paths only have a direct reference to their final node. This means
/// that ascending to the parent node requires following the path from the root
/// node down. (Paths could also store references to every node alongside them
/// in a fixed-size array; this would speed up walking over the tree, but it
/// would considerably embiggen the size of the path construct.)
@usableFromInline
internal struct _UnsafePath {
  @usableFromInline
  internal var ancestors: _AncestorSlots

  @usableFromInline
  internal var node: _UnmanagedNode

  @usableFromInline
  internal var nodeSlot: _Slot

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
    self.nodeSlot = .zero
    self._isItem = root.storage.header.hasItems
  }
}

extension _UnsafePath {
  internal init(
    _ level: _Level,
    _ ancestors: _AncestorSlots,
    _ node: _UnmanagedNode,
    _ childSlot: _Slot
  ) {
    assert(childSlot < node.childEnd)
    self.level = level
    self.ancestors = ancestors
    self.node = node
    self.nodeSlot = childSlot
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
    && left.nodeSlot == right.nodeSlot
    && left._isItem == right._isItem
  }
}

extension _UnsafePath: Hashable {
  @usableFromInline
  @_effects(releasenone)
  internal func hash(into hasher: inout Hasher) {
    // Note: we don't hash nodes, as they aren't compared by ==, either.
    hasher.combine(ancestors.path)
    hasher.combine(nodeSlot)
    hasher.combine(level._shift)
    hasher.combine(_isItem)
  }
}

extension _UnsafePath: Comparable {
  @usableFromInline
  @_effects(releasenone)
  internal static func <(left: Self, right: Self) -> Bool {
    // This implements a total ordering across paths based on the slot
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
      let l = left.nodeSlot
      let r = right.ancestors[level]
      return l < r
    }
    if level < left.level {
      guard !right._isItem else { return false }
      let l = left.ancestors[level]
      let r = right.nodeSlot
      return l < r
    }
    guard left._isItem == right._isItem else { return left._isItem }
    return left.nodeSlot < right.nodeSlot
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
      d += "[\(self.nodeSlot)]?"
    } else if isOnItem {
      d += "[\(self.nodeSlot)]"
    } else if isOnChild {
      d += ".\(self.nodeSlot)"
    } else if isOnNodeEnd {
      d += ".$(\(self.nodeSlot))"
    }
    return d
  }
}

extension _UnsafePath {
  /// Returns true if this path addresses an item in the tree; otherwise returns
  /// false.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  @inlinable @inline(__always)
  internal var isOnItem: Bool {
    // Note: this may be true even if nodeSlot == itemCount (insertion paths).
    _isItem
  }

  /// Returns true if this path addresses the position following a node's last
  /// valid item. Such paths can represent the place of an item that might be
  /// inserted later; they do not occur while simply iterating over existing
  /// items.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  internal var isPlaceholder: Bool {
    _isItem && nodeSlot.value == node.itemCount
  }

  /// Returns true if this path addresses a node in the tree; otherwise returns
  /// false.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  internal var isOnChild: Bool {
    !_isItem && nodeSlot.value < node.childCount
  }

  /// Returns true if this path addresses an empty slot within a node in a tree;
  /// otherwise returns false.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  internal var isOnNodeEnd: Bool {
    !_isItem && nodeSlot.value == node.childCount
  }

  /// Returns true if this path addresses an item on the leftmost branch of the
  /// tree, or the empty slot at the end of an empty tree.
  @inlinable
  internal var isOnLeftmostItem: Bool {
    // We are on the leftmost item in the tree if we are currently
    // addressing an item and the ancestors path is all zero bits.
    _isItem && ancestors == .empty && nodeSlot == .zero
  }
}

extension _UnsafePath {
  /// Returns an unmanaged reference to the child node this path is currently
  /// addressing.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  internal var currentChild: _UnmanagedNode {
    assert(isOnChild)
    return node.unmanagedChild(at: nodeSlot)
  }

  /// Returns the chid slot in this path corresponding to the specified level.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  internal func childSlot(at level: _Level) -> _Slot {
    assert(level < self.level)
    return ancestors[level]
  }
  /// Returns the slot of the currently addressed item.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  @inlinable @inline(__always)
  internal var currentItemSlot: _Slot {
    assert(isOnItem)
    return nodeSlot
  }
}

extension _UnsafePath {
  /// Positions this path on the item with the specified slot within its
  /// current node.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  @inlinable
  internal mutating func selectItem(at slot: _Slot) {
    // As a special exception, this allows slot to equal the item count.
    // This can happen for paths that address the position a new item might be
    // inserted later.
    assert(slot <= node.itemEnd)
    nodeSlot = slot
    _isItem = true
  }

  /// Positions this path on the child with the specified slot within its
  /// current node, without descending into it.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  @inlinable
  internal mutating func selectChild(at slot: _Slot) {
    // As a special exception, this allows slot to equal the child count.
    // This is equivalent to a call to `selectEnd()`.
    assert(slot <= node.childEnd)
    nodeSlot = slot
    _isItem = false
  }

  /// Positions this path on the empty slot at the end of its current node.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  @usableFromInline
  @_effects(releasenone)
  internal mutating func selectEnd() {
    nodeSlot = node.childEnd
    _isItem = false
  }

  /// Descend onto the first path within the currently selected child.
  /// (Either the first item if it exists, or the first child. If the child
  /// is an empty node (which should not happen in a valid hash tree), then this
  /// selects the empty slot at the end of it.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  @usableFromInline
  @_effects(releasenone)
  internal mutating func descend() {
    self.node = currentChild
    self.ancestors[level] = nodeSlot
    self.nodeSlot = .zero
    self._isItem = node.hasItems
    self.level = level.descend()
  }

  /// Ascend to the nearest ancestor for which the `test`  predicate returns
  /// true. Because paths do not contain references to every node on them,
  /// you need to manually supply a valid reference to the root node. This
  /// method visits every node between the root and the current final node on
  /// the path.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  internal mutating func ascendToNearestAncestor(
    under root: _RawNode,
    where test: (_UnmanagedNode, _Slot) -> Bool
  ) -> Bool {
    if self.level.isAtRoot { return false }
    var best: _UnsafePath? = nil
    var n = root.unmanaged
    var l: _Level = .top
    while l < self.level {
      let slot = self.ancestors[l]
      if test(n, slot) {
        best = _UnsafePath(l, self.ancestors.truncating(to: l), n, slot)
      }
      n = n.unmanagedChild(at: slot)
      l = l.descend()
    }
    guard let best = best else { return false }
    self = best
    return true
  }
  /// Ascend to the parent node of this path. Because paths do not contain
  /// references to every node on them, you need to manually supply a valid
  /// reference to the root node. This method visits every node
  /// between the root and the current final node on the path.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
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
    self.nodeSlot = self.ancestors[l]
    let oldNode = self.node
    self.node = n
    self.ancestors.clear(l)
    self.level = l
    assert(self.currentChild == oldNode)
  }
}

extension _UnsafePath {
  /// Given a path that is on an item, advance it to the next item within its
  /// current node, and return true. If there is no next item, position the path
  /// on the first child, and return false. If there is no children, position
  /// the path on the node's end position, and return false.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  mutating func selectNextItem() -> Bool {
    assert(isOnItem)
    nodeSlot = nodeSlot.next()
    if nodeSlot < node.itemEnd { return true }
    nodeSlot = .zero
    _isItem = false
    return false
  }

  /// Given a path that is on a child node, advance it to the next child within
  /// its current node, and return true. If there is no next child, position
  /// the path on the node's end position, and return false.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  mutating func selectNextChild() -> Bool {
    assert(!isOnItem)
    let childEnd = node.childEnd
    guard nodeSlot < childEnd else { return false }
    nodeSlot = nodeSlot.next()
    return nodeSlot < childEnd
  }
}

extension _UnsafePath {
  /// If this path addresses a child node, descend into the leftmost item
  /// within the subtree under it (i.e., the first item that would be visited
  /// by a preorder walk within that subtree). Do nothing if the path addresses
  /// an item or the end position.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  @usableFromInline
  @_effects(releasenone)
  internal mutating func descendToLeftMostItem() {
    while isOnChild {
      descend()
    }
  }

  /// Given a path addressing a child node, descend into the rightmost item
  /// within the subtree under it (i.e., the last item that would be visited
  /// by a preorder walk within that subtree). Do nothing if the path addresses
  /// an item or the end position.
  ///
  /// - Note: It is undefined behavior to call this on a path that is no longer
  ///    valid.
  internal mutating func descendToRightMostItem() {
    assert(isOnChild)
    while true {
      descend()
      let childEnd = node.childEnd
      guard childEnd > .zero else { break }
      selectChild(at: childEnd.previous())
    }
    let itemEnd = node.itemEnd
    assert(itemEnd > .zero)
    selectItem(at: itemEnd.previous())
  }

  /// Find the next item in a preorder walk in the tree following the currently
  /// addressed item, and return true. Return false and do nothing if the
  /// path does not currently address an item.
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
      under: root, where: { $1.next() < $0.childEnd }
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

  /// Find the previous item in a preorder walk in the tree preceding the
  /// currently addressed position, and return true.
  /// Return false if there is no previous item.
  @usableFromInline
  @_effects(releasenone)
  internal mutating func findPredecessorItem(under root: _RawNode) -> Bool {
    switch (isOnItem, nodeSlot > .zero) {
    case (true, true):
      selectItem(at: nodeSlot.previous())
      return true
    case (false, true):
      selectChild(at: nodeSlot.previous())
      descendToRightMostItem()
      return true
    case (false, false):
      if node.hasItems {
        selectItem(at: node.itemEnd.previous())
        return true
      }
    case (true, false):
      break
    }
    guard
      ascendToNearestAncestor(
        under: root,
        where: { $0.hasItems || $1 > .zero })
    else { return false }

    if nodeSlot > .zero {
      selectChild(at: nodeSlot.previous())
      descendToRightMostItem()
      return true
    }
    if node.hasItems {
      selectItem(at: node.itemEnd.previous())
      return true
    }
    return false
  }
}

extension _RawNode {
  /// Return the integer position of the item addressed by the given path
  /// within a preorder walk of the tree. If the path addresses the end
  /// position, then return the number of items in the tree.
  ///
  /// This method must only be called on the root node.
  internal func preorderPosition(
    _ level: _Level, of path: _UnsafePath
  ) -> Int {
    if path.isOnNodeEnd { return count }
    assert(path.isOnItem)
    if level < path.level {
      let childSlot = path.childSlot(at: level)
      return read {
        let prefix = $0._children[..<childSlot.value]
          .reduce($0.itemCount) { $0 + $1.count }
        let positionWithinChild = $0[child: childSlot]
          .preorderPosition(level.descend(), of: path)
        return prefix + positionWithinChild
      }
    }
    assert(path.level == level)
    return path.nodeSlot.value
  }

  /// Return the number of steps between two paths within a preorder walk of the
  /// tree. The two paths must not address a child node.
  ///
  /// This method must only be called on the root node.
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
      return start.currentItemSlot.distance(to: end.currentItemSlot)
    }
    if
      start.level < end.level,
      start.ancestors.isEqual(to: end.ancestors, upTo: start.level)
    {
      // Shortcut: start's node is an ancestor of end's position.
      return start.node._distance(
        start.level, fromItemAt: start.currentItemSlot, to: end)
    }
    if start.ancestors.isEqual(to: end.ancestors, upTo: end.level) {
      // Shortcut: end's node is an ancestor of start's position.
      return -end.node._distance(
        end.level, fromItemAt: end.currentItemSlot, to: start)
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
    let slot1 = start.childSlot(at: level)
    let slot2 = end.childSlot(at: level)
    if slot1 == slot2 {
      return read {
        $0[child: slot1]._distance(level.descend(), from: start, to: end)
      }
    }
    return read {
      let children = $0._children
      let d1 = children[slot1.value]
        .preorderPosition(level.descend(), of: start)
      let d2 = children[slot1.value &+ 1 ..< slot2.value]
        .reduce(0) { $0 + $1.count }
      let d3 = children[slot2.value]
        .preorderPosition(level.descend(), of: end)
      return (children[slot1.value].count - d1) + d2 + d3
    }
  }
}

extension _UnmanagedNode {
  internal func _distance(
    _ level: _Level, fromItemAt start: _Slot, to end: _UnsafePath
  ) -> Int {
    read {
      assert(start < $0.itemEnd)
      assert(level < end.level)
      let childSlot = end.childSlot(at: level)
      let children = $0._children
      let prefix = children[..<childSlot.value]
        .reduce($0.itemCount - start.value) { $0 + $1.count }
      let positionWithinChild = children[childSlot.value]
        .preorderPosition(level.descend(), of: end)
      return prefix + positionWithinChild
    }
  }
}

extension _Node {
  /// Return the path to the given key in this tree if it exists; otherwise
  /// return nil.
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
      case .found(_, let slot):
        path.selectItem(at: slot)
        return (true, path)
      case .notFound(_, let slot), .newCollision(_, let slot):
        path.selectItem(at: slot)
        return (false, path)
      case .expansion:
        return (false, path)
      case .descend(_, let slot):
        path.selectChild(at: slot)
        path.descend()
      }
    }
  }
}
