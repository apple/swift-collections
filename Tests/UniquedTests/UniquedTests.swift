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
@_spi(Testing) import UniquedModule
import DequeModule
import CollectionsTestSupport

class UniquedTests: CollectionTestCase {
  typealias MinimalImmutableBase<T> = MinimalRandomAccessCollection<T>
  typealias MinimalBase<T> = MinimalRangeReplaceableRandomAccessCollection<T>
  typealias MinimalMutableBase<T> = MinimalMutableRangeReplaceableRandomAccessCollection<T>

  func test_init_uncheckedUniqueElements_concrete() {
    withEvery("count", in: 0 ..< 20) { count in
      let contents = MinimalImmutableBase<Int>(0 ..< count)
      let set = Uniqued(uncheckedUniqueElements: contents)
      expectEqual(set.count, count)
      expectEqual(set.isEmpty, count == 0)
      expectEqualElements(set, 0 ..< count)
      for i in 0 ..< count {
        expectTrue(set.contains(i))
      }
    }
  }

  func test_init_uncheckedUniqueElements_generic() {
    withEvery("count", in: 0 ..< 20) { count in
      let set = Uniqued<MinimalBase<Int>>(uncheckedUniqueElements: 0 ..< count)
      expectEqual(set.count, count)
      expectEqual(set.isEmpty, count == 0)
      expectEqualElements(set, 0 ..< count)
      for i in 0 ..< count {
        expectTrue(set.contains(i))
      }
    }
  }

  func test_init_uniqueElements_concrete() {
    withEvery("count", in: 0 ..< 20) { count in
      let contents = MinimalImmutableBase<Int>(0 ..< count)
      let set = Uniqued(uniqueElements: contents)
      expectEqual(set.count, count)
      expectEqual(set.isEmpty, count == 0)
      expectEqualElements(set, 0 ..< count)
      for i in 0 ..< count {
        expectTrue(set.contains(i))
      }
    }
  }

  func test_init_uniqueElements_generic() {
    withEvery("count", in: 0 ..< 20) { count in
      let set = Uniqued<MinimalBase<Int>>(uniqueElements: 0 ..< count)
      expectEqual(set.count, count)
      expectEqual(set.isEmpty, count == 0)
      expectEqualElements(set, 0 ..< count)
      for i in 0 ..< count {
        expectTrue(set.contains(i))
      }
    }
  }

  func test_init_empty() {
    let set = Uniqued<MinimalBase<Int>>()
    expectEqual(set.count, 0)
    expectTrue(set.isEmpty)
    expectEqualElements(set, [])
  }

  func test_init_self() {
    withEvery("count", in: 0 ..< 20) { count in
      let set = Uniqued<MinimalBase<Int>>(0 ..< count)
      let copy = Uniqued(set)
      expectEqualElements(copy, set)
      expectEqual(set._hashTableIdentity, copy._hashTableIdentity)
    }
  }

  func test_init_set() {
    withEvery("count", in: 0 ..< 20) { count in
      let set = Set(0 ..< count)
      let ordered = Uniqued<MinimalBase<Int>>(set)
      expectEqual(ordered.count, count)
      expectEqualElements(ordered, set)
    }
  }

  func test_init_dictionary_keys() {
    withEvery("count", in: 0 ..< 20) { count in
      let dict: [Int: Int]
        = .init(uniqueKeysWithValues: (0 ..< count).lazy.map { (key: $0, value: 2 * $0) })
      let ordered = Uniqued<MinimalBase<Int>>(dict.keys)
      expectEqual(ordered.count, count)
      expectEqualElements(ordered, dict.keys)
    }
  }

  /// Create a new `Uniqued` instance using the generic initializer.
  static func _genericInitializer<T, S: Sequence>(
    _ type: T.Type = T.self,
    from elements: S
  ) -> Uniqued<T>
  where T: RandomAccessCollection & RangeReplaceableCollection,
        T.Element == S.Element
  {
    return Uniqued<T>.init(elements)
  }


  func test_generic_init_self() {
    withEvery("count", in: 0 ..< 20) { count in
      let set = Uniqued<MinimalBase<Int>>(0 ..< count)
      let copy: Uniqued<MinimalBase<Int>> = Self._genericInitializer(from: set)
      expectEqualElements(copy, set)
      expectEqual(set._hashTableIdentity, copy._hashTableIdentity)
    }
  }

  func test_generic_init_set() {
    withEvery("count", in: 0 ..< 20) { count in
      let expected = Set(0 ..< count)
      let actual = Self._genericInitializer(MinimalBase<Int>.self, from: expected)
      expectEqualElements(actual, expected)
    }
  }

  func test_generic_init_array() {
    withEvery("count", in: 0 ..< 20) { count in
      let expected = Array(0 ..< count)
      withEvery("dupes", in: 1 ... 3) { dupes in
        let input = (0 ..< count).flatMap { repeatElement($0, count: dupes) }
        let actual = Self._genericInitializer(MinimalBase<Int>.self, from: input)
        expectEqualElements(actual, expected)
      }
    }
  }

