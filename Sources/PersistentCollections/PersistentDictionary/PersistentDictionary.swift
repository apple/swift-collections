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

public struct PersistentDictionary<Key: Hashable, Value> {
  @usableFromInline
  internal typealias _Node = PersistentCollections._Node<Key, Value>

  @usableFromInline
  internal typealias _UnsafeHandle = _Node.UnsafeHandle

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
    self.init(_root: _new, version: _new.initialVersionNumber)
  }
}

extension PersistentDictionary {
  /// Accesses the value associated with the given key for reading and writing.
  ///
  /// This *key-based* subscript returns the value for the given key if the key
  /// is found in the dictionary, or `nil` if the key is not found.
  ///
  /// The following example creates a new dictionary and prints the value of a
  /// key found in the dictionary (`"Coral"`) and a key not found in the
  /// dictionary (`"Cerise"`).
  ///
  ///     var hues: PersistentDictionary = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
  ///     print(hues["Coral"])
  ///     // Prints "Optional(16)"
  ///     print(hues["Cerise"])
  ///     // Prints "nil"
  ///
  /// When you assign a value for a key and that key already exists, the
  /// dictionary overwrites the existing value. If the dictionary doesn't
  /// contain the key, the key and value are added as a new key-value pair.
  ///
  /// Inserting a new key-value pair into a dictionary invalidates all
  /// previously returned indices to it. Updating the value of an existing key
  /// does not invalidate any indices.
  ///
  /// Here, the value for the key `"Coral"` is updated from `16` to `18` and a
  /// new key-value pair is added for the key `"Cerise"`.
  ///
  ///     hues["Coral"] = 18
  ///     print(hues["Coral"])
  ///     // Prints "Optional(18)"
  ///
  ///     hues["Cerise"] = 330
  ///     print(hues["Cerise"])
  ///     // Prints "Optional(330)"
  ///
  /// If you assign `nil` as the value for the given key, the dictionary
  /// removes that key and its associated value. Removing an existing key-value
  /// pair in the dictionary invalidates all previously returned indices to it.
  /// Removing a key that doesn't exist does not invalidate any indices.
  ///
  /// In the following example, the key-value pair for the key `"Aquamarine"`
  /// is removed from the dictionary by assigning `nil` to the key-based
  /// subscript.
  ///
  ///     hues["Aquamarine"] = nil
  ///     print(hues)
  ///     // Prints "["Coral": 18, "Heliotrope": 296, "Cerise": 330]"
  ///
  /// - Parameter key: The key to find in the dictionary.
  ///
  /// - Returns: The value associated with `key` if `key` is in the dictionary;
  ///   otherwise, `nil`.
  ///
  /// - Complexity: Traversing the hash tree to find a key requires visiting
  ///     O(log(`count`)) nodes. Looking up and updating values in the
  ///     dictionary through this subscript has an expected complexity of O(1)
  ///     hashing/comparison operations on average, if `Key` implements
  ///     high-quality hashing.
  ///
  ///     When used to mutate dictionary values with shared storage, this
  ///     operation is expected to copy at most O(log(`count`)) items.
  @inlinable
  public subscript(key: Key) -> Value? {
    get {
      _root.get(.top, key, _Hash(key))
    }
    set {
      if let value = newValue {
        _updateValue(value, forKey: key)
        _invalidateIndices()
      } else {
        removeValue(forKey: key)
      }
    }
    @inline(__always) // https://github.com/apple/swift-collections/issues/164
    _modify {
      _invalidateIndices()
      var state = _root.prepareValueUpdate(key, _Hash(key))
      defer {
        _root.finalizeValueUpdate(state)
      }
      yield &state.value
    }
  }

