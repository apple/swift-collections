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

extension _Rope: BidirectionalCollection {
  var height: UInt8 { _root?.height ?? 0 }
  
  var isEmpty: Bool {
    guard _root != nil else { return true }
    return root.childCount == 0
  }
  
  var startIndex: Index { Index(height: height) }
  
  var endIndex: Index {
    guard let root = _root else { return startIndex }
    var i = Index(height: height)
    i[height: height] = root.childCount
    return i
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
    precondition(i < endIndex, "Can't move after endIndex")
    if !root.formSuccessor(of: &i) {
      i = endIndex
    }
  }
  
  func formIndex(before i: inout Index) {
    precondition(i > startIndex, "Can't move before startIndex")
    let success = root.formPredecessor(of: &i)
    precondition(success, "Invalid index")
  }
  
  subscript(i: Index) -> Element {
    get { root[i].value }
    @inline(__always) _modify { yield &root[i].value }
  }
}

extension _Rope {
  struct Index {
    typealias Summary = _Rope.Summary

    // ┌──────────────────────────────────┬────────┐
    // │ b63:b8                           │ b7:b0  │
    // ├──────────────────────────────────┼────────┤
    // │ path                             │ height │
    // └──────────────────────────────────┴────────┘
    var _path: UInt64

    @inline(__always)
    static var _pathBitWidth: Int { 56 }

    init(height: UInt8) {
      self._path = UInt64(truncatingIfNeeded: height)
      assert((Int(height) + 1) * Summary.nodeSizeBitWidth <= Self._pathBitWidth)
    }
  }
}

extension _Rope.Index: Equatable {
  static func ==(left: Self, right: Self) -> Bool {
    left._path == right._path
  }
}
extension _Rope.Index: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(_path)
  }
}

extension _Rope.Index: Comparable {
  static func <(left: Self, right: Self) -> Bool {
    left._path < right._path
  }
}

extension _Rope.Index: CustomStringConvertible {
  var description: String {
    var r = "<"
    for h in stride(from: height, through: 0, by: -1) {
      r += "\(self[height: h])"
      if h > 0 { r += ", " }
    }
    r += ">"
    return r
  }
}

extension _Rope.Index {
  var height: UInt8 {
    UInt8(truncatingIfNeeded: _path)
  }

  subscript(height height: UInt8) -> Int {
    get {
      assert(height <= self.height)
      let shift = 8 + Int(height) * Summary.nodeSizeBitWidth
      let mask: UInt64 = (1 &<< Summary.nodeSizeBitWidth) &- 1
      return numericCast((_path &>> shift) & mask)
    }
    set {
      assert(height <= self.height)
      assert(newValue >= 0 && newValue <= Summary.maxNodeSize)
      let shift = 8 + Int(height) * Summary.nodeSizeBitWidth
      let mask: UInt64 = (1 &<< Summary.nodeSizeBitWidth) &- 1
      _path &= ~(mask &<< shift)
      _path |= numericCast(newValue) &<< shift
    }
  }
  
  func isEmpty(below height: UInt8) -> Bool {
    let shift = Int(height) * Summary.nodeSizeBitWidth
    assert(shift + Summary.nodeSizeBitWidth <= Self._pathBitWidth)
    let mask: UInt64 = ((1 &<< shift) - 1) &<< 8
    return (_path & mask) == 0
  }
  
  mutating func clear(below height: UInt8) {
    let shift = Int(height) * Summary.nodeSizeBitWidth
    assert(shift + Summary.nodeSizeBitWidth <= Self._pathBitWidth)
    let mask: UInt64 = ((1 &<< shift) - 1) &<< 8
    _path &= ~mask
  }
}

extension _Rope {
  static var maxHeight: Int {
    Index._pathBitWidth / Summary.nodeSizeBitWidth
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
    if start == end { return 0 }
    precondition(_root != nil, "Invalid index")
    if start < end {
      return root.distance(from: start, to: end, in: metric)
    }
    return -root.distance(from: end, to: start, in: metric)
  }

