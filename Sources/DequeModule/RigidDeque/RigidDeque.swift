//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(<6.2)

@frozen
@available(*, unavailable, message: "RigidDeque requires a Swift 6.2 toolchain")
public struct RigidDeque<Element: ~Copyable>: ~Copyable {
  public init() {
    fatalError()
  }
}

#else

@available(SwiftStdlib 5.0, *)
@frozen
@safe
public struct RigidDeque<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal typealias _Slot = _DequeSlot

  @usableFromInline
  internal typealias _UnsafeHandle = _UnsafeDequeHandle<Element>

  @usableFromInline
  internal var _handle: _UnsafeHandle

  @_alwaysEmitIntoClient
  @_transparent
  internal init(_handle: consuming _UnsafeHandle) {
    self._handle = _handle
  }

  @_alwaysEmitIntoClient
  @_transparent
  deinit {
    _handle.dispose()
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque: @unchecked Sendable where Element: Sendable & ~Copyable {}

@available(SwiftStdlib 5.0, *)
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

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @usableFromInline
  internal var description: String {
    _handle.description
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(borrow self)
  internal func _span(over slots: Range<_DequeSlot>) -> Span<Element> {
    let span = Span(_unsafeElements: _handle.buffer(for: slots))
    return _overrideLifetime(span, borrowing: self)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(&self)
  internal mutating func _mutableSpan(over slots: Range<_DequeSlot>) -> MutableSpan<Element> {
    let span = MutableSpan(_unsafeElements: _handle.mutableBuffer(for: slots))
    return _overrideLifetime(span, mutating: &self)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  public typealias Index = Int

  @_alwaysEmitIntoClient
  @_transparent
  public var isEmpty: Bool { _handle.count == 0 }

  @_alwaysEmitIntoClient
  @_transparent
  public var count: Int { _handle.count }

  @_alwaysEmitIntoClient
  @_transparent
  public var startIndex: Int { 0 }

  @_alwaysEmitIntoClient
  @_transparent
  public var endIndex: Int { _handle.count }

  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(borrow self)
  public func borrowElement(at index: Int) -> Ref<Element> {
    precondition(index >= 0 && index < count, "Index out of bounds")
    let slot = _handle.slot(forOffset: index)
    return Ref(unsafeAddress: _handle.ptr(at: slot), borrowing: self)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Mut<Element> {
    precondition(index >= 0 && index < count, "Index out of bounds")
    let slot = _handle.slot(forOffset: index)
    return Mut(unsafeAddress: _handle.mutablePtr(at: slot), mutating: &self)
  }

  @_alwaysEmitIntoClient
  public subscript(position: Int) -> Element {
    @inline(__always)
    @_transparent
    unsafeAddress {
      precondition(position >= 0 && position < count, "Index out of bounds")
      let slot = _handle.slot(forOffset: position)
      return _handle.ptr(at: slot)
    }
    @inline(__always)
    @_transparent
    unsafeMutableAddress {
      precondition(position >= 0 && position < count, "Index out of bounds")
      let slot = _handle.slot(forOffset: position)
      return _handle.mutablePtr(at: slot)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public var capacity: Int { _handle.capacity }

  @_alwaysEmitIntoClient
  @_transparent
  public var freeCapacity: Int { capacity - count }

  @_alwaysEmitIntoClient
  @_transparent
  public var isFull: Bool { count == capacity }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func resize(to newCapacity: Int) {
    _handle.reallocate(capacity: newCapacity)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque {
  @_alwaysEmitIntoClient
  @_transparent
  internal func _copy() -> Self {
    RigidDeque(_handle: _handle.allocateCopy())
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func _copy(capacity: Int) -> Self {
    RigidDeque(_handle: _handle.allocateCopy(capacity: capacity))
  }
}

#endif // compiler(<6.2)