  func test_firstIndexOf_lastIndexOf() {
    withEvery("count", in: 0 ..< 20) { count in
      let contents = Array(0 ..< count)
      withEvery("dupes", in: 1 ... 3) { dupes in
        let input = (0 ..< count).flatMap { repeatElement($0, count: dupes) }
        let set = Uniqued<[Int]>(input)
        withEvery("item", in: contents) { item in
          expectNotNil(set.firstIndex(of: item)) { index in
            expectEqual(set[index], item)
            expectEqual(contents[index], item)
            expectEqual(set.lastIndex(of: item), index)
          }
        }
        expectNil(set.firstIndex(of: count))
        expectNil(set.lastIndex(of: count))
      }
    }
  }

  func test_Collection() {
    withEvery("count", in: [0, 1, 15, 16, 20]) { count in
      let scale = _UnsafeHashTable.scale(forCapacity: count)
      withEvery("bias", in: _UnsafeHashTable.biasRange(scale: scale)) { bias in
        let contents = Array(0 ..< count)
        let set = Uniqued<[Int]>(_scale: scale, bias: bias, contents: contents)
        checkBidirectionalCollection(set, expectedContents: contents)
      }
    }
  }

  func test_CustomStringConvertible() {
    let a: Uniqued<Array<Int>> = []
    expectEqual(a.description, "[]")

    let b: Uniqued<Array<Int>> = [0]
    expectEqual(b.description, "[0]")

    let c: Uniqued<Array<Int>> = [0, 1, 2, 3, 4]
    expectEqual(c.description, "[0, 1, 2, 3, 4]")
  }

  func test_CustomDebugStringConvertible() {
    let a: Uniqued<Array<Int>> = []
    expectEqual(a.debugDescription, "OrderedSet<Int>([])")

    let b: Uniqued<Array<Int>> = [0]
    expectEqual(b.debugDescription, "OrderedSet<Int>([0])")

    let c: Uniqued<Array<Int>> = [0, 1, 2, 3, 4]
    expectEqual(c.debugDescription, "OrderedSet<Int>([0, 1, 2, 3, 4])")

    let d: Uniqued<Deque<Int>> = []
    expectEqual(d.debugDescription, "Uniqued<Deque<Int>>([])")

    let e: Uniqued<Deque<Int>> = [0]
    expectEqual(e.debugDescription, "Uniqued<Deque<Int>>([0])")

    let f: Uniqued<Deque<Int>> = [0, 1, 2, 3, 4]
    expectEqual(f.debugDescription, "Uniqued<Deque<Int>>([0, 1, 2, 3, 4])")
  }

  func test_customReflectable() {
    do {
      let set: Uniqued<[Int]> = [1, 2, 3]
      let mirror = Mirror(reflecting: set)
      expectEqual(mirror.displayStyle, .collection)
      expectNil(mirror.superclassMirror)
      expectTrue(mirror.children.compactMap { $0.label }.isEmpty) // No label
      expectEqualElements(mirror.children.map { $0.value as? Int }, set.map { $0 })
    }

    do {
      let set: Uniqued<Deque<Int>> = [1, 2, 3]
      let mirror = Mirror(reflecting: set)
      expectEqual(mirror.displayStyle, .collection)
      expectNil(mirror.superclassMirror)
      expectTrue(mirror.children.compactMap { $0.label }.isEmpty) // No label
      expectEqualElements(mirror.children.map { $0.value as? Int }, set.map { $0 })
    }
  }

  func test_Equatable_Hashable() {
    let samples: [[Uniqued<[Int]>]] = [
      [[1, 2, 3],
       [1, 2, 3]],
      [[3, 2, 1],
       [3, 2, 1]],
      [[1, 1, 1],
       [1, 1, 1],
       [1, 1],
       [1]],
      [[1, 2],
       [1, 2, 2],
       [1, 1, 2],
       [1, 1, 2, 2]],
    ]
    checkHashable(equivalenceClasses: samples)

    // Check that hash encoding matches that of the underlying arrays.
    for equivalenceClass in samples {
      for item in equivalenceClass {
        expectEqual(item.hashValue, item.contents.hashValue)
      }
    }
  }

