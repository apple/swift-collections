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
  /// Creates a dictionary from a sequence of key-value pairs.
  ///
  /// If duplicates are encountered the last instance of the key-value pair is the one
  /// that is kept.
  ///
  /// - Parameter keysAndValues: A sequence of key-value pairs to use
  ///     for the new dictionary.
  /// - Complexity: O(`n` * log(`n`)) where `n` is the number of elements in
  ///     the sequence.
  @inlinable
  @inline(__always)
  public init<S>(
    keysWithValues keysAndValues: S
  ) where S: Sequence, S.Element == (key: Key, value: Value) {
    self.init()
    
    for (key, value) in keysAndValues {
      self._root.updateAnyValue(value, forKey: key, updatingKey: true)
    }
  }
  
  /// Creates a dictionary from a sequence of key-value pairs.
  ///
  /// If duplicates are encountered the last instance of the key-value pair is the one
  /// that is kept.
  ///
  /// - Parameter keysAndValues: A sequence of key-value pairs to use
  ///     for the new dictionary.
  /// - Complexity: O(`n` * log(`n`)) where `n` is the number of elements in
  ///     the sequence.
  @inlinable
  @inline(__always)
  public init<S>(
    keysWithValues keysAndValues: S
  ) where S: Sequence, S.Element == (Key, Value) {
    self.init()
    
    for (key, value) in keysAndValues {
      self._root.updateAnyValue(value, forKey: key)
    }
  }
  
  /// Creates a dictionary from a sequence of **sorted** key-value pairs.
  ///
  /// This is a more efficient alternative to ``init(keysWithValues:)`` which offers
  /// better asymptotic performance, and also reduces memory usage when constructing a
  /// sorted dictionary on a pre-sorted sequence.
  ///
  /// - Parameter keysAndValues: A sequence of key-value pairs in non-decreasing
  ///     comparison order for the new dictionary.
  /// - Complexity: O(`n`) where `n` is the number of elements in the
  ///     sequence.
  @inlinable
  @inline(__always)
  public init<S>(
    sortedKeysWithValues keysAndValues: S
  ) where S: Sequence, S.Element == (key: Key, value: Value) {
    var builder = _Tree.Builder()
    
    var previousKey: Key? = nil
    for (key, value) in keysAndValues {
      precondition(previousKey == nil || previousKey! < key,
             "Sequence out of order.")
      builder.append((key, value))
      previousKey = key
    }
    
    self.init(_rootedAt: builder.finish())
  }
  
  /// Creates a dictionary from a sequence of **sorted** key-value pairs.
  ///
  /// This is a more efficient alternative to ``init(keysWithValues:)`` which offers
  /// better asymptotic performance, and also reduces memory usage when constructing a
  /// sorted dictionary on a pre-sorted sequence.
  ///
  /// - Parameter keysAndValues: A sequence of key-value pairs in non-decreasing
  ///     comparison order for the new dictionary.
  /// - Complexity: O(`n`) where `n` is the number of elements in the
  ///     sequence.
  @inlinable
  @inline(__always)
  public init<S>(
    sortedKeysWithValues keysAndValues: S
  ) where S: Sequence, S.Element == (Key, Value) {
    var builder = _Tree.Builder()
    
    var previousKey: Key? = nil
    for (key, value) in keysAndValues {
      precondition(previousKey == nil || previousKey! < key,
             "Sequence out of order.")
      builder.append((key, value))
      previousKey = key
    }
    
    self.init(_rootedAt: builder.finish())
  }
  
  /// Creates a new sorted dictionary whose keys are the groupings returned
  /// by the given closure and whose values are arrays of the elements that
  /// returned each key.
  ///
  /// The arrays in the “values” position of the new sorted dictionary each contain at least
  /// one element, with the elements in the same order as the source sequence.
  /// The following example declares an array of names, and then creates a sorted dictionary
  /// from that array by grouping the names by first letter:
  ///
  ///     let students = ["Kofi", "Abena", "Efua", "Kweku", "Akosua"]
  ///     let studentsByLetter = SortedDictionary(grouping: students, by: { $0.first! })
  ///     // ["A": ["Abena", "Akosua"], "E": ["Efua"], "K": ["Kofi", "Kweku"]]
  ///
  /// The new `studentsByLetter` sorted dictionary has three entries, with students’ names
  /// grouped by the keys `"A"`, `"E"`, and `"K"`
  ///
  ///
  /// - Parameters:
  ///   - values: A sequence of values to group into a dictionary.
  ///   - keyForValue: A closure that returns a key for each element in values.
  @inlinable
  public init<S>(
    grouping values: S,
    by keyForValue: (S.Element) throws -> Key
  ) rethrows where Value == [S.Element], S : Sequence {
    self.init()
    for value in values {
      let key = try keyForValue(value)
      self.modifyValue(forKey: key, default: []) { group in
        group.append(value)
      }
    }
  }
}
