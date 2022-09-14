//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public struct PersistentDictionary<Key, Value> where Key: Hashable {
  @usableFromInline
  internal typealias _Node = PersistentCollections._Node<Key, Value>

  @usableFromInline
  var _root: _Node

  @inlinable
  internal init(_root: _Node) {
    self._root = _root
  }
}

extension PersistentDictionary {
  @inlinable
  public init() {
    self.init(_root: _Node(storage: _emptySingleton, count: 0))
  }

  @inlinable
  public init(_ other: PersistentDictionary<Key, Value>) {
    self = other
  }

  @inlinable
  public func _invariantCheck() {
    _root._fullInvariantCheck(.top, _Hash(_value: 0))
  }


  @inlinable
  @inline(__always)
  public init<S: Sequence>(
    uniqueKeysWithValues keysAndValues: S
  ) where S.Element == (Key, Value) {
    self.init()
    for (key, value) in keysAndValues {
      let unique = updateValue(value, forKey: key) == nil
      precondition(unique, "Duplicate key: '\(key)'")
    }
    _invariantCheck()
  }

  @inlinable
  @inline(__always)
  public init<Keys: Sequence, Values: Sequence>(
    uniqueKeys keys: Keys,
    values: Values
  ) where Keys.Element == Key, Values.Element == Value {
    self.init(uniqueKeysWithValues: zip(keys, values))
  }

  @inlinable
  public subscript(key: Key) -> Value? {
    get {
      return _get(key)
    }
    mutating set(optionalValue) {
      if let value = optionalValue {
        updateValue(value, forKey: key)
      } else {
        removeValue(forKey: key)
      }
    }
  }

  @inlinable
  public subscript(
    key: Key,
    default defaultValue: @autoclosure () -> Value
  ) -> Value {
    get {
      return _get(key) ?? defaultValue()
    }
    mutating set(value) {
      updateValue(value, forKey: key)
    }
  }

  @inlinable
  public func contains(_ key: Key) -> Bool {
    _root.containsKey(.top, key, _Hash(key))
  }

  @inlinable
  func _get(_ key: Key) -> Value? {
    _root.get(.top, key, _Hash(key))
  }

  /// Returns the index for the given key.
  @inlinable
  public func index(forKey key: Key) -> Index? {
    _root.position(forKey: key, .top, _Hash(key)).map { Index(_value: $0) }
  }

  @inlinable
  @discardableResult
  public mutating func updateValue(
    _ value: __owned Value, forKey key: Key
  ) -> Value? {
    return _root.updateValue(value, forKey: key, .top, _Hash(key))
  }

  // fluid/immutable API
  @inlinable
  public func updatingValue(_ value: Value, forKey key: Key) -> Self {
    var copy = self
    copy.updateValue(value, forKey: key)
    return copy
  }

  @inlinable
  @discardableResult
  public mutating func removeValue(forKey key: Key) -> Value? {
    _root.remove(key, .top, _Hash(key))?.value
  }

  // fluid/immutable API
  @inlinable
  public func removingValue(forKey key: Key) -> Self {
    var copy = self
    copy.removeValue(forKey: key)
    return copy
  }
}

