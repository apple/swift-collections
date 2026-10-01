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
  public func isValid(_ index: Index) -> Bool {
    index._version == _version
  }

  @inlinable
  public func validate(_ index: Index) {
    precondition(isValid(index), "Invalid index")
  }

  @inlinable
  internal mutating func _invalidateIndices() {
    _version.bump()
  }

  /// Validate `index` and fill out all cached information in it,
  /// to speed up subsequent lookups.
  @inlinable
  public func grease(_ index: inout Index) {
    validate(index)
    guard unsafe index._leaf == nil else { return }
    unsafe index._leaf = _unmanagedLeaf(at: index._path)
  }
}

extension Rope {
  @inlinable
  public var _height: UInt8 {
    _root?.height ?? 0
  }

  @inlinable
  internal var _startPath: _Path {
    _Path(height: _height)
  }

  @inlinable
  internal var _endPath: _Path {
    guard let root = _root else { return _startPath }
    var path = _Path(height: _height)
    path[_height] = root.childCount
    return path
  }
}

extension Rope: BidirectionalCollection {
  public typealias SubSequence = Slice<Self>

  @inlinable
  public var isEmpty: Bool {
    guard _root != nil else { return true }
    return root.childCount == 0
  }

  @inlinable
  public var startIndex: Index {
    // Note: `leaf` is intentionally not set here, to speed up accessing this property.
    return Index(version: _version, path: _startPath)
  }

  @inlinable
  public var endIndex: Index {
    Index(version: _version, path: _endPath)
  }

  @inlinable
  public func index(after i: Index) -> Index {
    var i = i
    formIndex(after: &i)
    return i
  }

  @inlinable
  public func index(before i: Index) -> Index {
    var i = i
    formIndex(before: &i)
    return i
  }

  @inlinable
  public func formIndex(after i: inout Index) {
    validate(i)
    precondition(i < endIndex, "Cannot advance above endIndex")
    if let leaf = unsafe i._leaf {
      let done = unsafe leaf.read {
        let slot = unsafe i._path[$0.height] &+ 1
        guard unsafe slot < $0.childCount else { return false }
        unsafe i._path[$0.height] = slot
        return true
      }
      if done { return }
    }
    if !root.formSuccessor(of: &i) {
      i = endIndex
    }
  }

  @inlinable
  public func formIndex(before i: inout Index) {
    validate(i)
    precondition(i > startIndex, "Cannot advance below startIndex")
    if let leaf = unsafe i._leaf {
      let done = unsafe leaf.read {
        let slot = unsafe i._path[$0.height]
        guard slot > 0 else { return false }
        unsafe i._path[$0.height] = slot &- 1
        return true
      }
      if done { return }
    }
    let success = root.formPredecessor(of: &i)
    precondition(success, "Invalid index")
  }

  @inlinable
  public subscript(i: Index) -> Element {
    get {
      validate(i)
      if let ref = unsafe i._leaf {
        return unsafe ref.read {
          unsafe $0.children[i._path[$0.height]].value
        }
      }
      return root[i._path].value
    }
    @inline(__always) _modify {
      validate(i)
      // Note: we must not use _leaf -- it may not be on a unique path.
      defer { _invalidateIndices() }
      yield &root[i._path].value
    }
  }
}

extension Rope {
  /// Update the element at the given index, while keeping the index valid.
  @inlinable
  public mutating func update<R>(
    at index: inout Index,
    by body: (inout Element) -> R
  ) -> R {
    validate(index)
    var state = unsafe root._prepareModify(at: index._path)
    defer {
      _invalidateIndices()
      index._version = self._version
      unsafe index._leaf = root._finalizeModify(&state).leaf
    }
    return body(&state.item.value)
  }
}

extension Rope {
  @inlinable @inline(__always)
  public static var _maxHeight: Int {
    _Path._pathBitWidth / Summary.nodeSizeBitWidth
  }

