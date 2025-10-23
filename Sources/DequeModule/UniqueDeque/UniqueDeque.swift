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
@available(*, unavailable, message: "UniqueDeque requires a Swift 6.2 toolchain")
public struct UniqueDeque<Element: ~Copyable>: ~Copyable {
  public init() {
    fatalError()
  }
}

#else

@available(SwiftStdlib 5.0, *)
@frozen
@safe
public struct UniqueDeque<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _storage: RigidDeque<Element>
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque: @unchecked Sendable where Element: Sendable & ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  public typealias Index = Int

  /// A Boolean value indicating whether this deque contains no elements.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var isEmpty: Bool { _storage.isEmpty }

  /// The number of elements in this deque.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var count: Int { _storage.count }

  /// The position of the first element in a nonempty deque. This is always zero.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var startIndex: Int { _storage.startIndex }

  /// The deque’s "past the end” position—that is, the position one greater than
  /// the last valid subscript argument. This is always equal to deque's count.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_transparent
  public var endIndex: Int { _storage.endIndex }

  /// The range of indices that are valid for subscripting the deque.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var indices: Range<Int> { unsafe Range(uncheckedBounds: (0, count)) }

  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(borrow self)
  public func borrowElement(at index: Int) -> Ref<Element> {
    _storage.borrowElement(at: index)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Mut<Element> {
    _storage.mutateElement(at: index)
  }

  @_alwaysEmitIntoClient
  public subscript(position: Int) -> Element {
    @inline(__always)
    @_transparent
    unsafeAddress {
      precondition(position >= 0 && position < count, "Index out of bounds")
      let slot = _storage._handle.slot(forOffset: position)
      return _storage._handle.ptr(at: slot)
    }
    @inline(__always)
    @_transparent
    unsafeMutableAddress {
      precondition(position >= 0 && position < count, "Index out of bounds")
      let slot = _storage._handle.slot(forOffset: position)
      return _storage._handle.mutablePtr(at: slot)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal var _capacity: Int { _storage.capacity }

  @_alwaysEmitIntoClient
  @_transparent
  internal var _freeCapacity: Int { _storage.freeCapacity }

  @_alwaysEmitIntoClient
  @_transparent
  internal var _isFull: Bool { _storage.isFull }

  @inlinable
  internal mutating func _grow(to minimumCapacity: Int) {
    if _fastPath(minimumCapacity <= _capacity) {
      return
    }

    let c = Swift.max(minimumCapacity, 7 * _capacity / 4)
    _storage.resize(to: c)
  }

  @inlinable
  internal mutating func _ensureFreeCapacity(_ freeCapacity: Int) {
    _grow(to: count + freeCapacity)
  }
}

#endif // compiler(<6.2)
