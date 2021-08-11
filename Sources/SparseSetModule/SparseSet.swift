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

public struct SparseSet<Key, Value> where Key: FixedWidthInteger, Key.Stride == Int {
  @usableFromInline
  internal var _dense: DenseStorage

  @inlinable
  @inline(__always)
  internal var _sparse: SparseStorage {
    get {
      SparseStorage(__sparseBuffer)
    }
    set {
      __sparseBuffer = newValue._buffer
    }
  }

  @usableFromInline
  internal var __sparseBuffer: SparseStorage.Buffer
}

// MARK: -

extension SparseSet {
  /// A read-only collection view for the keys contained in this sparse set, as
  /// a `ContiguousArray`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var keys: ContiguousArray<Key> {
    _dense._keys
  }

  /// A mutable collection view containing the values in this sparse set.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var values: Values {
    get {
      Values(_base: self)
    }
    _modify {
      var values = Values(_base: self)
      self = SparseSet()
      defer { self = values._base }
      yield &values
    }
  }
}

// MARK: -

extension SparseSet {
  /// The size of the key universe. The sparse set has enough space allocated to
  /// store all (non-negative) keys less than this value. Adding a key to the
  /// sparse set that is greater than or equal to the universe size will result
  /// in extra memory allocation.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var universeSize: Int { _sparse.capacity }

  /// A Boolean value indicating whether the sparse set is empty.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { _dense.isEmpty }

  /// The number of elements in the sparse set.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var count: Int { _dense.count }

  /// Returns the index for the given key.
  ///
  /// If the given key is found in the sparse set, this method returns an
  /// index into the sparse set that corresponds with the key-value pair.
  ///
  /// - Parameter key: The key to find in the sparse set.
  ///
  /// - Returns: The index for `key` and its associated value if `key` is in
  ///    the sparse set; otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func index(forKey key: Key) -> Int? {
    return _find(key: key)
  }

  /// Accesses the element at the specified index.
  ///
  /// - Parameter offset: The offset of the element to access, measured from
  ///   the start of the collection. `offset` must be greater than or equal to
  ///   `0` and less than `count`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public subscript(offset offset: Int) -> Element {
    (_dense._keys[offset], _dense._values[offset])
  }
}

// MARK: -

extension SparseSet {
  /// Inserts a new value and its associated key into the sparse set. If the key
  /// already exists in the sparse set then its currently associated value is
  /// replaced by the new value.
  ///
  /// - Parameters:
  ///   - newValue: The value to insert.
  ///   - key: The key associated with the value.
  ///
  /// - Returns: If the key already exists in the sparse set then its associated
  ///   value is replaced with `newValue` and the old value is returned,
  ///   otherwise `nil` is returned.
  ///
  /// - Complexity: Amortized O(1).
  @discardableResult
  @inlinable
  public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
    if let existingIndex = _find(key: key) {
      let existingValue = _dense._values[existingIndex]
      _dense._values[existingIndex] = value
      return existingValue
    }
    _append(value: value, key: key)
    return nil
  }

  /// Ensures that the specified key exists in the sparse set (by appending one
  /// with the supplied default value if necessary), then calls `body` to update
  /// it in place.
  ///
  /// You can use this method to perform in-place operations on values in the
  /// sparse set, whether or not `Value` has value semantics.
  ///
  /// - Parameters:
  ///   - key: The key to look up (or append). If `key` does not already exist
  ///     in the sparse set, it is appended with the supplied default value.
  ///   - defaultValue: The default value to append if `key` doesn't exist in
  ///     the sparse set.
  ///   - body: A function that performs an in-place mutation on the sparse set
  ///     value.
  ///
  /// - Returns: The return value of `body`.
  ///
  /// - Complexity: `O(1)`.
  @inlinable
  public mutating func modifyValue<R>(
    forKey key: Key,
    default defaultValue: @autoclosure () -> Value,
    _ body: (inout Value) throws -> R
  ) rethrows -> R {
    if let existingIndex = _find(key: key) {
      return try body(&_dense._values[existingIndex])
    }
    _append(value: defaultValue(), key: key)
    let i = _dense.count - 1
    return try body(&_dense._values[i])
  }

  /// Removes the given key and its associated value from the sparse set.
  ///
  /// Calling this method will invalidate existing indices. When a non-final
  /// element is removed the final element is moved to fill the resulting gap.
  ///
  /// - Parameter key: The key to remove.
  ///
  /// - Returns: If the key is contained in the sparse set then its associated
  ///   value is returned, otherwise `nil`.
  ///
  /// - Complexity: O(1).
  @discardableResult
  @inlinable
  public mutating func removeValue(forKey key: Key) -> Value? {
    guard let existingIndex = _find(key: key) else {
      return nil
    }
    let existing = _remove(at: existingIndex)
    return existing.value
  }
}

