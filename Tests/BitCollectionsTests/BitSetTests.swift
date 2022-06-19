//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import _CollectionsTestSupport
import BitCollections

final class BitSetTest: CollectionTestCase {
  func test_empty_initializer() {
    let set = BitSet()
    expectEqual(set.count, 0)
    expectTrue(set.isEmpty)
    expectEqualElements(set, [])
  }

  func test_array_literal_initializer() {
    let set0: BitSet = []
    expectEqual(set0.count, 0)
    expectTrue(set0.isEmpty)
    expectEqualElements(set0, [])

    let set1: BitSet = [0, 3, 50, 10, 21, 11, 3, 100, 300, 20]
    expectEqual(set1.count, 9)
    expectEqualElements(set1, [0, 3, 10, 11, 20, 21, 50, 100, 300])
  }

  func test_sequence_initializer() {
    withEvery("i", in: 0 ..< 100) { i in
      var rng = RepeatableRandomNumberGenerator(seed: i)
      let input = (0 ..< 1000).shuffled(using: &rng).prefix(100)
      let expected = input.sorted()
      let actual = BitSet(input)
      expectEqual(actual.count, expected.count)
      expectEqualElements(actual, expected)

      let actual2 = BitSet(actual)
      expectEqualElements(actual2, actual)
    }
  }

  func test_range_initializer() {
    withEveryRange("range", in: 0 ..< 200) { range in
      let set = BitSet(range)
      expectEqualElements(set, range)
    }
  }

  func test_bitPattern_initializer() {
    let s1 = BitSet(bitPattern: 0 as UInt)
    expectEqualElements(s1, [])

    let s2 = BitSet(bitPattern: 1 as UInt)
    expectEqualElements(s2, [0])

    let s3 = BitSet(bitPattern: 2 as UInt)
    expectEqualElements(s3, [1])

    let s4 = BitSet(bitPattern: 23)
    expectEqualElements(s4, [0, 1, 2, 4])

    let s5 = BitSet(bitPattern: -1)
    expectEqualElements(s5, 0 ..< UInt.bitWidth)
  }

  func test_collection_strides() {
    withEvery("stride", in: [1, 2, 3, 5, 7, 8, 11, 13, 63, 79, 300]) { stride in
      withEvery("count", in: [0, 1, 2, 5, 10, 20, 25]) { count in
        let input = Swift.stride(from: 0, to: stride * count, by: stride)
        let expected = Array(input)
        let actual = BitSet(input)
        checkBidirectionalCollection(actual, expectedContents: expected)
      }
    }
  }

  func withInterestingSets(
    _ label: String,
    maximum: Int,
    file: StaticString = #file,
    line: UInt = #line,
    run body: (Set<Int>) -> Void
  ) {
    let context = TestContext.current
    func yield(_ desc: String, _ set: Set<Int>) {
      let entry = context.push(
        "\(label): \(desc)", file: file, line: line)
      defer { context.pop(entry) }
      body(set)
    }

    yield("empty", [])
    yield("full", Set(0 ..< maximum))
    var rng = RepeatableRandomNumberGenerator(seed: 0)
    let c = 10

    func randomSelection(_ desc: String, count: Int) {
      // 1% filled
      for i in 0 ..< c {
        let set = Set((0 ..< maximum)
                        .shuffled(using: &rng)
                        .prefix(count))
        yield("\(desc)/\(i)", set)
      }
    }
    if maximum > 100 {
      randomSelection("1%", count: maximum / 100)
      randomSelection("9%", count: 9 * maximum / 100)
    }
    randomSelection("50%", count: maximum / 2)

    let a = maximum / 3
    let b = 2 * maximum / 3
    yield("0..<a", Set(0 ..< a))
    yield("a..<b", Set(a ..< b))
    yield("b..<max", Set(b ..< maximum))
    yield("0..<b", Set(0 ..< b))
    yield("a..<max", Set(a ..< maximum))
  }

