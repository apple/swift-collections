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

import _CollectionsTestSupport
import PersistentCollections

extension PersistentSet: SetAPIChecker {}

class PersistentSetTests: CollectionTestCase {
  func test_init_empty() {
    let set = PersistentSet<Int>()
    expectEqual(set.count, 0)
    expectTrue(set.isEmpty)
    expectEqualElements(set, [])
  }

  func test_BidirectionalCollection_fixtures() {
    withEachFixture { fixture in
      withLifetimeTracking { tracker in
        let (set, ref) = tracker.persistentSet(for: fixture)
        checkBidirectionalCollection(set, expectedContents: ref, by: ==)
      }
    }
  }

  func test_BidirectionalCollection_random100() {
    let s = PersistentSet<Int>(0 ..< 100)
    checkBidirectionalCollection(s, expectedContents: Array(s))
  }

  func test_basics() {
    var set: PersistentSet<HashableBox<Int>> = []

    let a1 = HashableBox(1)
    let a2 = HashableBox(1)

    var r = set.insert(a1)
    expectTrue(r.inserted)
    expectIdentical(r.memberAfterInsert, a1)
    expectIdentical(set.first, a1)
    expectTrue(set.contains(a1))
    expectTrue(set.contains(a2))

    r = set.insert(a2)
    expectFalse(r.inserted)
    expectIdentical(r.memberAfterInsert, a1)
    expectIdentical(set.first, a1)
    expectTrue(set.contains(a1))
    expectTrue(set.contains(a2))

    var old = set.update(with: a2)
    expectIdentical(old, a1)
    expectIdentical(set.first, a2)
    expectTrue(set.contains(a1))
    expectTrue(set.contains(a2))

    old = set.remove(a1)
    expectIdentical(old, a2)
    expectNil(set.first)
    expectFalse(set.contains(a1))
    expectFalse(set.contains(a2))

    old = set.update(with: a1)
    expectNil(old)
    expectIdentical(set.first, a1)
    expectTrue(set.contains(a1))
    expectTrue(set.contains(a2))
  }

