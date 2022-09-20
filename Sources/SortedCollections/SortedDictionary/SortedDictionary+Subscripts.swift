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

extension SortedDictionary {
  /// Accesses the value associated with the key for both read and write operations
  ///
  /// This key-based subscript returns the value for the given key if the key is found in
  /// the dictionary, or nil if the key is not found.
  ///
  /// When you assign a value for a key and that key already exists, the dictionary overwrites
  /// the existing value. If the dictionary doesn’t contain the key, the key and value are added
  /// as a new key-value pair.
  ///
  /// - Parameter key: The key to find in the dictionary.
  /// - Returns: The value associated with key if key is in the dictionary; otherwise, nil.
  /// - Complexity: O(`log n`)
  @inlinable
  @inline(__always)
  public subscript(key: Key) -> Value? {
    get {
      return self._root.findAnyValue(forKey: key)
    }
    
    _modify {
      var (cursor, found) = self._root.takeCursor(forKey: key)
      
      var value: Value?
      if found {
        value = cursor.moveValue()
      }
      
      defer {
        if found {
          if let value = value {
            cursor.initializeValue(to: value)
          } else {
            cursor.removeElement(hasValueHole: true)
          }
        } else {
          if let value = value {
            cursor.insertElement(
              (key, value),
              capacity: self._root.internalCapacity
            )
          } else {
            // no-op
          }
        }
        
        cursor.apply(to: &self._root)
      }
      
      yield &value
    }
    
    set {
      if let newValue = newValue {
        self._root.updateAnyValue(newValue, forKey: key)
      } else {
        self._root.removeAnyElement(forKey: key)
      }
    }
  }
  
  /// Accesses the value with the given key. If the dictionary doesn’t contain the given
  /// key, accesses the provided default value as if the key and default value existed
  /// in the dictionary.
  ///
  /// Use this subscript when you want either the value for a particular key or, when that
  /// key is not present in the dictionary, a default value.
  ///
  /// - Parameters:
  ///   - key: The key the look up in the dictionary.
  ///   - defaultValue: The default value to use if key doesn’t exist in the dictionary.
  /// - Returns: The value associated with key in the dictionary; otherwise, defaultValue.
  /// - Complexity: O(`log n`)
  @inlinable
  @inline(__always)
  public subscript(
    key: Key,
    default defaultValue: @autoclosure () -> Value
  ) -> Value {
    get {
      return self[key] ?? defaultValue()
    }
    
    set {
      self[key] = newValue
    }
    
    _modify {
      var (cursor, found) = self._root.takeCursor(forKey: key)
      
      var value: Value
      if found {
        value = cursor.moveValue()
      } else {
        value = defaultValue()
      }
      
      defer {
        if found {
          cursor.initializeValue(to: value)
        } else {
          cursor.insertElement(
            (key, value),
            capacity: self._root.internalCapacity
          )
        }
        
        cursor.apply(to: &self._root)
      }
      
      yield &value
    }

  }
  
  /// Accesses the key-value pair at the specified position.
  ///
  /// This subscript takes an index into the sorted dictionary, instead of a key, and
  /// returns the corresponding key-value pair as a tuple. When performing
  /// collection-based operations that return an index into a dictionary, use this
  /// subscript with the resulting value.
  ///
  /// For example, to find the key for a particular value in a sorted dictionary, use
  /// the `firstIndex(where:)` method.
  ///
  ///     let countryCodes: SortedDictionary<Int, Int> = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
  ///     if let index = countryCodes.firstIndex(where: { $0.value == "Japan" }) {
  ///         print(countryCodes[index])
  ///         print("Japan's country code is '\(countryCodes[index].key)'.")
  ///     } else {
  ///         print("Didn't find 'Japan' as a value in the dictionary.")
  ///     }
  ///     // Prints "(key: "JP", value: "Japan")"
  ///     // Prints "Japan's country code is 'JP'."
  ///
  /// - Parameter position: The position of the key-value pair to access.
  ///     `position` must be a valid index of the sorted dictionary and not equal
  ///     to `endIndex`.
  /// - Returns: A two-element tuple with the key and value corresponding to
  ///     `position`.
  /// - Complexity: O(1)
  @inlinable
  public subscript(position: Index) -> Element {
    get {
      position._index.ensureValid(forTree: self._root)
      return self._root[position._index]
    }
  }
  
  /// Accesses a contiguous subrange of the collection's elements.
  ///
  /// - Parameter bounds: A range of the collection's indices. The bounds of
  ///   the range must be valid indices of the collection.
  ///
  /// - Complexity: O(1)
  @inlinable
  public subscript(bounds: Range<Index>) -> SubSequence {
    bounds.lowerBound._index.ensureValid(forTree: _root)
    bounds.upperBound._index.ensureValid(forTree: _root)
    
    let bound = bounds.lowerBound._index..<bounds.upperBound._index
    
    return SubSequence(_root[bound])
  }
}
