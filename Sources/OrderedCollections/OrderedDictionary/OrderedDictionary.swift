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

/// An ordered collection of key-value pairs.
///
/// Like the standard `Dictionary`, ordered dictionaries use a hash table to
/// ensure that no two entries have the same keys, and to efficiently look up
/// values corresponding to specific keys. However, like an `Array` (and
/// unlike `Dictionary`), ordered dictionaries maintain their elements in a
/// particular user-specified order, and they support efficient random-access
/// traversal of their entries.
///
/// `OrderedDictionary` is a useful alternative to `Dictionary` when the order
/// of elements is important, or when you need to be able to efficiently access
/// elements at various positions within the collection.
///
/// You can create an ordered dictionary with any key type that conforms to the
/// `Hashable` protocol.
///
///     let responses: OrderedDictionary = [
///       200: "OK",
///       403: "Access forbidden",
///       404: "File not found",
///       500: "Internal server error",
///     ]
///
/// ### Equality of Ordered Dictionaries
///
/// Two ordered dictionaries are considered equal if they contain the same
/// elements, and *in the same order*. This matches the concept of equality of
/// an `Array`, and it is different from the unordered `Dictionary`.
///
///     let a: OrderedDictionary = [1: "one", 2: "two"]
///     let b: OrderedDictionary = [2: "two", 1: "one"]
///     a == b // false
///     b.swapAt(0, 1) // `b` now has value [1: "one", 2: "two"]
///     a == b // true
///
/// (`OrderedDictionary` only conforms to `Equatable` when its `Value` is
/// equatable.)
///
/// ### Dictionary Operations
///
/// `OrderedDictionary` provides many of the same operations as `Dictionary`.
///
/// For example, you can look up and add/remove values using the familiar
/// key-based subscript, returning an optional value:
///
///     var dictionary: OrderedDictionary<String, Int> = [:]
///     dictionary["one"] = 1
///     dictionary["two"] = 2
///     dictionary["three"] // nil
///     // dictionary is now ["one": 1, "two": 2]
///
/// If a new entry is added using the subscript setter, it gets appended to the
/// end of the dictionary. (So that by default, the dictionary contains its
/// elements in the order they were originally inserted.)
///
/// `OrderedDictionary` also implements the variant of this subscript that takes
/// a default value. Like with `Dictionary`, this is useful when you want to
/// perform in-place mutations on values:
///
///     let text = "short string"
///     var counts: OrderedDictionary<Character, Int> = [:]
///     for character in text {
///       counts[character, default: 0] += 1
///     }
///     // counts is ["s": 2, "h": 1, "o": 1,
///     //            "r": 2, "t": 2, " ": 1,
///     //            "i": 1, "n": 1, "g": 1]
///
/// If the `Value` type implements reference semantics, or when you need to
/// perform a series of individual mutations on the values, the closure-based
/// `modifyValue(forKey:default:_:)` method provides an easier-to-use
/// alternative to the defaulted key-based subscript.
///
///     let text = "short string"
///     var counts: OrderedDictionary<Character, Int> = [:]
///     for character in text {
///       counts.modifyValue(forKey: character, default: 0) { value in
///         value += 1
///       }
///     }
///     // Same result as before
///
/// (This isn't currently available on the regular `Dictionary`.)
///
/// The `Dictionary` type's original `updateValue(_:forKey:)` method is also
/// available, and so is `index(forKey:)`, grouping/uniquing initializers
/// (`init(uniqueKeysWithValues:)`, `init(_:uniquingKeysWith:)`,
/// `init(grouping:by:)`), methods for merging one dictionary with another
/// (`merge`, `merging`), filtering dictionary entries (`filter(_:)`),
/// transforming values (`mapValues(_:)`), and a combination of these two
/// (`compactMapValues(_:)`).
///
/// ### Sequence and Collection Operations
///
/// Ordered dictionaries use integer indices representing offsets from the
/// beginning of the collection. However, to avoid ambiguity between key-based
/// and indexing subscripts, `OrderedDictionary` doesn't directly conform to
/// `Collection`. Instead, it only conforms to `Sequence`, and provides a
/// random-access collection view over its key-value pairs:
///
///     responses[0] // `nil` (key-based subscript)
///     responses.elements[0] // `(200, "OK")` (index-based subscript)
///
/// Because ordered dictionaries need to maintain unique keys, neither
/// `OrderedDictionary` nor its `elements` view can conform to the full
/// `MutableCollection` or `RangeReplaceableCollection` protocols. However, they
/// are able to partially implement requirements: they support mutations
/// that merely change the order of elements, or just remove a subset of
/// existing members:
///
///     // Permutation operations from MutableCollection:
///     func swapAt(_ i: Int, _ j: Int)
///     func partition(by predicate: (Element) throws -> Bool) -> rethrows Int
///     func sort() where Element: Comparable
///     func sort(by predicate: (Element, Element) throws -> Bool) rethrows
///     func shuffle()
///     func shuffle<T: RandomNumberGenerator>(using generator: inout T)
///
///     // Removal operations from RangeReplaceableCollection:
///     func removeAll(keepingCapacity: Bool = false)
///     func remove(at index: Int) -> Element
///     func removeSubrange(_ bounds: Range<Int>)
///     func removeLast() -> Element
///     func removeLast(_ n: Int)
///     func removeFirst() -> Element
///     func removeFirst(_ n: Int)
///     func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows
///
/// `OrderedDictionary` also implements `reserveCapacity(_)` from
/// `RangeReplaceableCollection`, to allow for efficient insertion of a known
/// number of elements. (However, unlike `Array` and `Dictionary`,
/// `OrderedDictionary` does not provide a `capacity` property.)
///
/// ### Keys and Values Views
///
/// Like the standard `Dictionary`, `OrderedDictionary` provides `keys` and
/// `values` properties that provide lightweight views into the corresponding
/// parts of the dictionary.
///
/// The `keys` collection is of type `OrderedSet<Key>`, containing all the keys
/// in the original dictionary.
///
///     let d: OrderedDictionary = [2: "two", 1: "one", 0: "zero"]
///     d.keys // [2, 1, 0] as OrderedSet<Int>
///
/// The `keys` property is read-only, so you cannot mutate the dictionary
/// through it. However, it returns an ordinary ordered set value, which can be
/// copied out and then mutated if desired. (Such mutations won't affect the
/// original dictionary value.)
///
/// The `values` collection is a mutable random-access collection of the values
/// in the dictionary:
///
///     d.values // "two", "one", "zero"
///     d.values[2] = "nada"
///     // `d` is now [2: "two", 1: "one", 0: "nada"]
///     d.values.sort()
///     // `d` is now [2: "nada", 1: "one", 0: "two"]
///
/// Both views store their contents in regular `Array` values, accessible
/// through their `elements` property.
///
/// ## Performance
///
/// Like the standard `Dictionary` type, the performance of hashing operations
/// in `OrderedDictionary` is highly sensitive to the quality of hashing
/// implemented by the `Key` type. Failing to correctly implement hashing can
/// easily lead to unacceptable performance, with the severity of the effect
/// increasing with the size of the hash table.
///
/// In particular, if a certain set of keys all produce the same hash value,
/// then hash table lookups regress to searching an element in an unsorted
/// array, i.e., a linear operation. To ensure hashed collection types exhibit
/// their target performance, it is important to ensure that such collisions
/// cannot be induced merely by adding a particular list of keys to the
/// dictionary.
///
/// The easiest way to achieve this is to make sure `Key` implements hashing
/// following `Hashable`'s documented best practices. The conformance must
/// implement the `hash(into:)` requirement, and every bit of information that
/// is compared in `==` needs to be combined into the supplied `Hasher` value.
/// When used correctly, `Hasher` produces high-quality, randomly seeded hash
/// values that prevent repeatable hash collisions.
///
/// When `Key` correctly conforms to `Hashable`, key-based lookups in an ordered
/// dictionary is expected to take O(1) equality checks on average. Hash
/// collisions can still occur organically, so the worst-case lookup performance
/// is technically still O(*n*) (where *n* is the size of the dictionary);
/// however, long lookup chains are unlikely to occur in practice.
///
/// ## Implementation Details
///
/// An ordered dictionary consists of an ordered set of keys, alongside a
/// regular `Array` value that contains their associated values.
@frozen
public struct OrderedDictionary<Key: Hashable, Value> {
  @usableFromInline
  internal var _keys: OrderedSet<Key>

