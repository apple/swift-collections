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
  func isValid(_ index: Index) -> Bool {
    index._version == _version
  }

  func validate(_ index: Index) {
    precondition(isValid(index), "Invalid index")
  }

  mutating func invalidateIndices() {
    _version.bump()
  }

  func ensureLeaf(in index: inout Index) {
    validate(index)
    guard index._leaf == nil else { return }
    index._leaf = _unmanagedLeaf(at: index._path)
  }
}

extension _Rope: BidirectionalCollection {
  var height: UInt8 {
    _root?.height ?? 0
  }

  var isEmpty: Bool {
    guard _root != nil else { return true }
    return root.childCount == 0
  }

  var startPath: Path {
    Path(height: height)
  }

  var endPath: Path {
    guard let root = _root else { return startPath }
    var path = Path(height: height)
    path[height] = root.childCount
    return path
  }

  var startIndex: Index {
    // Note: `leaf` is intentionally not set here, to speed up accessing this property.
    return Index(version: _version, path: startPath, leaf: nil)
  }

  var endIndex: Index {
    Index(version: _version, path: endPath, leaf: nil)
  }
  
  func index(after i: Index) -> Index {
    var i = i
    formIndex(after: &i)
    return i
  }
  
  func index(before i: Index) -> Index {
    var i = i
    formIndex(before: &i)
    return i
  }
  
  func formIndex(after i: inout Index) {
    validate(i)
    precondition(i < endIndex, "Can't move after endIndex")
    if let leaf = i._leaf {
      let done = leaf.read {
        let slot = i._path[$0.height] &+ 1
        guard slot < $0.childCount else { return false }
        i._path[$0.height] = slot
        return true
      }
      if done { return }
    }
    if !root.formSuccessor(of: &i) {
      i = endIndex
    }
  }
  
  func formIndex(before i: inout Index) {
    validate(i)
    precondition(i > startIndex, "Can't move before startIndex")
    if let leaf = i._leaf {
      let done = leaf.read {
        let slot = i._path[$0.height]
        guard slot > 0 else { return false }
        i._path[$0.height] = slot &- 1
        return true
      }
      if done { return }
    }
    let success = root.formPredecessor(of: &i)
    precondition(success, "Invalid index")
  }
  
  subscript(i: Index) -> Element {
    get {
      validate(i)
      if let ref = i._leaf {
        return ref.read {
          $0.children[i._path[$0.height]].value
        }
      }
      return root[i._path].value
    }
    @inline(__always) _modify {
      validate(i)
      // Note: we must not use _leaf -- it may not be on a unique path.
      defer { invalidateIndices() }
      yield &root[i._path].value
    }
  }
}

extension _Rope {
  /// Update the element at the given index, while keeping the index valid.
  mutating func update<R>(
    at index: inout Index,
    by body: (inout Element) -> R
  ) -> R {
    validate(index)
    var state = root._prepareModify(at: index._path)
    defer {
      index._leaf = root._finalizeModify(&state).leaf
    }
    return body(&state.item.value)
  }
}

extension _Rope {
  static var maxHeight: Int {
    Path._pathBitWidth / Summary.nodeSizeBitWidth
  }

  /// The estimated maximum number of items that can fit in this rope in the worst possible case,
  /// i.e., when the tree consists of minimum-sized nodes. (The data structure itself has no
  /// inherent limit, but this implementation of it is limited by the fixed 56-bit path
  /// representation used in the `Index` type.)
  ///
  /// This is one less than the minimum possible size for a rope whose size exceeds the maximum.
  static var minimumCapacity: Int {
    var c = 2
    for _ in 0 ..< maxHeight {
      let (r, overflow) = c.multipliedReportingOverflow(by: Summary.minNodeSize)
      if overflow { return .max }
      c = r
    }
    return c - 1
  }

  /// The maximum number of items that can fit in this rope in the best possible case, i.e., when
  /// the tree consists of maximum-sized nodes. (The data structure itself has no inherent limit,
  /// but this implementation of it is limited by the fixed 56-bit path representation used in
  /// the `Index` type.)
  static var maximumCapacity: Int {
    var c = 1
    for _ in 0 ... maxHeight {
      let (r, overflow) = c.multipliedReportingOverflow(by: Summary.maxNodeSize)
      if overflow { return .max }
      c = r
    }
    return c
  }
}

