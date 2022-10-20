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

extension PersistentDictionary {
  @inlinable
  public mutating func merge(
    _ keysAndValues: Self,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows {
    _invalidateIndices()
    try _root.merge(.top, keysAndValues._root, combine)
  }

  @inlinable
  public mutating func merge<S: Sequence>(
    _ keysAndValues: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == (Key, Value) {
    for (key, value) in keysAndValues {
      try self.updateValue(forKey: key) { target in
        if let old = target {
          target = try combine(old, value)
        } else {
          target = value
        }
      }
    }
  }

  @_disfavoredOverload // https://github.com/apple/swift-collections/issues/125
  @inlinable
  public mutating func merge<S: Sequence>(
    _ keysAndValues: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows where S.Element == Element {
    try merge(
      keysAndValues.lazy.map { ($0.key, $0.value) },
      uniquingKeysWith: combine)
  }

  @inlinable
  public func merging(
    _ other: Self,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows -> Self {
    var copy = self
    try copy.merge(other, uniquingKeysWith: combine)
    return copy
  }

  @inlinable
  public func merging<S: Sequence>(
    _ other: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows -> Self
  where S.Element == (Key, Value) {
    var copy = self
    try copy.merge(other, uniquingKeysWith: combine)
    return copy
  }

  @_disfavoredOverload // https://github.com/apple/swift-collections/issues/125
  @inlinable
  public func merging<S: Sequence>(
    _ other: __owned S,
    uniquingKeysWith combine: (Value, Value) throws -> Value
  ) rethrows -> Self
  where S.Element == Element {
    var copy = self
    try copy.merge(other, uniquingKeysWith: combine)
    return copy
  }
}
