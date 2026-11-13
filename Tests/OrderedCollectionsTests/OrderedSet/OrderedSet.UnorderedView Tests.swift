//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
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
import OrderedCollections
import _CollectionsTestSupport
#endif

// Note: This cannot really work unless `UnorderedView` becomes a Collection.
// extension OrderedSet.UnorderedView: SetAPIChecker {}

class OrderedSetUnorderedViewTests: CollectionTestCase {
  func test_Equatable_Hashable() {
    let samples: [[OrderedSet<Int>]] = [
      [[], OrderedSet(minimumCapacity: 100, persistent: true)],
      [[1], OrderedSet(_scale: 5, bias: 7, contents: [1])],
      [[2], [2]],
      [[1, 2], [2, 1]],
      [[1, 2, 3], [3, 1, 2],
       OrderedSet(_scale: 5, bias: 3, contents: [2, 3, 1])],
      [[1, 2, 4], [4, 2, 1]],
      [OrderedSet(0 ..< 15),
       OrderedSet(_scale: 5, bias: 0, contents: (0 ..< 15).reversed())],
      [OrderedSet(0 ..< 16), OrderedSet((0 ..< 16).reversed())],
      [OrderedSet(1 ..< 17), OrderedSet((1 ..< 17).reversed())],
    ]
    checkHashable(equivalenceClasses: samples.map { $0.map { $0.unordered }})
  }

  func test_unordered_insert() {
    withEvery("count", in: 0 ..< 20) { count in
      withEvery("dupes", in: 1 ... 3) { dupes in
        withLifetimeTracking { tracker in
          let input = (0 ..< dupes * count)
            .map { tracker.instance(for: $0 / dupes) }
            .shuffled()
          let reference: [Int: LifetimeTracked<Int>] =
            .init(input.lazy.map { ($0.payload, $0) },
                  uniquingKeysWith: { a, b in a })
          var set = OrderedSet<LifetimeTracked<Int>>()
          withEvery("offset", in: input.indices) { offset in
            let item = input[offset]
            let ref = reference[item.payload]
            let (inserted, member) = set.unordered.insert(item)
            expectEqual(inserted, ref === item)
            expectEqual(member, item)
            expectIdentical(member, ref)
            expectTrue(set.contains(item))
          }
        }
      }
    }
    // Check CoW copying behavior
    do {
      var set = OrderedSet<Int>(0 ..< 30)
      let copy = set
      expectTrue(set.unordered.insert(30).inserted)
      expectTrue(set.contains(30))
      expectFalse(copy.contains(30))
    }
  }

  func test_unordered_update() {
    withEvery("count", in: 0 ..< 20) { count in
      withEvery("dupes", in: 1 ... 3) { dupes in
        withLifetimeTracking { tracker in
          let input = (0 ..< dupes * count)
            .map { tracker.instance(for: $0 / dupes) }
            .shuffled()
          var reference: [Int: LifetimeTracked<Int>] = [:]
          var set = OrderedSet<LifetimeTracked<Int>>()
          withEvery("offset", in: input.indices) { offset in
            let item = input[offset]
            let old = set.unordered.update(with: item)
            expectIdentical(old, reference[item.payload])
            reference[item.payload] = item
            expectTrue(set.contains(item))
          }
        }
      }
    }
    // Check CoW copying behavior
    do {
      var set = OrderedSet<Int>(0 ..< 30)
      let copy = set
      expectNil(set.unordered.update(with: 30))
      expectTrue(set.contains(30))
      expectFalse(copy.contains(30))
    }
  }

  func test_SetAlgebraMemberIdentity() {
    checkSetAlgebraMemberIdentity(
      OrderedSet<LifetimeTracked<Int>>.UnorderedView.self,
      models: [[], [0], [0, 1, 2, 3], Set(stride(from: 0, to: 200, by: 2))],
      members: { Array(OrderedSet($0)) })
  }

  static let samples: [[Int]] = [
    [], [0], [3], [0, 1], [1, 0], [2, 3, 0], [3, 2, 1, 0], [0, 1, 2, 3],
    [4, 1, 5, 0], Array(stride(from: 0, to: 32, by: 2)),
    Array((5 ..< 25).reversed()),
  ]

  func withEverySamplePair(_ body: ([Int], [Int]) -> Void) {
    withEvery("a", in: Self.samples) { a in
      withEvery("b", in: Self.samples) { b in
        body(a, b)
      }
    }
  }

  func test_initializers() {
    withEvery("a", in: Self.samples) { a in
      typealias View = OrderedSet<Int>.UnorderedView
      expectEqualElements(OrderedSet(View(a + a)), a)
      expectEqualElements(OrderedSet(View(OrderedSet(a).unordered)), a)
      let fromSet = OrderedSet(View(Set(a)))
      expectEqual(fromSet.count, a.count)
      expectEqual(Set(fromSet), Set(a))
      let keys = Dictionary(uniqueKeysWithValues: a.map { ($0, $0) }).keys
      let fromKeys = OrderedSet(View(keys))
      expectEqual(fromKeys.count, a.count)
      expectEqual(Set(fromKeys), Set(a))
    }
    expectEqualElements(OrderedSet(OrderedSet<Int>.UnorderedView()), [])
    let literal: OrderedSet<Int>.UnorderedView = [3, 1, 2, 1]
    expectEqualElements(OrderedSet(literal), [3, 1, 2])
  }