  /// The estimated maximum number of items that can fit in this rope in the worst possible case,
  /// i.e., when the tree consists of minimum-sized nodes. (The data structure itself has no
  /// inherent limit, but this implementation of it is limited by the fixed 56-bit path
  /// representation used in the `Index` type.)
  ///
  /// This is one less than the minimum possible size for a rope whose size exceeds the maximum.
  @inlinable
  public static var _minimumCapacity: Int {
    var c = 2
    for _ in 0 ..< _maxHeight {
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
  @inlinable
  public static var _maximumCapacity: Int {
    var c = 1
    for _ in 0 ... _maxHeight {
      let (r, overflow) = c.multipliedReportingOverflow(by: Summary.maxNodeSize)
      if overflow { return .max }
      c = r
    }
    return c
  }
}

extension Rope {
  @inlinable
  public func count(in metric: some RopeMetric<Element>) -> Int {
    guard _root != nil else { return 0 }
    return root.count(in: metric)
  }
}

extension Rope._Node {
  @inlinable
  public func count(in metric: some RopeMetric<Element>) -> Int {
    metric._nonnegativeSize(of: self.summary)
  }
}

extension Rope {
  @inlinable
  public func distance(from start: Index, to end: Index, in metric: some RopeMetric<Element>) -> Int {
    validate(start)
    validate(end)
    if start == end { return 0 }
    precondition(_root != nil, "Invalid index")
    if unsafe start._leaf == end._leaf, let leaf = unsafe start._leaf {
      // Fast path: both indices are pointing within the same leaf.
      return unsafe leaf.read {
        let h = unsafe $0.height
        let a = start._path[h]
        let b = end._path[h]
        return unsafe $0.distance(from: a, to: b, in: metric)
      }
    }
    if start < end {
      return root.distance(from: start, to: end, in: metric)
    }
    return -root.distance(from: end, to: start, in: metric)
  }

  @inlinable
  public func offset(of index: Index, in metric: some RopeMetric<Element>) -> Int {
    validate(index)
    if _root == nil { return 0 }
    return root.distanceFromStart(to: index, in: metric)
  }
}

extension Rope._Node {
  @inlinable
  internal func distanceFromStart(
    to index: Index, in metric: some RopeMetric<Element>
  ) -> Int {
    let slot = index._path[height]
    precondition(slot <= childCount, "Invalid index")
    if slot == childCount {
      precondition(index._isEmpty(below: height), "Invalid index")
      return metric._nonnegativeSize(of: self.summary)
    }
    if height == 0 {
      return unsafe readLeaf { unsafe $0.distance(from: 0, to: slot, in: metric) }
    }
    return unsafe readInner {
      var distance = unsafe $0.distance(from: 0, to: slot, in: metric)
      distance += unsafe $0.children[slot].distanceFromStart(to: index, in: metric)
      return distance
    }
  }

  @inlinable
  internal func distanceToEnd(
    from index: Index, in metric: some RopeMetric<Element>
  ) -> Int {
    let d = metric._nonnegativeSize(of: self.summary) - self.distanceFromStart(to: index, in: metric)
    assert(d >= 0)
    return d
  }

  @inlinable
  internal func distance(
    from start: Index, to end: Index, in metric: some RopeMetric<Element>
  ) -> Int {
    assert(start < end)
    let a = start._path[height]
    let b = end._path[height]
    precondition(a < childCount, "Invalid index")
    precondition(b <= childCount, "Invalid index")
    assert(a <= b)
    if b == childCount {
      precondition(end._isEmpty(below: height), "Invalid index")
      return distanceToEnd(from: start, in: metric)
    }
    if height == 0 {
      assert(a < b)
      return unsafe readLeaf { unsafe $0.distance(from: a, to: b, in: metric) }
    }
    return unsafe readInner {
      let c = unsafe $0.children
      if a == b {
        return unsafe c[a].distance(from: start, to: end, in: metric)
      }
      var d = unsafe c[a].distanceToEnd(from: start, in: metric)
      d += unsafe $0.distance(from: a + 1, to: b, in: metric)
      d += unsafe c[b].distanceFromStart(to: end, in: metric)
      return d
    }
  }
}

extension Rope {
  @inlinable
  public func formIndex(
    _ i: inout Index,
    offsetBy distance: inout Int,
    in metric: some RopeMetric<Element>,
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
    if let leaf = unsafe i._leaf {
      // Fast path: move within a single leaf
      let r = unsafe leaf.read {
        unsafe $0._seekForwardInLeaf(from: &i._path, by: &distance, in: metric, preferEnd: preferEnd)
      }
      if r { return }
    }
    if root.seekForward(from: &i, by: &distance, in: metric, preferEnd: preferEnd) {
      return
    }
    precondition(distance == 0, "Position out of bounds")
    i = endIndex
  }

  @inlinable
  public func index(
    _ i: Index,
    offsetBy distance: Int,
    in metric: some RopeMetric<Element>,
    preferEnd: Bool
  ) -> (index: Index, remaining: Int) {
    var i = i
    var distance = distance
    formIndex(&i, offsetBy: &distance, in: metric, preferEnd: preferEnd)
    return (i, distance)
  }
}

extension Rope._UnsafeHandle {
  @inlinable
  func _seekForwardInLeaf(
    from path: inout Rope._Path,
    by distance: inout Int,
    in metric: some RopeMetric<Element>,
    preferEnd: Bool
  ) -> Bool {
    assert(distance >= 0)
    assert(unsafe height == 0)
    let c = unsafe children
    var slot = path[0]
    defer { path[0] = slot }
    while slot < c.count {
      let d = metric._nonnegativeSize(of: unsafe c[slot].summary)
      if preferEnd ? d >= distance : d > distance {
        return true
      }
      distance &-= d
      slot &+= 1
    }
    return false
  }

  @inlinable
  func _seekBackwardInLeaf(
    from path: inout Rope._Path,
    by distance: inout Int,
    in metric: some RopeMetric<Element>,
    preferEnd: Bool
  ) -> Bool {
    assert(distance >= 0)
    assert(unsafe height == 0)
    let c = unsafe children
    var slot = path[0] &- 1
    while slot >= 0 {
      let d = metric._nonnegativeSize(of: unsafe c[slot].summary)
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

extension Rope._Node {
  @inlinable
  func seekForward(
    from i: inout Index,
    by distance: inout Int,
    in metric: some RopeMetric<Element>,
    preferEnd: Bool
  ) -> Bool {
    assert(distance >= 0)

    if height == 0 {
      let r = unsafe readLeaf {
        unsafe $0._seekForwardInLeaf(
          from: &i._path, by: &distance, in: metric, preferEnd: preferEnd)
      }
      if r {
        unsafe i._leaf = asUnmanagedLeaf
      }
      return r
    }
    
    return unsafe readInner {
      var slot = i._path[height]
      precondition(slot < childCount, "Invalid index")
      let c = unsafe $0.children
      if unsafe c[slot].seekForward(from: &i, by: &distance, in: metric, preferEnd: preferEnd) {
        return true
      }
      slot &+= 1
      while slot < c.count {
        let d = metric.size(of: unsafe c[slot].summary)
        if preferEnd ? d >= distance : d > distance {
          unsafe i._path[$0.height] = slot
          unsafe i._clear(below: $0.height)
          let success = unsafe c[slot].seekForward(
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

  @inlinable
  func seekBackward(
    from i: inout Index,
    by distance: inout Int,
    in metric: some RopeMetric<Element>,
    preferEnd: Bool
  ) -> Bool {
    assert(distance >= 0)
    guard distance > 0 || preferEnd else { return true }
    if height == 0 {
      return unsafe readLeaf {
        unsafe $0._seekBackwardInLeaf(
          from: &i._path, by: &distance, in: metric, preferEnd: preferEnd)
      }
    }
    
    return unsafe readInner {
      var slot = i._path[height]
      precondition(slot <= childCount, "Invalid index")
      let c = unsafe $0.children
      if
        slot < childCount,
        unsafe c[slot].seekBackward(
          from: &i, by: &distance, in: metric, preferEnd: preferEnd)
      {
        return true
      }
      slot -= 1
      while slot >= 0 {
        let d = metric.size(of: unsafe c[slot].summary)
        if preferEnd ? d > distance : d >= distance {
          unsafe i._path[$0.height] = slot
          unsafe i._clear(below: $0.height)
          distance = d - distance
          let success = unsafe c[slot].seekForward(
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
