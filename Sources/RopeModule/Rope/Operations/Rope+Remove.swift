//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

extension Rope {
  @inlinable
  @discardableResult
  public mutating func remove(at index: Index) -> Element {
    _remove(at: index).removed
  }

  /// Remove the element at the specified index, and update `index` to address the subsequent
  /// element in the new collection. (Or the `endIndex` if it originally addressed the last item.)
  @inlinable
  @discardableResult
  public mutating func remove(at index: inout Index) -> Element {
    let (old, path) = _remove(at: index)
    index = unsafe Index(version: _version, path: path, leaf: _unmanagedLeaf(at: path))
    return old
  }

  @inlinable
  @discardableResult
  internal mutating func _remove(at index: Index) -> (removed: Element, path: _Path) {
    validate(index)
    var path = index._path
    let r = root.remove(at: &path)
    if root.isEmpty {
      _root = nil
      assert(r.pathIsAtEnd)
    } else if root.childCount == 1, root.height > 0 {
      root = unsafe root.readInner { unsafe $0.children.first! }
      path.popRoot()
    }
    _invalidateIndices()
    return (r.removed.value, r.pathIsAtEnd ? _endPath : path)
  }
}

extension Rope._Node {
  @inlinable
  internal mutating func remove(
    at path: inout _Path
  ) -> (removed: _Item, delta: Summary, needsFixing: Bool, pathIsAtEnd: Bool) {
    ensureUnique()
    let h = height
    let slot = path[h]
    precondition(slot < childCount, "Invalid index")
    guard h > 0 else {
      let r = _removeItem(at: slot)
      return (r.removed, r.delta, self.isUndersized, slot == childCount)
    }
    let r = unsafe updateInner { unsafe $0.mutableChildren[slot].remove(at: &path) }
    self.summary.subtract(r.delta)
    var isAtEnd = r.pathIsAtEnd
    if r.needsFixing {
      let prepended = fixDeficiency(on: &path)
      isAtEnd = isAtEnd && prepended
    }
    if isAtEnd, path[h] < childCount - 1 {
      path[h] += 1
      path.clear(below: h)
      isAtEnd = false
    }
    return (r.removed, r.delta, self.isUndersized, isAtEnd)
  }
}

extension Rope {
  @inlinable
  @discardableResult
  public mutating func remove(
    at position: Int,
    in metric: some RopeMetric<Element>
  ) -> (removed: Element, next: Index) {
    _invalidateIndices()
    var path = _Path(height: self._height)
    let r = root.remove(at: position, in: metric, initializing: &path)
    if root.isEmpty {
      _root = nil
    } else if root.childCount == 1, root.height > 0 {
      root = unsafe root.readInner { unsafe $0.children.first! }
    }
    if r.pathIsAtEnd {
      return (r.removed.value, endIndex)
    }
    let i = Index(version: _version, path: path)
    return (r.removed.value, i)
  }
}

extension Rope._Node {
  /// Note: `self` may be left undersized after calling this function, which
  /// is expected to be resolved by the caller. This is indicated by the `needsFixing` component
  /// in the return value.
  ///
  /// - Returns: A tuple `(removed, delta, needsFixing, pathIsAtEnd)`, where
  ///     `removed` is the element that got removed,
  ///     `delta` is its summary,
  ///     `needsFixing` indicates whether the node was left undersized, and
  ///     `pathIsAtEnd` indicates if `path` now addresses the end of the node's subtree.
  @inlinable
  internal mutating func remove(
    at position: Int,
    in metric: some RopeMetric<Element>,
    initializing path: inout _Path
  ) -> (removed: _Item, delta: Summary, needsFixing: Bool, pathIsAtEnd: Bool) {
    ensureUnique()
    let h = height
    guard h > 0 else {
      let (slot, remaining) = unsafe readLeaf {
        unsafe $0.findSlot(at: position, in: metric, preferEnd: false)
      }
      precondition(remaining == 0, "Element to be removed doesn't fall on an element boundary")
      path[h] = slot
      let r = _removeItem(at: slot)
      return (r.removed, r.delta, self.isUndersized, slot == childCount)
    }
    let r = unsafe updateInner {
      let (slot, remaining) = unsafe $0.findSlot(at: position, in: metric, preferEnd: false)
      path[h] = slot
      return unsafe $0.mutableChildren[slot].remove(at: remaining, in: metric, initializing: &path)
    }
    self.summary.subtract(r.delta)
    var isAtEnd = r.pathIsAtEnd
    if r.needsFixing {
      let prepended = fixDeficiency(on: &path)
      isAtEnd = isAtEnd && prepended
    }
    if isAtEnd, path[h] < childCount - 1 {
      path[h] += 1
      path.clear(below: h)
      isAtEnd = false
    }
    return (r.removed, r.delta, self.isUndersized, isAtEnd)
  }
}

extension Rope._Node {
  /// Returns: `true` if new items got prepended to the child addressed by `path`.
  ///   `false` if new items got appended.
  @inlinable
  @discardableResult
  internal mutating func fixDeficiency(on path: inout _Path) -> Bool {
    assert(isUnique())
    return unsafe updateInner {
      let c = unsafe $0.mutableChildren
      let h = unsafe $0.height
      let slot = path[h]
      assert(unsafe c[slot].isUndersized)
      guard c.count > 1 else { return true }
      let prev = slot - 1
      let prevSum: Int
      if prev >= 0 {
        let prevCount = unsafe c[prev].childCount
        prevSum = unsafe prevCount + c[slot].childCount
        if prevSum <= Summary.maxNodeSize {
          unsafe Self.redistributeChildren(&c[prev], &c[slot], to: prevSum)
          assert(unsafe c[slot].isEmpty)
          _ = unsafe $0._removeChild(at: slot)
          path[h] = prev
          path[h - 1] += prevCount
          return true
        }
      } else {
        prevSum = 0
      }

      let next = slot + 1
      let nextSum: Int
      if next < c.count {
        let nextCount = unsafe c[next].childCount
        nextSum = unsafe c[slot].childCount + nextCount
        if nextSum <= Summary.maxNodeSize {
          unsafe Self.redistributeChildren(&c[slot], &c[next], to: nextSum)
          assert(unsafe c[next].isEmpty)
          _ = unsafe $0._removeChild(at: next)
          // `path` doesn't need updating.
          return false
        }
      } else {
        nextSum = 0
      }

      if prev >= 0 {
        assert(unsafe c[prev].childCount > Summary.minNodeSize)
        let origCount = unsafe c[slot].childCount
        unsafe Self.redistributeChildren(&c[prev], &c[slot], to: prevSum / 2)
        path[h - 1] += unsafe c[slot].childCount - origCount
        assert(unsafe !c[prev].isUndersized)
        assert(unsafe !c[slot].isUndersized)
        return true
      }
      assert(next < c.count)
      assert(unsafe c[next].childCount > Summary.minNodeSize)
      unsafe Self.redistributeChildren(&c[slot], &c[next], to: nextSum / 2)
      // `path` doesn't need updating.
      assert(unsafe !c[slot].isUndersized)
      assert(unsafe !c[next].isUndersized)
      return false
    }
  }
}