  func test_descriptions() {
    withEvery("a", in: Self.samples) { a in
      let view = OrderedSet(a).unordered
      expectEqual(view.description, "\(a)")
      expectEqual(view.debugDescription, view.description)
      let mirror = view.customMirror
      expectEqual(mirror.displayStyle, .collection)
      expectEqualElements(mirror.children.map { $0.value as! Int }, a)
    }
  }

  func test_union() {
    withEverySamplePair { a, b in
      let expected = a + b.filter { !a.contains($0) }
      let x = OrderedSet(a).unordered
      let y = OrderedSet(b).unordered
      expectEqualElements(OrderedSet(x.union(y)), expected)
      expectEqualElements(OrderedSet(x.union(b + b)), expected)
      var z = x
      z.formUnion(y)
      expectEqualElements(OrderedSet(z), expected)
      z = x
      z.formUnion(b + b)
      expectEqualElements(OrderedSet(z), expected)
    }
  }

  func test_intersection() {
    withEverySamplePair { a, b in
      let expected = a.filter { b.contains($0) }
      let x = OrderedSet(a).unordered
      let y = OrderedSet(b).unordered
      expectEqualElements(OrderedSet(x.intersection(y)), expected)
      expectEqualElements(OrderedSet(x.intersection(b + b)), expected)
      var z = x
      z.formIntersection(y)
      expectEqualElements(OrderedSet(z), expected)
      z = x
      z.formIntersection(b + b)
      expectEqualElements(OrderedSet(z), expected)
    }
  }

  func test_symmetricDifference() {
    withEverySamplePair { a, b in
      let expected =
        a.filter { !b.contains($0) } + b.filter { !a.contains($0) }
      let x = OrderedSet(a).unordered
      let y = OrderedSet(b).unordered
      expectEqualElements(OrderedSet(x.symmetricDifference(y)), expected)
      expectEqualElements(OrderedSet(x.symmetricDifference(b + b)), expected)
      var z = x
      z.formSymmetricDifference(y)
      expectEqualElements(OrderedSet(z), expected)
      z = x
      z.formSymmetricDifference(b + b)
      expectEqualElements(OrderedSet(z), expected)
    }
  }

  func test_subtracting() {
    withEverySamplePair { a, b in
      let expected = a.filter { !b.contains($0) }
      let x = OrderedSet(a).unordered
      let y = OrderedSet(b).unordered
      expectEqualElements(OrderedSet(x.subtracting(y)), expected)
      expectEqualElements(OrderedSet(x.subtracting(b + b)), expected)
      var z = x
      z.subtract(y)
      expectEqualElements(OrderedSet(z), expected)
      z = x
      z.subtract(b + b)
      expectEqualElements(OrderedSet(z), expected)
    }
  }

  func test_predicates() {
    withEverySamplePair { a, b in
      let x = OrderedSet(a).unordered
      let y = OrderedSet(b).unordered
      let setA = Set(a)
      let setB = Set(b)
      let seqB = b + b
      expectEqual(x == y, setA == setB)
      expectEqual(x.isEqualSet(to: y), setA == setB)
      expectEqual(x.isEqualSet(to: seqB), setA == setB)

      let isSubset = setA.isSubset(of: setB)
      expectEqual(x.isSubset(of: y), isSubset)
      expectEqual(x.isSubset(of: setB), isSubset)
      expectEqual(x.isSubset(of: seqB), isSubset)

      let isSuperset = setA.isSuperset(of: setB)
      expectEqual(x.isSuperset(of: y), isSuperset)
      expectEqual(x.isSuperset(of: setB), isSuperset)
      expectEqual(x.isSuperset(of: seqB), isSuperset)

      let isStrictSubset = setA.isStrictSubset(of: setB)
      expectEqual(x.isStrictSubset(of: y), isStrictSubset)
      expectEqual(x.isStrictSubset(of: setB), isStrictSubset)
      expectEqual(x.isStrictSubset(of: seqB), isStrictSubset)

      let isStrictSuperset = setA.isStrictSuperset(of: setB)
      expectEqual(x.isStrictSuperset(of: y), isStrictSuperset)
      expectEqual(x.isStrictSuperset(of: setB), isStrictSuperset)
      expectEqual(x.isStrictSuperset(of: seqB), isStrictSuperset)

      let isDisjoint = setA.isDisjoint(with: setB)
      expectEqual(x.isDisjoint(with: y), isDisjoint)
      expectEqual(x.isDisjoint(with: setB), isDisjoint)
      expectEqual(x.isDisjoint(with: seqB), isDisjoint)
    }
  }
}
