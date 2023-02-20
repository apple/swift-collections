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

extension _Rope {
  mutating func remove(at index: Index) -> Element {
    validate(index)
    let old = root.remove(at: index._path).removed
    if root.isEmpty {
      _root = nil
    } else if root.childCount == 1, root.height > 0 {
      root = root.readInner { $0.children.first! }
    }
    invalidateIndices()
    return old.value
  }
}

extension _Rope.Node {
  mutating func remove(
    at path: Path
  ) -> (removed: Item, delta: Summary, needsFixing: Bool) {
    ensureUnique()
    let slot = path[height]
    precondition(slot < childCount, "Invalid index")
    guard height > 0 else {
      let r = _removeItem(at: slot)
      return (r.removed, r.delta, self.isUndersized)
    }
    let r = updateInner { $0.mutableChildren[slot].remove(at: path) }
    self.summary.subtract(r.delta)
    if r.needsFixing {
      fixDeficiency(at: slot)
    }
    return (r.removed, r.delta, self.isUndersized)
  }
}

extension _Rope {
  mutating func remove(
    at position: Int,
    in metric: some _RopeMetric<Element>
  ) -> Element {
    invalidateIndices()
    let old = root.remove(at: position, in: metric).removed
    if root.isEmpty {
      _root = nil
    } else if root.childCount == 1, root.height > 0 {
      root = root.readInner { $0.children.first! }
    }
    return old.value
  }
}

extension _Rope.Node {
  mutating func remove(
    at position: Int,
    in metric: some _RopeMetric<Element>
  ) -> (removed: Item, delta: Summary, needsFixing: Bool) {
    ensureUnique()
    guard height > 0 else {
      let (slot, remaining) = readLeaf {
        $0.findSlot(at: position, in: metric, preferEnd: false)
      }
      precondition(remaining == 0, "Element to be removed doesn't fall on an element boundary")
      let r = _removeItem(at: slot)
      return (r.removed, r.delta, self.isUndersized)
    }
    let (slot, r) = updateInner {
      let (slot, remaining) = $0.findSlot(at: position, in: metric, preferEnd: false)
      return (slot, $0.mutableChildren[slot].remove(at: remaining, in: metric))
    }
    self.summary.subtract(r.delta)
    if r.needsFixing {
      fixDeficiency(at: slot)
    }
    return (r.removed, r.delta, self.isUndersized)
  }
}

extension _Rope.Node {
  mutating func fixDeficiency(at slot: Int) {
    assert(isUnique())
    updateInner {
      let c = $0.mutableChildren
      assert(c[slot].isUndersized)
      guard c.count > 1 else { return }
      let prev = slot - 1
      let prevSum = prev >= 0 ? c[prev].childCount + c[slot].childCount : 0
      if prev >= 0, prevSum <= Summary.maxNodeSize {
        Self.redistributeChildren(&c[prev], &c[slot], to: prevSum)
        assert(c[slot].isEmpty)
        _ = $0._removeChild(at: slot)
        return
      }
      
      let next = slot + 1
      let nextSum = next < c.count ? c[slot].childCount + c[next].childCount : 0
      if next < c.count, nextSum <= Summary.maxNodeSize {
        Self.redistributeChildren(&c[slot], &c[next], to: nextSum)
        assert(c[next].isEmpty)
        _ = $0._removeChild(at: next)
        return
      }
      if prev >= 0 {
        assert(c[prev].childCount > Summary.minNodeSize)
        Self.redistributeChildren(&c[prev], &c[slot], to: prevSum / 2)
        assert(!c[prev].isUndersized)
        assert(!c[slot].isUndersized)
        return
      }
      assert(next < c.count)
      assert(c[next].childCount > Summary.minNodeSize)
      Self.redistributeChildren(&c[slot], &c[next], to: nextSum / 2)
      assert(!c[slot].isUndersized)
      assert(!c[next].isUndersized)
    }
  }
}
