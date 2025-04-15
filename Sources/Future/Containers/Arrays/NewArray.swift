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

/// What `Array` might look like if we defined it today.
@frozen
public struct NewArray<Element> {
  @usableFromInline
  internal var _storage: Shared<RigidArray<Element>>

  @inlinable
  public init(minimumCapacity: Int) {
    self._storage = Shared(RigidArray(capacity: minimumCapacity))
  }
}

extension NewArray {
  @available(SwiftStdlib 6.2, *)
  public var span: Span<Element> {
    @lifetime(borrow self)
    get {
      _storage.value.span
    }
  }
}

extension NewArray {
  @inlinable
  public var capacity: Int { _storage.value.capacity }

  @inlinable
  internal mutating func _ensureUnique() {
    _storage.ensureUnique { $0._copy() }
  }

  @inlinable
  internal mutating func _ensureUnique(
    minimumCapacity: Int,
    linear: Bool = false
  ) {
    // FIXME: Handle resizing
    if !_storage.isUnique() {
      let c = Swift.max(count, minimumCapacity)
      _storage = Shared(_storage.value._copy(capacity: c))
    } else if minimumCapacity > self.capacity {
      _storage = Shared(_storage.value._move(capacity: minimumCapacity))
    }
  }

  @inlinable
  internal mutating func _update<E: Error, Result: ~Copyable>(
    minimumCapacity: Int,
    _ body: (inout RigidArray<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    _ensureUnique(minimumCapacity: minimumCapacity)
    return try body(&_storage.value)
  }
}

extension NewArray: RandomAccessCollection, MutableCollection {
  public typealias Index = Int

  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { _storage.value.count }

  public subscript(position: Int) -> Element {
    @inlinable
    unsafeAddress {
      unsafe _storage.value.borrowElement(at: position)._pointer
    }
    @inlinable
    unsafeMutableAddress {
      _ensureUnique()
      return unsafe _storage.value.mutateElement(at: position)._pointer
    }
  }
}

#if false // FIXME: Implement
extension NewArray: RangeReplaceableCollection {
  public init() {
    // FIXME: Figure out if we can implement empty singletons in this setup.
    self._storage = Shared(RigidArray(capacity: 0))
  }

  mutating public func replaceSubrange(
    _ subrange: Range<Int>,
    with newElements: some Collection<Element>
  ) {
    let delta = newElements.count - subrange.count
    _ensureUnique(minimumCapacity: capacity + delta)
  }
}
#endif
