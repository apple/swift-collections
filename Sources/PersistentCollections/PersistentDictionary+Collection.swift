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
  public typealias Index = PersistentDictionaryIndex
  
  ///
  /// Manipulating Indices
  ///
  
  public var startIndex: Self.Index { PersistentDictionaryIndex(value: 0) }
  
  public var endIndex: Self.Index { PersistentDictionaryIndex(value: count) }
  
  public func index(after i: Self.Index) -> Self.Index {
    return i + 1
  }
  
  ///
  /// Returns the index for the given key.
  ///
  public func index(forKey key: Key) -> Self.Index? {
    return rootNode.index(key, computeHash(key), 0, 0) 
  }
  
  ///
  /// Accesses the key-value pair at the specified position.
  ///
  public subscript(position: Self.Index) -> Self.Element {
    return rootNode.get(position: position, 0, position.value)
  }
}

public struct PersistentDictionaryIndex: Comparable {
  let value: Int
  
  public static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.value < rhs.value
  }
  
  public static func +(lhs: Self, rhs: Int) -> Self {
    return PersistentDictionaryIndex(value: lhs.value + rhs)
  }
}
