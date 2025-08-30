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
@_spi(Testing) import SortedCollections
import _CollectionsTestSupport

class SortedSetTests: CollectionTestCase {
  func test_init_sortedElements() {
    withEvery("count", in: 0 ..< 40) { count in
      let set = SortedSet(sortedElements: 0 ..< count)
      expectEqual(set.count, count)
      expectEqual(set.isEmpty, count == 0)
      expectEqualElements(set, 0 ..< count)
      for i in 0 ..< count {
        expectTrue(set.contains(i))
      }
    }
  }

  func test_init_empty() {
    let set = SortedSet<Int>()
    expectEqual(set.count, 0)
    expectTrue(set.isEmpty)
    expectEqualElements(set, [])
  }

  func test_init_self() {
    withEvery("count", in: 0 ..< 40) { count in
      let set = SortedSet(0 ..< count)
      let copy = SortedSet(set)
      expectEqualElements(copy, set)
    }
  }

  func test_init_set() {
    withEvery("count", in: 0 ..< 40) { count in
      let set = Set(0 ..< count)
      let sorted = SortedSet(set)
      expectEqual(sorted.count, count)
      expectEqualElements(sorted, set.sorted())
    }
  }

  func test_init_dictionary_keys() {
    withEvery("count", in: 0 ..< 20) { count in
      let dict: [Int: Int]
        = .init(uniqueKeysWithValues: (0 ..< count).lazy.map { (key: $0, value: 2 * $0) })
      let sorted = SortedSet(dict.keys)
      expectEqual(sorted.count, count)
      expectEqualElements(sorted, dict.keys.sorted())
    }
  }

  func test_firstIndexOf_lastIndexOf() {
    withEvery("count", in: 0 ..< 20) { count in
      let contents = Array(0 ..< count)
      withEvery("dupes", in: 1 ... 3) { dupes in
        let input = (0 ..< count).flatMap { repeatElement($0, count: dupes) }
        let set = SortedSet(input)
        withEvery("item", in: contents) { item in
          expectNotNil(set.firstIndex(of: item)) { index in
            expectEqual(set[index], item)
            let offset = set.distance(from: set.startIndex, to: index)
            expectEqual(contents[offset], item)
            expectEqual(set.lastIndex(of: item), index)
          }
        }
        expectNil(set.firstIndex(of: count))
        expectNil(set.lastIndex(of: count))
      }
    }
  }
  
  func test_indexOf() {
    withEvery("count", in: 0 ..< 40) { count in
      let set = SortedSet(0 ..< count)
      withEvery("item", in: 0 ..< count) { item in
        expectNotNil(set.index(of: item)) { index in
          expectEqual(set[index], item)
          let offset = set.distance(from: set.startIndex, to: index)
          expectEqual(offset, item)
        }
      }
      expectNil(set.index(of: count))
    }
  }
  
  func test_removeAtIndex() {
    withEvery("count", in: 0 ..< 40) { count in
      withEvery("index", in: 0..<count) { index in
        var sorted = SortedSet(0 ..< count)
        let removed = sorted.remove(at: sorted.index(sorted.startIndex, offsetBy: index))
        
        var comparisonKeys = Array(0 ..< count)
        comparisonKeys.remove(at: index)
        
        expectEqual(removed, index)
        expectEqual(sorted.count, count - 1)
        expectEqualElements(sorted, comparisonKeys)
      }
    }
  }

  func test_CustomStringConvertible() {
    let a: SortedSet<Int> = []
    expectEqual(a.description, "[]")

    let b: SortedSet<Int> = [0]
    expectEqual(b.description, "[0]")

    let c: SortedSet<Int> = [0, 1, 2, 3, 4]
    expectEqual(c.description, "[0, 1, 2, 3, 4]")
  }

  func test_CustomDebugStringConvertible() {
    let a: SortedSet<Int> = []
    expectEqual(a.debugDescription, "SortedSet<Int>([])")

    let b: SortedSet<Int> = [0]
    expectEqual(b.debugDescription, "SortedSet<Int>([0])")

    let c: SortedSet<Int> = [0, 1, 2, 3, 4]
    expectEqual(c.debugDescription, "SortedSet<Int>([0, 1, 2, 3, 4])")
  }

  func test_customReflectable() {
    do {
      let set: SortedSet<Int> = [1, 2, 3]
      let mirror = Mirror(reflecting: set)
      expectEqual(mirror.displayStyle, .set)
      expectNil(mirror.superclassMirror)
      expectTrue(mirror.children.compactMap { $0.label }.isEmpty) // No label
      expectEqualElements(mirror.children.map { $0.value as? Int }, set.map { $0 })
    }
  }

