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
  var rootNode: BitmapIndexedDictionaryNode<Key, Value>

  fileprivate init(_ rootNode: BitmapIndexedDictionaryNode<Key, Value>) {
    self.rootNode = rootNode
  }

  public init() {
    self.init(BitmapIndexedDictionaryNode())
  }

  public init(_ map: PersistentDictionary<Key, Value>) {
    self.init(map.rootNode)
  }

  @inlinable
  @inline(__always)
  public init<S: Sequence>(
    uniqueKeysWithValues keysAndValues: S
  ) where S.Element == (Key, Value) {
    var builder = Self()
    var expectedCount = 0
    keysAndValues.forEach { key, value in
      builder.updateValue(value, forKey: key)
      expectedCount += 1

      guard expectedCount == builder.count else {
        preconditionFailure("Duplicate key: '\(key)'")
      }
    }
    self.init(builder)
  }

  @inlinable
  @inline(__always)
  public init<Keys: Sequence, Values: Sequence>(
    uniqueKeys keys: Keys,
    values: Values
  ) where Keys.Element == Key, Values.Element == Value {
    self.init(uniqueKeysWithValues: zip(keys, values))
  }

  ///
  /// Inspecting a Dictionary
  ///

  public var isEmpty: Bool { rootNode.count == 0 }

  public var count: Int { rootNode.count }

  public var underestimatedCount: Int { rootNode.count }

  public var capacity: Int { rootNode.count }

  ///
  /// Accessing Keys and Values
  ///

  public subscript(key: Key) -> Value? {
    get {
      return get(key)
    }
    mutating set(optionalValue) {
      if let value = optionalValue {
        updateValue(value, forKey: key)
      } else {
        removeValue(forKey: key)
      }
    }
  }

  public subscript(
    key: Key,
    default defaultValue: @autoclosure () -> Value
  ) -> Value {
    get {
      return get(key) ?? defaultValue()
    }
    mutating set(value) {
      updateValue(value, forKey: key)
    }
  }

  public func contains(_ key: Key) -> Bool {
    rootNode.containsKey(key, _computeHash(key), 0)
  }

  func get(_ key: Key) -> Value? {
    rootNode.get(key, _computeHash(key), 0)
  }

  @discardableResult
  public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
    let isUnique = isKnownUniquelyReferenced(&self.rootNode)

    var effect = _DictionaryEffect<Value>()
    let keyHash = _computeHash(key)
    let newRootNode = rootNode.updateOrUpdating(
      isUnique, key, value, keyHash, 0, &effect)

    if effect.modified {
      self.rootNode = newRootNode
    }

    // Note, always tracking discardable result negatively impacts batch use cases
    return effect.previousValue
  }

  // fluid/immutable API
  public func updatingValue(_ value: Value, forKey key: Key) -> Self {
    var effect = _DictionaryEffect<Value>()
    let keyHash = _computeHash(key)
    let newRootNode = rootNode.updateOrUpdating(
      false, key, value, keyHash, 0, &effect)

    if effect.modified {
      return Self(newRootNode)
    } else { return self }
  }

  @discardableResult
  public mutating func removeValue(forKey key: Key) -> Value? {
    let isUnique = isKnownUniquelyReferenced(&self.rootNode)

    var effect = _DictionaryEffect<Value>()
    let keyHash = _computeHash(key)
    let newRootNode = rootNode.removeOrRemoving(
      isUnique, key, keyHash, 0, &effect)

    if effect.modified {
      self.rootNode = newRootNode
    }

    // Note, always tracking discardable result negatively impacts batch use cases
    return effect.previousValue
  }

  // fluid/immutable API
  public func removingValue(forKey key: Key) -> Self {
    var effect = _DictionaryEffect<Value>()
    let keyHash = _computeHash(key)
    let newRootNode = rootNode.removeOrRemoving(false, key, keyHash, 0, &effect)

    if effect.modified {
      return Self(newRootNode)
    } else { return self }
  }
}