// MARK: -

extension SparseSet {
  /// Accesses the value associated with the given key for reading and writing.
  ///
  /// This *key-based* subscript returns the value for the given key if the key
  /// is found in the sparse set, or `nil` if the key is not found.
  ///
  /// When you assign a value for a key and that key already exists, the
  /// sparse set overwrites the existing value. If the sparse set doesn't
  /// contain the key, the key and value are added as a new key-value pair.
  ///
  /// If you assign `nil` as the value for the given key, the sparse set
  /// removes that key and its associated value.
  ///
  /// - Parameter key: The key to find in the sparse set.
  ///
  /// - Returns: The value associated with `key` if `key` is in the sparse set;
  ///   otherwise, `nil`.
  ///
  /// - Complexity: Looking up values in the sparse set through this subscript
  ///    has O(1) complexity. Updating the sparse set also has an amortized
  ///    expected complexity of O(1) -- although individual updates may need to
  ///    copy or resize the sparse set's underlying storage.
  @inlinable
  public subscript(key: Key) -> Value? {
    get {
      guard let index = _find(key: key) else { return nil }
      return _dense._values[index]
    }
    set {
      // We have a separate `set` in addition to `_modify` in hopes of getting
      // rid of `_modify`'s swapAt dance in the usual case where the caller just
      // wants to assign a new value.
      let index = _find(key: key)
      switch (index, newValue) {
      case let (index?, newValue?): // Assign
        _dense._values[index] = newValue
      case let (index?, nil): // Remove
        _remove(at: index)
      case let (nil, newValue?): // Insert
        _append(value: newValue, key: key)
      case (nil, nil): // Noop
        break
      }
    }
    _modify {
      let index = _find(key: key)

      // To support in-place mutations better, we swap the value to the end of
      // the array and pop it off. Later we either put things back in place,
      // or swap keys too depending on whether we are are assigning or removing.
      var value: Value? = nil
      if let index = index {
        _dense._values.swapAt(index, _dense._values.count - 1)
        value = _dense._values.removeLast()
      }

      defer {
        switch (index, value) {
        case let (index?, value?): // Assign
          _dense._values.append(value)
          _dense._values.swapAt(index, _dense._values.count - 1)
        case let (index?, nil): // Remove
          _ensureUnique()
          if index < _dense._values.count {
            let shiftedKey = _dense._keys.removeLast()
            _dense._keys[index] = shiftedKey
            _sparse[shiftedKey] = index
          } else {
            _dense._keys.removeLast()
          }
        case let (nil, value?): // Insert
          _append(value: value, key: key)
        case (nil, nil): // Noop
          break
        }
      }

      yield &value
    }
  }

