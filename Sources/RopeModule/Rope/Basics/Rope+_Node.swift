//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if swift(<5.8) && !COLLECTIONS_SINGLE_MODULE
import _CollectionsUtilities // for 5.8 polyfills
#endif

extension Rope {
  struct _Node: _RopeItem {
    typealias Element = Rope.Element
    typealias Summary = Rope.Summary
    typealias Index = Rope.Index
    typealias _Item = Rope._Item
    typealias _Storage = Rope._Storage
    typealias _UnsafeHandle = Rope._UnsafeHandle
    typealias _Path = Rope._Path
    typealias _UnmanagedLeaf = Rope._UnmanagedLeaf

    var object: AnyObject
    var summary: Summary
    
    init(leaf: _Storage<_Item>, summary: Summary? = nil) {
      self.object = leaf
      self.summary = .zero
      self.summary = readLeaf { handle in
        handle.children.reduce(into: .zero) { $0.add($1.summary) }
      }
    }
    
    init(inner: _Storage<_Node>, summary: Summary? = nil) {
      assert(inner.header.height > 0)
      self.object = inner
      self.summary = .zero
      self.summary = readInner { handle in
        handle.children.reduce(into: .zero) { $0.add($1.summary) }
      }
    }
  }
}

extension Rope._Node: @unchecked Sendable where Element: Sendable {
  // @unchecked because `object` is stored as an `AnyObject` above.
}

extension Rope._Node {
  var _headerPtr: UnsafePointer<_RopeStorageHeader> {
    let p = _getUnsafePointerToStoredProperties(object)
      .assumingMemoryBound(to: _RopeStorageHeader.self)
    return .init(p)
  }
  
  var header: _RopeStorageHeader {
    _headerPtr.pointee
  }
  
  @inline(__always)
  var height: UInt8 { header.height }
  
  @inline(__always)
  var isLeaf: Bool { height == 0 }
  
  @inline(__always)
  var asLeaf: _Storage<_Item> {
    assert(height == 0)
    return unsafeDowncast(object, to: _Storage<_Item>.self)
  }
  
  @inline(__always)
  var asInner: _Storage<Self> {
    assert(height > 0)
    return unsafeDowncast(object, to: _Storage<Self>.self)
  }
  
  @inline(__always)
  var childCount: Int { header.childCount }
  
  var isEmpty: Bool { childCount == 0 }
  var isSingleton: Bool { isLeaf && childCount == 1 }
  var isUndersized: Bool { childCount < Summary.minNodeSize }
  var isFull: Bool { childCount == Summary.maxNodeSize }
}

extension Rope._Node {
  static func createLeaf() -> Self {
    Self(leaf: .create(height: 0), summary: Summary.zero)
  }
  
  static func createLeaf(_ item: __owned _Item) -> Self {
    var leaf = createLeaf()
    leaf._appendItem(item)
    return leaf
  }
  
  static func createInner(height: UInt8) -> Self {
    Self(inner: .create(height: height), summary: .zero)
  }
  
  static func createInner(children left: __owned Self, _ right: __owned Self) -> Self {
    assert(left.height == right.height)
    var new = createInner(height: left.height + 1)
    new.summary = left.summary
    new.summary.add(right.summary)
    new.updateInner { h in
      h._appendChild(left)
      h._appendChild(right)
    }
    return new
  }
}

extension Rope._Node {
  @inline(__always)
  mutating func isUnique() -> Bool {
    isKnownUniquelyReferenced(&object)
  }
  
  mutating func ensureUnique() {
    guard !isKnownUniquelyReferenced(&object) else { return }
    self = copy()
  }

  @inline(never)
  func copy() -> Self {
    if isLeaf {
      return Self(leaf: readLeaf { $0.copy() }, summary: self.summary)
    }
    return Self(inner: readInner { $0.copy() }, summary: self.summary)
  }

