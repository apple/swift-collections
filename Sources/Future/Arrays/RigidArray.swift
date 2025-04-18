//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A manually resizable, heap allocated, noncopyable array of
/// potentially noncopyable elements.
@safe
@frozen
public struct RigidArray<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: UnsafeMutableBufferPointer<Element>

  @usableFromInline
  internal var _count: Int

  deinit {
    unsafe _storage.extracting(0 ..< count).deinitialize()
    unsafe _storage.deallocate()
  }

  @inlinable
  public init(capacity: Int) {
    precondition(capacity >= 0)
    if capacity > 0 {
      unsafe _storage = .allocate(capacity: capacity)
    } else {
      unsafe _storage = .init(start: nil, count: 0)
    }
    _count = 0
  }

  @inlinable
  public init(count: Int, initializedBy generator: (Int) -> Element) {
    unsafe _storage = .allocate(capacity: count)
    for i in 0 ..< count {
      unsafe _storage.initializeElement(at: i, to: generator(i))
    }
    _count = count
  }
}

extension RigidArray: @unchecked Sendable where Element: Sendable & ~Copyable {}

extension RigidArray where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public var capacity: Int { unsafe _storage.count }

  @inlinable
  @inline(__always)
  public var freeCapacity: Int { capacity - count }

  @inlinable
  @inline(__always)
  public var isFull: Bool { freeCapacity == 0 }
}

extension RigidArray where Element: ~Copyable {
  @inlinable
  internal var _items: UnsafeMutableBufferPointer<Element> {
    unsafe _storage.extracting(Range(uncheckedBounds: (0, _count)))
  }

  @inlinable
  internal var _freeSpace: UnsafeMutableBufferPointer<Element> {
    unsafe _storage.extracting(Range(uncheckedBounds: (_count, capacity)))
  }
}

//MARK: - Span creation