  func test_firstIndexOf_lastIndexOf() {
    let max = 1000
    withInterestingSets("input", maximum: max) { input in
      let bits = BitSet(input)
      withEvery("value", in: 0 ..< max) { value in
        if input.contains(value) {
          expectNotNil(bits.firstIndex(of: value)) { i in
            expectEqual(bits[i], value)
            expectNotNil(bits.lastIndex(of: value)) { j in
              expectEqual(i, j)
            }
          }
        } else {
          expectNil(bits.firstIndex(of: value))
          expectNil(bits.lastIndex(of: value))
        }
      }
    }
  }

  func test_hashable() {
    // This is a silly test, but it does exercise hashing a bit.
    let classes: [[BitSet]] = [
      [[]],
      [[1]],
      [[2]],
      [[1, 5, 10], [10, 5, 1]],
      [[1, 5, 11], [11, 5, 1]],
      [[1, 5, 100], [100, 5, 1]],
    ]
    checkHashable(equivalenceClasses: classes)
  }

  func test_contains_Int() {
    withInterestingSets("input", maximum: 1000) { input in
      let bitset = BitSet(input)
      withEvery("value", in: 0 ..< 1000) { value in
        expectEqual(bitset.contains(value), input.contains(value))
      }
      expectFalse(bitset.contains(-1))
      expectFalse(bitset.contains(5000))
    }
  }

  func test_contains_Int32() {
    withInterestingSets("input", maximum: 1000) { input in
      let bitset = BitSet(input)
      withEvery("value", in: 0 ..< 1000) { value in
        expectEqual(bitset.contains(Int32(value)), input.contains(value))
      }
      expectFalse(bitset.contains(-1 as Int32))
      expectFalse(bitset.contains(5000 as Int32))
    }
  }

  func test_contains_Sequence() {
    // This exercises the `_customContainsEquatableElement`
    // implementation in `BitSet`'s `Sequence` conformance.
    withInterestingSets("input", maximum: 1000) { input in
      func check<S: Sequence>(_ seq: S)
      where S.Element == Int
      {
        withEvery("value", in: 0 ..< 1000) { value in
          expectEqual(seq.contains(value), input.contains(value))
        }
        expectFalse(seq.contains(-1))
        expectFalse(seq.contains(5000))
      }
      let bitset = BitSet(input)
      check(bitset)
    }
  }

  func checkInsert<F: FixedWidthInteger>(for type: F.Type, count: Int) {
    withEvery("seed", in: 0 ..< 10) { seed in
      var rng = RepeatableRandomNumberGenerator(seed: seed)
      var actual: BitSet = []
      var expected: Set<Int> = []
      let input = (0 ..< count).shuffled(using: &rng)
      withEvery("i", in: input.indices) { i in
        let (i1, m1) = actual.insert(F(input[i]))
        expected.insert(input[i])
        expectTrue(i1)
        expectEqual(m1, F(input[i]))
        if i % 25 == 0 {
          expectEqual(Array(actual), expected.sorted())
        }
        let (i2, m2) = actual.insert(F(input[i]))
        expectFalse(i2)
        expectEqual(m2, m1)
      }
      expectEqual(Array(actual), expected.sorted())
    }
  }

  func test_insert_Int() {
    checkInsert(for: Int.self, count: 100)
  }
  func test_insert_Int32() {
    checkInsert(for: Int32.self, count: 100)
  }
  func test_insert_UInt16() {
    checkInsert(for: UInt16.self, count: 100)
  }

  func checkUpdate<F: FixedWidthInteger>(for type: F.Type, count: Int) {
    withEvery("seed", in: 0 ..< 10) { seed in
      var rng = RepeatableRandomNumberGenerator(seed: seed)
      var actual: BitSet = []
      var expected: Set<Int> = []
      let input = (0 ..< count).shuffled(using: &rng)
      withEvery("i", in: input.indices) { i in
        let old = actual.update(with: F(input[i]))
        expected.update(with: input[i])
        expectEqual(old, F(input[i]))
        if i % 25 == 0 {
          expectEqual(Array(actual), expected.sorted())
        }
        expectNil(actual.update(with: F(input[i])))
      }
      expectEqual(Array(actual), expected.sorted())
    }
  }

