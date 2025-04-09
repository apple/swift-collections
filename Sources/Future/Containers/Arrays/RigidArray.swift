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

extension RigidArray where Element: ~Copyable {
  @available(SwiftStdlib 6.2, *)
  public var span: Span<Element> {
    @lifetime(borrow self)
    @inlinable
    get {
      let result = unsafe Span(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, borrowing: self)
    }
  }
  
  #if compiler(>=6.3) // FIXME: Turn this on once we have a new enough toolchain
  @available(SwiftStdlib 6.2, *)
  public var mutableSpan: MutableSpan<Element> {
    @lifetime(&self)
    @inlinable
    mutating get {
      let result = unsafe MutableSpan(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, mutating: self)
    }
  }
  #endif
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
}

extension RigidArray where Element: ~Copyable {
  // FIXME: This is wildly unsafe. Remove it once the subscript can have proper accessors.
  @inlinable
  @_transparent
  internal mutating func _unsafeMutableAddressOfElement(
    at index: Int
  ) -> UnsafeMutablePointer<Element> {
    precondition(index >= 0 && index < _count)
    return unsafe _storage.baseAddress.unsafelyUnwrapped.advanced(by: index)
  }

  // FIXME: This is wildly unsafe. Remove it once the subscript can have proper accessors.
  @inlinable
  @_transparent
  public func _unsafeAddressOfElement(at index: Int) -> UnsafePointer<Element> {
    precondition(index >= 0 && index < _count)
    return unsafe UnsafePointer(_storage.baseAddress.unsafelyUnwrapped.advanced(by: index))
  }

  @inlinable
  public subscript(position: Int) -> Element {
    @inline(__always)
    unsafeAddress {
      unsafe _unsafeAddressOfElement(at: position)
    }
    @inline(__always)
    unsafeMutableAddress {
      unsafe _unsafeMutableAddressOfElement(at: position)
    }
  }
}

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

extension RigidArray where Element: ~Copyable {
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
}

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