  /// Accesses the value with the given key. If the sparse set doesn't contain
  /// the given key, accesses the provided default value as if the key and
  /// default value existed in the sparse set.
  ///
  /// Use this subscript when you want either the value for a particular key
  /// or, when that key is not present in the sparse set, a default value.
  ///
  /// When a sparse set's `Value` type has value semantics, you can use this
  /// subscript to perform in-place operations on values in the sparse set.
  ///
  /// - Note: Do not use this subscript to modify sparse set values if the
  ///   sparse set's `Value` type is a class. In that case, the default value
  ///   and key are not written back to the sparse set after an operation. (For
  ///   a variant of this operation that supports this usecase, see
  ///   `modifyValue(forKey:default:_:)`.)
  ///
  /// - Parameters:
  ///   - key: The key the look up in the sparse set.
  ///   - defaultValue: The default value to use if `key` doesn't exist in the
  ///     sparse set.
  ///
  /// - Returns: The value associated with `key` in the sparse set; otherwise,
  ///   `defaultValue`.
  ///
  /// - Complexity: Looking up values in the sparse set through this subscript
  ///    has O(1) complexity. Updating the sparse set also has an amortized
  ///    expected complexity of O(1) -- although individual updates may need to
  ///    copy or resize the sparse set's underlying storage.
  @inlinable
  public subscript(
    key: Key,
    default defaultValue: @autoclosure () -> Value
  ) -> Value {
    get {
      guard let index = _find(key: key) else { return defaultValue() }
      return _dense._values[index]
    }
    _modify {
      let index: Int

      if let existingIndex = _find(key: key) {
        index = existingIndex
      } else {
        index = _dense.count
        _append(value: defaultValue(), key: key)
      }

      var value: Value = _dense._values.withUnsafeMutableBufferPointer { buffer in
        assert(index < buffer.count)
        return (buffer.baseAddress! + index).move()
      }
      defer {
        _dense._values.withUnsafeMutableBufferPointer { buffer in
          assert(index < buffer.count)
          (buffer.baseAddress! + index).initialize(to: value)
        }
      }
      yield &value
    }
  }
}

// MARK: -

