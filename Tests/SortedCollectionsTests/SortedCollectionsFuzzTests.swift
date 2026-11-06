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

#if UnstableSortedCollections

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import SortedCollections
#endif

/// An element whose identity (`tag`) is separate from its value, so we can
/// tell whether a collection kept the old member or replaced it.
fileprivate struct Tagged: Comparable, CustomStringConvertible {
  var value: Int
  var tag: Int

  static func ==(left: Self, right: Self) -> Bool { left.value == right.value }
  static func <(left: Self, right: Self) -> Bool { left.value < right.value }

  var description: String { "\(value)#\(tag)" }
}

fileprivate struct FuzzRandom {
  var rng: RepeatableRandomNumberGenerator

  init(seed: Int) {
    rng = RepeatableRandomNumberGenerator(seed: seed)
  }

  mutating func roll(_ n: Int) -> Int {
    precondition(n > 0)
    return Int.random(in: 0 ..< n, using: &rng)
  }
}

final class SortedCollectionsFuzzTests: CollectionTestCase {
  /// Checks every read-only view of `d` against the model.
  fileprivate func checkDictionary(
    _ d: SortedDictionary<Int, Int>,
    _ model: [Int: Int],
    domain: Int,
    random: inout FuzzRandom
  ) {
    let expected = model.sorted { $0.key < $1.key }
    expectEqual(d.count, model.count)
    expectEqual(d.isEmpty, model.isEmpty)
    expectEqualElements(d.map { $0.key }, expected.map { $0.key })
    expectEqualElements(d.map { $0.value }, expected.map { $0.value })
    expectEqualElements(d.keys, expected.map { $0.key })
    expectEqualElements(d.values, expected.map { $0.value })

    // Backward iteration.
    var backward: [Int] = []
    var i = d.endIndex
    while i != d.startIndex {
      d.formIndex(before: &i)
      backward.append(d[i].key)
    }
    expectEqualElements(backward, expected.map { $0.key }.reversed())
    expectEqual(d.distance(from: d.startIndex, to: d.endIndex), model.count)

    // Random access by offset, and lookups.
    if !expected.isEmpty {
      let offset = random.roll(expected.count)
      let j = d.index(d.startIndex, offsetBy: offset)
      expectEqual(d[j].key, expected[offset].key)
      expectEqual(d.distance(from: d.startIndex, to: j), offset)
      let back = d.index(d.endIndex, offsetBy: offset - expected.count)
      expectEqual(back, j)
    }
    for k in 0 ..< domain {
      expectEqual(d[k], model[k], "key \(k)")
      let index = d.index(forKey: k)
      expectEqual(index != nil, model[k] != nil, "key \(k)")
      if let index { expectEqual(d[index].key, k) }
    }
  }

