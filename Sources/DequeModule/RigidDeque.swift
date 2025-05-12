//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import Future
#endif

@frozen
public struct RigidDeque<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal typealias _Slot = _DequeSlot

  @usableFromInline
  internal typealias _UnsafeHandle = _UnsafeDequeHandle<Element>

  @usableFromInline
  internal var _handle: _UnsafeHandle

  @inlinable
  internal init(_handle: consuming _UnsafeHandle) {
    self._handle = _handle
  }

  @inlinable
  public init(capacity: Int) {
    self.init(_handle: .allocate(capacity: capacity))
  }

  deinit {
    _handle.dispose()
  }
}

extension RigidDeque: @unchecked Sendable where Element: Sendable & ~Copyable {}

extension RigidDeque where Element: ~Copyable {
#if COLLECTIONS_INTERNAL_CHECKS
  @usableFromInline @inline(never) @_effects(releasenone)
  internal func _checkInvariants() {
    _handle._checkInvariants()
  }
#else
  @inlinable @inline(__always)
  internal func _checkInvariants() {}
#endif // COLLECTIONS_INTERNAL_CHECKS
}

extension RigidDeque where Element: ~Copyable {
  @usableFromInline
  internal var description: String {
    _handle.description
  }
}

@available(SwiftStdlib 6.2, *)
extension RigidDeque where Element: ~Copyable {
  @inlinable
  @lifetime(borrow self)
  internal func _span(over slots: Range<_DequeSlot>) -> Span<Element> {
    let span = Span(_unsafeElements: _handle.buffer(for: slots))
    return _overrideLifetime(span, borrowing: self)
  }

  @inlinable
  @lifetime(&self)
  internal mutating func _mutableSpan(over slots: Range<_DequeSlot>) -> MutableSpan<Element> {
    let span = MutableSpan(_unsafeElements: _handle.mutableBuffer(for: slots))
    return _overrideLifetime(span, mutating: &self)
  }
}

@available(SwiftStdlib 6.2, *)
extension RigidDeque: RandomAccessContainer, MutableContainer where Element: ~Copyable {
  @inlinable
  @lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Span<Element> {
    let slots = _handle.slotRange(following: &index)
    return _span(over: slots)
  }
  
  @inlinable
  @lifetime(borrow self)
  public func previousSpan(before index: inout Int) -> Span<Element> {
    let slots = _handle.slotRange(preceding: &index)
    return _span(over: slots)
  }
  
  @inlinable
  @lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int
  ) -> MutableSpan<Element> {
    let slots = _handle.slotRange(following: &index)
    return _mutableSpan(over: slots)
  }
  
  public mutating func swapAt(_ i: Int, _ j: Int) {
    precondition(i >= 0 && i < count, "Index out of bounds")
    precondition(j >= 0 && j < count, "Index out of bounds")
    let slot1 = _handle.slot(forOffset: i)
    let slot2 = _handle.slot(forOffset: j)
    unsafe _handle.mutableBuffer.swapAt(slot1.position, slot2.position)
  }
}

extension RigidDeque where Element: ~Copyable {
  public typealias Index = Int

  @inlinable
  public var isEmpty: Bool { _handle.count == 0 }

  @inlinable
  public var count: Int { _handle.count }

  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { _handle.count }

  @lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    precondition(index >= 0 && index < count, "Index out of bounds")
    let slot = _handle.slot(forOffset: index)
    return Borrow(unsafeAddress: _handle.ptr(at: slot), borrowing: self)
  }

  @lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Inout<Element> {
    precondition(index >= 0 && index < count, "Index out of bounds")
    let slot = _handle.slot(forOffset: index)
    return Inout(unsafeAddress: _handle.mutablePtr(at: slot), mutating: &self)
  }

  @inlinable
  public subscript(position: Int) -> Element {
    @inline(__always)
    _read {
      yield _handle[offset: position]
    }
    @inline(__always)
    _modify {
      yield &_handle[offset: position]
    }
  }
}

extension RigidDeque where Element: ~Copyable {
  @inlinable
  public var capacity: Int { _handle.capacity }

  @inlinable
  public var freeCapacity: Int { capacity - count }

  @inlinable
  public var isFull: Bool { count == capacity }

  @inlinable
  public mutating func resize(to newCapacity: Int) {
    _handle.reallocate(capacity: newCapacity)
  }
}

extension RigidDeque where Element: ~Copyable {
  @inlinable
  public mutating func append(_ newElement: consuming Element) {
    precondition(!isFull, "RigidDeque is full")
    _handle.uncheckedAppend(newElement)
  }

  @inlinable
  public mutating func prepend(_ newElement: consuming Element) {
    precondition(!isFull, "RigidDeque is full")
    _handle.uncheckedPrepend(newElement)
  }

  @inlinable
  public mutating func insert(_ newElement: consuming Element, at index: Int) {
    precondition(!isFull, "RigidDeque is full")
    precondition(index >= 0 && index <= count,
                 "Can't insert element at invalid index")
    _handle.uncheckedInsert(newElement, at: index)
  }
}

extension RigidDeque where Element: ~Copyable {
  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    precondition(index >= 0 && index < count,
                 "Can't remove element at invalid index")
    return _handle.uncheckedRemove(at: index)
  }

  @inlinable
  public mutating func removeSubrange(_ bounds: Range<Int>) {
    precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count,
                 "Index range out of bounds")
    _handle.uncheckedRemove(offsets: bounds)
  }

  @inlinable
  @discardableResult
  public mutating func removeFirst() -> Element {
    precondition(!isEmpty, "Cannot remove first element of an empty RigidDeque")
    return _handle.uncheckedRemoveFirst()
  }

  @inlinable
  @discardableResult
  public mutating func removeLast() -> Element {
    precondition(!isEmpty, "Cannot remove last element of an empty RigidDeque")
    return _handle.uncheckedRemoveLast()
  }

  @inlinable
  public mutating func removeFirst(_ n: Int) {
    precondition(n >= 0, "Can't remove a negative number of elements")
    precondition(n <= count, "Can't remove more elements than there are in a RigidDeque")
    _handle.uncheckedRemoveFirst(n)
  }

  @inlinable
  public mutating func removeLast(_ n: Int) {
    precondition(n >= 0, "Can't remove a negative number of elements")
    precondition(n <= count, "Can't remove more elements than there are in a RigidDeque")
    _handle.uncheckedRemoveLast(n)
  }

  @inlinable
  public mutating func removeAll() {
    _handle.uncheckedRemoveAll()
  }

  @inlinable
  public mutating func popFirst() -> Element? {
    guard !isEmpty else { return nil }
    return _handle.uncheckedRemoveFirst()
  }

  @inlinable
  public mutating func popLast() -> Element? {
    guard !isEmpty else { return nil }
    return _handle.uncheckedRemoveLast()
  }
}

extension RigidDeque {
  @inlinable
  internal func _copy() -> Self {
    RigidDeque(_handle: _handle.allocateCopy())
  }

  @inlinable
  internal func _copy(capacity: Int) -> Self {
    RigidDeque(_handle: _handle.allocateCopy(capacity: capacity))
  }
}