  @inline(never)
  func copy(slots: Range<Int>) -> Self {
    if isLeaf {
      let (object, summary) = readLeaf { $0.copy(slots: slots) }
      return Self(leaf: object, summary: summary)
    }
    let (object, summary) = readInner { $0.copy(slots: slots) }
    return Self(inner: object, summary: summary)
  }

  @inline(__always)
  func readLeaf<R>(
    _ body: (_UnsafeHandle<_Item>) -> R
  ) -> R {
    asLeaf.withUnsafeMutablePointers { h, p in
      let handle = _UnsafeHandle(isMutable: false, header: h, start: p)
      return body(handle)
    }
  }
  
  @inline(__always)
  mutating func updateLeaf<R>(
    _ body: (_UnsafeHandle<_Item>) -> R
  ) -> R {
    asLeaf.withUnsafeMutablePointers { h, p in
      let handle = _UnsafeHandle(isMutable: true, header: h, start: p)
      return body(handle)
    }
  }
  
  @inline(__always)
  func readInner<R>(
    _ body: (_UnsafeHandle<Self>) -> R
  ) -> R {
    asInner.withUnsafeMutablePointers { h, p in
      let handle = _UnsafeHandle(isMutable: false, header: h, start: p)
      return body(handle)
    }
  }
  
  @inline(__always)
  mutating func updateInner<R>(
    _ body: (_UnsafeHandle<Self>) -> R
  ) -> R {
    asInner.withUnsafeMutablePointers { h, p in
      let handle = _UnsafeHandle(isMutable: true, header: h, start: p)
      return body(handle)
    }
  }
}

extension Rope._Node {
  mutating func _insertItem(_ item: __owned _Item, at slot: Int) {
    assert(isLeaf)
    ensureUnique()
    self.summary.add(item.summary)
    updateLeaf { $0._insertChild(item, at: slot) }
  }
  
  mutating func _insertNode(_ node: __owned Self, at slot: Int) {
    assert(!isLeaf)
    assert(self.height == node.height + 1)
    ensureUnique()
    self.summary.add(node.summary)
    updateInner { $0._insertChild(node, at: slot) }
  }
}

extension Rope._Node {
  mutating func _appendItem(_ item: __owned _Item) {
    assert(isLeaf)
    ensureUnique()
    self.summary.add(item.summary)
    updateLeaf { $0._appendChild(item) }
  }
  
  mutating func _appendNode(_ node: __owned Self) {
    assert(!isLeaf)
    ensureUnique()
    self.summary.add(node.summary)
    updateInner { $0._appendChild(node) }
  }
}

extension Rope._Node {
  mutating func _removeItem(at slot: Int) -> (removed: _Item, delta: Summary) {
    assert(isLeaf)
    ensureUnique()
    let item = updateLeaf { $0._removeChild(at: slot) }
    let delta = item.summary
    self.summary.subtract(delta)
    return (item, delta)
  }
  
  mutating func _removeNode(at slot: Int) -> Self {
    assert(!isLeaf)
    ensureUnique()
    let result = updateInner { $0._removeChild(at: slot) }
    self.summary.subtract(result.summary)
    return result
  }
}

extension Rope._Node {
  mutating func split(keeping desiredCount: Int) -> Self {
    assert(desiredCount >= 0 && desiredCount <= childCount)
    var new = isLeaf ? Self.createLeaf() : Self.createInner(height: height)
    guard desiredCount < childCount else { return new }
    guard desiredCount > 0 else {
      swap(&self, &new)
      return new
    }
    ensureUnique()
    new.prependChildren(movingFromSuffixOf: &self, count: childCount - desiredCount)
    assert(childCount == desiredCount)
    return new
  }
}

extension Rope._Node {
  mutating func rebalance(nextNeighbor right: inout Rope<Element>._Node) -> Bool {
    assert(self.height == right.height)
    if self.isEmpty {
      swap(&self, &right)
      return true
    }
    guard self.isUndersized || right.isUndersized else { return false }
    let c = self.childCount + right.childCount
    let desired = (
      c <= Summary.maxNodeSize ? c
      : c / 2 >= Summary.minNodeSize ? c / 2
      : Summary.minNodeSize
    )
    Self.redistributeChildren(&self, &right, to: desired)
    return right.isEmpty
  }
  
