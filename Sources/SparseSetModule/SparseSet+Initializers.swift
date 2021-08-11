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
  @inlinable
  public init(minimumCapacity: Int, universeSize: Int? = nil) {
    self._dense = DenseStorage(minimumCapacity: minimumCapacity)
    let sparse = SparseStorage(
      withCapacity: universeSize ?? minimumCapacity,
      keys: EmptyCollection<Key>())
    self.__sparseBuffer = sparse._buffer
  }

  @inlinable
  public init() {
    self.init(minimumCapacity: 0, universeSize: 0)
  }
}

extension SparseSet {
  /// Creates a new sparse set from the key-value pairs in the given sequence.
  ///
  /// You use this initializer to create a sparse set when you have a sequence
  /// of key-value tuples with unique keys. Passing a sequence with duplicate
  /// keys to this initializer results in a runtime error. If your sequence
  /// might have duplicate keys, use the `SparseSet(_:uniquingKeysWith:)`
  /// initializer instead.
  ///
  /// - Parameter keysAndValues: A sequence of key-value pairs to use for the
  ///   new sparse set. Every key in `keysAndValues` must be unique.
  ///
  /// - Returns: A new sparse set initialized with the elements of
  ///   `keysAndValues`.
  ///
  /// - Precondition: The sequence must not have duplicate keys.
  @inlinable
  public init<S: Sequence>(
    uniqueKeysWithValues keysAndValues: S
  ) where S.Element == (key: Key, value: Value) {
    if S.self == Dictionary<Key, Value>.self {
      self.init(_uncheckedUniqueKeysWithValues: keysAndValues)
      return
    }
    self.init(minimumCapacity: keysAndValues.underestimatedCount)
    for (key, value) in keysAndValues {
      guard _find(key: key) == nil else {
        preconditionFailure("Duplicate key: '\(key)'")
      }
      _append(value: value, key: key)
    }
    _checkInvariants()
  }

  /// Creates a new sparse set from the key-value pairs in the given sequence.
  ///
  /// You use this initializer to create a sparse set when you have a sequence
  /// of key-value tuples with unique keys. Passing a sequence with duplicate
  /// keys to this initializer results in a runtime error. If your
  /// sequence might have duplicate keys, use the
  /// `SparseSet(_:uniquingKeysWith:)` initializer instead.
  ///
  /// - Parameter keysAndValues: A sequence of key-value pairs to use for
  ///   the new sparse set. Every key in `keysAndValues` must be unique.
  ///
  /// - Returns: A new sparse set initialized with the elements of
  ///   `keysAndValues`.
  ///
  /// - Precondition: The sequence must not have duplicate keys.
  @inlinable
  public init<S: Sequence>(
    uniqueKeysWithValues keysAndValues: S
  ) where S.Element == (Key, Value) {
    self.init(minimumCapacity: keysAndValues.underestimatedCount)
    for (key, value) in keysAndValues {
      guard _find(key: key) == nil else {
        preconditionFailure("Duplicate key: '\(key)'")
      }
      _append(value: value, key: key)
    }
    _checkInvariants()
  }
}

extension SparseSet {
  /// Creates a new sparse set from separate sequences of keys and values.
  ///
  /// You use this initializer to create a sparse set when you have two
  /// sequences with unique keys and their associated values, respectively.
  /// Passing a `keys` sequence with duplicate keys to this initializer results
  /// in a runtime error.
  ///
  /// - Parameters:
  ///   - keys: A sequence of unique keys.
  ///   - values: A sequence of values associated with items in `keys`.
  ///
  /// - Returns: A new sparse set initialized with the data in `keys` and
  ///   `values`.
  ///
  /// - Precondition: The sequence must not have duplicate keys, and `keys` and
  ///   `values` must contain an equal number of elements.
  @inlinable
  public init<Keys: Sequence, Values: Sequence>(
    uniqueKeys keys: Keys,
    values: Values
  ) where Keys.Element == Key, Values.Element == Value {
    let keys = ContiguousArray(keys)
    let values = ContiguousArray(values)
    precondition(keys.count == values.count,
                 "Mismatching element counts between keys and values")
    self._dense = DenseStorage(_keys: keys, _values: values)
    let universeSize: Int = keys.max().map { Int($0) + 1 } ?? 0
    var sparse = SparseStorage(withCapacity: universeSize)
    for (i, key) in keys.enumerated() {
      let existingIndex = sparse[key]
      precondition(existingIndex < 0 || existingIndex >= i || keys[existingIndex] != key, "Duplicate key: '\(key)'")
      sparse[key] = i
    }
    __sparseBuffer = sparse._buffer
    _checkInvariants()
  }
}

