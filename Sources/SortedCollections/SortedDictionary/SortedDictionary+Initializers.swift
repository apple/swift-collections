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
  /// Creates a dictionary from a sequence of key-value pairs which must
  /// be unique.
  /// - Complexity: O(`n log n`)
  @inlinable
  @inline(__always)
  public init<S>(
    uniqueKeysWithValues keysAndValues: S
  ) where S: Sequence, S.Element == Element {
    self.init()
    
    for (key, value) in keysAndValues {
      self._root.setAnyValue(value, forKey: key)
    }
  }
  
  /// Creates a dictionary from a sequence of **sorted** key-value pairs
  /// which must be unique.
  /// - Complexity: O(`n`)
  @inlinable
  @inline(__always)
  public init<S>(
    uniqueSortedKeysWithValues keysAndValues: S
  ) where S: Sequence, S.Element == Element {
    self.init()
    
    // TODO: implement O(n) version using BTree
    // TODO: should this validate the sorted invariant
    // in debug v production v unchecked builds?
    
    for (key, value) in keysAndValues {
      self._root.setAnyValue(value, forKey: key)
    }
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
    // TODO: implement some way to take advantage of S.underestimateCapacity
    for value in values {
      let key = try keyForValue(value)
      
      // TODO: optimize to avoid CoW copying the array
      if var group = self._root.findAnyValue(forKey: key) {
        group.append(value)
        self._root.setAnyValue(group, forKey: key)
      } else {
        self._root.setAnyValue([value], forKey: key)
      }
    }
  }
}