  func test_SortedDictionary_fuzz() {
    withEvery("domain", in: [8, 40, 300]) { domain in
      withEvery("seed", in: 0 ..< 60) { seed in
        var random = FuzzRandom(seed: seed)
        var d = SortedDictionary<Int, Int>()
        var model: [Int: Int] = [:]
        var snapshots: [(SortedDictionary<Int, Int>, [Int: Int])] = []

        withEvery("step", in: 0 ..< 300) { step in
          let k = random.roll(domain)
          switch random.roll(16) {
          case 0, 1:
            d[k] = step
            model[k] = step
          case 2:
            d[k] = nil
            model[k] = nil
          case 3:
            expectEqual(d.updateValue(step, forKey: k), model.updateValue(step, forKey: k))
          case 4, 5:
            expectEqual(d.removeValue(forKey: k), model.removeValue(forKey: k))
          case 6:
            let r = d.modifyValue(forKey: k, default: -1) { value -> Int in
              value += 1
              return value
            }
            model[k, default: -1] += 1
            expectEqual(r, model[k])
          case 7:
            d[k, default: 100] += 1
            model[k, default: 100] += 1
          case 8:
            guard !d.isEmpty else { break }
            let offset = random.roll(d.count)
            let removed = d.remove(at: d.index(d.startIndex, offsetBy: offset))
            let key = model.keys.sorted()[offset]
            expectEqual(removed.key, key)
            expectEqual(removed.value, model.removeValue(forKey: key))
          case 9:
            let n = random.roll(d.count + 1)
            let keys = model.keys.sorted()
            d.removeFirst(n)
            for key in keys.prefix(n) { model[key] = nil }
          case 10:
            let n = random.roll(d.count + 1)
            let keys = model.keys.sorted()
            d.removeLast(n)
            for key in keys.suffix(n) { model[key] = nil }
          case 11:
            let first = d.popFirst()
            let key = model.keys.min()
            expectEqual(first?.key, key)
            if let key { expectEqual(first?.value, model.removeValue(forKey: key)) }
          case 12:
            let last = d.popLast()
            let key = model.keys.max()
            expectEqual(last?.key, key)
            if let key { expectEqual(last?.value, model.removeValue(forKey: key)) }
          case 13:
            // Keep a copy around to check value semantics later.
            snapshots.append((d, model))
            if snapshots.count > 4 { snapshots.removeFirst() }
          case 14 where random.roll(2) == 0:
            // Mutations through the `_modify` accessor of `subscript(key:)`.
            switch random.roll(3) {
            case 0:
              expectEqual(d[k].take(), model.removeValue(forKey: k))
            case 1:
              d[k]? += 1
              model[k]? += 1
            default:
              func clear(_ value: inout Int?) { value = nil }
              clear(&d[k])
              model[k] = nil
            }
          case 14:
            let filtered = d.filter { $0.key % 3 == 0 }
            expectEqualElements(
              filtered.map { $0.key }, model.keys.filter { $0 % 3 == 0 }.sorted())
            let mapped = d.mapValues { $0 * 2 }
            expectEqualElements(
              mapped.map { $0.value },
              model.sorted { $0.key < $1.key }.map { $0.value * 2 })
          default:
            if random.roll(8) == 0 {
              d.removeAll()
              model.removeAll()
            } else {
              // Rebuild from a sequence.
              d = SortedDictionary(keysWithValues: model.map { ($0.key, $0.value) })
            }
          }
          checkDictionary(d, model, domain: domain, random: &random)
          for (copy, copyModel) in snapshots {
            expectEqualElements(
              copy.map { $0.key }, copyModel.keys.sorted(), "snapshot changed")
            expectEqualElements(
              copy.map { $0.value },
              copyModel.sorted { $0.key < $1.key }.map { $0.value },
              "snapshot changed")
          }
        }
      }
    }
  }

