//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import InternalCollectionsUtilities
import BasicContainers
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableHashedContainers

/// A key whose hash value is controlled separately from its identity, so that
/// we can force long collision chains.
fileprivate struct Collider: Hashable {
  var value: Int
  var hashKey: Int

  static func ==(left: Self, right: Self) -> Bool {
    left.value == right.value
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(hashKey)
  }
}

/// Generates random keys from a small domain, with a configurable number of
/// distinct hash values.
fileprivate struct KeyGenerator {
  var rng: RepeatableRandomNumberGenerator
  let domain: Int
  let hashCount: Int

  init(seed: Int, domain: Int, hashCount: Int) {
    self.rng = RepeatableRandomNumberGenerator(seed: seed)
    self.domain = domain
    self.hashCount = hashCount
  }

  func key(_ value: Int) -> Collider {
    Collider(value: value, hashKey: value % hashCount)
  }

  mutating func next() -> Int {
    Int.random(in: 0 ..< domain, using: &rng)
  }

  mutating func roll(_ n: Int) -> Int {
    Int.random(in: 0 ..< n, using: &rng)
  }
}

/// The hash layouts to exercise: no collisions, a handful of distinct hash
/// values, and everything in a single collision chain.
fileprivate let fuzzConfigurations: [(domain: Int, hashCount: Int)] = [
  (domain: 40, hashCount: 1 << 30),
  (domain: 40, hashCount: 5),
  (domain: 40, hashCount: 1),
  (domain: 300, hashCount: 1 << 30),
  (domain: 300, hashCount: 17),
]

fileprivate func setContents(
  _ set: borrowing RigidSet<LifetimeTracked<Collider>>
) -> [Int] {
  var result: [Int] = []
  var i = set.startIndex
  while i != set.endIndex {
    result.append(set[i].payload.value)
    i = set.index(after: i)
  }
  return result
}

fileprivate func setContents(
  _ set: borrowing UniqueSet<LifetimeTracked<Collider>>
) -> [Int] {
  var result: [Int] = []
  var i = set.startIndex
  while i != set.endIndex {
    result.append(set[i].payload.value)
    i = set.index(after: i)
  }
  return result
}

fileprivate func dictionaryContents(
  _ d: borrowing RigidDictionary<LifetimeTracked<Collider>, LifetimeTracked<Int>>
) -> [Int: Int] {
  var result: [Int: Int] = [:]
  var i = d.startIndex
  while i != d.endIndex {
    let item = d[i]
    let old = result.updateValue(item.value.payload, forKey: item.key.payload.value)
    expectNil(old, "Duplicate key \(item.key.payload.value)")
    i = d.index(after: i)
  }
  return result
}

fileprivate func dictionaryContents(
  _ d: borrowing UniqueDictionary<LifetimeTracked<Collider>, LifetimeTracked<Int>>
) -> [Int: Int] {
  var result: [Int: Int] = [:]
  var i = d.startIndex
  while i != d.endIndex {
    let item = d[i]
    let old = result.updateValue(item.value.payload, forKey: item.key.payload.value)
    expectNil(old, "Duplicate key \(item.key.payload.value)")
    i = d.index(after: i)
  }
  return result
}

class HashedContainersFuzzTests: CollectionTestCase {
  /// Runs random sequences of operations on a `RigidSet` and checks it against
  /// a standard `Set` after each step.
  func test_RigidSet_fuzz() {
    withEvery("config", in: fuzzConfigurations.indices) { c in
      let config = fuzzConfigurations[c]
      withEvery("seed", in: 0 ..< 100) { seed in
        withLifetimeTracking { tracker in
          var gen = KeyGenerator(
            seed: seed, domain: config.domain, hashCount: config.hashCount)
          var set = RigidSet<LifetimeTracked<Collider>>(
            capacity: gen.roll(config.domain + 1))
          var model: Set<Int> = []

          withEvery("step", in: 0 ..< 200) { step in
            let v = gen.next()
            let item = tracker.instance(for: gen.key(v))
            switch gen.roll(10) {
            case 0, 1, 2:
              if set.isFull && !model.contains(v) { break }
              let r = set.insert(item)
              expectEqual(r != nil, model.contains(v))
              model.insert(v)
            case 3:
              if set.isFull && !model.contains(v) { break }
              let r = set.update(with: item)
              expectEqual(r?.payload.value, model.contains(v) ? v : nil)
              model.insert(v)
            case 4, 5, 6:
              let r = set.remove(item)
              expectEqual(r?.payload.value, model.remove(v))
            case 7:
              let newCapacity = set.count + gen.roll(config.domain)
              set.reallocate(capacity: newCapacity)
              expectEqual(set.capacity, newCapacity)
            case 8:
              let roundTrip = UniqueSet(consuming: set)
              set = RigidSet(consuming: roundTrip)
            default:
              if gen.roll(4) == 0 {
                set.removeAll()
                model.removeAll()
              } else {
                expectEqual(set.index(of: item) != nil, model.contains(v))
              }
            }
            expectConsistentSet(set)
            expectEqual(set.count, model.count)
            expectEqualElements(setContents(set).sorted(), model.sorted())
            for k in 0 ..< config.domain {
              let probe = tracker.instance(for: gen.key(k))
              expectEqual(set.contains(probe), model.contains(k), "key \(k)")
            }
          }

          var consumed: [Int] = []
          set._consumeAll { buffer in
            for i in buffer.indices {
              consumed.append(buffer[i].payload.value)
            }
            buffer.deinitialize()
          }
          expectEqualElements(consumed.sorted(), model.sorted())
          expectEqual(set.count, 0)
          expectConsistentSet(set)
        }
      }
    }
  }

