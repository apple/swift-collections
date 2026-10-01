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
  @usableFromInline
  @frozen // Not really! This module isn't ABI stable.
  @unsafe
  internal struct _UnsafeHandle<Child: _RopeItem<Summary>> {
    @usableFromInline internal typealias Summary = Rope.Summary
    
    @usableFromInline
    internal let _header: UnsafeMutablePointer<_RopeStorageHeader>

    @usableFromInline
    internal let _start: UnsafeMutablePointer<Child>
#if DEBUG
    @usableFromInline
    @safe
    internal let _isMutable: Bool
#endif

    @inlinable
    internal init(
      isMutable: Bool,
      header: UnsafeMutablePointer<_RopeStorageHeader>,
      start: UnsafeMutablePointer<Child>
    ) {
      unsafe self._header = header
      unsafe self._start = start
#if DEBUG
      self._isMutable = isMutable
#endif
    }
    
    @inlinable @inline(__always)
    @safe
    internal func assertMutable() {
#if DEBUG
      assert(_isMutable)
#endif
    }
  }
}

extension Rope._UnsafeHandle {
  @inlinable @inline(__always)
  @safe
  internal var capacity: Int { Summary.maxNodeSize }
  
  @inlinable @inline(__always)
  internal var height: UInt8 { unsafe _header.pointee.height }

  @inlinable
  internal var childCount: Int {
    get { unsafe _header.pointee.childCount }
    nonmutating set {
      assertMutable()
      unsafe _header.pointee.childCount = newValue
    }
  }

  @inlinable
  internal var children: UnsafeBufferPointer<Child> {
    unsafe UnsafeBufferPointer(start: _start, count: childCount)
  }

  @inlinable
  internal func child(at slot: Int) -> Child? {
    assert(slot >= 0)
    guard unsafe slot < childCount else { return nil }
    return unsafe (_start + slot).pointee
  }

  @inlinable
  internal var mutableChildren: UnsafeMutableBufferPointer<Child> {
    assertMutable()
    return unsafe UnsafeMutableBufferPointer(start: _start, count: childCount)
  }

  @inlinable
  internal func mutableChildPtr(at slot: Int) -> UnsafeMutablePointer<Child> {
    assertMutable()
    assert(unsafe slot >= 0 && slot < childCount)
    return unsafe _start + slot
  }

  @inlinable
  internal var mutableBuffer: UnsafeMutableBufferPointer<Child> {
    assertMutable()
    return unsafe UnsafeMutableBufferPointer(start: _start, count: capacity)
  }

  @inlinable
  internal func copy() -> Rope._Storage<Child> {
    let new = unsafe Rope._Storage<Child>.create(height: self.height)
    let c = unsafe self.childCount
    new.header.childCount = c
    unsafe new.withUnsafeMutablePointerToElements { target in
      unsafe target.initialize(from: self._start, count: c)
    }
    return new
  }

  @inlinable
  internal func copy(
    slots: Range<Int>
  ) -> (object: Rope._Storage<Child>, summary: Summary) {
    assert(unsafe slots.lowerBound >= 0 && slots.upperBound <= childCount)
    let object = unsafe Rope._Storage<Child>.create(height: self.height)
    let c = slots.count
    let summary = unsafe object.withUnsafeMutablePointers { h, p in
      unsafe h.pointee.childCount = c
      unsafe p.initialize(from: self._start + slots.lowerBound, count: slots.count)
      return unsafe UnsafeBufferPointer(start: p, count: c)._sum()
    }
    return (object, summary)
  }

  @inlinable
  internal func _insertChild(_ child: __owned Child, at slot: Int) {
    assertMutable()
    assert(unsafe childCount < capacity)
    assert(unsafe slot >= 0 && slot <= childCount)
    unsafe (_start + slot + 1).moveInitialize(from: _start + slot, count: childCount - slot)
    unsafe (_start + slot).initialize(to: child)
    unsafe childCount += 1
  }

  @inlinable
  internal func _appendChild(_ child: __owned Child) {
    assertMutable()
    assert(unsafe childCount < capacity)
    unsafe (_start + childCount).initialize(to: child)
    unsafe childCount += 1
  }

  @inlinable
  internal func _removeChild(at slot: Int) -> Child {
    assertMutable()
    assert(unsafe slot >= 0 && slot < childCount)
    let result = unsafe (_start + slot).move()
    unsafe (_start + slot).moveInitialize(from: _start + slot + 1, count: childCount - slot - 1)
    unsafe childCount -= 1
    return result
  }

  @inlinable
  internal func _removePrefix(_ n: Int) -> Summary {
    assertMutable()
    assert(unsafe n <= childCount)
    var delta = Summary.zero
    let c = unsafe mutableChildren
    for i in 0 ..< n {
      let child = unsafe c.moveElement(from: i)
      delta.add(child.summary)
    }
    unsafe childCount -= n
    unsafe _start.moveInitialize(from: _start + n, count: childCount)
    return delta
  }

  @inlinable
  internal func _removeSuffix(_ n: Int) -> Summary {
    assertMutable()
    assert(unsafe n <= childCount)
    var delta = Summary.zero
    let c = unsafe mutableChildren
    for i in unsafe childCount - n ..< childCount {
      let child = unsafe c.moveElement(from: i)
      delta.add(child.summary)
    }
    unsafe childCount -= n
    return delta
  }

  @inlinable
  internal func _appendChildren(
    movingFromPrefixOf src: Self, count: Int
  ) -> Summary {
    assertMutable()
    src.assertMutable()
    assert(unsafe self.height == src.height)
    guard count > 0 else { return .zero }
    assert(unsafe count >= 0 && count <= src.childCount)
    assert(unsafe count <= capacity - self.childCount)

    unsafe (_start + childCount).moveInitialize(from: src._start, count: count)
    unsafe src._start.moveInitialize(from: src._start + count, count: src.childCount - count)
    unsafe childCount += count
    unsafe src.childCount -= count
    return unsafe children.suffix(count)._sum()
  }

  @inlinable
  internal func _prependChildren(
    movingFromSuffixOf src: Self, count: Int
  ) -> Summary {
    assertMutable()
    src.assertMutable()
    assert(unsafe self.height == src.height)
    guard count > 0 else { return .zero }
    assert(unsafe count >= 0 && count <= src.childCount)
    assert(unsafe count <= capacity - childCount)

    unsafe (_start + count).moveInitialize(from: _start, count: childCount)
    unsafe _start.moveInitialize(from: src._start + src.childCount - count, count: count)
    unsafe childCount += count
    unsafe src.childCount -= count
    return unsafe children.prefix(count)._sum()
  }

  @inlinable
  internal func distance(
    from start: Int, to end: Int, in metric: some RopeMetric<Element>
  ) -> Int {
    if start <= end {
      return unsafe children[start ..< end].reduce(into: 0) {
        $0 += metric._nonnegativeSize(of: $1.summary)
      }
    }
    return unsafe -children[end ..< start].reduce(into: 0) {
      $0 += metric._nonnegativeSize(of: $1.summary)
    }
  }
}