extension SparseSet {
  /// Creates a new sparse set from the key-value pairs in the given sequence,
  /// using a combining closure to determine the value for any duplicate keys.
  ///
  /// You use this initializer to create a sparse set when you have a sequence
  /// of key-value tuples that might have duplicate keys. As the sparse set is
  /// built, the initializer calls the `combine` closure with the current and
  /// new values for any duplicate keys. Pass a closure as `combine` that
  /// returns the value to use in the resulting sparse set: The closure can
  /// choose between the two values, combine them to produce a new value, or
  /// even throw an error.
  ///
  /// - Parameters:
  ///   - keysAndValues: A sequence of key-value pairs to use for the new
  ///     sparse set.
  ///   - combine: A closure that is called with the values for any duplicate
  ///     keys that are encountered. The closure returns the desired value for
  ///     the final sparse set.
  @inlinable
  @inline(__always)
  public init<S: Sequence>(
    _ keysAndValues: S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == (key: Key, value: Value) {
    self.init()
    try self.merge(keysAndValues, uniquingKeysWith: combine)
  }

  /// Creates a new sparse set from the key-value pairs in the given sequence,
  /// using a combining closure to determine the value for any duplicate keys.
  ///
  /// You use this initializer to create a sparse set when you have a sequence
  /// of key-value tuples that might have duplicate keys. As the sparse set is
  /// built, the initializer calls the `combine` closure with the current and
  /// new values for any duplicate keys. Pass a closure as `combine` that
  /// returns the value to use in the resulting sparse set: The closure can
  /// choose between the two values, combine them to produce a new value, or
  /// even throw an error.
  ///
  /// - Parameters:
  ///   - keysAndValues: A sequence of key-value pairs to use for the new
  ///     sparse set.
  ///   - combine: A closure that is called with the values for any duplicate
  ///     keys that are encountered. The closure returns the desired value for
  ///     the final sparse set.
  @inlinable
  @inline(__always)
  public init<S: Sequence>(
    _ keysAndValues: S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == (Key, Value) {
    self.init()
    try self.merge(keysAndValues, uniquingKeysWith: combine)
  }
}

extension SparseSet {
  @inlinable
  internal init<S: Sequence>(
    _uncheckedUniqueKeysWithValues keysAndValues: S
  ) where S.Element == (key: Key, value: Value) {
    self.init(minimumCapacity: keysAndValues.underestimatedCount)
    for (key, value) in keysAndValues {
      _append(value: value, key: key)
    }
    _checkInvariants()
  }

  /// Creates a new sparse set from the key-value pairs in the given sequence,
  /// which must not contain duplicate keys.
  ///
  /// In optimized builds, this initializer does not verify that the keys are
  /// actually unique. This makes creating the sparse set somewhat faster if you
  /// know for sure that the elements are unique (e.g., because they come from
  /// another collection with guaranteed-unique members, such as a
  /// `Dictionary`). However, if you accidentally call this initializer with
  /// duplicate members, it can return a corrupt sparse set value that may be
  /// difficult to debug.
  ///
  /// - Parameter keysAndValues: A sequence of key-value pairs to use for
  ///   the new sparse set. Every key in `keysAndValues` must be unique.
  ///
  /// - Returns: A new sparse set initialized with the elements of
  ///   `keysAndValues`.
  ///
  /// - Precondition: The sequence must not have duplicate keys.
  @inlinable
  public init<S: Sequence>(
    uncheckedUniqueKeysWithValues keysAndValues: S
  ) where S.Element == (key: Key, value: Value) {
#if DEBUG
    self.init(uniqueKeysWithValues: keysAndValues)
#else
    self.init(_uncheckedUniqueKeysWithValues: keysAndValues)
#endif
  }

  /// Creates a new sparse set from the key-value pairs in the given sequence,
  /// which must not contain duplicate keys.
  ///
  /// In optimized builds, this initializer does not verify that the keys are
  /// actually unique. This makes creating the sparse set somewhat faster if you
  /// know for sure that the elements are unique (e.g., because they come from
  /// another collection with guaranteed-unique members, such as a
  /// `Dictionary`). However, if you accidentally call this initializer with
  /// duplicate members, it can return a corrupt sparse set value that may be
  /// difficult to debug.
  ///
  /// - Parameter keysAndValues: A sequence of key-value pairs to use for
  ///   the new sparse set. Every key in `keysAndValues` must be unique.
  ///
  /// - Returns: A new sparse set initialized with the elements of
  ///   `keysAndValues`.
  ///
  /// - Precondition: The sequence must not have duplicate keys.
  @inlinable
  public init<S: Sequence>(
    uncheckedUniqueKeysWithValues keysAndValues: S
  ) where S.Element == (Key, Value) {
    // Add tuple labels
    let keysAndValues = keysAndValues.lazy.map { (key: $0.0, value: $0.1) }
    self.init(uncheckedUniqueKeysWithValues: keysAndValues)
  }
}

extension SparseSet {
  @inlinable
  internal init<Keys: Sequence, Values: Sequence>(
    _uncheckedUniqueKeys keys: Keys,
    values: Values
  ) where Keys.Element == Key, Values.Element == Value {
    let keys = ContiguousArray(keys)
    let values = ContiguousArray(values)
    self._dense = DenseStorage(_keys: keys, _values: values)
    let sparse = SparseStorage(keys: keys)
    __sparseBuffer = sparse._buffer
    _checkInvariants()
  }

  /// Creates a new sparse set from separate sequences of unique keys and
  /// associated values.
  ///
  /// In optimized builds, this initializer does not verify that the keys are
  /// actually unique. This makes creating the sparse set somewhat faster if you
  /// know for sure that the elements are unique (e.g., because they come from
  /// another collection with guaranteed-unique members, such as a
  /// `Dictionary`). However, if you accidentally call this initializer with
  /// duplicate members, it can return a corrupt sparse set value that may be
  /// difficult to debug.
  ///
  /// - Parameters:
  ///   - keys: A sequence of unique keys.
  ///   - values: A sequence of values associated with items in `keys`.
  ///
  /// - Returns: A new sparse set initialized with the data in
  ///   `keys` and `values`.
  ///
  /// - Precondition: The sequence must not have duplicate keys, and `keys` and
  ///    `values` must contain an equal number of elements.
  @inlinable
  @inline(__always)
  public init<Keys: Sequence, Values: Sequence>(
    uncheckedUniqueKeys keys: Keys,
    values: Values
  ) where Keys.Element == Key, Values.Element == Value {
#if DEBUG
    self.init(uniqueKeys: keys, values: values)
#else
    self.init(_uncheckedUniqueKeys: keys, values: values)
#endif
  }
}