extension RigidArray where Element: ~Copyable {
  @available(SwiftCompatibilitySpan 5.0, *)
  public var span: Span<Element> {
    @lifetime(borrow self)
    @inlinable
    get {
      let result = unsafe Span(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, borrowing: self)
    }
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  public var mutableSpan: MutableSpan<Element> {
    @lifetime(&self)
    @inlinable
    mutating get {
      let result = unsafe MutableSpan(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, mutating: &self)
    }
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  @lifetime(borrow self)
  internal func _span(in range: Range<Int>) -> Span<Element> {
    span._extracting(range)
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  @lifetime(&self)
  internal mutating func _mutableSpan(in range: Range<Int>) -> MutableSpan<Element> {
    let result = unsafe MutableSpan(_unsafeElements: _items.extracting(range))
    return unsafe _overrideLifetime(result, mutating: &self)
  }
}

extension RigidArray where Element: ~Copyable {
  @inlinable
  internal func _contiguousSubrange(following index: inout Int) -> Range<Int> {
    precondition(index >= 0 && index <= _count, "Index out of bounds")
    defer { index = _count }
    return unsafe Range(uncheckedBounds: (index, _count))
  }

  @inlinable
  internal func _contiguousSubrange(preceding index: inout Int) -> Range<Int> {
    precondition(index >= 0 && index <= _count, "Index out of bounds")
    defer { index = 0 }
    return unsafe Range(uncheckedBounds: (0, index))
  }
}

//MARK: - RandomAccessContainer conformance

@available(SwiftCompatibilitySpan 5.0, *)
extension RigidArray: RandomAccessContainer where Element: ~Copyable {
  @inlinable
  @lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Span<Element> {
    _span(in: _contiguousSubrange(following: &index))
  }

  @inlinable
  @lifetime(borrow self)
  public func previousSpan(before index: inout Int) -> Span<Element> {
    _span(in: _contiguousSubrange(preceding: &index))
  }
}

extension RigidArray where Element: ~Copyable {
  public typealias Index = Int

  @inlinable
  public var isEmpty: Bool { count == 0 }

  @inlinable
  public var count: Int { _count }

  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { count }

  @inlinable
  @lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    precondition(index >= 0 && index < _count, "Index out of bounds")
    return unsafe Borrow(
      unsafeAddress: _storage.baseAddress.unsafelyUnwrapped.advanced(by: index),
      borrowing: self
    )
  }
}

//MARK: - MutableContainer conformance

@available(SwiftCompatibilitySpan 5.0, *)
extension RigidArray: MutableContainer where Element: ~Copyable {
  @lifetime(&self)
  public mutating func nextMutableSpan(after index: inout Int) -> MutableSpan<Element> {
    _mutableSpan(in: _contiguousSubrange(following: &index))
  }
}

extension RigidArray where Element: ~Copyable {
  @inlinable
  @lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Inout<Element> {
    precondition(index >= 0 && index < _count)
    return unsafe Inout(
      unsafeAddress: _storage.baseAddress.unsafelyUnwrapped.advanced(by: index),
      mutating: &self
    )
  }
}

//MARK: Unsafe access

extension RigidArray where Element: ~Copyable {
  @inlinable
  public mutating func withUnsafeMutableBufferPointer<E: Error, R: ~Copyable>(
    _ body: (UnsafeMutableBufferPointer<Element>, inout Int) throws(E) -> R
  ) throws(E) -> R {
    defer { precondition(_count >= 0 && _count <= capacity) }
    return unsafe try body(_items, &_count)
  }
}

//MARK: - Resizing

extension RigidArray where Element: ~Copyable {
  @inlinable
  public mutating func resize(to newCapacity: Int) {
    precondition(newCapacity >= count)
    guard newCapacity != capacity else { return }
    let newStorage: UnsafeMutableBufferPointer<Element> = .allocate(capacity: newCapacity)
    let i = unsafe newStorage.moveInitialize(fromContentsOf: self._items)
    assert(i == count)
    unsafe _storage.deallocate()
    unsafe _storage = newStorage
  }

  @inlinable
  public mutating func reserveCapacity(_ n: Int) {
    guard capacity < n else { return }
    resize(to: n)
  }
}

//MARK: Range replacement operations

extension RigidArray where Element: ~Copyable {
  @inlinable
  @discardableResult
  public mutating func removeLast() -> Element {
    precondition(!isEmpty)
    let old = unsafe _storage.moveElement(from: _count - 1)
    _count -= 1
    return old
  }

  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    precondition(index >= 0 && index < count)
    let old = unsafe _storage.moveElement(from: index)
    let source = unsafe _storage.extracting(index + 1 ..< count)
    let target = unsafe _storage.extracting(index ..< count - 1)
    let i = unsafe target.moveInitialize(fromContentsOf: source)
    assert(i == target.endIndex)
    _count -= 1
    return old
  }
}

extension RigidArray where Element: ~Copyable {
  @inlinable
  public mutating func append(_ item: consuming Element) {
    precondition(!isFull)
    unsafe _storage.initializeElement(at: _count, to: item)
    _count += 1
  }
}

extension RigidArray where Element: ~Copyable {
  @inlinable
  public mutating func insert(_ item: consuming Element, at index: Int) {
    precondition(index >= 0 && index <= count)
    precondition(!isFull)
    if index < count {
      let source = unsafe _storage.extracting(index ..< count)
      let target = unsafe _storage.extracting(index + 1 ..< count + 1)
      let last = unsafe target.moveInitialize(fromContentsOf: source)
      assert(last == target.endIndex)
    }
    unsafe _storage.initializeElement(at: index, to: item)
    _count += 1
  }
}

extension RigidArray {
  @inlinable
  public mutating func append(contentsOf items: some Sequence<Element>) {
    for item in items {
      append(item)
    }
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  public mutating func append(contentsOf items: Span<Element>) {
    precondition(items.count <= freeCapacity)
    unsafe items.withUnsafeBufferPointer {
      _ = unsafe _freeSpace.initialize(fromContentsOf: $0)
    }
  }
}

//MARK: - Copying and moving helpers

extension RigidArray {
  @inlinable
  internal func _copy() -> Self {
    _copy(capacity: capacity)
  }

  @inlinable
  internal func _copy(capacity: Int) -> Self {
    precondition(capacity >= count)
    var result = RigidArray<Element>(capacity: capacity)
    let initialized = unsafe result._storage.initialize(fromContentsOf: _storage)
    precondition(initialized == count)
    result._count = count
    return result
  }

  @inlinable
  internal mutating func _move(capacity: Int) -> Self {
    precondition(capacity >= count)
    var result = RigidArray<Element>(capacity: capacity)
    let initialized = unsafe result._storage.moveInitialize(fromContentsOf: _storage)
    precondition(initialized == count)
    result._count = count
    self._count = 0
    return result
  }
}
