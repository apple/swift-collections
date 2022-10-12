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

/// A collection which maintains key-value pairs in ascending sorted order.
///
/// A sorted dictionary is a type of tree, providing efficient read and write operations
/// to the entries it contains. Each entry in the sorted dictionary is identified using a
/// key, which is a comparable type such as a string or number. You can use that key
/// to retrieve the corresponding value.
public struct SortedDictionary<Key: Comparable, Value> {
  /// An element of the sorted dictionary. A key-value tuple.
  public typealias Element = (key: Key, value: Value)
  
  @usableFromInline
  internal typealias _Tree = _BTree<Key, Value>
  
  @usableFromInline
  internal var _root: _Tree
  
  /// Creates an empty dictionary.
  /// 
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public init() {
    self._root = _Tree()
  }
  
  /// Creates a dictionary rooted at a given BTree.
  @inlinable
  internal init(_rootedAt tree: _Tree) {
    self._root = tree
  }
}

// MARK: Accessing Keys and Values
extension SortedDictionary {
  /// A read-only collection view for the keys contained in this dictionary, as
  /// an `SortedSet`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var keys: Keys { Keys(_base: self) }
  
  /// A mutable collection view containing the values in this dictionary.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var values: Values {
    get {
      Values(_base: self)
    }
    
    _modify {
      let dummyDict = SortedDictionary(_rootedAt: _BTree.dummy)
      var values = Values(_base: dummyDict)
      swap(&self, &values._base)
      defer { self = values._base }
      yield &values
    }
  }
}

// MARK: Mutations
extension SortedDictionary {
  /// Ensures that the specified key exists in the dictionary (by appending one
  /// with the supplied default value if necessary), then calls `body` to update
  /// it in place.
  ///
  /// You can use this method to perform in-place operations on values in the
  /// dictionary, whether or not `Value` has value semantics. The following
  /// example uses this method while counting the occurrences of each letter
  /// in a string:
  ///
  ///     let message = "Hello, Elle!"
  ///     var letterCounts: SortedDictionary<Character, Int> = [:]
  ///     for letter in message {
  ///         letterCounts.modifyValue(forKey: letter, default: 0) { count in
  ///             count += 1
  ///         }
  ///     }
  ///     // letterCounts == ["H": 1, "e": 2, "l": 4, "o": 1, ...]
  ///
  /// - Parameters:
  ///   - key: The key to look up. If `key` does not already exist
  ///      in the dictionary, it is inserted with the supplied default value.
  ///   - defaultValue: The default value to append if `key` doesn't exist in
  ///      the dictionary.
  ///   - body: A function that performs an in-place mutation on the dictionary
  ///      value.
  ///
  /// - Returns: The return value of `body`.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  public mutating func modifyValue<R>(
    forKey key: Key,
    default defaultValue: @autoclosure () -> Value,
    _ body: (inout Value) throws -> R
  ) rethrows -> R {
    var (cursor, found) = self._root.takeCursor(forKey: key)
    let r: R
    
    if found {
      r = try cursor.updateCurrentNode { handle, slot in
        try body(&handle[valueAt: slot])
      }
    } else {
      var value = defaultValue()
      r = try body(&value)
      cursor.insertElement((key, value), capacity: self._root.internalCapacity)
    }
    
    cursor.apply(to: &self._root)
    
    return r
  }
  
  
  /// Updates the value stored in the dictionary for the given key, or
  /// adds a new key-value pair if the key does not exist.
  ///
  /// Use this method instead of key-based subscripting when you need to
  /// know whether the new value supplants the value of an existing key. If
  /// the value of an existing key is updated, `updateValue(_:forKey:)`
  /// returns the original value.
  /// 
  /// - Parameters:
  ///   - value: The new value to add to the dictionary.
  ///   - key: The key to associate with value. If key already exists in the
  ///       dictionary, value replaces the existing associated value. If key
  ///       isn’t already a key of the dictionary, the `(key, value)` pair
  ///       is added.
  /// - Returns: The value that was replaced, or nil if a new key-value
  ///     pair was added.
  /// - Complexity: O(`log n`) where `n` is the number of key-value pairs in the
  ///   dictionary.
  @inlinable
  @discardableResult
  public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
    self._root.updateAnyValue(value, forKey: key)?.value
  }
}

// MARK: Removing Keys and Values
extension SortedDictionary {
  /// Removes the given key and its associated value from the sorted dictionary.
  ///
  /// Calling this method invalidates any existing indices for use with this sorted dictionary.
  ///
  /// - Parameter key: The key to remove along with its associated value.
  /// - Returns: The value that was removed, or `nil` if the key was not present
  ///     in the dictionary.
  /// - Complexity: O(`log n`) where `n` is the number of key-value pairs in the
  ///   dictionary.
  @inlinable
  @inline(__always)
  public mutating func removeValue(forKey key: Key) -> Value? {
    return self._root.removeAnyElement(forKey: key)?.value
  }
}

// MARK: Transforming a Dictionary
extension SortedDictionary {
  /// Returns a new dictionary containing the keys of this dictionary with the values
  /// transformed by the given closure.
  ///
  /// - Parameter transform: A closure that transforms a value. transform accepts
  ///     each value of the dictionary in order as its parameter and returns a transformed
  ///     value of the same or of a different type.
  /// - Returns: A sorted dictionary containing the keys and transformed values of
  ///     this dictionary.
  /// - Complexity: O(`n`)
  @inlinable
  @inline(__always)
  public func mapValues<T>(
    _ transform: (Value) throws -> T
  ) rethrows -> SortedDictionary<Key, T> {
    let tree = try self._root.mapValues(transform)
    return SortedDictionary<Key, T>(_rootedAt: tree)
  }
  
  /// Returns a new dictionary containing only the key-value pairs that have non-nil values
  /// as the result of transformation by the given closure.
  ///
  /// Use this method to receive a dictionary with non-optional values when your transformation
  /// produces optional values.
  ///
  /// - Parameter transform: A closure that transforms a value. `transform` accepts
  ///     each value of the dictionary as its parameter and returns an optional transformed
  ///     value of the same or of a different type.
  /// - Returns: A sorted dictionary containing the keys and non-nil transformed values
  ///     of this dictionary.
  /// - Complexity: O(`n`)
  func compactMapValues<T>(
    _ transform: (Value) throws -> T?
  ) rethrows -> SortedDictionary<Key, T> {
    // TODO: Optimize to reuse dictionary structure.
    // TODO: optimize to use identify fastest iteration method
    // TODO: optimize CoW checks
    var builder = _BTree<Key, T>.Builder()
    
    for (key, value) in self {
      if let newValue = try transform(value) {
        builder.append((key, newValue))
      }
    }
    
    return SortedDictionary<Key, T>(_rootedAt: builder.finish())
  }
}