  mutating func rebalance(prevNeighbor left: inout Self) -> Bool {
    guard left.rebalance(nextNeighbor: &self) else { return false }
    swap(&self, &left)
    return true
  }
  
  /// Shift children between `left` and `right` such that the number of children in `left`
  /// becomes `target`.
  internal static func redistributeChildren(
    _ left: inout Self,
    _ right: inout Self,
    to target: Int
  ) {
    assert(left.height == right.height)
    assert(target >= 0 && target <= Summary.maxNodeSize)
    left.ensureUnique()
    right.ensureUnique()
    
    let lc = left.childCount
    let rc = right.childCount
    let target = Swift.min(target, lc + rc)
    let d = target - lc
    if d == 0 { return }
    
    if d > 0 {
      left.appendChildren(movingFromPrefixOf: &right, count: d)
    } else {
      right.prependChildren(movingFromSuffixOf: &left, count: -d)
    }
  }
  
  mutating func appendChildren(movingFromPrefixOf other: inout Self, count: Int) {
    assert(self.height == other.height)
    let delta: Summary
    if isLeaf {
      delta = self.updateLeaf { dst in
        other.updateLeaf { src in
          dst._appendChildren(movingFromPrefixOf: src, count: count)
        }
      }
    } else {
      delta = self.updateInner { dst in
        other.updateInner { src in
          dst._appendChildren(movingFromPrefixOf: src, count: count)
        }
      }
    }
    self.summary.add(delta)
    other.summary.subtract(delta)
  }
  
  mutating func prependChildren(movingFromSuffixOf other: inout Self, count: Int) {
    assert(self.height == other.height)
    let delta: Summary
    if isLeaf {
      delta = self.updateLeaf { dst in
        other.updateLeaf { src in
          dst._prependChildren(movingFromSuffixOf: src, count: count)
        }
      }
    } else {
      delta = self.updateInner { dst in
        other.updateInner { src in
          dst._prependChildren(movingFromSuffixOf: src, count: count)
        }
      }
    }
    self.summary.add(delta)
    other.summary.subtract(delta)
  }
}

extension Rope._Node {
  var _startPath: _Path {
    _Path(height: self.height)
  }
  
  var lastPath: _Path {
    var path = _Path(height: self.height)
    _ = descendToLastItem(under: &path)
    return path
  }
  
  func isAtEnd(_ path: _Path) -> Bool {
    path[self.height] == childCount
  }
  
  func descendToFirstItem(under path: inout _Path) -> _UnmanagedLeaf {
    path.clear(below: self.height + 1)
    return unmanagedLeaf(at: path)
  }
  
  func descendToLastItem(under path: inout _Path) -> _UnmanagedLeaf {
    let h = self.height
    let slot = self.childCount - 1
    path[h] = slot
    if h > 0 {
      return readInner { $0.children[slot].descendToLastItem(under: &path) }
    }
    return asUnmanagedLeaf
  }
}

extension Rope {
  func _unmanagedLeaf(at path: _Path) -> _UnmanagedLeaf? {
    assert(path.height == self._height)
    guard path < _endPath else { return nil }
    return root.unmanagedLeaf(at: path)
  }
}

extension Rope._Node {
  var asUnmanagedLeaf: _UnmanagedLeaf {
    assert(height == 0)
    return _UnmanagedLeaf(unsafeDowncast(self.object, to: _Storage<_Item>.self))
  }
  
  func unmanagedLeaf(at path: _Path) -> _UnmanagedLeaf {
    if height == 0 {
      return asUnmanagedLeaf
    }
    let slot = path[height]
    return readInner { $0.children[slot].unmanagedLeaf(at: path) }
  }
}

