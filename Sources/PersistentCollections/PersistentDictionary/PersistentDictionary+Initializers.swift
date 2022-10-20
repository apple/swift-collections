//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentDictionary {
  @inlinable
  public init() {
    self.init(_new: ._emptyNode())
  }

  @inlinable
  public init(_ other: PersistentDictionary<Key, Value>) {
    self = other
  }

  // FIXME: This is a non-standard addition
  @inlinable
  public init(
    keys: PersistentSet<Key>,
    _ valueTransform: (Key) throws -> Value
  ) rethrows {
    let root = try keys._root.mapValues { try valueTransform($0.key) }
    self.init(_new: root)
  }

  @inlinable
  public init<S: Sequence>(
    uniqueKeysWithValues keysAndValues: S
  ) where S.Element == (Key, Value) {
    self.init()
    for item in keysAndValues {
      let hash = _Hash(item.0)
      let r = _root.insert(.top, item, hash)
      precondition(r.inserted, "Duplicate key: '\(item.0)'")
    }
    _invariantCheck()
  }

  @_disfavoredOverload // https://github.com/apple/swift-collections/issues/125
  @inlinable
  public init<S: Sequence>(
    uniqueKeysWithValues keysAndValues: S
  ) where S.Element == Element {
    if S.self == Self.self {
      self = keysAndValues as! Self
      return
    }
    self.init(
      uniqueKeysWithValues: keysAndValues.lazy.map { ($0.key, $0.value ) })
  }

  @inlinable
  public init<Keys: Sequence, Values: Sequence>(
    uniqueKeys keys: Keys,
    values: Values
  ) where Keys.Element == Key, Values.Element == Value {
    self.init(uniqueKeysWithValues: zip(keys, values))
  }

  public init<S: Sequence>(
    _ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == (Key, Value) {
    self.init()
    try self.merge(keysAndValues, uniquingKeysWith: combine)
  }

  @_disfavoredOverload // https://github.com/apple/swift-collections/issues/125
  public init<S: Sequence>(
    _ keysAndValues: S, uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == Element {
    try self.init(
      keysAndValues.lazy.map { ($0.key, $0.value) },
      uniquingKeysWith: combine)
  }
}

extension PersistentDictionary {
  @inlinable @inline(__always)
  public init<S: Sequence>(
    grouping values: S,
    by keyForValue: (S.Element) throws -> Key
  ) rethrows
  where Value: RangeReplaceableCollection, Value.Element == S.Element
  {
    try self.init(_grouping: values, by: keyForValue)
  }

  @inlinable @inline(__always)
  public init<S: Sequence>(
    grouping values: S,
    by keyForValue: (S.Element) throws -> Key
  ) rethrows
  where Value == [S.Element]
  {
    // Note: this extra overload is necessary to make type inference work
    // for the `Value` type -- we want it to default to `[S.Element`].
    // (https://github.com/apple/swift-collections/issues/139)
    try self.init(_grouping: values, by: keyForValue)
  }

  @inlinable
  internal init<S: Sequence>(
    _grouping values: S,
    by keyForValue: (S.Element) throws -> Key
  ) rethrows
  where Value: RangeReplaceableCollection, Value.Element == S.Element
  {
    self.init()
    for value in values {
      let key = try keyForValue(value)
      self.updateValue(forKey: key, default: Value()) { array in
        array.append(value)
      }
    }
  }
}
