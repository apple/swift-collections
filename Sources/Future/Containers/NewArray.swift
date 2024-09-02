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
  @inlinable
  public var capacity: Int { _storage.read { $0.capacity } }

  @inlinable
  internal mutating func _ensureUnique() {
    _storage.ensureUnique { $0._copy() }
  }

  @inlinable
  internal mutating func _ensureUnique(minimumCapacity: Int) {
    if !_storage.isUnique() {
      let c = Swift.max(count, minimumCapacity)
      _storage = Shared(_storage.read { $0._copy(capacity: c) })
    } else if minimumCapacity > self.capacity {
      _storage = Shared(_storage.update { $0._move(capacity: minimumCapacity) })
    }
  }

  @inlinable
  internal func _read<E: Error, Result: ~Copyable>(
    _ body: (borrowing RigidArray<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    try _storage.read(body)
  }

  @inlinable
  internal mutating func _update<E: Error, Result: ~Copyable>(
    _ body: (inout RigidArray<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    _ensureUnique()
    return try _storage.update(body)
  }

  @inlinable
  internal mutating func _update<E: Error, Result: ~Copyable>(
    minimumCapacity: Int,
    _ body: (inout RigidArray<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    _ensureUnique(minimumCapacity: minimumCapacity)
    return try _storage.update(body)
  }
}

extension NewArray: RandomAccessCollection, MutableCollection {
  public typealias Index = Int

  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { _storage.read { $0.count } }

  public subscript(position: Int) -> Element {
    @inlinable
    get {
      _read { $0[position] }
    }
    @inlinable
    @inline(__always)
    _modify {
      _ensureUnique()
      yield &_storage.value[position]
    }
  }
}

extension NewArray {
  public var span: Span<Element> {
    Span(unsafeElements: _storage.value._items, owner: self)
  }
}