  @usableFromInline
  internal var _values: ContiguousArray<Value>

  @inlinable
  @inline(__always)
  internal init(
    _uniqueKeys keys: OrderedSet<Key>,
    values: ContiguousArray<Value>
  ) {
    self._keys = keys
    self._values = values
  }
}

extension OrderedDictionary {
  /// A read-only collection view for the keys contained in this dictionary, as
  /// an `OrderedSet`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var keys: OrderedSet<Key> { _keys }

  /// A mutable collection view containing the values in this dictionary.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var values: Values {
    get { Values(_base: self) }
    _modify {
      var values = Values(_base: self)
      self = [:]
      defer { self = values._base }
      yield &values
    }
  }
}

extension OrderedDictionary {
  public typealias Index = Int

  /// A Boolean value indicating whether the dictionary is empty.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { _values.isEmpty }

  /// The number of elements in the dictionary.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var count: Int { _values.count }

  /// Returns the index for the given key.
  ///
  /// If the given key is found in the dictionary, this method returns an index
  /// into the dictionary that corresponds with the key-value pair.
  ///
  ///     let countryCodes: OrderedDictionary = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
  ///     let index = countryCodes.index(forKey: "JP")
  ///
  ///     print("Country code for \(countryCodes[index!].value): '\(countryCodes[index!].key)'.")
  ///     // Prints "Country code for Japan: 'JP'."
  ///
  /// - Parameter key: The key to find in the dictionary.
  ///
  /// - Returns: The index for `key` and its associated value if `key` is in
  ///    the dictionary; otherwise, `nil`.
  ///
  /// - Complexity: Expected to be O(1) on average, if `Key` implements
  ///    high-quality hashing.
  @inlinable
  @inline(__always)
  public func index(forKey key: Key) -> Int? {
    _keys.firstIndex(of: key)
  }

