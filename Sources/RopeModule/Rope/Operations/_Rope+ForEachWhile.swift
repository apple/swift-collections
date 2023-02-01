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
  func forEachWhile(
    _ body: (Element) -> Bool
  ) -> Bool {
    guard _root != nil else { return true }
    return root.forEachWhile(body)
  }

  func forEachWhile(
    from position: Int,
    in metric: some _RopeMetric<Element>,
    _ body: (Element, Element.Index?) -> Bool
  ) -> Bool {
    guard _root != nil else {
      precondition(position == 0, "Position out of bounds")
      return true
    }
    return root.forEachWhile(from: position, in: metric, body)
  }
}

extension _Rope.Node {
  func forEachWhile(
    _ body: (Element) -> Bool
  ) -> Bool {
    if isLeaf {
      return readLeaf {
        let c = $0.children
        for i in 0 ..< c.count {
          guard body(c[i].value) else { return false }
        }
        return true
      }
    }
    return readInner {
      let c = $0.children
      for i in 0 ..< c.count {
        guard c[i].forEachWhile(body) else { return false }
      }
      return true
    }
  }

  func forEachWhile(
    from position: Int,
    in metric: some _RopeMetric<Element>,
    _ body: (Element, Element.Index?) -> Bool
  ) -> Bool {
    if isLeaf {
      return readLeaf {
        let c = $0.children
        var (slot, rem) = $0.findSlot(at: position, in: metric, preferEnd: false)
        let i = metric.index(at: rem, in: c[slot].value)
        if !body(c[slot].value, i) { return false }
        slot += 1
        while slot < c.count {
          if !body(c[slot].value, nil) { return false }
          slot += 1
        }
        return true
      }
    }
    return readInner {
      let c = $0.children
      var (slot, rem) = $0.findSlot(at: position, in: metric, preferEnd: false)
      if !c[slot].forEachWhile(from: rem, in: metric, body) { return false }
      slot += 1
      while slot < c.count {
        if !c[slot].forEachWhile({ body($0, nil) }) { return false }
        slot += 1
      }
      return true
    }
  }
}