  func test_ExpressibleByArrayLiteral() {
    do {
      let set: Uniqued<[Int]> = []
      expectEqualElements(set, [] as [Int])
    }

    do {
      let set: Uniqued<[Int]> = [1, 2, 3]
      expectEqualElements(set, 1 ... 3)
    }

    do {
      let set: Uniqued<[Int]> = [
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
      ]
      expectEqualElements(set, 1 ... 8)
    }

    do {
      let set: Uniqued<[Int]> = [
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
      let set: Uniqued<[Int]> = [
        1, 2, 3, 4, 5, 6, 7, 8,
        9, 10, 11, 12, 13, 14, 15, 16,
        17, 18, 19, 20, 21, 22, 23, 24,
        25, 26, 27, 28, 29, 30, 31, 32]
      expectEqualElements(set, 1 ... 32)
    }
  }

  func test_Encodable() throws {
    let s1: Uniqued<[Int]> = []
    let v1: MinimalEncoder.Value = .array([])
    expectEqual(try MinimalEncoder.encode(s1), v1)

    let s2: Uniqued<[Int]> = [0, 1, 2, 3]
    let v2: MinimalEncoder.Value = .array([.int(0), .int(1), .int(2), .int(3)])
    expectEqual(try MinimalEncoder.encode(s2), v2)

    let s3: Uniqued<[Int]> = [3, 2, 1, 0]
    let v3: MinimalEncoder.Value = .array([.int(3), .int(2), .int(1), .int(0)])
    expectEqual(try MinimalEncoder.encode(s3), v3)

    let s4 = Uniqued<[Int]>(0 ..< 100)
    let v4: MinimalEncoder.Value = .array((0 ..< 100).map { .int($0) })
    expectEqual(try MinimalEncoder.encode(s4), v4)
  }

  func test_Decodable() throws {
    let s1: Uniqued<[Int]> = []
    let v1: MinimalEncoder.Value = .array([])
    expectEqual(try MinimalDecoder.decode(v1, as: Uniqued<[Int]>.self), s1)

    let s2: Uniqued<[Int]> = [0, 1, 2, 3]
    let v2: MinimalEncoder.Value = .array([.int(0), .int(1), .int(2), .int(3)])
    expectEqual(try MinimalDecoder.decode(v2, as: Uniqued<[Int]>.self), s2)

    let s3 = Uniqued<[Int]>(0 ..< 100)
    let v3: MinimalEncoder.Value = .array((0 ..< 100).map { .int($0) })
    expectEqual(try MinimalDecoder.decode(v3, as: Uniqued<[Int]>.self), s3)

    expectThrows(try MinimalDecoder.decode(.int(0), as: Uniqued<[Int]>.self))

    let v4: MinimalEncoder.Value = .array([.int(0), .int(1), .int(0)])
    expectThrows(try MinimalDecoder.decode(v4, as: Uniqued<[Int]>.self)) { error in
      expectNotNil(error as? DecodingError) { error in
        guard case .dataCorrupted(let context) = error else {
          expectFailure("Unexpected error \(error)")
          return
        }
        expectEqual(context.debugDescription,
                    "Decoded elements aren't unique (first duplicate at offset 2)")
      }
    }
  }

  func test_append_many() {
    #if COLLECTIONS_INTERNAL_CHECKS
    // This test just takes too long with O(n) appends.
    let count = 1_000
    #else
    let count = 10_000
    #endif

    var set = Uniqued<MinimalBase<Int>>()
    withEvery("item", in: 0 ..< count) { item in
      let res1 = set.append(item)
      expectTrue(res1.inserted)
      expectEqual(set[res1.index], item)

      let res2 = set.append(item)
      expectFalse(res2.inserted)
      expectEqual(res2.index, res1.index)

      expectEqual(set[res1.index], item) // Original index must remain valid.
      expectEqual(set[res2.index], item)
    }
  }

  func test_append() {
    withEvery("count", in: 0 ..< 20) { count in
      withEvery("dupes", in: 1 ... 3) { dupes in
        let input = (0 ..< count).flatMap { repeatElement($0, count: dupes) }.shuffled()
        var reference: [Int: Int] = [:] // Value to expected offset
        var actual = Uniqued<MinimalBase<Int>>()
        withEvery("offset", in: input.indices) { offset in
          let item = input[offset]
          let (inserted, index) = actual.append(item)
          expectEqual(actual[index], item)
          if let expectedOffset = reference[item] {
            // Existing item
            expectFalse(inserted)
            expectEqual(index.offset, expectedOffset)
          } else {
            expectTrue(inserted)
            expectEqual(index.offset, reference.count)
            reference[item] = reference.count
          }
        }
      }
    }
    // Check CoW copying behavior
    do {
      var set = Uniqued<MinimalBase<Int>>(0 ..< 30)
      let copy = set
      expectTrue(set.append(30).inserted)
      expectTrue(set.contains(30))
      expectFalse(copy.contains(30))
    }
  }

  func test_append_contentsOf() {
    withEvery("chunkLength", in: 1 ..< 10) { chunkLength in
      withEvery("chunkOverlap", in: 0 ... chunkLength) { chunkOverlap in
        var actual = Uniqued<MinimalBase<Int>>()
        var chunkStart = 0
        var expectedCount = 0
        withEvery("iteration", in: 0 ..< 100) { _ in
          let chunk = chunkStart ..< chunkStart + chunkLength
          actual.append(contentsOf: chunk)
          expectedCount = chunk.upperBound
          expectEqual(actual.count, expectedCount)
          chunkStart += chunkLength - chunkOverlap
        }
        expectEqualElements(actual, 0 ..< expectedCount)
      }
    }
  }

  func test_prepend_many() {
    #if COLLECTIONS_INTERNAL_CHECKS
    // This test just takes too long with O(n) appends.
    let count = 1_000
    #else
    let count = 10_000
    #endif

    var set = Uniqued<MinimalBase<Int>>()
    withEvery("item", in: 0 ..< count) { item in
      let res1 = set.prepend(item)
      expectTrue(res1.inserted)
      expectEqual(set[res1.index], item)

      let res2 = set.prepend(item)
      expectFalse(res2.inserted)
      expectEqual(res2.index, res1.index)

      expectEqual(set[res1.index], item) // Original index must remain valid.
      expectEqual(set[res2.index], item)
    }
  }

  func test_prepend() {
    withEvery("count", in: 0 ..< 20) { count in
      withEvery("dupes", in: 1 ... 3) { dupes in
        let input = (0 ..< count).flatMap { repeatElement($0, count: dupes) }.shuffled()
        var reference: [Int: Int] = [:] // Value to expected offset from end
        var actual = Uniqued<Deque<Int>>()
        withEvery("offset", in: input.indices) { offset in
          let item = input[offset]
          let (inserted, index) = actual.prepend(item)
          expectEqual(actual[index], item)
          if let expectedOffset = reference[item] {
            // Existing item
            expectFalse(inserted)
            expectEqual(index, actual.count - expectedOffset)
          } else {
            expectTrue(inserted)
            expectEqual(index, 0)
            reference[item] = actual.count
          }
        }
      }
    }
    // Check CoW copying behavior
    do {
      var set = Uniqued<MinimalBase<Int>>(0 ..< 30)
      let copy = set
      expectTrue(set.append(30).inserted)
      expectTrue(set.contains(30))
      expectFalse(copy.contains(30))
    }
  }

  func test_prepend_contentsOf() {
    withEvery("chunkLength", in: 1 ..< 10) { chunkLength in
      withEvery("chunkOverlap", in: 0 ... chunkLength) { chunkOverlap in
        var actual = Uniqued<MinimalBase<Int>>()
        var chunkStart = 0
        var expectedCount = 0
        withEvery("iteration", in: 0 ..< 100) { _ in
          let chunk = chunkStart ..< chunkStart + chunkLength
          actual.prepend(contentsOf: chunk.reversed())
          expectedCount = chunk.upperBound
          expectEqual(actual.count, expectedCount)
          chunkStart += chunkLength - chunkOverlap
        }
        expectEqualElements(actual, (0 ..< expectedCount).reversed())
      }
    }
  }

  func test_insert_at() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & RangeReplaceableCollection,
          Base.Element == Int
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        withEvery("isShared", in: [false, true]) { isShared in
          let count = layout.count
          withEvery("offset", in: 0 ... count) { offset in
            var set = Uniqued<Base>(layout: layout)
            withHiddenCopies(if: isShared, of: &set) { set in
              let i = set.index(set.startIndex, offsetBy: offset)
              let (inserted, index) = set.insert(count, at: i)
              expectTrue(inserted)
              expectEqual(set.count, count + 1)
              expectEqual(set[index], count)
              expectEqualElements(set[..<index], 0 ..< offset)
              expectEqualElements(set[set.index(after: index)...], offset ..< count)
              expectEqual(set.firstIndex(of: count), index, "Can't find newly inserted element")

              let i2 = set.index(set.startIndex, offsetBy: offset / 2)
              let (inserted2, index2) = set.insert(count, at: i2)
              expectFalse(inserted2)
              expectEqual(index2, index)
              expectEqual(set[index], count)
              expectEqual(set.count, count + 1)
            }
          }
        }
      }
    }

    check(MinimalBase<Int>.self)
    check(ContiguousArray<Int>.self)
    check(Deque<Int>.self)
  }

  func test_update_at_with() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & RangeReplaceableCollection & MutableCollection,
          Base.Element == HashableBox<Int>
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        let count = layout.count
        let contents = Base((0 ..< count).lazy.map { HashableBox($0) })
        withEvery("offset", in: 0 ..< count) { offset in
          var set = Uniqued<Base>(layout: layout, contents: contents)
          let index = set._index(at: offset) // This must remain valid throughout this test
          let new = HashableBox(offset)
          let old = set.update(at: index, with: new)
          expectIdentical(old, contents[index])
          expectIdentical(set[index], new)

          let copy = set

          let old2 = set.update(at: index, with: old)
          expectIdentical(old2, new)
          expectIdentical(set[index], old)
          expectIdentical(copy[index], new)
        }
      }
    }
    check(MinimalMutableBase<HashableBox<Int>>.self)
    check(ContiguousArray<HashableBox<Int>>.self)
    check(Deque<HashableBox<Int>>.self)
  }

  func test_updateOrAppend() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & RangeReplaceableCollection & MutableCollection,
          Base.Element == HashableBox<Int>
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        let count = layout.count
        let contents = Base((0 ..< count).lazy.map { HashableBox($0) })
        withEvery("offset", in: 0 ..< count) { offset in
          var set = Uniqued<Base>(layout: layout, contents: contents)
          let index = set._index(at: offset) // This must remain valid throughout this test
          let new = HashableBox(offset)
          let old = set.updateOrAppend(new)
          expectNotNil(old) { old in
            expectIdentical(old, contents[index])
            expectIdentical(set[index], new)

            let copy = set

            let old2 = set.updateOrAppend(old)
            expectNotNil(old2) { old2 in
              expectIdentical(old2, new)
              expectIdentical(set[index], old)
              expectIdentical(copy[index], new)
            }
          }
        }

        // Try appending something.
        var set = Uniqued<Base>(layout: layout, contents: contents)

        let new = HashableBox(count)
        do {
          expectNil(set.updateOrAppend(new))
          expectTrue(set.contains(new))
          expectIdentical(set.last, new)
        }

        let copy = set
        let new2 = HashableBox(count + 1)
        do {
          expectNil(set.updateOrAppend(new2))
          expectTrue(set.contains(new2))
          expectIdentical(set.last, new2)
        }

        expectEqual(copy.count, count + 1)
        expectIdentical(copy.last, new)
      }
    }
    check(MinimalMutableBase<HashableBox<Int>>.self)
    check(ContiguousArray<HashableBox<Int>>.self)
    check(Deque<HashableBox<Int>>.self)
  }


  func test_swapAt() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & RangeReplaceableCollection & MutableCollection,
          Base.Element == Int
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        withEvery("isShared", in: [false, true]) { isShared in
          let count = layout.count
          withEvery("a", in: 0 ..< count) { a in
            var set = Uniqued<Base>(layout: layout)
            withHiddenCopies(if: isShared, of: &set) { set in
              let b = count - a - 1
              let ai = set._index(at: a)
              let bi = set._index(at: b)
              expectEqual(set[ai], a)
              expectEqual(set[bi], b)
              set.swapAt(ai, bi)
              expectEqual(set[ai], b)
              expectEqual(set[bi], a)
              // Make sure we can still find these elements
              expectEqual(set.firstIndex(of: a), bi)
              expectEqual(set.firstIndex(of: b), ai)
            }
          }
        }
      }
    }
    check(MinimalMutableBase<Int>.self)
    check(ContiguousArray<Int>.self)
    check(Deque<Int>.self)
  }

  func test_partition() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & MutableCollection & RangeReplaceableCollection,
          Base.Element == Int
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        withEvery("offset", in: 0 ... layout.count) { offset in
          withEvery("isShared", in: [false, true]) { isShared in
            let count = layout.count
            var set = Uniqued<Base>(layout: layout)
            withHiddenCopies(if: isShared, of: &set) { set in
              let pivot = set.partition(by: { $0.isMultiple(of: 2) })
              withEvery("item", in: 0 ..< count) { item in
                expectNotNil(set.firstIndex(of: item)) { index in
                  expectEqual(set[index], item)
                  if item.isMultiple(of: 2) {
                    expectGreaterThanOrEqual(index, pivot)
                  } else {
                    expectLessThan(index, pivot)
                  }
                }
              }
            }
          }
        }
      }
    }
    check(MinimalMutableBase<Int>.self)
    check(ContiguousArray<Int>.self)
    check(Deque<Int>.self)
  }

  func test_partition_extremes() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & MutableCollection & RangeReplaceableCollection,
          Base.Element == Int
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        withEvery("offset", in: 0 ... layout.count) { offset in
          withEvery("isShared", in: [false, true]) { isShared in
            let count = layout.count
            var set = Uniqued<Base>(layout: layout)
            withHiddenCopies(if: isShared, of: &set) { set in
              do {
                let pivot = set.partition(by: { _ in false })
                expectEqual(pivot, set.endIndex)
                expectEqualElements(set, 0 ..< count)
              }

              do {
                let pivot = set.partition(by: { _ in true })
                expectEqual(pivot, set.startIndex)
                expectEqualElements(set, 0 ..< count)
              }
            }
          }
        }
      }
    }
    check(MinimalMutableBase<Int>.self)
    check(ContiguousArray<Int>.self)
    check(Deque<Int>.self)
  }

  func test_sort() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & MutableCollection & RangeReplaceableCollection,
          Base.Element == Int
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        withEvery("seed", in: 0 ..< 10) { seed in
          withEvery("isShared", in: [false, true]) { isShared in
            let count = layout.count
            var rng = RepeatableRandomNumberGenerator(seed: seed)
            let contents = (0 ..< count).shuffled(using: &rng)
            var set = Uniqued<Base>(layout: layout, contents: contents)
            withHiddenCopies(if: isShared, of: &set) { set in
              set.sort()
              expectEqualElements(set, 0 ..< count)

              set.sort(by: >)
              expectEqualElements(set, (0 ..< count).reversed())
            }
          }
        }
      }
    }
    check(MinimalMutableBase<Int>.self)
    check(ContiguousArray<Int>.self)
    check(Deque<Int>.self)
  }

  func test_shuffle() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & MutableCollection & RangeReplaceableCollection,
          Base.Element == Int
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        guard layout.count > 1 else { return }
        withEvery("seed", in: 0 ..< 10) { seed in
          withEvery("isShared", in: [false, true]) { isShared in
            let count = layout.count
            var contents = Base(0 ..< count)
            var set = Uniqued<Base>(layout: layout, contents: 0 ..< count)
            withHiddenCopies(if: isShared, of: &set) { set in
              var rng1 = RepeatableRandomNumberGenerator(seed: seed)
              contents.shuffle(using: &rng1)

              var rng2 = RepeatableRandomNumberGenerator(seed: seed)
              set.shuffle(using: &rng2)

              expectEqualElements(set, contents)

              // Check that shuffling with system RNG does permute the elements.
              var success = false
              for _ in 0 ..< 1000 {
                set.shuffle()
                if !set.elementsEqual(contents) {
                  success = true
                  break
                }
              }
              expectTrue(success)

            }
          }
        }
      }
    }
    check(MinimalMutableBase<Int>.self)
    check(ContiguousArray<Int>.self)
    check(Deque<Int>.self)
  }

  func test_remove_at() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & RangeReplaceableCollection,
          Base.Element == Int
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        withEvery("offset", in: 0 ..< layout.count) { offset in
          withEvery("isShared", in: [false, true]) { isShared in
            var set = Uniqued<Base>(layout: layout)
            withHiddenCopies(if: isShared, of: &set) { set in
              let count = layout.count
              let index = set._index(at: offset)
              let old = set.remove(at: index)
              expectEqual(old, offset)
              expectEqualElements(set[..<set._index(at: offset)], 0 ..< offset)
              expectEqualElements(set[set._index(at: offset)...], offset + 1 ..< count)
              // Check that elements are still accessible through the hash table.
              withEvery("item", in: 0 ..< count) { item in
                if item < offset {
                  expectEqual(set.firstIndex(of: item), set._index(at: item))
                } else if item == offset {
                  expectNil(set.firstIndex(of: item))
                } else {
                  expectEqual(set.firstIndex(of: item), set._index(at: item - 1))
                }
              }
            }
          }
        }
      }
    }
    check(MinimalBase<Int>.self)
    check(ContiguousArray<Int>.self)
    check(Deque<Int>.self)
  }

  func test_remove_at_capacity_behavior() {
    var set = Uniqued<MinimalBase<Int>>(0 ..< 1000)
    while !set.isEmpty {
      let originalCount = set.count
      context.withTrace("originalCount: \(originalCount)") {
        let scale = set._scale
        let old = set.remove(at: set.index(before: set.endIndex))
        expectEqual(old, set.count)
        if originalCount == _UnsafeHashTable.minimumCapacity(forScale: scale) {
          expectLessThan(set._scale, scale)
        } else {
          expectEqual(set._scale, scale)
        }
      }
    }
  }



  func test_remove_existing_element() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & RangeReplaceableCollection,
          Base.Element == Int
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        withEvery("item", in: 0 ..< layout.count) { item in
          withEvery("isShared", in: [false, true]) { isShared in
            var set = Uniqued<Base>(layout: layout)
            withHiddenCopies(if: isShared, of: &set) { set in
              let count = layout.count
              let old = set.remove(item)
              expectEqual(old, item)
              expectEqualElements(set[..<set._index(at: item)], 0 ..< item)
              expectEqualElements(set[set._index(at: item)...], item + 1 ..< count)
              // Check that elements are still accessible through the hash table.
              withEvery("i", in: 0 ..< count) { i in
                if i < item {
                  expectEqual(set.firstIndex(of: i), set._index(at: i))
                } else if i == item {
                  expectNil(set.firstIndex(of: i))
                } else {
                  expectEqual(set.firstIndex(of: i), set._index(at: i - 1))
                }
              }
            }
          }
        }
      }
    }
    check(MinimalBase<Int>.self)
    check(ContiguousArray<Int>.self)
  }

  func test_remove_nonexistent_element() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & RangeReplaceableCollection,
          Base.Element == Int
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        withEvery("item", in: layout.count ..< 2 * layout.count) { item in
          var set = Uniqued<Base>(layout: layout)
          let old = set.remove(item)
          expectNil(old)
          expectEqualElements(set, 0 ..< layout.count)
        }
      }
    }
    check(MinimalBase<Int>.self)
    check(ContiguousArray<Int>.self)
  }

  func test_remove_subrange() {
    func check<Base>(_ base: Base.Type)
    where Base: RandomAccessCollection & RangeReplaceableCollection,
          Base.Element == Int
    {
      let entry = context.push("base: \(base)")
      defer { context.pop(entry) }
      withUniquedLayouts(scales: [0, 5, 6]) { layout in
        withSomeRanges("offsetRange", in: 0 ..< layout.count) { offsetRange in
          withEvery("isShared", in: [false, true]) { isShared in
            var set = Uniqued<Base>(layout: layout)
            let low = offsetRange.lowerBound
            let high = offsetRange.upperBound
            withHiddenCopies(if: isShared, of: &set) { set in
              let count = layout.count
              let removedRange = set._indexRange(at: low ..< high)
              set.removeSubrange(removedRange)

              expectEqual(set.count, layout.count - offsetRange.count)

              if set.count < _UnsafeHashTable.minimumCapacity(forScale: layout.scale) {
                expectLessThan(set._scale, layout.scale)
              }

              expectEqualElements(set[_offsets: ..<low], 0 ..< low)
              expectEqualElements(set[_offsets: low...], high ..< count)
              // Check that elements are still accessible through the hash table.
              withEvery("i", in: 0 ..< count) { i in
                if i < offsetRange.lowerBound {
                  expectEqual(set.firstIndex(of: i), set._index(at: i))
                } else if i >= offsetRange.upperBound {
                  expectEqual(set.firstIndex(of: i),
                              set._index(at: i - offsetRange.count))
                } else {
                  expectNil(set.firstIndex(of: i))
                }
              }
            }
          }
        }
      }
    }
    check(MinimalBase<Int>.self)
    check(ContiguousArray<Int>.self)
  }

  func test_init_minimumCapacity() {
    withEvery("capacity", in: 0 ..< 1000) { capacity in
      let expectedScale = _UnsafeHashTable.scale(forCapacity: capacity)
      let set = Uniqued<MinimalBase<Int>>(minimumCapacity: capacity)
      expectEqual(set._scale, expectedScale)
      expectEqual(set._reservedScale, expectedScale)
      expectEqual(set._minimumCapacity, 0)
    }
  }

  func test_reserveCapacity_empty() {
    withEvery("capacity", in: 0 ..< 1000) { capacity in
      let expectedScale = _UnsafeHashTable.scale(forCapacity: capacity)
      var set = Uniqued<MinimalBase<Int>>()
      expectEqual(set._scale, 0)
      expectEqual(set._reservedScale, 0)
      expectEqual(set._minimumCapacity, 0)

      set.reserveCapacity(capacity)
      expectEqual(set._scale, expectedScale)
      expectEqual(set._reservedScale, expectedScale)
      expectEqual(set._minimumCapacity, 0)

      set.reserveCapacity(0)
      expectEqual(set._scale, 0)
      expectEqual(set._reservedScale, 0)
      expectEqual(set._minimumCapacity, 0)
    }
  }

  func test_reserveCapacity_behavior() {
    let scale1 = 6
    let range1 = 16 ... 48
    let count1 = 32

    let scale2 = 8
    let range2 = 64 ... 192
    let count2 = 128

    var set = Uniqued<MinimalBase<Int>>(0 ..< count1)
    expectEqual(set._scale, scale1)
    expectEqual(set._reservedScale, 0)
    expectEqual(set._minimumCapacity, range1.lowerBound)
    expectEqual(set._capacity, range1.upperBound)

    set.reserveCapacity(count2)
    expectEqual(set._scale, scale2)
    expectEqual(set._reservedScale, scale2)
    expectEqual(set._minimumCapacity, 0)
    expectEqual(set._capacity, range2.upperBound)

    set.append(contentsOf: count1 ..< count2)
    expectEqual(set._scale, scale2)
    expectEqual(set._reservedScale, scale2)
    expectEqual(set._minimumCapacity, 0)
    expectEqual(set._capacity, range2.upperBound)

    set.reserveCapacity(0)
    expectEqual(set._scale, scale2)
    expectEqual(set._reservedScale, 0)
    expectEqual(set._minimumCapacity, range2.lowerBound)
    expectEqual(set._capacity, range2.upperBound)

    set.removeSubrange(set._indexRange(at: count1...))
    expectEqual(set._scale, scale1)
    expectEqual(set._reservedScale, 0)
    expectEqual(set._minimumCapacity, range1.lowerBound)
    expectEqual(set._capacity, range1.upperBound)
  }

  func withSampleRanges(
    file: StaticString = #file,
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

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let u2 = Uniqued<MinimalBase<Int>>(r2)
      let actual1 = u1.union(u2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.union(u2).union(u1)
      expectEqualElements(actual2, expected)
    }
  }

  func test_formUnion_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).union(r2).sorted()

      var res = Uniqued<MinimalBase<Int>>()

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      res.formUnion(u1)
      expectEqualElements(res, r1)

      let u2 = Uniqued<MinimalBase<Int>>(r2)
      res.formUnion(u2)
      expectEqualElements(res, expected)

      res.formUnion(u1)
      res.formUnion(u2)
      expectEqualElements(res, expected)
    }
  }

  func test_union_generic() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).union(r2).sorted()
      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let u2 = u1.union(r2)
      expectEqualElements(u2, expected)

      let u3 = u2.union(r1)
      expectEqualElements(u3, expected)
    }
  }

  func test_formUnion_generic() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).union(r2).sorted()

      var res = Uniqued<MinimalBase<Int>>()

      res.formUnion(r1)
      expectEqualElements(res, r1)

      res.formUnion(r2)
      expectEqualElements(res, expected)

      res.formUnion(r1)
      res.formUnion(r2)
      expectEqualElements(res, expected)
    }
  }

  func test_intersection_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).intersection(r2).sorted()

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let u2 = Uniqued<MinimalBase<Int>>(r2)
      let actual1 = u1.intersection(u2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.intersection(r1)
      expectEqualElements(actual2, expected)
    }
  }

  func test_formIntersection_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).intersection(r2).sorted()

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let u2 = Uniqued<MinimalBase<Int>>(r2)
      var res = u1
      res.formIntersection(u2)
      expectEqualElements(res, expected)
      expectEqualElements(u1, r1)

      res.formIntersection(u1)
      res.formIntersection(u2)
      expectEqualElements(res, expected)
    }
  }

  func test_intersection_generic() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).intersection(r2).sorted()

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let actual1 = u1.intersection(r2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.intersection(r1).intersection(r2)
      expectEqualElements(actual2, expected)
    }
  }

  func test_formIntersection_generic() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).intersection(r2).sorted()

      var res = Uniqued<MinimalBase<Int>>(r1)
      res.formIntersection(r2)
      expectEqualElements(res, expected)

      res.formIntersection(r1)
      res.formIntersection(r2)
      expectEqualElements(res, expected)
    }
  }

  func test_symmetricDifference_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).symmetricDifference(r2).sorted()

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let u2 = Uniqued<MinimalBase<Int>>(r2)
      let actual1 = u1.symmetricDifference(u2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.symmetricDifference(u1).symmetricDifference(u2)
      expectEqual(actual2.count, 0)
    }
  }

  func test_formSymmetricDifference_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).symmetricDifference(r2).sorted()

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let u2 = Uniqued<MinimalBase<Int>>(r2)
      var res = u1
      res.formSymmetricDifference(u2)
      expectEqualElements(res, expected)
      expectEqualElements(u1, r1)

      res.formSymmetricDifference(u1)
      res.formSymmetricDifference(u2)
      expectEqual(res.count, 0)
    }
  }

  func test_symmetricDifference_generic() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).symmetricDifference(r2).sorted()

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let actual1 = u1.symmetricDifference(r2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.symmetricDifference(r1).symmetricDifference(r2)
      expectEqual(actual2.count, 0)
    }
  }

  func test_formSymmetricDifference_generic() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).symmetricDifference(r2).sorted()

      var res = Uniqued<MinimalBase<Int>>(r1)
      res.formSymmetricDifference(r2)
      expectEqualElements(res, expected)

      res.formSymmetricDifference(r1)
      res.formSymmetricDifference(r2)
      expectEqual(res.count, 0)
    }
  }

  func test_subtracting_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).subtracting(r2).sorted()

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let u2 = Uniqued<MinimalBase<Int>>(r2)
      let actual1 = u1.subtracting(u2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.subtracting(u2)
      expectEqualElements(actual2, expected)
    }
  }

  func test_subtract_Self() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).subtracting(r2).sorted()

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let u2 = Uniqued<MinimalBase<Int>>(r2)
      var res = u1
      res.subtract(u2)
      expectEqualElements(res, expected)
      expectEqualElements(u1, r1)

      res.subtract(u2)
      expectEqualElements(res, expected)
    }
  }

  func test_subtracting_generic() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).subtracting(r2).sorted()

      let u1 = Uniqued<MinimalBase<Int>>(r1)
      let actual1 = u1.subtracting(r2)
      expectEqualElements(actual1, expected)

      let actual2 = actual1.subtracting(r2)
      expectEqualElements(actual2, expected)
    }
  }

  func test_subtract_generic() {
    withSampleRanges { r1, r2 in
      let expected = Set(r1).subtracting(r2).sorted()

      var res = Uniqued<MinimalBase<Int>>(r1)
      res.subtract(r2)
      expectEqualElements(res, expected)

      res.subtract(r2)
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
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = Uniqued<MinimalBase<Int>>(r2)
        expectEqual(a.isSubset(of: b), expected)
      }
    }
  }

  func test_isSubset_Set() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isSubset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = Set<Int>(r2)
        expectEqual(a.isSubset(of: b), expected)
      }
    }
  }

  func test_isSubset_generic() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isSubset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = r2
        expectEqual(a.isSubset(of: b), expected)
      }
    }
  }

  func test_isSuperset_Self() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isSuperset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = Uniqued<MinimalBase<Int>>(r2)
        expectEqual(a.isSuperset(of: b), expected)
      }
    }
  }

  func test_isSuperset_Set() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isSuperset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = Set<Int>(r2)
        expectEqual(a.isSuperset(of: b), expected)
      }
    }
  }

  func test_isSuperset_generic() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isSuperset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = r2
        expectEqual(a.isSuperset(of: b), expected)
      }
    }
  }

  func test_isStrictSubset_Self() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isStrictSubset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = Uniqued<MinimalBase<Int>>(r2)
        expectEqual(a.isStrictSubset(of: b), expected)
      }
    }
  }

  func test_isStrictSubset_Set() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isStrictSubset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = Set<Int>(r2)
        expectEqual(a.isStrictSubset(of: b), expected)
      }
    }
  }

  func test_isStrictSubset_generic() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isStrictSubset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = r2
        expectEqual(a.isStrictSubset(of: b), expected)
      }
    }
  }

  func test_isStrictSuperset_Self() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isStrictSuperset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = Uniqued<MinimalBase<Int>>(r2)
        expectEqual(a.isStrictSuperset(of: b), expected)
      }
    }
  }

  func test_isStrictSuperset_Set() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isStrictSuperset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = Set<Int>(r2)
        expectEqual(a.isStrictSuperset(of: b), expected)
      }
    }
  }

  func test_isStrictSuperset_generic() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isStrictSuperset(of: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = r2
        expectEqual(a.isStrictSuperset(of: b), expected)
      }
    }
  }

  func test_isDisjoint_Self() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isDisjoint(with: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = Uniqued<MinimalBase<Int>>(r2)
        expectEqual(a.isDisjoint(with: b), expected)
      }
    }
  }

  func test_isDisjoint_Set() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isDisjoint(with: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = Set<Int>(r2)
        expectEqual(a.isDisjoint(with: b), expected)
      }
    }
  }

  func test_isDisjoint_generic() {
    withEvery("unit", in: [1, 3, 7, 10, 20, 50]) { unit in
      SampleRanges(unit: unit).withEveryPair { r1, r2 in
        let expected = Set(r1).isDisjoint(with: r2)
        let a = Uniqued<MinimalBase<Int>>(r1)
        let b = r2
        expectEqual(a.isDisjoint(with: b), expected)
      }
    }
  }
}