  func test_insert_fixtures() {
    withEachFixture { fixture in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var s: PersistentSet<LifetimeTracked<RawCollider>> = []
          var ref: Set<LifetimeTracked<RawCollider>> = []
          withEvery("i", in: 0 ..< fixture.count) { i in
            withHiddenCopies(if: isShared, of: &s) { s in
              let item = fixture.itemsInInsertionOrder[i]
              let key1 = tracker.instance(for: item)
              let r = s.insert(key1)
              expectTrue(r.inserted)
              expectEqual(r.memberAfterInsert, key1)

              let key2 = tracker.instance(for: item)
              ref.insert(key2)
              expectEqualSets(s, ref)
            }
          }
        }
      }
    }
  }

  func test_intersection_Self_basics() {
    let a = RawCollider(1, "A")
    let b = RawCollider(2, "B")
    let c = RawCollider(3, "C")

    let s0: PersistentSet<RawCollider> = []
    let s1: PersistentSet = [a, b]
    let s2: PersistentSet = [a, c]

    expectEqualSets(s0.intersection(s0), [])
    expectEqualSets(s1.intersection(s0), [])
    expectEqualSets(s0.intersection(s1), [])

    expectEqualSets(s1.intersection(s1), [a, b])
    expectEqualSets(s1.intersection(s2), [a])
    expectEqualSets(s2.intersection(s1), [a])

    let ab = RawCollider(4, "AB")
    let ac = RawCollider(5, "AC")
    let s3: PersistentSet = [ab, ac]
    let s4: PersistentSet = [a, ab]
    expectEqualSets(s1.intersection(s3), [])
    expectEqualSets(s2.intersection(s3), [])
    expectEqualSets(s1.intersection(s4), [a])
    expectEqualSets(s2.intersection(s4), [a])
    expectEqualSets(s3.intersection(s1), [])
    expectEqualSets(s3.intersection(s2), [])
    expectEqualSets(s4.intersection(s1), [a])
    expectEqualSets(s4.intersection(s2), [a])

    let ad = RawCollider(6, "AD")
    let ae = RawCollider(7, "AE")
    let s5: PersistentSet = [a, ab, ad, ae]
    expectEqualSets(s1.intersection(s5), [a])
    expectEqualSets(s2.intersection(s5), [a])
    expectEqualSets(s3.intersection(s5), [ab])
    expectEqualSets(s4.intersection(s5), [a, ab])

    expectEqualSets(s5.intersection(s1), [a])
    expectEqualSets(s5.intersection(s2), [a])
    expectEqualSets(s5.intersection(s3), [ab])
    expectEqualSets(s5.intersection(s4), [a, ab])

    let af1 = RawCollider(8, "AF")
    let af2 = RawCollider(9, "AF")
    let s6: PersistentSet = [af1, af2]
    expectEqualSets(s1.intersection(s6), [])
    expectEqualSets(s2.intersection(s6), [])
    expectEqualSets(s3.intersection(s6), [])
    expectEqualSets(s4.intersection(s6), [])
    expectEqualSets(s5.intersection(s6), [])

    expectEqualSets(s6.intersection(s1), [])
    expectEqualSets(s6.intersection(s2), [])
    expectEqualSets(s6.intersection(s3), [])
    expectEqualSets(s6.intersection(s4), [])
    expectEqualSets(s6.intersection(s5), [])

    let af3 = RawCollider(10, "AF")
    let s7: PersistentSet = [af1, af3]
    expectEqualSets(s1.intersection(s7), [])
    expectEqualSets(s2.intersection(s7), [])
    expectEqualSets(s3.intersection(s7), [])
    expectEqualSets(s4.intersection(s7), [])
    expectEqualSets(s5.intersection(s7), [])
    expectEqualSets(s6.intersection(s7), [af1])

    expectEqualSets(s7.intersection(s1), [])
    expectEqualSets(s7.intersection(s2), [])
    expectEqualSets(s7.intersection(s3), [])
    expectEqualSets(s7.intersection(s4), [])
    expectEqualSets(s7.intersection(s5), [])
    expectEqualSets(s7.intersection(s6), [af1])

    let s8: PersistentSet = [a, af1]
    expectEqualSets(s1.intersection(s8), [a])
    expectEqualSets(s2.intersection(s8), [a])
    expectEqualSets(s3.intersection(s8), [])
    expectEqualSets(s4.intersection(s8), [a])
    expectEqualSets(s5.intersection(s8), [a])
    expectEqualSets(s6.intersection(s8), [af1])
    expectEqualSets(s7.intersection(s8), [af1])

    expectEqualSets(s8.intersection(s1), [a])
    expectEqualSets(s8.intersection(s2), [a])
    expectEqualSets(s8.intersection(s3), [])
    expectEqualSets(s8.intersection(s4), [a])
    expectEqualSets(s8.intersection(s5), [a])
    expectEqualSets(s8.intersection(s6), [af1])
    expectEqualSets(s8.intersection(s7), [af1])

    let afa1 = RawCollider(11, "AFA")
    let afa2 = RawCollider(12, "AFA")
    let s9: PersistentSet = [afa1, afa2]
    expectEqualSets(s9.intersection(s6), [])
    expectEqualSets(s6.intersection(s9), [])
  }

  func test_isEqual_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      let u = Set(a)
      expectTrue(x.isEqual(to: x))
      withEverySubset("b", of: testItems) { b in
        let y = PersistentSet(b)
        let v = Set(b)

        let reference = (u == v)

        func checkSequence<S: Sequence>(
          _ a: PersistentSet<RawCollider>,
          _ b: S
        ) -> Bool
        where S.Element == RawCollider {
          a.isEqual(to: b)
        }

        expectEqual(x.isEqual(to: y), reference)
        expectEqual(checkSequence(x, y), reference)
        expectEqual(x.isEqual(to: v), reference)
        expectEqual(x.isEqual(to: b), reference)
      }
    }
  }

  func test_isSubset_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      let u = Set(a)
      expectTrue(x.isSubset(of: x))
      withEverySubset("b", of: testItems) { b in
        let y = PersistentSet(b)
        let v = Set(b)

        let reference = u.isSubset(of: v)

        func checkSequence<S: Sequence>(
          _ a: PersistentSet<RawCollider>,
          _ b: S
        ) -> Bool
        where S.Element == RawCollider {
          a.isSubset(of: b)
        }

        expectEqual(x.isSubset(of: y), reference)
        expectEqual(checkSequence(x, y), reference)
        expectEqual(x.isSubset(of: v), reference)
        expectEqual(x.isSubset(of: b), reference)
      }
    }
  }

  func test_isSuperset_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      let u = Set(a)
      expectTrue(x.isSuperset(of: x))
      withEverySubset("b", of: testItems) { b in
        let y = PersistentSet(b)
        let v = Set(b)

        let reference = u.isSuperset(of: v)

        func checkSequence<S: Sequence>(
          _ a: PersistentSet<RawCollider>,
          _ b: S
        ) -> Bool
        where S.Element == RawCollider {
          a.isSuperset(of: b)
        }

        expectEqual(x.isSuperset(of: y), reference)
        expectEqual(checkSequence(x, y), reference)
        expectEqual(x.isSuperset(of: v), reference)
        expectEqual(x.isSuperset(of: b), reference)
      }
    }
  }

  func test_isStrictsubset_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      let u = Set(a)
      expectFalse(x.isStrictSubset(of: x))
      withEverySubset("b", of: testItems) { b in
        let y = PersistentSet(b)
        let v = Set(b)

        let reference = u.isStrictSubset(of: v)

        func checkSequence<S: Sequence>(
          _ a: PersistentSet<RawCollider>,
          _ b: S
        ) -> Bool
        where S.Element == RawCollider {
          a.isStrictSubset(of: b)
        }

        expectEqual(x.isStrictSubset(of: y), reference)
        expectEqual(checkSequence(x, y), reference)
        expectEqual(x.isStrictSubset(of: v), reference)
        expectEqual(x.isStrictSubset(of: b), reference)
      }
    }
  }

  func test_isStrictSuperset_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      let u = Set(a)
      expectFalse(x.isStrictSuperset(of: x))
      withEverySubset("b", of: testItems) { b in
        let y = PersistentSet(b)
        let v = Set(b)

        let reference = u.isStrictSuperset(of: v)

        func checkSequence<S: Sequence>(
          _ a: PersistentSet<RawCollider>,
          _ b: S
        ) -> Bool
        where S.Element == RawCollider {
          a.isStrictSuperset(of: b)
        }

        expectEqual(x.isStrictSuperset(of: y), reference)
        expectEqual(checkSequence(x, y), reference)
        expectEqual(x.isStrictSuperset(of: v), reference)
        expectEqual(x.isStrictSuperset(of: b), reference)
      }
    }
  }

  func test_isDisjoint_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      let u = Set(a)
      expectEqual(x.isDisjoint(with: x), x.isEmpty)
      withEverySubset("b", of: testItems) { b in
        let y = PersistentSet(b)
        let v = Set(b)

        let reference = u.isDisjoint(with: v)

        func checkSequence<S: Sequence>(
          _ a: PersistentSet<RawCollider>,
          _ b: S
        ) -> Bool
        where S.Element == RawCollider {
          a.isDisjoint(with: b)
        }

        expectEqual(x.isDisjoint(with: y), reference)
        expectEqual(checkSequence(x, y), reference)
        expectEqual(x.isDisjoint(with: v), reference)
        expectEqual(x.isDisjoint(with: b), reference)
      }
    }
  }

  func test_intersection_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      let u = Set(a)
      expectEqualSets(x.intersection(x), u)
      withEverySubset("b", of: testItems) { b in
        let y = PersistentSet(b)
        let v = Set(b)

        let reference = u.intersection(v)

        func checkSequence<S: Sequence>(
          _ a: PersistentSet<RawCollider>,
          _ b: S
        ) -> PersistentSet<RawCollider>
        where S.Element == RawCollider {
          a.intersection(b)
        }

        expectEqualSets(x.intersection(y), reference)
        expectEqualSets(checkSequence(x, y), reference)
        expectEqualSets(x.intersection(v), reference)
        expectEqualSets(x.intersection(b), reference)
      }
    }
  }

  func test_subtracting_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      let u = Set(a)
      expectEqualSets(x.subtracting(x), [])
      withEverySubset("b", of: testItems) { b in
        let y = PersistentSet(b)
        let v = Set(b)

        let reference = u.subtracting(v)

        func checkSequence<S: Sequence>(
          _ a: PersistentSet<RawCollider>,
          _ b: S
        ) -> PersistentSet<RawCollider>
        where S.Element == RawCollider {
          a.subtracting(b)
        }

        expectEqualSets(x.subtracting(y), reference)
        expectEqualSets(checkSequence(x, y), reference)
        expectEqualSets(x.subtracting(v), reference)
        expectEqualSets(x.subtracting(b), reference)
      }
    }
  }

  func test_filter_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      withEverySubset("b", of: a) { b in
        let v = Set(b)
        expectEqualSets(x.filter { v.contains($0) }, v)
      }
    }
  }

  func test_union_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      let u = Set(a)
      expectEqualSets(x.union(x), u)
      withEverySubset("b", of: testItems) { b in
        let y = PersistentSet(b)
        let v = Set(b)

        let reference = u.union(v)

        func checkSequence<S: Sequence>(
          _ a: PersistentSet<RawCollider>,
          _ b: S
        ) -> PersistentSet<RawCollider>
        where S.Element == RawCollider {
          a.union(b)
        }

        expectEqualSets(x.union(y), reference)
        expectEqualSets(checkSequence(x, y), reference)
        expectEqualSets(x.union(v), reference)
        expectEqualSets(x.union(b), reference)
      }
    }
  }

  func test_symmetricDifference_exhaustive() {
    withEverySubset("a", of: testItems) { a in
      let x = PersistentSet(a)
      let u = Set(a)
      expectEqualSets(x.symmetricDifference(x), [])
      withEverySubset("b", of: testItems) { b in
        let y = PersistentSet(b)
        let v = Set(b)

        let reference = u.symmetricDifference(v)

        func checkSequence<S: Sequence>(
          _ a: PersistentSet<RawCollider>,
          _ b: S
        ) -> PersistentSet<RawCollider>
        where S.Element == RawCollider {
          a.symmetricDifference(b)
        }

        expectEqualSets(x.symmetricDifference(y), reference)
        expectEqualSets(checkSequence(x, y), reference)
        expectEqualSets(x.symmetricDifference(v), reference)
        expectEqualSets(x.symmetricDifference(b), reference)
      }
    }
  }
}
