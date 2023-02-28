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
  func find(
    at position: Int,
    in metric: some _RopeMetric<Element>,
    preferEnd: Bool
  ) -> (index: Index, remaining: Int) {
    let wholeSize = _root == nil ? 0 : metric.size(of: root.summary)
    precondition(position >= 0 && position <= wholeSize, "Position out of bounds")
    guard !isEmpty, preferEnd || position < wholeSize else {
      return (endIndex, position)
    }
    var position = position
    var node = root
    var path = Path(height: node.height)
    while node.height > 0 {
      node = node.readInner {
        let r = $0.findSlot(at: position, in: metric, preferEnd: preferEnd)
        position = r.remaining
        path[$0.height] = r.slot
        return $0.children[r.slot]
      }
    }
    let r = node.readLeaf { $0.findSlot(at: position, in: metric, preferEnd: preferEnd) }
    path[0] = r.slot
    let index = Index(version: _version, path: path, leaf: node.asUnmanagedLeaf)
    return (index, r.remaining)
  }
}

extension _Rope.UnsafeHandle {
  func findSlot(
    at position: Int,
    in metric: some _RopeMetric<Element>,
    preferEnd: Bool = true
  ) -> (slot: Int, remaining: Int) {
    var remaining = position
    var size = 0
    for slot in 0 ..< childCount {
      size = metric.size(of: children[slot].summary)
      let next = remaining - size
      let adjustment = (preferEnd ? 0 : 1)
      if next + adjustment <= 0 {
        return (slot, remaining)
      }
      remaining = next
    }
    precondition(remaining == 0, "Position out of bounds")
    return preferEnd ? (childCount - 1, remaining + size) : (childCount, 0)
  }

  func findSlot(
    from p: (slot: Int, remaining: Int),
    offsetBy distance: Int,
    in metric: some _RopeMetric<Element>,
    preferEnd: Bool = true
  ) -> (slot: Int, remaining: Int) {
    assert(p.slot >= 0 && p.slot < childCount)
    assert(p.remaining >= 0 && p.remaining <= metric.size(of: children[p.slot].summary))
    assert(distance >= 0)
    let adjustment = (preferEnd ? 0 : 1)
    var d = p.remaining + distance
    var slot = p.slot
    while slot < childCount {
      let size = metric.size(of: children[slot].summary)
      if d + adjustment <= size { break }
      d -= size
      slot += 1
    }
    assert(slot < childCount || d == 0)
    return (slot, d)
  }
}
