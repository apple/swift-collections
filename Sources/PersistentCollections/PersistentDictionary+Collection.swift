//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentDictionary: Collection {
  public struct Index: Comparable {
    internal let _value: Int

    internal init(_value: Int) {
      self._value = _value
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
      lhs._value < rhs._value
    }
  }

  ///
  /// Manipulating Indices
  ///
  
  public var startIndex: Index { Index(_value: 0) }
  
  public var endIndex: Index { Index(_value: count) }
  
  public func index(after i: Index) -> Index {
    Index(_value: i._value + 1)
  }
  
  /// Returns the index for the given key.
  public func index(forKey key: Key) -> Index? {
    _root.index(forKey: key, _HashPath(key), 0)
  }
  
  /// Accesses the key-value pair at the specified position.
  public subscript(position: Index) -> Element {
    _root.item(position: position._value)
  }
}

