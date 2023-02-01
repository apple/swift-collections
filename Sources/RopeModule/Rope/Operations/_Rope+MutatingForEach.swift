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
  @inline(__always)
  @discardableResult
  mutating func mutatingForEach<R>(
    _ body: (inout Element) -> R?
  ) -> R? {
    var i = startIndex
    return mutatingForEach(from: &i, body)
  }
  
  @inline(__always)
  @discardableResult
  mutating func mutatingForEach<R>(
    from index: inout Index,
    _ body: (inout Element) -> R?
  ) -> R? {
    var r: R? = nil
    let completed = _mutatingForEach(from: &index) {
      r = body(&$0)
      return r == nil
    }
    assert(completed == (r == nil))
    return r
  }
  
  mutating func _mutatingForEach(
    from index: inout Index,
    _ body: (inout Element) -> Bool
  ) -> Bool {
    guard _root != nil else { return true }
    return root.mutatingForEach(from: &index, body: body).continue
  }
}

extension _Rope.Node {
  mutating func mutatingForEach(
    from index: inout Index,
    body: (inout Element) -> Bool
  ) -> (continue: Bool, delta: Summary) {
    ensureUnique()
    let h = height
    var slot = index[height: h]
    precondition(slot <= childCount, "Index out of bounds")
    guard slot < childCount else { return (true, .zero) }
    var delta = Summary.zero
    defer { self.summary.add(delta) }
    if h > 0 {
      let r = updateInner {
        let c = $0.mutableChildren
        while slot < c.count {
          let (r, d) = c[slot].mutatingForEach(from: &index, body: body)
          delta.add(d)
          guard r else { return false }
          slot += 1
          index.clear(below: h)
          index[height: h] = slot
        }
        return true
      }
      return (r, delta)
    }
    let r = updateLeaf {
      let c = $0.mutableChildren
      while slot < c.count {
        let sum = c[slot].summary
        let r = body(&c[slot].value)
        delta.add(c[slot].summary.subtracting(sum))
        guard r else { return false }
        slot += 1
        index[height: h] = slot
      }
      return true
    }
    return (r, delta)
  }
}
