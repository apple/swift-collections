//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension SparseSet {
  @usableFromInline
  internal struct DenseStorage {
    @usableFromInline
    internal var _keys: ContiguousArray<Key>

    @usableFromInline
    internal var _values: ContiguousArray<Value>

    @usableFromInline
    internal init(_keys: ContiguousArray<Key>, _values: ContiguousArray<Value>) {
      self._keys = _keys
      self._values = _values
    }
  }
}

extension SparseSet.DenseStorage {
  @usableFromInline
  internal init() {
    self._keys = []
    self._values = []
  }

  @usableFromInline
  internal init(minimumCapacity: Int) {
    var keys: ContiguousArray<Key> = []
    keys.reserveCapacity(minimumCapacity)
    self._keys = keys
    var values: ContiguousArray<Value> = []
    values.reserveCapacity(minimumCapacity)
    self._values = values
  }
}

extension SparseSet.DenseStorage {
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { _keys.isEmpty }

  @inlinable
  @inline(__always)
  public var count: Int { _keys.count }
}

extension SparseSet.DenseStorage {
  @inlinable
  internal mutating func removeAll(keepingCapacity: Bool) {
    _keys.removeAll(keepingCapacity: keepingCapacity)
    _values.removeAll(keepingCapacity: keepingCapacity)
  }
}

extension SparseSet.DenseStorage {
  @inlinable
  internal mutating func append(value: Value, key: Key) {
    _keys.append(key)
    _values.append(value)
  }

  @inlinable
  @discardableResult
  internal mutating func removeLast() -> (key: Key, value: Value) {
    return (key: _keys.removeLast(), value: _values.removeLast())
  }
}