extension _Rope {
  func count(in metric: some _RopeMetric<Element>) -> Int {
    guard _root != nil else { return 0 }
    return root.count(in: metric)
  }
}

extension _Rope.Node {
  func count(in metric: some _RopeMetric<Element>) -> Int {
    metric.nonnegativeSize(of: self.summary)
  }
}

extension _Rope {
  func distance(from start: Index, to end: Index, in metric: some _RopeMetric<Element>) -> Int {
    validate(start)
    validate(end)
    if start == end { return 0 }
    precondition(_root != nil, "Invalid index")
    if start._leaf == end._leaf, let leaf = start._leaf {
      // Fast path: both indices are pointing within the same leaf.
      return leaf.read {
        let h = $0.height
        let a = start._path[h]
        let b = end._path[h]
        return $0.distance(from: a, to: b, in: metric)
      }
    }
    if start < end {
      return root.distance(from: start, to: end, in: metric)
    }
    return -root.distance(from: end, to: start, in: metric)
  }

  func offset(of index: Index, in metric: some _RopeMetric<Element>) -> Int {
    validate(index)
    if _root == nil { return 0 }
    return root.distanceFromStart(to: index, in: metric)
  }
}

extension _Rope.Node {
  func distanceFromStart(to index: Index, in metric: some _RopeMetric<Element>) -> Int {
    let slot = index._path[height]
    precondition(slot <= childCount, "Invalid index")
    if slot == childCount {
      precondition(index.isEmpty(below: height), "Invalid index")
      return metric.nonnegativeSize(of: self.summary)
    }
    if height == 0 {
      return readLeaf { $0.distance(from: 0, to: slot, in: metric) }
    }
    return readInner {
      var distance = $0.distance(from: 0, to: slot, in: metric)
      distance += $0.children[slot].distanceFromStart(to: index, in: metric)
      return distance
    }
  }
  
  func distanceToEnd(from index: Index, in metric: some _RopeMetric<Element>) -> Int {
    let d = metric.nonnegativeSize(of: self.summary) - self.distanceFromStart(to: index, in: metric)
    assert(d >= 0)
    return d
  }
  
  func distance(from start: Index, to end: Index, in metric: some _RopeMetric<Element>) -> Int {
    assert(start < end)
    let a = start._path[height]
    let b = end._path[height]
    precondition(a < childCount, "Invalid index")
    precondition(b <= childCount, "Invalid index")
    assert(a <= b)
    if b == childCount {
      precondition(end.isEmpty(below: height), "Invalid index")
      return distanceToEnd(from: start, in: metric)
    }
    if height == 0 {
      assert(a < b)
      return readLeaf { $0.distance(from: a, to: b, in: metric) }
    }
    return readInner {
      let c = $0.children
      if a == b {
        return c[a].distance(from: start, to: end, in: metric)
      }
      var d = c[a].distanceToEnd(from: start, in: metric)
      d += $0.distance(from: a + 1, to: b, in: metric)
      d += c[b].distanceFromStart(to: end, in: metric)
      return d
    }
  }
}

extension _Rope {
  func formIndex(
    _ i: inout Index,
    offsetBy distance: inout Int,
    in metric: some _RopeMetric<Element>,
    preferEnd: Bool
  ) {
    validate(i)
    if _root == nil {
      precondition(distance == 0, "Position out of bounds")
      return
    }
    if distance <= 0 {
      distance = -distance
      let success = root.seekBackward(
        from: &i, by: &distance, in: metric, preferEnd: preferEnd)
      precondition(success, "Position out of bounds")
      return
    }
    if let leaf = i._leaf {
      // Fast path: move within a single leaf
      let r = leaf.read {
        $0._seekForwardInLeaf(from: &i._path, by: &distance, in: metric, preferEnd: preferEnd)
      }
      if r { return }
    }
    if root.seekForward(from: &i, by: &distance, in: metric, preferEnd: preferEnd) {
      return
    }
    precondition(distance == 0, "Position out of bounds")
    i = endIndex
  }
  