  /// Accesses the element at the specified index. This can be used to
  /// perform in-place mutations on dictionary values.
  ///
  /// - Parameter offset: The offset of the element to access, measured from
  ///   the start of the collection. `offset` must be greater than or equal to
  ///   `0` and less than `count`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public subscript(offset offset: Int) -> Element {
    (_keys[offset], _values[offset])
  }
}

extension OrderedDictionary {
  /// Accesses the value associated with the given key for reading and writing.
  ///
  /// This *key-based* subscript returns the value for the given key if the key
  /// is found in the dictionary, or `nil` if the key is not found.
  ///
  /// The following example creates a new dictionary and prints the value of a
  /// key found in the dictionary (`"Coral"`) and a key not found in the
  /// dictionary (`"Cerise"`).
  ///
  ///     var hues: OrderedDictionary = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
  ///     print(hues["Coral"])
  ///     // Prints "Optional(16)"
  ///     print(hues["Cerise"])
  ///     // Prints "nil"
  ///
  /// When you assign a value for a key and that key already exists, the
  /// dictionary overwrites the existing value. If the dictionary doesn't
  /// contain the key, the key and value are added as a new key-value pair.
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
  /// removes that key and its associated value.
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
  /// - Complexity: Looking up values in the dictionary through this subscript
  ///    has an expected complexity of O(1) hashing/comparison operations on
  ///    average, if `Key` implements high-quality hashing. Updating the
  ///    dictionary also has an amortized expected complexity of O(1) --
  ///    although individual updates may need to copy or resize the dictionary's
  ///    underlying storage.
  @inlinable
  public subscript(key: Key) -> Value? {
    get {
      guard let index = _keys.firstIndex(of: key) else { return nil }
      return _values[index]
    }
    set {
      // We have a separate `set` in addition to `_modify` in hopes of getting
      // rid of `_modify`'s swapAt dance in the usua case where the calle just
      // wants to assign a new value.
      let (index, bucket) = _keys._find(key)
      switch (index, newValue) {
      case let (index?, newValue?): // Assign
        _values[index] = newValue
      case let (index?, nil): // Remove
        _keys._removeExistingMember(at: index, in: bucket)
        _values.remove(at: index)
      case let (nil, newValue?): // Insert
        _keys._appendNew(key, in: bucket)
        _values.append(newValue)
      case (nil, nil): // Noop
        break
      }
    }
    _modify {
      let (index, bucket) = _keys._find(key)

      // To support in-place mutations better, we swap the value to the end of
      // the array, pop it off, then put things back in place when we're done.
      var value: Value? = nil
      if let index = index {
        _values.swapAt(index, _values.count - 1)
        value = _values.removeLast()
      }

      defer {
        switch (index, value) {
        case let (index?, value?): // Assign
          _values.append(value)
          _values.swapAt(index, _values.count - 1)
        case let (index?, nil): // Remove
          if index < _values.count {
            let standin = _values.remove(at: index)
            _values.append(standin)
          }
          _keys._removeExistingMember(at: index, in: bucket)
        case let (nil, value?): // Insert
          _keys._appendNew(key, in: bucket)
          _values.append(value)
        case (nil, nil): // Noop
          break
        }
      }

      yield &value
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
  ///     var responseMessages: OrderedDictionary = [
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
  ///     var letterCounts: [Character: Int] = [:]
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
  /// - Complexity: Looking up values in the dictionary through this subscript
  ///    has an expected complexity of O(1) hashing/comparison operations on
  ///    average, if `Key` implements high-quality hashing. Updating the
  ///    dictionary also has an amortized expected complexity of O(1) --
  ///    although individual updates may need to copy or resize the dictionary's
  ///    underlying storage.
  @inlinable
  public subscript(
    key: Key,
    default defaultValue: @autoclosure () -> Value
  ) -> Value {
    get {
      guard let offset = _keys.firstIndex(of: key) else { return defaultValue() }
      return _values[offset]
    }
    _modify {
      let (inserted, index) = _keys.append(key)
      if inserted {
        assert(index == _values.count)
        _values.append(defaultValue())
      }
      var value: Value = _values.withUnsafeMutableBufferPointer { buffer in
        assert(index < buffer.count)
        return (buffer.baseAddress! + index).move()
      }
      defer {
        _values.withUnsafeMutableBufferPointer { buffer in
          assert(index < buffer.count)
          (buffer.baseAddress! + index).initialize(to: value)
        }
      }
      yield &value
    }
  }

}

extension OrderedDictionary {
  /// Updates the value stored in the dictionary for the given key, or appends a
  /// new key-value pair if the key does not exist.
  ///
  /// Use this method instead of key-based subscripting when you need to know
  /// whether the new value supplants the value of an existing key. If the
  /// value of an existing key is updated, `updateValue(_:forKey:)` returns
  /// the original value.
  ///
  ///     var hues: OrderedDictionary = [
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
  /// - Complexity: expected complexity is amortized O(1), if `Key` implements
  ///    high-quality hashing.
  @inlinable
  @discardableResult
  public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
    let (index, bucket) = _keys._find(key)
    if let index = index {
      let old = _values[index]
      _values[index] = value
      return old
    }
    _keys._appendNew(key, in: bucket)
    _values.append(value)
    return nil
  }

  /// Updates the value stored in the dictionary for the given key, or inserts a
  /// new key-value pair at the specified index if the key does not exist.
  ///
  /// Use this method instead of key-based subscripting when you need to insert
  /// new keys at a particular index. You can use the return value to
  /// determine whether or not the new value supplanted the value of an existing
  /// key.
  ///
  /// If the value of an existing key is updated,
  /// `updateValue(_:forKey:insertingAt:)` returns the original value and its
  /// index.
  ///
  ///     var hues: OrderedDictionary = [
  ///         "Heliotrope": 296,
  ///         "Coral": 16,
  ///         "Aquamarine": 156]
  ///     let newIndex = hues.startIndex
  ///     let (old, index) =
  ///         hues.updateValue(18, forKey: "Coral", insertingAt: newIndex)
  ///     if let old = old {
  ///         print("The value '\(old)' at offset \(index.offset) was replaced.")
  ///     }
  ///     // Prints "The value '16' at offset 1 was replaced."
  ///
  /// If the given key is not present in the dictionary, this method inserts the
  /// key-value pair at the specified index and returns `nil`.
  ///
  ///     let (old, index) =
  ///         hues.updateValue(330, forKey: "Cerise", insertingAt: newIndex)
  ///     if let old = old {
  ///         print("The value '\(old)' at offset \(index.offset) was replaced.")
  ///     } else {
  ///         print("A new value was inserted at offset \(index.offset).")
  ///     }
  ///     // Prints "A new value was inserted at offset 0.")
  ///
  /// - Parameters:
  ///   - value: The new value to add to the dictionary.
  ///   - key: The key to associate with `value`. If `key` already exists in
  ///      the dictionary, `value` replaces the existing associated value. If
  ///      `key` isn't already a key of the dictionary, the `(key, value)` pair
  ///      is inserted.
  ///   - index: The index at which to insert the key, if it doesn't already
  ///      exist.
  ///
  /// - Returns: A pair `(old, index)`, where `old` is the value that was
  ///    replaced, or `nil` if a new key-value pair was added, and `index`
  ///    is the index corresponding to the updated (or inserted) value.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  @discardableResult
  public mutating func updateValue(
    _ value: Value,
    forKey key: Key,
    insertingAt index: Int
  ) -> (originalMember: Value?, index: Int) {
    let (inserted, offset) = _keys.insert(key, at: index)
    if inserted {
      assert(offset == index)
      _values.insert(value, at: offset)
      return (nil, offset)
    }
    let old = _values[offset]
    _values[offset] = value
    return (old, offset)
  }

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
  ///     var letterCounts: [Character: Int] = [:]
  ///     for letter in message {
  ///         letterCounts.modifyValue(forKey: letter, default: 0) { count in
  ///             count += 1
  ///         }
  ///     }
  ///     // letterCounts == ["H": 1, "e": 2, "l": 4, "o": 1, ...]
  ///
  /// - Parameters:
  ///   - key: The key to look up (or append). If `key` does not already exist
  ///      in the dictionary, it is appended with the supplied default value.
  ///   - defaultValue: The default value to append if `key` doesn't exist in
  ///      the dictionary.
  ///   - body: A function that performs an in-place mutation on the dictionary
  ///      value.
  ///
  /// - Returns: The return value of `body`.
  ///
  /// - Complexity: expected complexity is amortized O(1), if `Key` implements
  ///    high-quality hashing. (Ignoring the complexity of calling `body`.)
  @inlinable
  public mutating func modifyValue<R>(
    forKey key: Key,
    default defaultValue: @autoclosure () -> Value,
    _ body: (inout Value) throws -> R
  ) rethrows -> R {
    let (index, bucket) = _keys._find(key)
    if let index = index {
      return try body(&_values[index])
    }
    _keys._appendNew(key, in: bucket)
    _values.append(defaultValue())
    let i = _values.index(before: _values.endIndex)
    return try body(&_values[i])
  }

  /// Ensures that the specified key exists in the dictionary (by inserting one
  /// with the specified index and default value if necessary), then calls
  /// `body` to update it in place.
  ///
  /// You can use this method to perform in-place operations on values in the
  /// dictionary, whether or not `Value` has value semantics. The following
  /// example uses this method while counting the occurrences of each letter
  /// in a string:
  ///
  ///     let message = "Hello, Elle!"
  ///     var letterCounts: [Character: Int] = [:]
  ///     for letter in message {
  ///         letterCounts.modifyValue(forKey: letter, default: 0) { count in
  ///             count += 1
  ///         }
  ///     }
  ///     // letterCounts == ["H": 1, "e": 2, "l": 4, "o": 1, ...]
  ///
  /// - Parameters:
  ///   - key: The key to look up (or append). If `key` does not already exist
  ///      in the dictionary, it is appended with the supplied default value.
  ///   - defaultValue: The default value to append if `key` doesn't exist in
  ///      the dictionary.
  ///   - body: A function that performs an in-place mutation on the dictionary
  ///      value.
  ///
  /// - Returns: The return value of `body`.
  ///
  /// - Complexity: expected complexity is amortized O(1), if `Key` implements
  ///    high-quality hashing. (Ignoring the complexity of calling `body`.)
  @inlinable
  public mutating func modifyValue<R>(
    forKey key: Key,
    insertingDefault defaultValue: @autoclosure () -> Value,
    at index: Int,
    _ body: (inout Value) throws -> R
  ) rethrows -> R {
    let (existingIndex, bucket) = _keys._find(key)
    if let existingIndex = existingIndex {
      return try body(&_values[existingIndex])
    }
    _keys._insertNew(key, at: index, in: bucket)
    _values.insert(defaultValue(), at: index)
    return try body(&_values[index])
  }
}

extension OrderedDictionary {
  /// Removes the given key and its associated value from the dictionary.
  ///
  /// If the key is found in the dictionary, this method returns the key's
  /// associated value.
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
  /// `nil`.
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
  /// - Complexity: O(`count`)
  @inlinable
  @discardableResult
  public mutating func removeValue(forKey key: Key) -> Value? {
    let (idx, bucket) = _keys._find(key)
    guard let index = idx else { return nil }
    _keys._removeExistingMember(at: index, in: bucket)
    return _values.remove(at: index)
  }
}

extension OrderedDictionary {
  /// Merges the key-value pairs in the given sequence into the dictionary,
  /// using a combining closure to determine the value for any duplicate keys.
  ///
  /// Use the `combine` closure to select a value to use in the updated
  /// dictionary, or to combine existing and new values. As the key-value
  /// pairs are merged with the dictionary, the `combine` closure is called
  /// with the current and new values for any duplicate keys that are
  /// encountered.
  ///
  /// This example shows how to choose the current or new values for any
  /// duplicate keys:
  ///
  ///     var dictionary: OrderedDictionary = ["a": 1, "b": 2]
  ///
  ///     // Keeping existing value for key "a":
  ///     dictionary.merge(zip(["a", "c"], [3, 4])) { (current, _) in current }
  ///     // ["b": 2, "a": 1, "c": 4]
  ///
  ///     // Taking the new value for key "a":
  ///     dictionary.merge(zip(["a", "d"], [5, 6])) { (_, new) in new }
  ///     // ["b": 2, "a": 5, "c": 4, "d": 6]
  ///
  /// - Parameters:
  ///   - other: A sequence of key-value pairs.
  ///   - combine: A closure that takes the current and new values for any
  ///     duplicate keys. The closure returns the desired value for the final
  ///     dictionary.
  ///
  /// - Complexity: Expected to be O(*n*) on average, where *n* is the number of
  ///    elements in `keysAndValues`, if `Key` implements high-quality hashing.
  @inlinable
  public mutating func merge<S: Sequence>(
    _ keysAndValues: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == (key: Key, value: Value) {
    for (key, value) in keysAndValues {
      let (index, bucket) = _keys._find(key)
      if let index = index {
        try { $0 = try combine($0, value) }(&_values[index])
      } else {
        _keys._appendNew(key, in: bucket)
        _values.append(value)
      }
    }
  }

  /// Merges the key-value pairs in the given sequence into the dictionary,
  /// using a combining closure to determine the value for any duplicate keys.
  ///
  /// Use the `combine` closure to select a value to use in the updated
  /// dictionary, or to combine existing and new values. As the key-value
  /// pairs are merged with the dictionary, the `combine` closure is called
  /// with the current and new values for any duplicate keys that are
  /// encountered.
  ///
  /// This example shows how to choose the current or new values for any
  /// duplicate keys:
  ///
  ///     var dictionary: OrderedDictionary = ["a": 1, "b": 2]
  ///
  ///     // Keeping existing value for key "a":
  ///     dictionary.merge(zip(["a", "c"], [3, 4])) { (current, _) in current }
  ///     // ["b": 2, "a": 1, "c": 4]
  ///
  ///     // Taking the new value for key "a":
  ///     dictionary.merge(zip(["a", "d"], [5, 6])) { (_, new) in new }
  ///     // ["b": 2, "a": 5, "c": 4, "d": 6]
  ///
  /// - Parameters:
  ///   - other: A sequence of key-value pairs.
  ///   - combine: A closure that takes the current and new values for any
  ///     duplicate keys. The closure returns the desired value for the final
  ///     dictionary.
  ///
  /// - Complexity: Expected to be O(*n*) on average, where *n* is the number of
  ///    elements in `keysAndValues`, if `Key` implements high-quality hashing.
  @inlinable
  public mutating func merge<S: Sequence>(
    _ keysAndValues: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == (Key, Value) {
    let mapped: LazyMapSequence =
      keysAndValues.lazy.map { (key: $0.0, value: $0.1) }
    try merge(mapped, uniquingKeysWith: combine)
  }

  /// Creates a dictionary by merging key-value pairs in a sequence into this
  /// dictionary, using a combining closure to determine the value for
  /// duplicate keys.
  ///
  /// Use the `combine` closure to select a value to use in the returned
  /// dictionary, or to combine existing and new values. As the key-value
  /// pairs are merged with the dictionary, the `combine` closure is called
  /// with the current and new values for any duplicate keys that are
  /// encountered.
  ///
  /// This example shows how to choose the current or new values for any
  /// duplicate keys:
  ///
  ///     let dictionary: OrderedDictionary = ["a": 1, "b": 2]
  ///     let newKeyValues = zip(["a", "b"], [3, 4])
  ///
  ///     let keepingCurrent = dictionary.merging(newKeyValues) { (current, _) in current }
  ///     // ["b": 2, "a": 1]
  ///     let replacingCurrent = dictionary.merging(newKeyValues) { (_, new) in new }
  ///     // ["b": 4, "a": 3]
  ///
  /// - Parameters:
  ///   - other: A sequence of key-value pairs.
  ///   - combine: A closure that takes the current and new values for any
  ///     duplicate keys. The closure returns the desired value for the final
  ///     dictionary.
  ///
  /// - Returns: A new dictionary with the combined keys and values of this
  ///   dictionary and `other`.
  ///
  /// - Complexity: Expected to be O(`count` + *n*) on average, where *n* is the
  ///    number of elements in `keysAndValues`, if `Key` implements high-quality
  ///    hashing.
  @inlinable
  public __consuming func merging<S: Sequence>(
    _ other: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows -> Self where S.Element == (key: Key, value: Value) {
    var copy = self
    try copy.merge(other, uniquingKeysWith: combine)
    return copy
  }

  /// Creates a dictionary by merging key-value pairs in a sequence into this
  /// dictionary, using a combining closure to determine the value for
  /// duplicate keys.
  ///
  /// Use the `combine` closure to select a value to use in the returned
  /// dictionary, or to combine existing and new values. As the key-value
  /// pairs are merged with the dictionary, the `combine` closure is called
  /// with the current and new values for any duplicate keys that are
  /// encountered.
  ///
  /// This example shows how to choose the current or new values for any
  /// duplicate keys:
  ///
  ///     let dictionary: OrderedDictionary = ["a": 1, "b": 2]
  ///     let newKeyValues = zip(["a", "b"], [3, 4])
  ///
  ///     let keepingCurrent = dictionary.merging(newKeyValues) { (current, _) in current }
  ///     // ["b": 2, "a": 1]
  ///     let replacingCurrent = dictionary.merging(newKeyValues) { (_, new) in new }
  ///     // ["b": 4, "a": 3]
  ///
  /// - Parameters:
  ///   - other: A sequence of key-value pairs.
  ///   - combine: A closure that takes the current and new values for any
  ///     duplicate keys. The closure returns the desired value for the final
  ///     dictionary.
  ///
  /// - Returns: A new dictionary with the combined keys and values of this
  ///   dictionary and `other`.
  ///
  /// - Complexity: Expected to be O(`count` + *n*) on average, where *n* is the
  ///    number of elements in `keysAndValues`, if `Key` implements high-quality
  ///    hashing.
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

extension OrderedDictionary {
  /// Returns a new dictionary containing the key-value pairs of the dictionary
  /// that satisfy the given predicate.
  ///
  /// - Parameter isIncluded: A closure that takes a key-value pair as its
  ///   argument and returns a Boolean value indicating whether the pair
  ///   should be included in the returned dictionary.
  ///
  /// - Returns: A dictionary of the key-value pairs that `isIncluded` allows.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Self {
    var result: OrderedDictionary = [:]
    for element in self where try isIncluded(element) {
      result._keys._appendNew(element.key)
      result._values.append(element.value)
    }
    return result
  }
}

extension OrderedDictionary {
  /// Returns a new dictionary containing the keys of this dictionary with the
  /// values transformed by the given closure.
  ///
  /// - Parameter transform: A closure that transforms a value. `transform`
  ///   accepts each value of the dictionary as its parameter and returns a
  ///   transformed value of the same or of a different type.
  /// - Returns: A dictionary containing the keys and transformed values of
  ///   this dictionary.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func mapValues<T>(
    _ transform: (Value) throws -> T
  ) rethrows -> OrderedDictionary<Key, T> {
    OrderedDictionary<Key, T>(
      _uniqueKeys: _keys,
      values: ContiguousArray(try _values.map(transform)))
  }

  /// Returns a new dictionary containing only the key-value pairs that have
  /// non-`nil` values as the result of transformation by the given closure.
  ///
  /// Use this method to receive a dictionary with non-optional values when
  /// your transformation produces optional values.
  ///
  /// In this example, note the difference in the result of using `mapValues`
  /// and `compactMapValues` with a transformation that returns an optional
  /// `Int` value.
  ///
  ///     let data: OrderedDictionary = ["a": "1", "b": "three", "c": "///4///"]
  ///
  ///     let m: [String: Int?] = data.mapValues { str in Int(str) }
  ///     // ["a": Optional(1), "b": nil, "c": nil]
  ///
  ///     let c: [String: Int] = data.compactMapValues { str in Int(str) }
  ///     // ["a": 1]
  ///
  /// - Parameter transform: A closure that transforms a value. `transform`
  ///   accepts each value of the dictionary as its parameter and returns an
  ///   optional transformed value of the same or of a different type.
  ///
  /// - Returns: A dictionary containing the keys and non-`nil` transformed
  ///   values of this dictionary.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func compactMapValues<T>(
    _ transform: (Value) throws -> T?
  ) rethrows -> OrderedDictionary<Key, T> {
    var result: OrderedDictionary<Key, T> = [:]
    for (key, value) in self {
      if let value = try transform(value) {
        result._keys._appendNew(key)
        result._values.append(value)
      }
    }
    return result
  }
}