  /// Accesses the value with the given key. If the dictionary doesn't contain
  /// the given key, accesses the provided default value as if the key and
  /// default value existed in the dictionary.
  ///
  /// Use this subscript when you want either the value for a particular key
  /// or, when that key is not present in the dictionary, a default value. This
  /// example uses the subscript with a message to use in case an HTTP response
  /// code isn't recognized:
  ///
  ///     var responseMessages: PersistentDictionary = [
  ///         200: "OK",
  ///         403: "Access forbidden",
  ///         404: "File not found",
  ///         500: "Internal server error"]
  ///
  ///     let httpResponseCodes = [200, 403, 301]
  ///     for code in httpResponseCodes {
  ///         let message = responseMessages[code, default: "Unknown response"]
  ///         print("Response \(code): \(message)")
  ///     }
  ///     // Prints "Response 200: OK"
  ///     // Prints "Response 403: Access forbidden"
  ///     // Prints "Response 301: Unknown response"
  ///
  /// When a dictionary's `Value` type has value semantics, you can use this
  /// subscript to perform in-place operations on values in the dictionary.
  /// The following example uses this subscript while counting the occurrences
  /// of each letter in a string:
  ///
  ///     let message = "Hello, Elle!"
  ///     var letterCounts: PersistentDictionary<Character, Int> = [:]
  ///     for letter in message {
  ///         letterCounts[letter, default: 0] += 1
  ///     }
  ///     // letterCounts == ["H": 1, "e": 2, "l": 4, "o": 1, ...]
  ///
  /// When `letterCounts[letter, defaultValue: 0] += 1` is executed with a
  /// value of `letter` that isn't already a key in `letterCounts`, the
  /// specified default value (`0`) is returned from the subscript,
  /// incremented, and then added to the dictionary under that key.
  ///
  /// Inserting a new key-value pair invalidates all existing indices in the
  /// dictionary. Updating the value of an existing key does not invalidate
  /// any indices.
  ///
  /// - Note: Do not use this subscript to modify dictionary values if the
  ///   dictionary's `Value` type is a class. In that case, the default value
  ///   and key are not written back to the dictionary after an operation. (For
  ///   a variant of this operation that supports this usecase, see
  ///   `updateValue(forKey:default:_:)`.)
  ///
  /// - Parameters:
  ///   - key: The key the look up in the dictionary.
  ///   - defaultValue: The default value to use if `key` doesn't exist in the
  ///     dictionary.
  ///
  /// - Returns: The value associated with `key` in the dictionary; otherwise,
  ///   `defaultValue`.
  ///
  /// - Complexity: Traversing the hash tree to find a key requires visiting
  ///     O(log(`count`)) nodes. Looking up and updating values in the
  ///     dictionary through this subscript has an expected complexity of O(1)
  ///     hashing/comparison operations on average, if `Key` implements
  ///     high-quality hashing.
  ///
  ///     When used to mutate dictionary values with shared storage, this
  ///     operation is expected to copy at most O(log(`count`)) items.
  @inlinable
  public subscript(
    key: Key,
    default defaultValue: @autoclosure () -> Value
  ) -> Value {
    get {
      _root.get(.top, key, _Hash(key)) ?? defaultValue()
    }
    set {
      _updateValue(newValue, forKey: key)
      _invalidateIndices()
    }
    @inline(__always) // https://github.com/apple/swift-collections/issues/164
    _modify {
      _invalidateIndices()
      var state = _root.prepareDefaultedValueUpdate(
        .top, key, defaultValue, _Hash(key))
      defer {
        _root.finalizeDefaultedValueUpdate(state)
      }
      yield &state.item.value
    }
  }

  // FIXME: New addition; needs discussion
  @inlinable
  public func contains(_ key: Key) -> Bool {
    _root.containsKey(.top, key, _Hash(key))
  }

  /// Returns the index for the given key.
  @inlinable
  public func index(forKey key: Key) -> Index? {
    guard let path = _root.path(to: key, _Hash(key))
    else { return nil }
    return Index(_root: _root.unmanaged, version: _version, path: path)
  }

  /// Updates the value stored in the dictionary for the given key, or appends a
  /// new key-value pair if the key does not exist.
  ///
  /// Use this method instead of key-based subscripting when you need to know
  /// whether the new value supplants the value of an existing key. If the
  /// value of an existing key is updated, `updateValue(_:forKey:)` returns
  /// the original value.
  ///
  ///     var hues: PersistentDictionary = [
  ///         "Heliotrope": 296,
  ///         "Coral": 16,
  ///         "Aquamarine": 156]
  ///
  ///     if let oldValue = hues.updateValue(18, forKey: "Coral") {
  ///         print("The old value of \(oldValue) was replaced with a new one.")
  ///     }
  ///     // Prints "The old value of 16 was replaced with a new one."
  ///
  /// If the given key is not present in the dictionary, this method appends the
  /// key-value pair and returns `nil`.
  ///
  ///     if let oldValue = hues.updateValue(330, forKey: "Cerise") {
  ///         print("The old value of \(oldValue) was replaced with a new one.")
  ///     } else {
  ///         print("No value was found in the dictionary for that key.")
  ///     }
  ///     // Prints "No value was found in the dictionary for that key."
  ///
  /// Inserting a new key-value pair invalidates all existing indices in the
  /// dictionary. Updating the value of an existing key does not invalidate
  /// any indices.
  ///
  /// - Parameters:
  ///   - value: The new value to add to the dictionary.
  ///   - key: The key to associate with `value`. If `key` already exists in
  ///     the dictionary, `value` replaces the existing associated value. If
  ///     `key` isn't already a key of the dictionary, the `(key, value)` pair
  ///     is added.
  ///
  /// - Returns: The value that was replaced, or `nil` if a new key-value pair
  ///   was added.
  ///
  /// - Complexity: Traversing the hash tree to find a key requires visiting
  ///     O(log(`count`)) nodes. Updating values in the has an expected
  ///     complexity of O(1) hashing/comparison operations on average, if
  ///     `Key` implements high-quality hashing.
  ///
  ///     When used to mutate dictionary values with shared storage, this
  ///     operation is expected to copy at most O(log(`count`)) items.
  @inlinable
  @discardableResult
  public mutating func updateValue(
    _ value: __owned Value, forKey key: Key
  ) -> Value? {
    let hash = _Hash(key)
    let r = _root.updateValue(.top, forKey: key, hash) {
      $0.initialize(to: (key, value))
    }
    _invalidateIndices()
    if r.inserted { return nil }
    return _UnsafeHandle.update(r.leaf) {
      let p = $0.itemPtr(at: r.slot)
      let old = p.pointee.value
      p.pointee.value = value
      return old
    }
  }