  func index(
    _ i: Index,
    offsetBy distance: Int,
    in metric: some _RopeMetric<Element>,
    preferEnd: Bool
  ) -> (index: Index, remainder: Int) {
    var i = i
    var distance = distance
    formIndex(&i, offsetBy: &distance, in: metric, preferEnd: preferEnd)
    return (i, distance)
  }
}

extension _Rope.UnsafeHandle {
  func _seekForwardInLeaf(
    from path: inout _Rope.Path,
    by distance: inout Int,
    in metric: some _RopeMetric<Element>,
    preferEnd: Bool
  ) -> Bool {
    assert(distance >= 0)
    assert(height == 0)
    let c = children
    var slot = path[0]
    defer { path[0] = slot }
    while slot < c.count {
      let d = metric.nonnegativeSize(of: c[slot].summary)
      if preferEnd ? d >= distance : d > distance {
        return true
      }
      distance &-= d
      slot &+= 1
    }
    return false
  }

  func _seekBackwardInLeaf(
    from path: inout _Rope.Path,
    by distance: inout Int,
    in metric: some _RopeMetric<Element>,
    preferEnd: Bool
  ) -> Bool {
    assert(distance >= 0)
    assert(height == 0)
    let c = children
    var slot = path[0] &- 1
    while slot >= 0 {
      let d = metric.nonnegativeSize(of: c[slot].summary)
      if preferEnd ? d > distance : d >= distance {
        path[0] = slot
        distance = d &- distance
        return true
      }
      distance &-= d
      slot &-= 1
    }
    return false
  }
}

extension _Rope.Node {
  func seekForward(
    from i: inout Index,
    by distance: inout Int,
    in metric: some _RopeMetric<Element>,
    preferEnd: Bool
  ) -> Bool {
    assert(distance >= 0)

    if height == 0 {
      let r = readLeaf {
        $0._seekForwardInLeaf(from: &i._path, by: &distance, in: metric, preferEnd: preferEnd)
      }
      if r {
        i._leaf = asUnmanagedLeaf
      }
      return r
    }
    
    return readInner {
      var slot = i._path[height]
      precondition(slot < childCount, "Invalid index")
      let c = $0.children
      if c[slot].seekForward(from: &i, by: &distance, in: metric, preferEnd: preferEnd) {
        return true
      }
      slot &+= 1
      while slot < c.count {
        let d = metric.size(of: c[slot].summary)
        if preferEnd ? d >= distance : d > distance {
          i._path[$0.height] = slot
          i.clear(below: $0.height)
          let success = c[slot].seekForward(
            from: &i, by: &distance, in: metric, preferEnd: preferEnd)
          precondition(success)
          return true
        }
        distance &-= d
        slot &+= 1
      }
      return false
    }
  }
  
  func seekBackward(
    from i: inout Index,
    by distance: inout Int,
    in metric: some _RopeMetric<Element>,
    preferEnd: Bool
  ) -> Bool {
    assert(distance >= 0)
    guard distance > 0 || preferEnd else { return true }
    if height == 0 {
      return readLeaf {
        $0._seekBackwardInLeaf(from: &i._path, by: &distance, in: metric, preferEnd: preferEnd)
      }
    }
    
    return readInner {
      var slot = i._path[height]
      precondition(slot <= childCount, "Invalid index")
      let c = $0.children
      if slot < childCount,
         c[slot].seekBackward(from: &i, by: &distance, in: metric, preferEnd: preferEnd) {
        return true
      }
      slot -= 1
      while slot >= 0 {
        let d = metric.size(of: c[slot].summary)
        if preferEnd ? d > distance : d >= distance {
          i._path[$0.height] = slot
          i.clear(below: $0.height)
          distance = d - distance
          let success = c[slot].seekForward(
            from: &i, by: &distance, in: metric, preferEnd: preferEnd)
          precondition(success)
          return true
        }
        distance -= d
        slot -= 1
      }
      return false
    }
  }
}
