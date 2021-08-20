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
  internal struct _DenseStorage {
    @usableFromInline
    internal var keys: ContiguousArray<Key>

    @usableFromInline
    internal var values: ContiguousArray<Value>

    @usableFromInline
    internal init(keys: ContiguousArray<Key>, values: ContiguousArray<Value>) {
      self.keys = keys
      self.values = values
    }
  }
}

extension SparseSet._DenseStorage {
  @usableFromInline
  internal init() {
    self.keys = []
    self.values = []
  }

  @usableFromInline
  internal init(minimumCapacity: Int) {
    var keys: ContiguousArray<Key> = []
    keys.reserveCapacity(minimumCapacity)
    self.keys = keys
    var values: ContiguousArray<Value> = []
    values.reserveCapacity(minimumCapacity)
    self.values = values
  }
}

extension SparseSet._DenseStorage {
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { keys.isEmpty }

  @inlinable
  @inline(__always)
  public var count: Int { keys.count }
}

extension SparseSet._DenseStorage {
  @inlinable
  internal mutating func removeAll(keepingCapacity: Bool) {
    keys.removeAll(keepingCapacity: keepingCapacity)
    values.removeAll(keepingCapacity: keepingCapacity)
  }
}

extension SparseSet._DenseStorage {
  @inlinable
  internal mutating func append(value: Value, key: Key) {
    keys.append(key)
    values.append(value)
  }

  @inlinable
  @discardableResult
  internal mutating func removeLast() -> (key: Key, value: Value) {
    return (key: keys.removeLast(), value: values.removeLast())
  }
}
