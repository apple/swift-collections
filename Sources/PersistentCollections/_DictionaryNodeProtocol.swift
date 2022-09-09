//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// FIXME: Remove
internal protocol _DictionaryNodeProtocol: _NodeProtocol
where Element == (key: Key, value: Value)
{
  associatedtype Key: Hashable
  associatedtype Value

  func get(_ key: Key, _ path: _HashPath) -> Value?

  func containsKey(_ key: Key, _ path: _HashPath) -> Bool

  func index(
    forKey key: Key, _ path: _HashPath, _ skippedBefore: Int
  ) -> PersistentDictionary<Key, Value>.Index?

  func updateOrUpdating(
    _ isUnique: Bool,
    _ item: Element,
    _ path: _HashPath,
    _ effect: inout _DictionaryEffect<Value>
  ) -> Self

  func removeOrRemoving(
    _ isStorageKnownUniquelyReferenced: Bool,
    _ key: Key,
    _ path: _HashPath,
    _ effect: inout _DictionaryEffect<Value>
  ) -> Self
}