  /// Runs random sequences of operations on a `UniqueSet` and checks it against
  /// a standard `Set` after each step.
  func test_UniqueSet_fuzz() {
    withEvery("config", in: fuzzConfigurations.indices) { c in
      let config = fuzzConfigurations[c]
      withEvery("seed", in: 0 ..< 100) { seed in
        withLifetimeTracking { tracker in
          var gen = KeyGenerator(
            seed: seed, domain: config.domain, hashCount: config.hashCount)
          var set = UniqueSet<LifetimeTracked<Collider>>()
          var model: Set<Int> = []

          withEvery("step", in: 0 ..< 200) { step in
            let v = gen.next()
            let item = tracker.instance(for: gen.key(v))
            switch gen.roll(10) {
            case 0, 1, 2:
              let r = set.insert(item)
              expectEqual(r != nil, model.contains(v))
              model.insert(v)
            case 3:
              let r = set.update(with: item)
              expectEqual(r?.payload.value, model.contains(v) ? v : nil)
              model.insert(v)
            case 4, 5, 6:
              let r = set.remove(item)
              expectEqual(r?.payload.value, model.remove(v))
            case 7:
              let n = gen.roll(2 * config.domain)
              set.reserveCapacity(n)
              expectGreaterThanOrEqual(set.capacity, n)
            case 8:
              let roundTrip = RigidSet(consuming: set)
              set = UniqueSet(consuming: roundTrip)
            default:
              if gen.roll(4) == 0 {
                let keep = gen.roll(2) == 0
                let oldCapacity = set.capacity
                set.removeAll(keepingCapacity: keep)
                model.removeAll()
                if keep { expectEqual(set.capacity, oldCapacity) }
              } else {
                expectEqual(set.index(of: item) != nil, model.contains(v))
              }
            }
            expectTrue(set._checkInvariants())
            expectEqual(set.count, model.count)
            expectGreaterThanOrEqual(set.capacity, set.count)
            expectEqualElements(setContents(set).sorted(), model.sorted())
            for k in 0 ..< config.domain {
              let probe = tracker.instance(for: gen.key(k))
              expectEqual(set.contains(probe), model.contains(k), "key \(k)")
            }
          }
        }
      }
    }
  }

  /// Runs random sequences of operations on a `RigidDictionary` and checks it
  /// against a standard `Dictionary` after each step.
  func test_RigidDictionary_fuzz() {
    typealias Key = LifetimeTracked<Collider>
    typealias Value = LifetimeTracked<Int>
    withEvery("config", in: fuzzConfigurations.indices) { c in
      let config = fuzzConfigurations[c]
      withEvery("seed", in: 0 ..< 100) { seed in
        withLifetimeTracking { tracker in
          var gen = KeyGenerator(
            seed: seed, domain: config.domain, hashCount: config.hashCount)
          var d = RigidDictionary<Key, Value>(capacity: gen.roll(config.domain + 1))
          var model: [Int: Int] = [:]

          withEvery("step", in: 0 ..< 200) { step in
            let k = gen.next()
            let key = tracker.instance(for: gen.key(k))
            let value = tracker.instance(for: step)
            let canAdd = !d.isFull || model[k] != nil
            switch gen.roll(12) {
            case 0, 1:
              guard canAdd else { break }
              let r = d.insertValue(value, forKey: key)
              if let old = model[k] {
                expectEqual(r?.payload, step) // Not inserted
                _ = old
              } else {
                expectNil(r)
                model[k] = step
              }
            case 2, 3:
              guard canAdd else { break }
              let r = d.updateValue(value, forKey: key)
              expectEqual(r?.payload, model.updateValue(step, forKey: k))
            case 4:
              // Closure-based update: insert, replace or remove.
              let action = gen.roll(3)
              if action != 2 && !canAdd { break }
              let hadValue = d.updateValue(forKey: key) { slot -> Int? in
                let old = slot?.payload
                switch action {
                case 0: slot = nil
                case 1: slot = tracker.instance(for: step)
                default: break
                }
                return old
              }
              expectEqual(hadValue, model[k])
              switch action {
              case 0: model[k] = nil
              case 1: model[k] = step
              default: break
              }
            case 5:
              guard canAdd else { break }
              guard #available(SwiftStdlib 6.4, *) else { break }
              let expected = model[k] ?? step
              let ref = d.memoizedValue(forKey: key) { _ in
                tracker.instance(for: step)
              }
              expectEqual(ref.value.payload, expected)
              model[k] = expected
            case 6, 7, 8:
              let r = d.removeValue(forKey: key)
              expectEqual(r?.payload, model.removeValue(forKey: k))
            case 9:
              let newCapacity = d.count + gen.roll(config.domain)
              d.reallocate(capacity: newCapacity)
              expectEqual(d.capacity, newCapacity)
            case 10:
              let roundTrip = UniqueDictionary(consuming: d)
              d = RigidDictionary(consuming: roundTrip)
            default:
              if gen.roll(4) == 0 {
                d.removeAll()
                model.removeAll()
              } else {
                expectEqual(d.withValue(forKey: key) { $0.payload }, model[k])
              }
            }
            expectTrue(d._checkInvariants())
            expectEqual(d.count, model.count)
            expectEqual(dictionaryContents(d), model)
            d.withKeys { keys in
              expectEqual(keys.count, model.count)
            }
            for k in 0 ..< config.domain {
              let probe = tracker.instance(for: gen.key(k))
              expectEqual(d.containsKey(probe), model[k] != nil, "key \(k)")
            }
          }
        }
      }
    }
  }