  @inlinable
  @discardableResult
  internal mutating func _updateValue(
    _ value: __owned Value, forKey key: Key
  ) -> Bool {
    let hash = _Hash(key)
    let r = _root.updateValue(.top, forKey: key, hash) {
      $0.initialize(to: (key, value))
    }
    if r.inserted { return true }
    _UnsafeHandle.update(r.leaf) {
      $0[item: r.slot].value = value
    }
    return false
  }

  // fluid/immutable API
  @inlinable
  public func updatingValue(_ value: Value, forKey key: Key) -> Self {
    var copy = self
    copy.updateValue(value, forKey: key)
    return copy
  }

  // FIXME: New addition; needs discussion
  @inlinable @inline(__always)
  public mutating func updateValue<R>(
    forKey key: Key,
    with body: (inout Value?) throws -> R
  ) rethrows -> R {
    try body(&self[key])
  }

  @inlinable
  public mutating func updateValue<R>(
    forKey key: Key,
    default defaultValue: @autoclosure () -> Value,
    with body: (inout Value) throws -> R
  ) rethrows -> R {
    let hash = _Hash(key)
    let r = _root.updateValue(.top, forKey: key, hash) {
      $0.initialize(to: (key, defaultValue()))
    }
    return try _UnsafeHandle.update(r.leaf) {
      try body(&$0[item: r.slot].value)
    }
  }

  /// Removes the given key and its associated value from the dictionary.
  ///
  /// If the key is found in the dictionary, this method returns the key's
  /// associated value, and invalidates all previously returned indices.
  ///
  ///     var hues: OrderedDictionary = [
  ///        "Heliotrope": 296,
  ///        "Coral": 16,
  ///        "Aquamarine": 156]
  ///     if let value = hues.removeValue(forKey: "Coral") {
  ///         print("The value \(value) was removed.")
  ///     }
  ///     // Prints "The value 16 was removed."
  ///
  /// If the key isn't found in the dictionary, `removeValue(forKey:)` returns
  /// `nil`. Removing a key that isn't in the dictionary does not invalidate
  /// any indices.
  ///
  ///     if let value = hues.removeValue(forKey: "Cerise") {
  ///         print("The value \(value) was removed.")
  ///     } else {
  ///         print("No value found for that key.")
  ///     }
  ///     // Prints "No value found for that key.""
  ///
  /// - Parameter key: The key to remove along with its associated value.
  /// - Returns: The value that was removed, or `nil` if the key was not
  ///   present in the dictionary.
  ///
  /// - Complexity: Traversing the hash tree to find a key requires visiting
  ///     O(log(`count`)) nodes. Updating values in the has an expected
  ///     complexity of O(1) hashing/comparison operations on average, if
  ///     `Key` implements high-quality hashing.
  ///
  ///     When used to mutate dictionary values with shared storage, this
  ///     operation is expected to copy at most O(log(`count`)) items.
  @inlinable
  @discardableResult
  public mutating func removeValue(forKey key: Key) -> Value? {
    guard let r = _root.remove(.top, key, _Hash(key)) else { return nil }
    _invalidateIndices()
    assert(r.remainder == nil)
    _invariantCheck()
    return r.removed.value
  }

  // fluid/immutable API
  @inlinable
  public func removingValue(forKey key: Key) -> Self {
    guard let r = _root.removing(.top, key, _Hash(key)) else { return self }
    return Self(_new: r.replacement.finalize(.top))
  }

  @inlinable
  public mutating func remove(at index: Index) -> Element {
    precondition(_isValid(index), "Invalid index")
    precondition(index._path._isItem, "Can't remove item at end index")
    _invalidateIndices()
    let r = _root.remove(.top, at: index._path)
    assert(r.remainder == nil)
    return r.removed
  }
}