  func test_update_Int() {
    checkUpdate(for: Int.self, count: 100)
  }
  func test_update_Int32() {
    checkUpdate(for: Int32.self, count: 100)
  }
  func test_update_UInt16() {
    checkUpdate(for: UInt16.self, count: 100)
  }

  func test_remove_Int() {
    func checkRemove<F: FixedWidthInteger>(for type: F.Type, count: Int) {
      context.withTrace("\(type)") {
        withEvery("seed", in: 0 ..< 10) { seed in
          var rng = RepeatableRandomNumberGenerator(seed: seed)
          var actual = BitSet(0 ..< count)
          var expected = Set<Int>(0 ..< count)
          let input = (0 ..< count).shuffled(using: &rng)

          if F.isSigned {
            expectNil(actual.remove(F(-1)))
          }

          withEvery("i", in: input.indices) { i in
            let v = input[i]
            let old = actual.remove(F(v))
            expected.remove(v)
            expectEqual(old, F(v))
            if i % 25 == 0 {
              expectEqual(Array(actual), expected.sorted())
            }
            expectNil(actual.remove(F(v)))
          }
          expectEqual(Array(actual), expected.sorted())
        }
      }
    }

    checkRemove(for: Int.self, count: 100)
    checkRemove(for: Int32.self, count: 100)
    checkRemove(for: UInt16.self, count: 100)
  }

  func test_union_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.union(b).sorted()
        let c = BitSet(a)
        let d = BitSet(b)
        let actual = c.union(d)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_union_Sequence() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.union(b).sorted()
        let c = BitSet(a)
        let actual = c.union(b)
        expectEqualElements(actual, expected)

