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

extension OrderedDictionary {
  /// Returns the index for the given key.
  ///
  /// If the given key is found in the dictionary, this method returns an index
  /// into the dictionary that corresponds with the key-value pair.
  ///
  ///     let countryCodes: OrderedDictionary = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
  ///     let index = countryCodes.index(forKey: "JP")
  ///
  ///     print("Country code for \(countryCodes[offset: index!].value): '\(countryCodes[offset: index!].key)'.")
  ///     // Prints "Country code for Japan: 'JP'."
  ///
  /// - Parameter key: The key to find in the dictionary.
  ///
  /// - Returns: The index for `key` and its associated value if `key` is in
  ///    the dictionary; otherwise, `nil`.
  ///
  /// - Complexity: Expected to be O(1) on average, if `Key` implements
  ///    high-quality hashing.
  @available(*, deprecated, renamed: "keys.firstIndex(of:)")
  @inlinable
  @inline(__always)
  public func index(forKey key: Key) -> Int? {
    _keys.firstIndex(of: key)
  }
}

extension OrderedDictionary.Elements {
  /// Returns the index for the given key.
  ///
  /// If the given key is found in the dictionary, this method returns an index
  /// into the dictionary that corresponds with the key-value pair.
  ///
  ///     let countryCodes: OrderedDictionary = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
  ///     let index = countryCodes.elements.index(forKey: "JP")
  ///
  ///     print("Country code for \(countryCodes[offset: index!].value): '\(countryCodes[offset: index!].key)'.")
  ///     // Prints "Country code for Japan: 'JP'."
  ///
  /// - Parameter key: The key to find in the dictionary.
  ///
  /// - Returns: The index for `key` and its associated value if `key` is in
  ///    the dictionary; otherwise, `nil`.
  ///
  /// - Complexity: Expected to be O(1) on average, if `Key` implements
  ///    high-quality hashing.
  @available(*, deprecated, renamed: "keys.firstIndex(of:)")
  @inlinable
  public func index(forKey key: Key) -> Int? {
    _base._keys.firstIndex(of: key)
  }
}

extension OrderedDictionary.Elements.SubSequence {
  /// Returns the index for the given key.
  ///
  /// If the given key is found in the dictionary slice, this method returns an
  /// index into the dictionary that corresponds with the key-value pair.
  ///
  ///     let countryCodes: OrderedDictionary = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
  ///     let slice = countryCodes.elements[1...]
  ///     let index = slice.index(forKey: "JP")
  ///
  ///     print("Country code for \(countryCodes[offset: index!].value): '\(countryCodes[offset: index!].key)'.")
  ///     // Prints "Country code for Japan: 'JP'."
  ///
  /// - Parameter key: The key to find in the dictionary slice.
  ///
  /// - Returns: The index for `key` and its associated value if `key` is in
  ///    the dictionary slice; otherwise, `nil`.
  ///
  /// - Complexity: Expected to be O(1) on average, if `Key` implements
  ///    high-quality hashing.
  @available(*, deprecated, renamed: "keys.firstIndex(of:)")
  @inlinable
  public func index(forKey key: Key) -> Int? {
    guard let index = _base.keys.firstIndex(of: key) else { return nil }
    guard _bounds.contains(index) else { return nil }
    return index
  }
}


extension OrderedDictionary {
  /// Accesses the element at the specified index. This can be used to
  /// perform in-place mutations on dictionary values.
  ///
  /// - Parameter offset: The offset of the element to access, measured from
  ///   the start of the collection. `offset` must be greater than or equal to
  ///   `0` and less than `count`.
  ///
  /// - Complexity: O(1)
  @available(*, deprecated, message: "Please use `elements[offset]`")
  @inlinable
  @inline(__always)
  public subscript(offset offset: Int) -> Element {
    (_keys[offset], _values[offset])
  }
}

extension OrderedDictionary {
  @available(*, deprecated, renamed: "updateValue(forKey:default:with:)")
  @inlinable
  public mutating func modifyValue<R>(
    forKey key: Key,
    default defaultValue: @autoclosure () -> Value,
    _ body: (inout Value) throws -> R
  ) rethrows -> R {
    try self.updateValue(forKey: key, default: defaultValue(), with: body)
  }

  @available(*, deprecated, renamed: "updateValue(forKey:insertingDefault:at:with:)")
  @inlinable
  public mutating func modifyValue<R>(
    forKey key: Key,
    insertingDefault defaultValue: @autoclosure () -> Value,
    at index: Int,
    _ body: (inout Value) throws -> R
  ) rethrows -> R {
    try self.updateValue(
      forKey: key,
      insertingDefault: defaultValue(),
      at: index,
      with: body)
  }
}
