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

#if swift(>=5.7)
@frozen
public enum CombiningBehavior {
  case include
  case discard
  case merge
}

public protocol TreeDictionaryCombiningStrategy<Key, Value> {
  associatedtype Key: Hashable
  associatedtype Value

  var valuesOnlyInFirst: CombiningBehavior { get }
  var valuesOnlyInSecond: CombiningBehavior { get }
  var equalValuesInBoth: CombiningBehavior { get }
  var unequalValuesInBoth: CombiningBehavior { get }

  func areEquivalentValues(_ a: Value, _ b: Value) -> Bool

  func merge(_ key: Key, _ value1: Value?, _ value2: Value?) throws -> Value?
}

extension TreeDictionaryCombiningStrategy {
  public typealias Element = (key: Key, value: Value)
}

extension TreeDictionaryCombiningStrategy where Value: Equatable {
  @inlinable @inline(__always)
  public func areEquivalentValues(_ a: Value, _ b: Value) -> Bool {
    a == b
  }
}

extension TreeDictionary {
  @inlinable
  public func combining(
    _ other: Self,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws -> Self {
    let root = try _root.combining(.top, other._root, by: strategy)
    return Self(_new: root)
  }

  @inlinable
  mutating func combine(
    _ other: Self,
    by strategy: some TreeDictionaryCombiningStrategy<Key, Value>
  ) throws {
    self = try combining(other, by: strategy)
  }
}
#endif