  func test_SortedSet_fuzz() {
    withEvery("domain", in: [8, 40, 300]) { domain in
      withEvery("seed", in: 0 ..< 25) { seed in
        var random = FuzzRandom(seed: seed)
        var set = SortedSet<Tagged>()
        // Maps each member's value to the tag of the member stored for it.
        var model: [Int: Int] = [:]
        var snapshots: [(SortedSet<Tagged>, [Int: Int])] = []

        func randomOther() -> (SortedSet<Tagged>, [Int: Int]) {
          var other: [Int: Int] = [:]
          for _ in 0 ..< random.roll(domain + 1) {
            other[random.roll(domain)] = -1 - random.roll(1000)
          }
          let s = SortedSet(other.map { Tagged(value: $0.key, tag: $0.value) })
          return (s, other)
        }

        withEvery("step", in: 0 ..< 300) { step in
          let v = random.roll(domain)
          let item = Tagged(value: v, tag: step)
          // Which of two equal members the set algebra operations keep is
          // unspecified (see `checkSetAlgebraMemberIdentity`), so after those
          // we only check membership and then adopt the set's members.
          var syncTags = false
          switch random.roll(14) {
          case 0, 1, 2:
            let r = set.insert(item)
            expectEqual(r.inserted, model[v] == nil)
            // Inserting an existing value must keep the existing member.
            expectEqual(r.memberAfterInsert.tag, model[v] ?? step)
            if model[v] == nil { model[v] = step }
          case 3:
            let old = set.update(with: item)
            expectEqual(old?.tag, model[v])
            model[v] = step
          case 4, 5:
            let removed = set.remove(item)
            expectEqual(removed?.tag, model.removeValue(forKey: v))
          case 6:
            guard !set.isEmpty else { break }
            let offset = random.roll(set.count)
            let removed = set.remove(at: set.index(set.startIndex, offsetBy: offset))
            let key = model.keys.sorted()[offset]
            expectEqual(removed.value, key)
            expectEqual(removed.tag, model.removeValue(forKey: key))
          case 7:
            let n = random.roll(set.count + 1)
            let keys = model.keys.sorted()
            if random.roll(2) == 0 {
              set.removeFirst(n)
              for key in keys.prefix(n) { model[key] = nil }
            } else {
              set.removeLast(n)
              for key in keys.suffix(n) { model[key] = nil }
            }
          case 8:
            let (other, otherModel) = randomOther()
            set.formUnion(other)
            for (key, tag) in otherModel where model[key] == nil { model[key] = tag }
            syncTags = true
          case 9:
            let (other, otherModel) = randomOther()
            set.formIntersection(other)
            model = model.filter { otherModel[$0.key] != nil }
            syncTags = true
          case 10:
            let (other, otherModel) = randomOther()
            set.subtract(other)
            model = model.filter { otherModel[$0.key] == nil }
            syncTags = true
          case 11:
            let (other, otherModel) = randomOther()
            set.formSymmetricDifference(other)
            var result = model.filter { otherModel[$0.key] == nil }
            for (key, tag) in otherModel where model[key] == nil { result[key] = tag }
            model = result
            syncTags = true
          case 12:
            snapshots.append((set, model))
            if snapshots.count > 4 { snapshots.removeFirst() }
          default:
            // Range subscripts.
            let a = random.roll(domain + 1)
            let b = random.roll(domain + 1)
            let (lo, hi) = (min(a, b), max(a, b))
            let range = Tagged(value: lo, tag: 0) ..< Tagged(value: hi, tag: 0)
            expectEqualElements(
              set[range].map { $0.value },
              model.keys.filter { $0 >= lo && $0 < hi }.sorted())
            let from = Tagged(value: lo, tag: 0)...
            expectEqualElements(
              set[from].map { $0.value }, model.keys.filter { $0 >= lo }.sorted())
            let through = ...Tagged(value: hi, tag: 0)
            expectEqualElements(
              set[through].map { $0.value }, model.keys.filter { $0 <= hi }.sorted())
          }

          if syncTags {
            expectEqualElements(set.map { $0.value }, model.keys.sorted())
            model = Dictionary(uniqueKeysWithValues: set.map { ($0.value, $0.tag) })
          }
          let expected = model.sorted { $0.key < $1.key }
          expectEqual(set.count, model.count)
          expectEqualElements(set.map { $0.value }, expected.map { $0.key })
          expectEqualElements(set.map { $0.tag }, expected.map { $0.value })
          var backward: [Int] = []
          var i = set.endIndex
          while i != set.startIndex {
            set.formIndex(before: &i)
            backward.append(set[i].value)
          }
          expectEqualElements(backward, expected.map { $0.key }.reversed())
          for k in 0 ..< domain {
            let probe = Tagged(value: k, tag: 0)
            expectEqual(set.contains(probe), model[k] != nil, "value \(k)")
            let index = set.index(of: probe)
            expectEqual(index.map { set[$0].tag }, model[k], "value \(k)")
          }
          for (copy, copyModel) in snapshots {
            expectEqualElements(
              copy.map { $0.value }, copyModel.keys.sorted(), "snapshot changed")
          }
        }
      }
    }
  }
}

#endif
