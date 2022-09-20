//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _CollectionsTestSupport
import PersistentCollections

extension LifetimeTracker {
  func persistentDictionary<Keys: Sequence>(
    keys: Keys
  ) -> (
    dictionary: PersistentDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>>,
    keys: [LifetimeTracked<Int>],
    values: [LifetimeTracked<Int>]
  )
  where Keys.Element == Int
  {
    let k = Array(keys)
    let keys = self.instances(for: k)
    let values = self.instances(for: k.map { $0 + 100 })
    let dictionary = PersistentDictionary(uniqueKeys: keys, values: values)
    return (dictionary, keys, values)
  }
}

protocol DataGenerator {
  associatedtype Key: Hashable
  associatedtype Value: Equatable

  func key(for i: Int) -> Key
  func value(for i: Int) -> Value
}

struct IntDataGenerator: DataGenerator {
  typealias Key = Int
  typealias Value = Int

  let valueOffset: Int

  init(valueOffset: Int) {
    self.valueOffset = valueOffset
  }

  func key(for i: Int) -> Key {
    i
  }

  func value(for i: Int) -> Value {
    i + valueOffset
  }
}

struct ColliderDataGenerator: DataGenerator {
  typealias Key = Collider
  typealias Value = Int

  let groups: Int
  let valueOffset: Int

  init(groups: Int, valueOffset: Int) {
    self.groups = groups
    self.valueOffset = valueOffset
  }

  func key(for i: Int) -> Key {
    Collider(i, Hash(i % groups))
  }

  func value(for i: Int) -> Value {
    i + valueOffset
  }
}

extension LifetimeTracker {
  func persistentDictionary<Payloads: Sequence, G: DataGenerator>(
    _ payloads: Payloads,
    with generator: G
  ) -> (
    map: PersistentDictionary<LifetimeTracked<G.Key>, LifetimeTracked<G.Value>>,
    expected: [LifetimeTracked<G.Key>: LifetimeTracked<G.Value>]
  )
  where Payloads.Element == Int
  {
    typealias Key = LifetimeTracked<G.Key>
    typealias Value = LifetimeTracked<G.Value>
    func gen() -> [(Key, Value)] {
      payloads.map {
        (instance(for: generator.key(for: $0)),
         instance(for: generator.value(for: $0)))
      }
    }
    let map = PersistentDictionary(uniqueKeysWithValues: gen())
    let expected = Dictionary(uniqueKeysWithValues: gen())
    return (map, expected)
  }

  func persistentDictionary<Keys: Sequence>(
    keys: Keys
  ) -> (
    map: PersistentDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>>,
    expected: [LifetimeTracked<Int>: LifetimeTracked<Int>]
  )
  where Keys.Element == Int
  {
    persistentDictionary(keys, with: IntDataGenerator(valueOffset: 100))
  }
}

func _expectFailure(
  _ diagnostic: String,
  _ message: () -> String,
  trapping: Bool,
  file: StaticString,
  line: UInt
) {
  expectFailure(
      """
      \(diagnostic)
      \(message())
      """,
      trapping: trapping,
      file: file, line: line)
}

func expectEqualDictionaries<Key: Hashable, Value: Equatable>(
  _ map: PersistentDictionary<Key, Value>,
  _ ref: [(key: Key, value: Value)],
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #file,
  line: UInt = #line
) {
  expectEqualDictionaries(
    map, Dictionary(uniqueKeysWithValues: ref),
    message(),
    trapping: trapping,
    file: file, line: line)
}

func expectEqualDictionaries<Key: Hashable, Value: Equatable>(
  _ map: PersistentDictionary<Key, Value>,
  _ dict: Dictionary<Key, Value>,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #file,
  line: UInt = #line
) {
  var dict = dict
  var seen: Set<Key> = []
  var mismatches: [(key: Key, map: Value?, dict: Value?)] = []
  var dupes: [(key: Key, map: Value)] = []
  for (key, value) in map {
    if !seen.insert(key).inserted {
      dupes.append((key, value))
    } else {
      let expected = dict.removeValue(forKey: key)
      if value != expected {
        mismatches.append((key, value, expected))
      }
    }
  }
  for (key, value) in dict {
    mismatches.append((key, nil, value))
  }
  if !mismatches.isEmpty || !dupes.isEmpty {
    let msg1 = mismatches.lazy.map { k, m, d in
      "\n  \(k): \(m == nil ? "nil" : "\(m!)") vs \(d == nil ? "nil" : "\(d!)")"
    }.joined(separator: "")
    let msg2 = dupes.lazy.map { k, v in
      "\n  \(k): \(v) (duped)"
    }.joined(separator: "")
    _expectFailure(
      "\n\(mismatches.count) mismatches (actual vs expected):\(msg1)\(msg2)",
      message, trapping: trapping, file: file, line: line)
  }
}

func mutate<T, R>(
  _ value: inout T,
  _ body: (inout T) throws -> R
) rethrows -> R {
  try body(&value)
}