extension SparseSet {
  /// Merges the key-value pairs in the given sequence into the sparse set,
  /// using a combining closure to determine the value for any duplicate keys.
  ///
  /// Use the `combine` closure to select a value to use in the updated sparse
  /// set, or to combine existing and new values. As the key-value pairs are
  /// merged with the sparse set, the `combine` closure is called with the
  /// current and new values for any duplicate keys that are encountered.
  ///
  /// - Parameters:
  ///   - other: A sequence of key-value pairs.
  ///   - combine: A closure that takes the current and new values for any
  ///     duplicate keys. The closure returns the desired value for the final
  ///     sparse set.
  @inlinable
  public mutating func merge<S: Sequence>(
    _ keysAndValues: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == (key: Key, value: Value) {
    for (key, value) in keysAndValues {
      if let index = _find(key: key) {
        try { $0 = try combine($0, value) }(&_dense._values[index])
      } else {
        _append(value: value, key: key)
      }
    }
  }

  /// Merges the key-value pairs in the given sequence into the sparse set,
  /// using a combining closure to determine the value for any duplicate keys.
  ///
  /// Use the `combine` closure to select a value to use in the updated sparse
  /// set, or to combine existing and new values. As the key-value pairs are
  /// merged with the sparse set, the `combine` closure is called with the
  /// current and new values for any duplicate keys that are encountered.
  ///
  /// - Parameters:
  ///   - other: A sequence of key-value pairs.
  ///   - combine: A closure that takes the current and new values for any
  ///     duplicate keys. The closure returns the desired value for the final
  ///     sparse set.
  @inlinable
  public mutating func merge<S: Sequence>(
    _ keysAndValues: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == (Key, Value) {
    let mapped: LazyMapSequence =
    keysAndValues.lazy.map { (key: $0.0, value: $0.1) }
    try merge(mapped, uniquingKeysWith: combine)
  }

  /// Creates a sparse set by merging key-value pairs in a sequence into this
  /// sparse set, using a combining closure to determine the value for duplicate
  /// keys.
  ///
  /// Use the `combine` closure to select a value to use in the returned sparse
  /// set, or to combine existing and new values. As the key-value pairs are
  /// merged with the sparse set, the `combine` closure is called with the
  /// current and new values for any duplicate keys that are encountered.
  ///
  /// - Parameters:
  ///   - other: A sequence of key-value pairs.
  ///   - combine: A closure that takes the current and new values for any
  ///     duplicate keys. The closure returns the desired value for the final
  ///     sparse set.
  ///
  /// - Returns: A new sparse set with the combined keys and values of this
  ///   sparse set and `other`.
  @inlinable
  public __consuming func merging<S: Sequence>(
    _ other: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows -> Self where S.Element == (key: Key, value: Value) {
    var copy = self
    try copy.merge(other, uniquingKeysWith: combine)
    return copy
  }

  /// Creates a sparse set by merging key-value pairs in a sequence into this
  /// sparse set, using a combining closure to determine the value for duplicate
  /// keys.
  ///
  /// Use the `combine` closure to select a value to use in the returned sparse
  /// set, or to combine existing and new values. As the key-value pairs are
  /// merged with the sparse set, the `combine` closure is called with the
  /// current and new values for any duplicate keys that are encountered.
  ///
  /// - Parameters:
  ///   - other: A sequence of key-value pairs.
  ///   - combine: A closure that takes the current and new values for any
  ///     duplicate keys. The closure returns the desired value for the final
  ///     sparse set.
  ///
  /// - Returns: A new sparse set with the combined keys and values of this
  ///   sparse set and `other`.
  @inlinable
  public __consuming func merging<S: Sequence>(
    _ other: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows -> Self where S.Element == (Key, Value) {
    var copy = self
    try copy.merge(other, uniquingKeysWith: combine)
    return copy
  }
}

// MARK: -

extension SparseSet {
  /// Returns a new sparse set containing the key-value pairs of the sparse set
  /// that satisfy the given predicate.
  ///
  /// - Parameter isIncluded: A closure that takes a key-value pair as its
  ///   argument and returns a Boolean value indicating whether the pair
  ///   should be included in the returned sparse set.
  ///
  /// - Returns: A sparse set of the key-value pairs that `isIncluded` allows.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Self {
    var result: SparseSet = [:]
    for element in self where try isIncluded(element) {
      result._append(value: element.value, key: element.key)
    }
    return result
  }
}

// MARK: -

extension SparseSet {
  /// Returns a new sparse set containing the keys of this sparse set with the
  /// values transformed by the given closure.
  ///
  /// - Parameter transform: A closure that transforms a value. `transform`
  ///   accepts each value of the sparse set as its parameter and returns a
  ///   transformed value of the same or of a different type.
  /// - Returns: A sparse set containing the keys and transformed values of
  ///   this sparse set.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func mapValues<T>(
    _ transform: (Value) throws -> T
  ) rethrows -> SparseSet<Key, T> {
    SparseSet<Key, T>(
      uniqueKeys: _dense._keys,
      values: ContiguousArray(try _dense._values.map(transform)))
  }

  /// Returns a new sparse set containing only the key-value pairs that have
  /// non-`nil` values as the result of transformation by the given closure.
  ///
  /// Use this method to receive a sparse set with non-optional values when
  /// your transformation produces optional values.
  ///
  /// - Parameter transform: A closure that transforms a value. `transform`
  ///   accepts each value of the sparse set as its parameter and returns an
  ///   optional transformed value of the same or of a different type.
  ///
  /// - Returns: A sparse set containing the keys and non-`nil` transformed
  ///   values of this sparse set.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func compactMapValues<T>(
    _ transform: (Value) throws -> T?
  ) rethrows -> SparseSet<Key, T> {
    var result: SparseSet<Key, T> = [:]
    for (key, value) in self {
      if let value = try transform(value) {
        result._append(value: value, key: key)
      }
    }
    return result
  }
}

// MARK: -

extension SparseSet {
  /// When resizing or cloning the sparse data storage we can either: copy all
  /// of the data in the existing underlying buffer (including that of keys not
  /// in the set) to the new buffer; or initialize the new buffer using only the
  /// dense key data storage. The latter will be more efficient when the number
  /// of keys in the sparse set is small relative to the universe size. This
  /// constant is the density threshold which determines which strategy we use.
  @usableFromInline
  internal static var sparseDensityThresholdForCopyAll: Double { 0.1 }