  func offset(of index: Index, in metric: some _RopeMetric<Element>) -> Int {
    distance(from: startIndex, to: index, in: metric)
  }
}

extension _Rope.Node {
  func distanceFromStart(to index: Index, in metric: some _RopeMetric<Element>) -> Int {
    let slot = index[height: height]
    precondition(slot <= childCount, "Invalid index")
    if slot == childCount {
      precondition(index.isEmpty(below: height), "Invalid index")
      return metric.nonnegativeSize(of: self.summary)
    }
    if height == 0 {
      return readLeaf {
        $0.children[..<slot].reduce(into: 0) {
          $0 += metric.nonnegativeSize(of: $1.summary)
        }
      }
    }
    return readInner {
      var distance = $0.children[..<slot].reduce(into: 0) {
        $0 += metric.nonnegativeSize(of: $1.summary)
      }
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
    let a = start[height: height]
    let b = end[height: height]
    precondition(a < childCount, "Invalid index")
    precondition(b <= childCount, "Invalid index")
    assert(a <= b)
    if b == childCount {
      precondition(end.isEmpty(below: height), "Invalid index")
      return distanceToEnd(from: start, in: metric)
    }
    if height == 0 {
      assert(a < b)
      return readLeaf {
        $0.children[a..<b].reduce(into: 0) { $0 += metric.size(of: $1.summary) }
      }
    }
    return readInner {
      let c = $0.children
      if a == b {
        return c[a].distance(from: start, to: end, in: metric)
      }
      var d = c[a].distanceToEnd(from: start, in: metric)
      d += c[(a + 1) ..< b].reduce(into: 0) { $0 += metric.nonnegativeSize(of: $1.summary) }
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
    if root.seekForward(from: &i, by: &distance, in: metric, preferEnd: preferEnd) {
      return
    }
    precondition(distance == 0, "Position out of bounds")
    i = endIndex
  }
  
  func index(
    _ i: Index, offsetBy distance: Int, in metric: some _RopeMetric<Element>, preferEnd: Bool
  ) -> (index: Index, remainder: Int) {
    var i = i
    var distance = distance
    formIndex(&i, offsetBy: &distance, in: metric, preferEnd: preferEnd)
    return (i, distance)
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
    var slot = i[height: height]
    precondition(slot < childCount, "Invalid index")
    
    if height == 0 {
      return readLeaf {
        let c = $0.children
        while slot < c.count {
          let d = metric.nonnegativeSize(of: c[slot].summary)
          if preferEnd ? d >= distance : d > distance {
            i[height: 0] = slot
            return true
          }
          distance &-= d
          slot &+= 1
        }
        return false
      }
    }
    
    return readInner {
      let c = $0.children
      if c[slot].seekForward(from: &i, by: &distance, in: metric, preferEnd: preferEnd) {
        return true
      }
      slot &+= 1
      while slot < c.count {
        let d = metric.size(of: c[slot].summary)
        if preferEnd ? d >= distance : d > distance {
          i[height: $0.height] = slot
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
    var slot = i[height: height]
    precondition(slot <= childCount, "Invalid index")
    
    if height == 0 {
      return readLeaf {
        let c = $0.children
        slot &-= 1
        while slot >= 0 {
          let d = metric.nonnegativeSize(of: c[slot].summary)
          if preferEnd ? d > distance : d >= distance {
            i[height: 0] = slot
            distance = d &- distance
            return true
          }
          distance &-= d
          slot &-= 1
        }
        return false
      }
    }
    
    return readInner {
      let c = $0.children
      if slot < childCount,
         c[slot].seekBackward(from: &i, by: &distance, in: metric, preferEnd: preferEnd) {
        return true
      }
      slot -= 1
      while slot >= 0 {
        let d = metric.size(of: c[slot].summary)
        if preferEnd ? d > distance : d >= distance {
          i[height: $0.height] = slot
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
