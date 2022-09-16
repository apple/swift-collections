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

  /// The version number of this instance, used for quick index validation.
  /// This is initialized to a (very weakly) random value and it gets
  /// incremented on every mutation that needs to invalidate indices.
  @usableFromInline
  var _version: UInt

  @inlinable
  internal init(_root: _Node, version: UInt) {
    self._root = _root
    self._version = version
  }

  @inlinable
  internal init(_new: _Node) {
    self._root = _new
    // Ideally we would simply just generate a true random number, but the
    // memory address of the root node is a reasonable substitute.
    let address = Unmanaged.passUnretained(_root.raw.storage).toOpaque()
    self._version = UInt(bitPattern: address)
  }
}

extension PersistentDictionary {
  @inlinable
  public init() {
    self.init(_new: _Node(storage: _emptySingleton, count: 0))
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
      _root.get(.top, key, _Hash(key))
    }
    mutating set {
      if let value = newValue {
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
      _root.get(.top, key, _Hash(key)) ?? defaultValue()
    }
    set {
      updateValue(newValue, forKey: key)
    }
    @inline(__always) // https://github.com/apple/swift-collections/issues/164
    _modify {
      var state = _root.prepareDefaultedValueUpdate(
        key, defaultValue, .top, _Hash(key))
      if state.inserted { _invalidateIndices() }
      defer {
        _root.finalizeDefaultedValueUpdate(state)
      }
      yield &state.item.value
    }
  }

  @inlinable
  public func contains(_ key: Key) -> Bool {
    _root.containsKey(.top, key, _Hash(key))
  }

  /// Returns the index for the given key.
  @inlinable
  public func index(forKey key: Key) -> Index? {
    let (found, path) = _root.path(to: key, hash: _Hash(key))
    guard found else { return nil }
    return Index(_root: _root.unmanaged, version: _version, path: path)
  }

  @inlinable
  @discardableResult
  public mutating func updateValue(
    _ value: __owned Value, forKey key: Key
  ) -> Value? {
    let old = _root.updateValue(value, forKey: key, .top, _Hash(key))
    if old == nil { _invalidateIndices() }
    return old
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
    let old = _root.remove(key, .top, _Hash(key))?.value
    if old != nil { _invalidateIndices() }
    return old
  }

  // fluid/immutable API
  @inlinable
  public func removingValue(forKey key: Key) -> Self {
    var copy = self
    copy.removeValue(forKey: key)
    return copy
  }
}