  func test_ExpressibleByArrayLiteral() {
    do {
      let set: SortedSet<Int> = []
      expectEqualElements(set, [] as [Int])
    }

    do {
      let set: SortedSet<Int> = [1, 2, 3]
      expectEqualElements(set, 1 ... 3)
    }

    do {
      let set: SortedSet<Int> = [
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
      ]
      expectEqualElements(set, 1 ... 8)
    }

    do {
      let set: SortedSet<Int> = [
        1, 1, 1, 1,
        2, 2, 2, 2,
        3, 3, 3, 3,
        4, 4, 4, 4,
        5, 5, 5, 5,
        6, 6, 6, 6,
        7, 7, 7, 7,
        8, 8, 8, 8,
      ]
      expectEqualElements(set, 1 ... 8)
    }

    do {
      let set: SortedSet<Int> = [
        1, 2, 3, 4, 5, 6, 7, 8,
        9, 10, 11, 12, 13, 14, 15, 16,
        17, 18, 19, 20, 21, 22, 23, 24,
        25, 26, 27, 28, 29, 30, 31, 32]
      expectEqualElements(set, 1 ... 32)
    }
  }

  func test_Encodable() throws {
    let s1: SortedSet<Int> = []
    let v1: MinimalEncoder.Value = .array([])
    expectEqual(try MinimalEncoder.encode(s1), v1)

    let s2: SortedSet<Int> = [0, 1, 2, 3]
    let v2: MinimalEncoder.Value = .array([.int(0), .int(1), .int(2), .int(3)])
    expectEqual(try MinimalEncoder.encode(s2), v2)

    let s4 = SortedSet<Int>(0 ..< 100)
    let v4: MinimalEncoder.Value = .array((0 ..< 100).map { .int($0) })
    expectEqual(try MinimalEncoder.encode(s4), v4)
  }

  func test_Decodable() throws {
    let s1: SortedSet<Int> = []
    let v1: MinimalEncoder.Value = .array([])
    expectEqual(try MinimalDecoder.decode(v1, as: SortedSet<Int>.self), s1)

    let s2: SortedSet<Int> = [0, 1, 2, 3]
    let v2: MinimalEncoder.Value = .array([.int(0), .int(1), .int(2), .int(3)])
    expectEqual(try MinimalDecoder.decode(v2, as: SortedSet<Int>.self), s2)

    let s3 = SortedSet<Int>(0 ..< 100)
    let v3: MinimalEncoder.Value = .array((0 ..< 100).map { .int($0) })
    expectEqual(try MinimalDecoder.decode(v3, as: SortedSet<Int>.self), s3)

    expectThrows(try MinimalDecoder.decode(.int(0), as: SortedSet<Int>.self))

    let v4: MinimalEncoder.Value = .array([.int(0), .int(1), .int(0)])
    expectThrows(try MinimalDecoder.decode(v4, as: SortedSet<Int>.self)) { error in
      expectNotNil(error as? DecodingError) { error in
        guard case .dataCorrupted(let context) = error else {
          expectFailure("Unexpected error \(error)")
          return
        }
        expectEqual(context.debugDescription,
                    "Decoded elements out of order.")
      }
    }
  }


  func withSampleRanges(
    file: StaticString = #filePath,
    line: UInt = #line,
    _ body: (Range<Int>, Range<Int>) throws -> Void
  ) rethrows {
    for c1 in [0, 10, 32, 64, 128, 256] {
      for c2 in [0, 10, 32, 64, 128, 256] {
        for overlap in Set([0, 1, c1 / 2, c1, -5]) {
          let r1 = 0 ..< c1
          let r2 = c1 - overlap ..< c1 - overlap + c2
          if r1.lowerBound <= r2.lowerBound {
            let e1 = context.push("range1: \(r1)", file: file, line: line)
            let e2 = context.push("range2: \(r2)", file: file, line: line)
            defer {
              context.pop(e2)
              context.pop(e1)
            }
            try body(r1, r2)
          } else {
            let e1 = context.push("range1: \(r2)", file: file, line: line)
            let e2 = context.push("range2: \(r1)", file: file, line: line)
            defer {
              context.pop(e2)
              context.pop(e1)
            }
            try body(r2, r1)
          }
        }
      }
    }
  }