  /// Runs random sequences of operations on a `UniqueDictionary` and checks it
  /// against a standard `Dictionary` after each step.
  func test_UniqueDictionary_fuzz() {
    typealias Key = LifetimeTracked<Collider>
    typealias Value = LifetimeTracked<Int>
    withEvery("config", in: fuzzConfigurations.indices) { c in
      let config = fuzzConfigurations[c]
      withEvery("seed", in: 0 ..< 100) { seed in
        withLifetimeTracking { tracker in
          var gen = KeyGenerator(
            seed: seed, domain: config.domain, hashCount: config.hashCount)
          var d = UniqueDictionary<Key, Value>()
          var model: [Int: Int] = [:]

          withEvery("step", in: 0 ..< 200) { step in
            let k = gen.next()
            let key = tracker.instance(for: gen.key(k))
            let value = tracker.instance(for: step)
            switch gen.roll(12) {
            case 0, 1:
              let r = d.insertValue(value, forKey: key)
              if model[k] != nil {
                expectEqual(r?.payload, step) // Not inserted
              } else {
                expectNil(r)
                model[k] = step
              }
            case 2, 3:
              let r = d.updateValue(value, forKey: key)
              expectEqual(r?.payload, model.updateValue(step, forKey: k))
            case 4:
              let action = gen.roll(3)
              let hadValue = d.updateValue(forKey: key) { slot -> Int? in
                let old = slot?.payload
                switch action {
                case 0: slot = nil
                case 1: slot = tracker.instance(for: step)
                default: break
                }
                return old
              }
              expectEqual(hadValue, model[k])
              switch action {
              case 0: model[k] = nil
              case 1: model[k] = step
              default: break
              }
            case 5:
              guard #available(SwiftStdlib 6.4, *) else { break }
              let expected = model[k] ?? step
              let ref = d.memoizedValue(forKey: key) { _ in
                tracker.instance(for: step)
              }
              expectEqual(ref.value.payload, expected)
              model[k] = expected
            case 6, 7, 8:
              let r = d.removeValue(forKey: key)
              expectEqual(r?.payload, model.removeValue(forKey: k))
            case 9:
              let n = gen.roll(2 * config.domain)
              d.reserveCapacity(n)
              expectGreaterThanOrEqual(d.capacity, n)
            case 10:
              let roundTrip = RigidDictionary(consuming: d)
              d = UniqueDictionary(consuming: roundTrip)
            default:
              if gen.roll(4) == 0 {
                let keep = gen.roll(2) == 0
                let oldCapacity = d.capacity
                d.removeAll(keepingCapacity: keep)
                model.removeAll()
                if keep { expectEqual(d.capacity, oldCapacity) }
              } else {
                expectEqual(d.withValue(forKey: key) { $0.payload }, model[k])
              }
            }
            expectTrue(d._checkInvariants())
            expectEqual(d.count, model.count)
            expectGreaterThanOrEqual(d.capacity, d.count)
            expectEqual(dictionaryContents(d), model)
            for k in 0 ..< config.domain {
              let probe = tracker.instance(for: gen.key(k))
              expectEqual(d.containsKey(probe), model[k] != nil, "key \(k)")
            }
          }
        }
      }
    }
  }
}

#endif
