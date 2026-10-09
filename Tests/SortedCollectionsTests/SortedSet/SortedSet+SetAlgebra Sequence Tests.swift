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

#if UnstableSortedCollections

import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import SortedCollections
import _CollectionsTestSupport
#endif

extension SortedSet: SetAPIChecker {}

class SortedSetSequenceOperationTests: CollectionTestCase {
  func test_union_sequence() {
    let a: SortedSet = [1, 2, 3]
    expectEqualElements(a.union(0 ..< 5), [0, 1, 2, 3, 4])
    expectEqualElements(a.union([3, 4, 4, 5]), [1, 2, 3, 4, 5])
    expectEqualElements(a.union(AnySequence([10, 1])), [1, 2, 3, 10])
    expectEqualElements(a.union(SortedSet([4, 5])), [1, 2, 3, 4, 5])

    var b = a
    b.formUnion(2 ..< 6)
    expectEqualElements(b, [1, 2, 3, 4, 5])
    b.formUnion(AnySequence([6, 6]))
    expectEqualElements(b, [1, 2, 3, 4, 5, 6])
  }

  func test_intersection_sequence() {
    let a: SortedSet = [1, 2, 3, 4]
    expectEqualElements(a.intersection(2 ..< 6), [2, 3, 4])
    expectEqualElements(a.intersection([4, 2, 2, 9]), [2, 4])
    expectEqualElements(a.intersection(AnySequence([3])), [3])
    expectEqualElements(a.intersection(SortedSet([2, 3])), [2, 3])

    var b = a
    b.formIntersection(3 ..< 10)
    expectEqualElements(b, [3, 4])
  }

  func test_symmetricDifference_sequence() {
    let a: SortedSet = [1, 2, 3]
    expectEqualElements(a.symmetricDifference(2 ..< 5), [1, 4])
    expectEqualElements(a.symmetricDifference([3, 3, 5]), [1, 2, 5])
    expectEqualElements(a.symmetricDifference(AnySequence([1, 2, 3])), [])

    var b = a
    b.formSymmetricDifference(0 ..< 2)
    expectEqualElements(b, [0, 2, 3])
  }

  func test_subtracting_sequence() {
    let a: SortedSet = [1, 2, 3, 4]
    expectEqualElements(a.subtracting(2 ..< 4), [1, 4])
    expectEqualElements(a.subtracting([4, 4, 9]), [1, 2, 3])
    expectEqualElements(a.subtracting(AnySequence<Int>([])), [1, 2, 3, 4])
    expectEqualElements(a.subtracting(SortedSet([1])), [2, 3, 4])

    var b = a
    b.subtract(1 ..< 3)
    expectEqualElements(b, [3, 4])
  }

  func test_isSubset_sequence() {
    let a: SortedSet = [2, 3]
    expectTrue(a.isSubset(of: 0 ..< 10))
    expectTrue(a.isSubset(of: [3, 2, 2]))
    expectTrue(a.isSubset(of: AnySequence([1, 2, 3])))
    expectTrue(a.isSubset(of: SortedSet([1, 2, 3])))
    expectFalse(a.isSubset(of: 0 ..< 3))
    expectFalse(a.isSubset(of: [Int]()))
  }

  func test_isStrictSubset_sequence() {
    let a: SortedSet = [2, 3]
    expectTrue(a.isStrictSubset(of: 0 ..< 10))
    expectFalse(a.isStrictSubset(of: [2, 3]))
    expectFalse(a.isStrictSubset(of: AnySequence([2, 3])))
    expectFalse(a.isStrictSubset(of: [2]))
  }

  func test_isSuperset_sequence() {
    let a: SortedSet = [1, 2, 3, 4]
    expectTrue(a.isSuperset(of: 2 ..< 4))
    expectTrue(a.isSuperset(of: [4, 2, 2]))
    expectTrue(a.isSuperset(of: AnySequence([1])))
    expectTrue(a.isSuperset(of: SortedSet([3])))
    expectFalse(a.isSuperset(of: 2 ..< 6))
    expectFalse(a.isSuperset(of: [9]))
  }

  func test_isStrictSuperset_sequence() {
    let a: SortedSet = [1, 2, 3, 4]
    expectTrue(a.isStrictSuperset(of: 2 ..< 4))
    expectFalse(a.isStrictSuperset(of: [1, 2, 3, 4]))
    expectFalse(a.isStrictSuperset(of: AnySequence([1, 2, 3, 4])))
    expectFalse(a.isStrictSuperset(of: [0]))
  }

  func test_isDisjoint_sequence() {
    let a: SortedSet = [1, 2, 3]
    expectTrue(a.isDisjoint(with: 10 ..< 20))
    expectTrue(a.isDisjoint(with: [9, 9]))
    expectTrue(a.isDisjoint(with: AnySequence<Int>([])))
    expectTrue(a.isDisjoint(with: SortedSet([4, 5])))
    expectTrue(SortedSet<Int>().isDisjoint(with: 1 ..< 3))
    expectFalse(a.isDisjoint(with: 3 ..< 5))
    expectFalse(a.isDisjoint(with: [2]))
  }
}

#endif