extension Rope._Node {
  func formSuccessor(of i: inout Index) -> Bool {
    let h = self.height
    var slot = i._path[h]
    if h == 0 {
      slot &+= 1
      guard slot < childCount else {
        return false
      }
      i._path[h] = slot
      i._leaf = asUnmanagedLeaf
      return true
    }
    return readInner {
      let c = $0.children
      if c[slot].formSuccessor(of: &i) {
        return true
      }
      slot += 1
      guard slot < childCount else {
        return false
      }
      i._path[h] = slot
      i._leaf = c[slot].descendToFirstItem(under: &i._path)
      return true
    }
  }
  
  func formPredecessor(of i: inout Index) -> Bool {
    let h = self.height
    var slot = i._path[h]
    if h == 0 {
      guard slot > 0 else {
        return false
      }
      i._path[h] = slot &- 1
      i._leaf = asUnmanagedLeaf
      return true
    }
    return readInner {
      let c = $0.children
      if slot < c.count, c[slot].formPredecessor(of: &i) {
        return true
      }
      guard slot > 0 else {
        return false
      }
      slot -= 1
      i._path[h] = slot
      i._leaf = c[slot].descendToLastItem(under: &i._path)
      return true
    }
  }
}

extension Rope._Node {
  var lastItem: _Item {
    get {
      self[lastPath]
    }
    _modify {
      assert(childCount > 0)
      var state = _prepareModifyLast()
      defer {
        _ = _finalizeModify(&state)
      }
      yield &state.item
    }
  }
  
  var firstItem: _Item {
    get {
      self[_startPath]
    }
    _modify {
      yield &self[_startPath]
    }
  }
  
  subscript(path: _Path) -> _Item {
    get {
      let h = height
      let slot = path[h]
      precondition(slot < childCount, "Path out of bounds")
      guard h == 0 else {
        return readInner { $0.children[slot][path] }
      }
      return readLeaf { $0.children[slot] }
    }
    @inline(__always)
    _modify {
      var state = _prepareModify(at: path)
      defer {
        _ = _finalizeModify(&state)
      }
      yield &state.item
    }
  }
  
  struct _ModifyState {
    var path: _Path
    var item: _Item
    var summary: Summary
  }
  
  mutating func _prepareModify(at path: _Path) -> _ModifyState {
    ensureUnique()
    let h = height
    let slot = path[h]
    precondition(slot < childCount, "Path out of bounds")
    guard h == 0 else {
      return updateInner { $0.mutableChildren[slot]._prepareModify(at: path) }
    }
    let item = updateLeaf { $0.mutableChildren.moveElement(from: slot) }
    return _ModifyState(path: path, item: item, summary: item.summary)
  }
  
  mutating func _prepareModifyLast() -> _ModifyState {
    var path = _Path(height: height)
    return _prepareModifyLast(&path)
  }
  
  mutating func _prepareModifyLast(_ path: inout _Path) -> _ModifyState {
    ensureUnique()
    let h = height
    let slot = self.childCount - 1
    path[h] = slot
    guard h == 0 else {
      return updateInner { $0.mutableChildren[slot]._prepareModifyLast(&path) }
    }
    let item = updateLeaf { $0.mutableChildren.moveElement(from: slot) }
    return _ModifyState(path: path, item: item, summary: item.summary)
  }
  
  mutating func _finalizeModify(
    _ state: inout _ModifyState
  ) -> (delta: Summary, leaf: _UnmanagedLeaf) {
    assert(isUnique())
    let h = height
    let slot = state.path[h]
    assert(slot < childCount, "Path out of bounds")
    guard h == 0 else {
      let r = updateInner { $0.mutableChildren[slot]._finalizeModify(&state) }
      summary.add(r.delta)
      return r
    }
    let delta = state.item.summary.subtracting(state.summary)
    updateLeaf { $0.mutableChildren.initializeElement(at: slot, to: state.item) }
    summary.add(delta)
    return (delta, asUnmanagedLeaf)
  }
}