  func test_union_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).union(r2).sorted()

      let u1 = SortedSet(r1)
      let u2 = SortedSet(r2)
      let actual1 = u1.union(u2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.union(u2).union(u1)
      expectEqualElements(actual2, expected)
    }
  }

  func test_formUnion_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).union(r2).sorted()

      var res: SortedSet<Int> = []

      let u1 = SortedSet(r1)
      res.formUnion(u1)
      expectEqualElements(res, r1)

      let u2 = SortedSet(r2)
      res.formUnion(u2)
      expectEqualElements(res, expected)

      res.formUnion(u1)
      res.formUnion(u2)
      expectEqualElements(res, expected)
    }
  }

  func test_intersection_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).intersection(r2).sorted()

      let u1 = SortedSet(r1)
      let u2 = SortedSet(r2)
      let actual1 = u1.intersection(u2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.intersection(u1)
      expectEqualElements(actual2, expected)
    }
  }

  func test_formIntersection_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).intersection(r2).sorted()

      let u1 = SortedSet(r1)
      let u2 = SortedSet(r2)
      var res = u1
      res.formIntersection(u2)
      expectEqualElements(res, expected)
      expectEqualElements(u1, r1)

      res.formIntersection(u1)
      res.formIntersection(u2)
      expectEqualElements(res, expected)
    }
  }


  func test_symmetricDifference_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).symmetricDifference(r2).sorted()

      let u1 = SortedSet(r1)
      let u2 = SortedSet(r2)
      let actual1 = u1.symmetricDifference(u2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.symmetricDifference(u1).symmetricDifference(u2)
      expectEqual(actual2.count, 0)
    }
  }

  func test_formSymmetricDifference_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).symmetricDifference(r2).sorted()

      let u1 = SortedSet(r1)
      let u2 = SortedSet(r2)
      var res = u1
      res.formSymmetricDifference(u2)
      expectEqualElements(res, expected)
      expectEqualElements(u1, r1)

      res.formSymmetricDifference(u1)
      res.formSymmetricDifference(u2)
      expectEqual(res.count, 0)
    }
  }

  func test_subtracting_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).subtracting(r2).sorted()

      let u1 = SortedSet(r1)
      let u2 = SortedSet(r2)
      let actual1 = u1.subtracting(u2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.subtracting(u2)
      expectEqualElements(actual2, expected)
    }
  }

  func test_subtract_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).subtracting(r2).sorted()

      let u1 = SortedSet(r1)
      let u2 = SortedSet(r2)
      var res = u1
      res.subtract(u2)
      expectEqualElements(res, expected)
      expectEqualElements(u1, r1)

      res.subtract(u2)
      expectEqualElements(res, expected)
    }
  }

  struct SampleRanges {
    let unit: Int

    init(unit: Int) {
      self.unit = unit
    }

    var empty: Range<Int> { unit ..< unit }

    var a: Range<Int> { 0 ..< unit }
    var b: Range<Int> { unit ..< 2 * unit }
    var c: Range<Int> { 2 * unit ..< 3 * unit }

    var ab: Range<Int> { 0 ..< 2 * unit }
    var bc: Range<Int> { unit ..< 3 * unit }

    var abc: Range<Int> { 0 ..< 3 * unit }

    var ranges: [Range<Int>] { [empty, a, b, c, ab, bc, abc] }

    func withEveryPair(
      _ body: (Range<Int>, Range<Int>) throws -> Void
    ) rethrows {
      try withEvery("range1", in: ranges) { range1 in
        try withEvery("range2", in: ranges) { range2 in
          try body(range1, range2)
        }
      }
    }
  }

  func test_isSubset_Self() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isSubset(of: r2)
        let a = SortedSet(r1)
        let b = SortedSet(r2)
        expectEqual(a.isSubset(of: b), expected)
      }
    }
  }

  func test_isSuperset_Self() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isSuperset(of: r2)
        let a = SortedSet(r1)
        let b = SortedSet(r2)
        expectEqual(a.isSuperset(of: b), expected)
      }
    }
  }

  func test_isStrictSubset_Self() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isStrictSubset(of: r2)
        let a = SortedSet(r1)
        let b = SortedSet(r2)
        expectEqual(a.isStrictSubset(of: b), expected)
      }
    }
  }

  func test_isStrictSuperset_Self() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isStrictSuperset(of: r2)
        let a = SortedSet(r1)
        let b = SortedSet(r2)
        expectEqual(a.isStrictSuperset(of: b), expected)
      }
    }
  }

  func test_isDisjoint_Self() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isDisjoint(with: r2)
        let a = SortedSet(r1)
        let b = SortedSet(r2)
        expectEqual(a.isDisjoint(with: b), expected)
      }
    }
  }
}