        func union<S: Sequence>(_ first: BitSet, _ second: S) -> BitSet
        where S.Element: FixedWidthInteger {
          first.union(second)
        }
        expectEqualElements(union(c, BitSet(b)), expected)
      }
    }
  }

  func test_union_Range() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in
      let a = BitSet()

      let b = a.union(0 ..< 5*step)
      expectEqualElements(b, 0 ..< 5*step)

      let c = b.union(0 ..< 10*step)
      expectEqualElements(c, 0 ..< 10*step)

      let d = c.union(50*step ..< 50*step)
      expectEqualElements(d, 0 ..< 10*step)

      let e = d.union(20*step ..< 30*step)
      expectEqualElements(e, Array(0 ..< 10*step) + Array(20*step ..< 30*step))

      let f = e.union(5*step ..< 25*step)
      expectEqualElements(f, 0 ..< 30*step)

      let g = f.union(30*step ..< 30*step)
      expectEqualElements(g, 0 ..< 30*step)
    }
  }

  func test_formUnion_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.union(b).sorted()
        var c = BitSet(a)
        let d = BitSet(b)
        c.formUnion(d)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_formUnion_Sequence() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.union(b).sorted()
        var c = BitSet(a)
        c.formUnion(b)
        expectEqualElements(c, expected)

        func union<S: Sequence>(_ first: inout BitSet, _ second: S)
        where S.Element: FixedWidthInteger {
          first.formUnion(second)
        }
        var d = BitSet(a)
        union(&d, BitSet(b))
        expectEqualElements(d, expected)
        union(&d, 0 ..< 200)
        expectEqualElements(d, 0 ..< 200)
      }
    }
  }

  func test_formUnion_Range() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in
      var a = BitSet()

      a.formUnion(0 ..< 5*step)
      expectEqualElements(a, 0 ..< 5*step)

      a.formUnion(0 ..< 10*step)
      expectEqualElements(a, 0 ..< 10*step)

      a.formUnion(50*step ..< 50*step)
      expectEqualElements(a, 0 ..< 10*step)

      a.formUnion(20*step ..< 30*step)
      expectEqualElements(a, Array(0 ..< 10*step) + Array(20*step ..< 30*step))

      a.formUnion(5*step ..< 25*step)
      expectEqualElements(a, 0 ..< 30*step)

      a.formUnion(30*step ..< 30*step)
      expectEqualElements(a, 0 ..< 30*step)
    }
  }

  func test_intersection_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.intersection(b).sorted()
        let c = BitSet(a)
        let d = BitSet(b)
        let actual = c.intersection(d)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_intersection_Sequence() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.intersection(b).sorted()
        let c = BitSet(a)
        let actual = c.intersection(b)
        expectEqualElements(actual, expected)

        expectEqualElements(c.intersection([-100]), [])
        expectEqualElements(c.intersection(-100 ..< -10), [])

        func intersection<S: Sequence>(_ first: BitSet, _ second: S) -> BitSet
        where S.Element: FixedWidthInteger {
          first.intersection(second)
        }
        let d = intersection(c, BitSet(b))
        expectEqualElements(d, expected)
        let e = intersection(d, 40 ..< 60)
        expectEqualElements(e, expected.filter { (40 ..< 60).contains($0) })
      }
    }
  }

  func test_intersection_Range() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in
      let a = BitSet(0 ..< 10*step)
      let b = a.intersection(10*step ..< 20*step)
      expectEqualElements(b, [])

      let c = a.intersection(0 ..< 10*step)
      expectEqualElements(c, 0 ..< 10*step)

      let d = a.intersection(0 ..< 5*step)
      expectEqualElements(d, 0 ..< 5*step)

      let e = d.intersection(20*step ..< 20*step)
      expectEqualElements(e, [])

      let f = a.intersection(-100*step ..< -10*step)
      expectEqualElements(f, [])

      let g = a.intersection(-100*step ..< 10*step)
      expectEqualElements(g, 0 ..< 10*step)
    }
  }

  func test_formIntersection_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.intersection(b).sorted()
        var c = BitSet(a)
        let d = BitSet(b)
        c.formIntersection(d)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_formIntersection_Sequence() {
    func intersection<S: Sequence>(_ first: inout BitSet, _ second: S)
    where S.Element: FixedWidthInteger {
      first.formIntersection(second)
    }

    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.intersection(b).sorted()
        var c = BitSet(a)
        c.formIntersection(b)
        expectEqualElements(c, expected)

        var d = BitSet(a)
        intersection(&d, BitSet(b))
        expectEqualElements(d, expected)

        intersection(&d, 40 ..< 60)
        expectEqualElements(d, expected.filter { (40 ..< 60).contains($0) })
      }
    }

    var s = BitSet(0 ..< 100)
    intersection(&s, [-100, -10, 0, 1, 2])
    expectEqualElements(s, [0, 1, 2])

    intersection(&s, -100 ..< -10)
    expectEqualElements(s, [])

    s = BitSet(0 ..< 100)
    intersection(&s, -100 ..< 10)
    expectEqualElements(s, 0 ..< 10)
  }

  func test_formIntersection_Range() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in
      var a = BitSet(0 ..< 10*step)
      a.formIntersection(10*step ..< 20*step)
      expectEqualElements(a, [])

      var b = BitSet(0 ..< 10*step)
      b.formIntersection(0 ..< 10*step)
      expectEqualElements(b, 0 ..< 10*step)

      var c = BitSet(0 ..< 10*step)
      c.formIntersection(0 ..< 5*step)
      expectEqualElements(c, 0 ..< 5*step)

      var d = BitSet(0 ..< 10*step)
      d.formIntersection(20*step ..< 20*step)
      expectEqualElements(d, [])

      var e = BitSet(0 ..< 100*step)
      e.formIntersection(50*step ..< 100*step)
      expectEqualElements(e, 50*step ..< 100*step)

      var f = BitSet(0 ..< 100*step)
      f.formIntersection(-100*step ..< -10*step)
      expectEqualElements(f, [])

      var g = BitSet(0 ..< 100*step)
      g.formIntersection(-100*step ..< 10*step)
      expectEqualElements(g, 0 ..< 10 * step)
    }
  }

  func test_symmetricDifference_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.symmetricDifference(b).sorted()
        let c = BitSet(a)
        let d = BitSet(b)
        let actual = c.symmetricDifference(d)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_symmetricDifference_Sequence() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.symmetricDifference(b).sorted()
        let c = BitSet(a)
        let actual = c.symmetricDifference(b)
        expectEqualElements(actual, expected)

        func symmetricDifference<S: Sequence>(
          _ first: BitSet,
          _ second: S
        ) -> BitSet
        where S.Element: FixedWidthInteger {
          first.symmetricDifference(second)
        }
        let d = symmetricDifference(c, BitSet(b))
        expectEqualElements(d, expected)
        let e = symmetricDifference(d, 40 ..< 60)
        let expected2 = a
          .symmetricDifference(b)
          .symmetricDifference(40 ..< 60)
          .sorted()
        expectEqualElements(e, expected2)
      }
    }
  }

  func test_symmetricDifference_Range() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in
      let a = BitSet()

      let b = a.symmetricDifference(0 ..< 10*step)
      expectEqualElements(b, 0 ..< 10*step)

      let c = b.symmetricDifference(5*step ..< 10*step)
      expectEqualElements(c, 0 ..< 5*step)

      let d = b.symmetricDifference(0 ..< 5*step)
      expectEqualElements(d, 5*step ..< 10*step)

      let e = b.symmetricDifference(3*step ..< 7*step)
      expectEqualElements(e, Array(0 ..< 3*step) + Array(7*step ..< 10*step))

      let f = e.symmetricDifference(20*step ..< 20*step)
      expectEqualElements(f, e)
    }
  }

  func test_formSymmetricDifference_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.symmetricDifference(b).sorted()
        var c = BitSet(a)
        let d = BitSet(b)
        c.formSymmetricDifference(d)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_formSymmetricDifference_Sequence() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.symmetricDifference(b).sorted()
        var c = BitSet(a)
        c.formSymmetricDifference(b)
        expectEqualElements(c, expected)

        func symmetricDifference<S: Sequence>(
          _ first: inout BitSet,
          _ second: S
        ) where S.Element: FixedWidthInteger {
          first.formSymmetricDifference(second)
        }
        var d = BitSet(a)
        symmetricDifference(&d, BitSet(b))
        expectEqualElements(d, expected)
        symmetricDifference(&d, 40 ..< 60)
        let expected2 = a
          .symmetricDifference(b)
          .symmetricDifference(40 ..< 60)
          .sorted()
        expectEqualElements(d, expected2)
      }
    }
  }

  func test_formSymmetricDifference_Range() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in
      var a = BitSet()

      a.formSymmetricDifference(0 ..< 10*step)
      expectEqualElements(a, 0 ..< 10*step)

      a.formSymmetricDifference(5*step ..< 10*step)
      expectEqualElements(a, 0 ..< 5*step)

      a.formSymmetricDifference(0 ..< 5*step)
      expectEqualElements(a, [])

      a = BitSet(0 ..< 10*step)
      a.formSymmetricDifference(3*step ..< 7*step)
      expectEqualElements(a, Array(0 ..< 3*step) + Array(7*step ..< 10*step))

      a.formSymmetricDifference(20*step ..< 20*step)
      expectEqualElements(a, Array(0 ..< 3*step) + Array(7*step ..< 10*step))
    }
  }

  func test_subtracting_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.subtracting(b).sorted()
        let c = BitSet(a)
        let d = BitSet(b)
        let actual = c.subtracting(d)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_subtracting_Sequence() {
    func subtracting<S: Sequence>(
      _ first: BitSet,
      _ second: S
    ) -> BitSet
    where S.Element: FixedWidthInteger {
      first.subtracting(second)
    }

    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.subtracting(b).sorted()
        let c = BitSet(a)
        let actual = c.subtracting(b)
        expectEqualElements(actual, expected)

        expectEqual(c.subtracting([-100]), c)
        expectEqual(subtracting(c, -100 ..< -10), c)

        let d = subtracting(c, BitSet(b))
        expectEqualElements(d, expected)
        let e = subtracting(d, 40 ..< 60)
        expectEqualElements(
          e, expected.filter { !(40 ..< 60).contains($0)})
      }
    }
  }

  func test_subtracting_Range() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in
      let a = BitSet(0 ..< 10*step)

      let b = a.subtracting(9*step ..< 11*step)
      expectEqualElements(b, 0 ..< 9*step)

      let c = b.subtracting(-1*step ..< 1*step)
      expectEqualElements(c, 1*step ..< 9*step)

      let expected = Array(1*step ..< 4*step) + Array(6*step ..< 9*step)
      let d = c.subtracting(4*step ..< 6*step)
      expectEqualElements(d, expected)

      let e = d.subtracting(10*step ..< 100*step)
      expectEqualElements(e, expected)

      let f = e.subtracting(-10*step ..< -1*step)
      expectEqualElements(f, expected)
    }
  }

  func test_subtract_Self() {
    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.subtracting(b).sorted()
        var c = BitSet(a)
        let d = BitSet(b)
        c.subtract(d)
        expectEqualElements(c, expected)
      }
    }
  }

  func test_subtract_Sequence() {
    func subtract<S: Sequence>(
      _ first: inout BitSet,
      _ second: S
    )
    where S.Element: FixedWidthInteger {
      first.subtract(second)
    }

    withInterestingSets("a", maximum: 200) { a in
      withInterestingSets("b", maximum: 200) { b in
        let expected = a.subtracting(b).sorted()
        var c = BitSet(a)
        c.subtract(b)
        expectEqualElements(c, expected)

        subtract(&c, [-100])
        expectEqualElements(c, expected)

        subtract(&c, -100 ..< -10)
        expectEqualElements(c, expected)

        var d = BitSet(a)
        subtract(&d, BitSet(b))
        expectEqualElements(d, expected)

        subtract(&d, 40 ..< 60)
        expectEqualElements(
          d, expected.filter { !(40 ..< 60).contains($0)})
      }
    }
  }

  func test_subtract_Range() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in
      var a = BitSet(0 ..< 10*step)

      a.subtract(9*step ..< 11*step)
      expectEqualElements(a, 0 ..< 9*step)

      a.subtract(-1*step ..< 1*step)
      expectEqualElements(a, 1*step ..< 9*step)

      let expected = Array(1*step ..< 4*step) + Array(6*step ..< 9*step)
      a.subtract(4*step ..< 6*step)
      expectEqualElements(a, expected)

      a.subtract(10*step ..< 100*step)
      expectEqualElements(a, expected)

      a.subtract(-10*step ..< -1*step)
      expectEqualElements(a, expected)
    }
  }

  func test_isSubset() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in

      let inputs: [String: BitSet] = [
        "empty": BitSet(),
        "a": BitSet(10*step ..< 20*step),
        "b": BitSet(10*step ..< 20*step).subtracting(13*step ..< 14*step),
        "c": BitSet(10*step ..< 20*step - 1),
      ]

      let tests: [(range: Range<Int>, expected: Set<String>)] = [
        ( 10*step ..< 12*step, ["empty"]),
        ( 12*step ..< 18*step, ["empty"]),
        ( 18*step ..< 20*step, ["empty"]),
        ( 11*step ..< 21*step, ["empty"]),
        (  9*step ..< 19*step, step > 1 ? ["empty"] : ["empty", "c"]),
        ( 10*step ..< 20*step, ["empty", "a", "b", "c"]),
        ( 10*step ..< 20*step - 1, ["empty", "c"]),
        (-10*step ..< 20*step, ["empty", "a", "b", "c"]),
        ( 10*step ..< 21*step, ["empty", "a", "b", "c"]),
        ( 15*step ..< 15*step, ["empty"]),
      ]

      withEvery("input", in: inputs.keys) { input in
        let set = inputs[input]!
        expectTrue(set.isSubset(of: set))

        withEvery("test", in: tests) { test in
          let expected = test.expected.contains(input)

          func forceSequence<S: Sequence>(_ other: S) -> Bool
          where S.Element: FixedWidthInteger {
            set.isSubset(of: other)
          }

          if test.range.lowerBound >= 0 {
            expectEqual(set.isSubset(of: BitSet(test.range)), expected)
            expectEqual(forceSequence(BitSet(test.range)), expected)
          }

          expectEqual(set.isSubset(of: Array(test.range)), expected)

          expectEqual(set.isSubset(of: test.range), expected)
          expectEqual(forceSequence(test.range), expected)
        }
      }
    }
  }

  func test_isStrictSubset() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in

      let inputs: [String: BitSet] = [
        "empty": BitSet(),
        "a": BitSet(10*step ..< 20*step),
        "b": BitSet(10*step ..< 20*step).subtracting(13*step ..< 14*step),
        "c": BitSet(10*step ..< 20*step - 1),
      ]

      let tests: [(range: Range<Int>, expected: Set<String>)] = [
        ( 10*step ..< 12*step, ["empty"]),
        ( 12*step ..< 18*step, ["empty"]),
        ( 18*step ..< 20*step, ["empty"]),
        ( 11*step ..< 21*step, ["empty"]),
        (  9*step ..< 19*step, step > 1 ? ["empty"] : ["empty", "c"]),
        ( 10*step ..< 20*step, ["empty", "b", "c"]),
        ( 10*step ..< 20*step - 1, ["empty"]),
        (-10*step ..< 20*step, ["empty", "a", "b", "c"]),
        ( 10*step ..< 21*step, ["empty", "a", "b", "c"]),
        ( 15*step ..< 15*step, []),
      ]

      withEvery("input", in: inputs.keys) { input in
        let set = inputs[input]!
        expectFalse(set.isStrictSubset(of: set))

        withEvery("test", in: tests) { test in
          let expected = test.expected.contains(input)

          func forceSequence<S: Sequence>(_ other: S) -> Bool
          where S.Element: FixedWidthInteger {
            set.isStrictSubset(of: other)
          }

          if test.range.lowerBound >= 0 {
            expectEqual(set.isStrictSubset(of: BitSet(test.range)), expected)
            expectEqual(forceSequence(BitSet(test.range)), expected)
          }

          expectEqual(set.isStrictSubset(of: Array(test.range)), expected)

          expectEqual(set.isStrictSubset(of: test.range), expected)
          expectEqual(forceSequence(test.range), expected)
        }
      }
    }
  }

  func test_isSuperset() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in

      let inputs: [String: BitSet] = [
        "empty": BitSet(),
        "a": BitSet(10*step ..< 20*step),
        "b": BitSet(10*step ..< 20*step).subtracting(13*step ..< 14*step),
        "c": BitSet(10*step ..< 20*step - 1),
      ]

      let tests: [(range: Range<Int>, expected: Set<String>)] = [
        ( 10*step ..< 12*step, ["a", "b", "c"]),
        ( 12*step ..< 18*step, ["a", "c"]),
        ( 18*step ..< 20*step, ["a", "b"]),
        ( 11*step ..< 21*step, []),
        (  9*step ..< 19*step, []),
        ( 10*step ..< 20*step, ["a"]),
        ( 10*step ..< 20*step - 1, ["a", "c"]),
        (-10*step ..< 20*step, []),
        ( 10*step ..< 21*step, []),
        ( 15*step ..< 15*step, ["empty", "a", "b", "c"]),
      ]

      withEvery("input", in: inputs.keys) { input in
        let set = inputs[input]!
        expectTrue(set.isSuperset(of: set))

        withEvery("test", in: tests) { test in
          let expected = test.expected.contains(input)

          func forceSequence<S: Sequence>(_ other: S) -> Bool
          where S.Element: FixedWidthInteger {
            set.isSuperset(of: other)
          }

          if test.range.lowerBound >= 0 {
            expectEqual(set.isSuperset(of: BitSet(test.range)), expected)
            expectEqual(forceSequence(BitSet(test.range)), expected)
          }

          expectEqual(set.isSuperset(of: Array(test.range)), expected)

          expectEqual(set.isSuperset(of: test.range), expected)
          expectEqual(forceSequence(test.range), expected)
        }
      }
    }
  }

  func test_isStrictSuperset() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in

      let inputs: [String: BitSet] = [
        "empty": BitSet(),
        "a": BitSet(10*step ..< 20*step),
        "b": BitSet(10*step ..< 20*step).subtracting(13*step ..< 14*step),
        "c": BitSet(10*step ..< 20*step - 1),
      ]

      let tests: [(range: Range<Int>, expected: Set<String>)] = [
        ( 10*step ..< 12*step, ["a", "b", "c"]),
        ( 12*step ..< 18*step, ["a", "c"]),
        ( 18*step ..< 20*step, ["a", "b"]),
        ( 11*step ..< 21*step, []),
        (  9*step ..< 19*step, []),
        ( 10*step ..< 20*step, []),
        ( 10*step ..< 20*step - 1, ["a"]),
        (-10*step ..< 20*step, []),
        ( 10*step ..< 21*step, []),
        ( 15*step ..< 15*step, ["a", "b", "c"]),
      ]

      withEvery("input", in: inputs.keys) { input in
        let set = inputs[input]!
        expectFalse(set.isStrictSuperset(of: set))

        withEvery("test", in: tests) { test in
          let expected = test.expected.contains(input)

          func forceSequence<S: Sequence>(_ other: S) -> Bool
          where S.Element: FixedWidthInteger {
            set.isStrictSuperset(of: other)
          }

          if test.range.lowerBound >= 0 {
            expectEqual(set.isStrictSuperset(of: BitSet(test.range)), expected)
            expectEqual(forceSequence(BitSet(test.range)), expected)
          }

          expectEqual(set.isStrictSuperset(of: Array(test.range)), expected)

          expectEqual(set.isStrictSuperset(of: test.range), expected)
          expectEqual(forceSequence(test.range), expected)
        }
      }
    }
  }

  func test_isDisjoint() {
    withEvery("step", in: [1, 5, 16, 23, 24, UInt.bitWidth]) { step in

      let inputs: [String: BitSet] = [
        "empty": BitSet(),
        "a": BitSet(10*step ..< 20*step),
        "b": BitSet(10*step ..< 20*step).subtracting(13*step ..< 14*step),
        "c": BitSet(10*step ..< 20*step - 1),
      ]

      let tests: [(range: Range<Int>, expected: Set<String>)] = [
        ( 10*step ..< 12*step, ["empty"]),
        ( 12*step ..< 18*step, ["empty"]),
        ( 18*step ..< 20*step, ["empty"]),
        ( 11*step ..< 21*step, ["empty"]),
        (  9*step ..< 19*step, ["empty"]),
        ( 10*step ..< 20*step, ["empty"]),
        ( 10*step ..< 20*step - 1, ["empty"]),
        (-10*step ..< 20*step, ["empty"]),
        ( 10*step ..< 21*step, ["empty"]),
        ( 15*step ..< 15*step, ["empty", "a", "b", "c"]),
        ( 13*step ..< 14*step, ["empty", "b"]),
        ( 20*step - 1 ..< 22*step, ["empty", "c"]),
      ]

      withEvery("input", in: inputs.keys) { input in
        let set = inputs[input]!
        expectEqual(set.isDisjoint(with: set), set.isEmpty)

        withEvery("test", in: tests) { test in
          let expected = test.expected.contains(input)

          func forceSequence<S: Sequence>(_ other: S) -> Bool
          where S.Element: FixedWidthInteger {
            set.isDisjoint(with: other)
          }

          if test.range.lowerBound >= 0 {
            expectEqual(set.isDisjoint(with: BitSet(test.range)), expected)
            expectEqual(forceSequence(BitSet(test.range)), expected)
          }

          expectEqual(set.isDisjoint(with: Array(test.range)), expected)

          expectEqual(set.isDisjoint(with: test.range), expected)
          expectEqual(forceSequence(test.range), expected)
        }
      }
    }
  }
}
