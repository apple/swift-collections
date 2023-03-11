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
  struct UnsafeHandle<Child: _RopeItem<Summary>> {
    typealias Summary = _Rope.Summary
    typealias Element = _Rope.Element
    
    let _header: UnsafeMutablePointer<_RopeStorageHeader>
    let _start: UnsafeMutablePointer<Child>
#if DEBUG
    let _isMutable: Bool
#endif
    
    init(
      isMutable: Bool,
      header: UnsafeMutablePointer<_RopeStorageHeader>,
      start: UnsafeMutablePointer<Child>
    ) {
      self._header = header
      self._start = start
#if DEBUG
      self._isMutable = isMutable
#endif
    }
    
    @inline(__always)
    func assertMutable() {
#if DEBUG
      assert(_isMutable)
#endif
    }
  }
}

extension _Rope.UnsafeHandle {
  @inline(__always)
  var capacity: Int { Summary.maxNodeSize }
  
  @inline(__always)
  var height: UInt8 { _header.pointee.height }
  
  var childCount: Int {
    get { _header.pointee.childCount }
    nonmutating set {
      assertMutable()
      _header.pointee.childCount = newValue
    }
  }
  
  var children: UnsafeBufferPointer<Child> {
    UnsafeBufferPointer(start: _start, count: childCount)
  }
  
  func child(at slot: Int) -> Child? {
    assert(slot >= 0)
    guard slot < childCount else { return nil }
    return (_start + slot).pointee
  }
  
  var mutableChildren: UnsafeMutableBufferPointer<Child> {
    assertMutable()
    return UnsafeMutableBufferPointer(start: _start, count: childCount)
  }
  
  func mutableChildPtr(at slot: Int) -> UnsafeMutablePointer<Child> {
    assertMutable()
    assert(slot >= 0 && slot < childCount)
    return _start + slot
  }
  
  var mutableBuffer: UnsafeMutableBufferPointer<Child> {
    assertMutable()
    return UnsafeMutableBufferPointer(start: _start, count: capacity)
  }
  
  func copy() -> _Rope.Storage<Child> {
    let new = _Rope.Storage<Child>.create(height: self.height)
    let c = self.childCount
    new.header.childCount = c
    new.withUnsafeMutablePointerToElements { target in
      target.initialize(from: self._start, count: c)
    }
    return new
  }

  func copy(slots: Range<Int>) -> (object: _Rope.Storage<Child>, summary: Summary) {
    assert(slots.lowerBound >= 0 && slots.upperBound <= childCount)
    let object = _Rope.Storage<Child>.create(height: self.height)
    let c = slots.count
    let summary = object.withUnsafeMutablePointers { h, p in
      h.pointee.childCount = c
      p.initialize(from: self._start + slots.lowerBound, count: slots.count)
      return UnsafeBufferPointer(start: p, count: c)._sum()
    }
    return (object, summary)
  }

  func _insertChild(_ child: __owned Child, at slot: Int) {
    assertMutable()
    assert(childCount < capacity)
    assert(slot >= 0 && slot <= childCount)
    (_start + slot + 1).moveInitialize(from: _start + slot, count: childCount - slot)
    (_start + slot).initialize(to: child)
    childCount += 1
  }
  
  func _appendChild(_ child: __owned Child) {
    assertMutable()
    assert(childCount < capacity)
    (_start + childCount).initialize(to: child)
    childCount += 1
  }
  
  func _removeChild(at slot: Int) -> Child {
    assertMutable()
    assert(slot >= 0 && slot < childCount)
    let result = (_start + slot).move()
    (_start + slot).moveInitialize(from: _start + slot + 1, count: childCount - slot - 1)
    childCount -= 1
    return result
  }

  func _removePrefix(_ n: Int) -> Summary {
    assertMutable()
    assert(n <= childCount)
    var delta = Summary.zero
    let c = mutableChildren
    for i in 0 ..< n {
      let child = c.moveElement(from: i)
      delta.add(child.summary)
    }
    childCount -= n
    _start.moveInitialize(from: _start + n, count: childCount)
    return delta
  }

  func _removeSuffix(_ n: Int) -> Summary {
    assertMutable()
    assert(n <= childCount)
    var delta = Summary.zero
    let c = mutableChildren
    for i in childCount - n ..< childCount {
      let child = c.moveElement(from: i)
      delta.add(child.summary)
    }
    childCount -= n
    return delta
  }
  
  func _appendChildren(movingFromPrefixOf src: Self, count: Int) -> Summary {
    assertMutable()
    src.assertMutable()
    assert(self.height == src.height)
    guard count > 0 else { return .zero }
    assert(count >= 0 && count <= src.childCount)
    assert(count <= capacity - self.childCount)
    
    (_start + childCount).moveInitialize(from: src._start, count: count)
    src._start.moveInitialize(from: src._start + count, count: src.childCount - count)
    childCount += count
    src.childCount -= count
    return children.suffix(count)._sum()
  }
  
  func _prependChildren(movingFromSuffixOf src: Self, count: Int) -> Summary {
    assertMutable()
    src.assertMutable()
    assert(self.height == src.height)
    guard count > 0 else { return .zero }
    assert(count >= 0 && count <= src.childCount)
    assert(count <= capacity - childCount)
    
    (_start + count).moveInitialize(from: _start, count: childCount)
    _start.moveInitialize(from: src._start + src.childCount - count, count: count)
    childCount += count
    src.childCount -= count
    return children.prefix(count)._sum()
  }

  func distance(from start: Int, to end: Int, in metric: some _RopeMetric<Element>) -> Int {
    if start <= end {
      return children[start ..< end].reduce(into: 0) {
        $0 += metric.nonnegativeSize(of: $1.summary)
      }
    }
    return -children[end ..< start].reduce(into: 0) {
      $0 += metric.nonnegativeSize(of: $1.summary)
    }
  }
}