  /// Ensures that the sparse data storage buffer is uniquely referenced,
  /// copying it if necessary.
  ///
  /// This function should be called whenever key data is mutated in a way that
  /// would make the sparse storage inconsistent with the keys in the dense
  /// storage.
  @inlinable
  internal mutating func _ensureUnique() {
    if !isKnownUniquelyReferenced(&__sparseBuffer) {
      let density = Double(_dense.count) / Double(_sparse.capacity)
      if density > SparseSet.sparseDensityThresholdForCopyAll {
        __sparseBuffer = .bufferWith(contentsOf: __sparseBuffer)
      } else {
        __sparseBuffer = .bufferWith(capacity: _sparse.capacity, keys: _dense._keys)
      }
    }
  }

  @inlinable
  internal mutating func _ensureUniverseContains(key: Key) {
    let minUniverseSize = Int(key) + 1
    if universeSize < minUniverseSize {
      var newUniverseSize = Swift.max(Int((1.5 * Double(universeSize)).rounded(.up)), minUniverseSize)
      if newUniverseSize - 1 > Int(Key.max) {
          newUniverseSize = Int(Key.max) + 1
      }
      _resizeUniverse(to: newUniverseSize)
    }
  }

  @inlinable
  internal mutating func _resizeUniverse(to newUniverseSize: Int) {
    let density = Double(_dense.count) / Double(_sparse.capacity)
    let copyAllThreshold = 0.1
    if density > copyAllThreshold {
      _sparse.resize(to: newUniverseSize)
    } else {
      _sparse.resize(to: newUniverseSize, keys: keys)
    }
  }
}

// MARK: -

extension SparseSet {
  @inlinable
  internal func _find(key: Key) -> Int? {
    guard key >= 0 && key < _sparse.capacity else {
      return nil
    }
    let index = _sparse[key]
    guard index >= 0 && index < _dense.count else {
      return nil
    }
    if _dense._keys[index] == key {
      return index
    }
    return nil
  }

  @inlinable
  internal mutating func _append(value: Value, key: Key) {
    defer { _checkInvariants() }
    _ensureUnique()
    _dense.append(value: value, key: key)
    _ensureUniverseContains(key: key)
    _sparse[key] = _dense.count - 1
  }

  @inlinable
  @discardableResult
  internal mutating func _remove(at index: Int) -> (key: Key, value: Value) {
    defer { _checkInvariants() }
    if index < _dense.count - 1 {
      _ensureUnique()
      let existingKey = _dense._keys[index]
      let existingValue = _dense._values[index]
      let (shiftedKey, shiftedValue) = _dense.removeLast()
      _dense._keys[index] = shiftedKey
      _dense._values[index] = shiftedValue
      _sparse[shiftedKey] = index
      return (existingKey, existingValue)
    } else {
      return _dense.removeLast()
    }
  }

  @inlinable
  internal mutating func _swapAt(_ i: Int, _ j: Int) {
    guard i != j else { return }
    defer { _checkInvariants() }
    _ensureUnique()
    _dense._values.swapAt(i, j)
    let keyA = _dense._keys[i]
    let keyB = _dense._keys[j]
    _dense._keys[i] = keyB
    _dense._keys[j] = keyA
    _sparse[keyA] = j
    _sparse[keyB] = i
  }
}
