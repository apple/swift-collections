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

import Testing

#if COLLECTIONS_SINGLE_MODULE
  @testable import Collections
#else
  import _CollectionsTestSupport
  import ContainersPreview
  @testable import BasicContainers
  internal import Foundation
#endif

// We have to assume that the properties (count, isEmpty, startIndex, endIndex)
// are working correctly.
@Suite("StringCollection")
struct StringCollectionTests {
  @Suite("Initializers")
  struct InitializerTests {
    @available(macOS 15.0, *)
    @Test("Empty init produces empty collection")
    func emptyInit() async throws {
      let c = StringCollection()
      #expect(c.isEmpty)
      #expect(c.count == 0)
      #expect(c.startIndex == c.endIndex)
    }

    @available(macOS 15.0, *)
    @Test("Variadic init stores elements in order")
    func variadicInitOrder() async throws {
      let c = StringCollection("a", "bb", "ccc")
      #expect(!c.isEmpty)
      #expect(c.count == 3)
      #expect(c.elementsEqual(["a", "bb", "ccc"]))
    }

    @available(macOS 15.0, *)
    @Test("Variadic init accepts StringProtocol types")
    func variadicInitStringProtocol() async throws {
      let sub: Substring = "hello".prefix(3)  // "hel"
      let c = StringCollection(sub, "lo")
      #expect(c.count == 2)
      #expect(c.first == "hel")
      #expect(c.last == "lo")
    }

    @available(macOS 15.0, *)
    @Test("Duplicates of the same value")
    func repeatingInit() async throws {
      let c0 = StringCollection(repeating: "x", count: 0)
      #expect(c0.isEmpty)

      let c3 = StringCollection(repeating: "ab", count: 3)
      #expect(c3.count == 3)
      #expect(c3.elementsEqual(["ab", "ab", "ab"]))

      let cEmpty = StringCollection(repeating: "", count: 2)
      #expect(cEmpty.count == 2)
      #expect(cEmpty.elementsEqual(["", ""]))
    }

    @available(macOS 15.0, *)
    @Test("Reading from another Sequence")
    func sequenceInit() async throws {
      let cEmpty = StringCollection([String]())
      #expect(cEmpty.isEmpty)

      let arr = ["a", "bb", "ccc"]
      let c = StringCollection(arr)
      #expect(c.count == 3)
      #expect(c.elementsEqual(arr))
    }
  }

  @Suite("Equality and Hashing")
  struct ComparisonDemos {
    @available(macOS 15.0, *)
    @Test("Equatable equality and inequality")
    func equatable() async throws {
      let a = StringCollection("a", "b", "c")
      let b = StringCollection("a", "b", "c")
      let c = StringCollection("a", "c", "b")
      let d = StringCollection("a", "b", "c", "d")
      #expect(a == b)
      #expect(a != c)
      #expect(a != d)
    }

    @available(macOS 15.0, *)
    @Test("Hashable matches equality semantics")
    func hashable() async throws {
      let a = StringCollection("x", "y")
      let b = StringCollection("x", "y")
      let c = StringCollection("x", "z")
      #expect(a.hashValue == b.hashValue)
      #expect(a == b)
      #expect(a != c)
    }
  }

  @Suite("Searching methods")
  struct SearchTests {
    @available(macOS 15.0, *)
    @Test("Check first & last locations of given element values")
    func searching() async throws {
      let fruits = StringCollection(
        "apple",
        "banana",
        "apple",
        "cherry",
        "banana"
      )
      let firstIndex = fruits.startIndex
      let endingIndex = fruits.endIndex

      let firstApple = try #require(fruits.firstIndex(of: "apple"))
      let lastApple = try #require(fruits.lastIndex(of: "apple"))
      #expect(firstApple == firstIndex)
      #expect(fruits.distance(from: firstIndex, to: lastApple) == +2)
      #expect(fruits[firstApple] == "apple")
      #expect(fruits[lastApple] == "apple")

      let firstBanana = try #require(fruits.firstIndex(of: "banana"))
      let lastBanana = try #require(fruits.lastIndex(of: "banana"))
      #expect(firstBanana == fruits.index(after: firstIndex))
      #expect(lastBanana == fruits.index(before: endingIndex))
      #expect(fruits[firstBanana] == "banana")
      #expect(fruits[lastBanana] == "banana")

      let firstCherry = try #require(fruits.firstIndex(of: "cherry"))
      let lastCherry = try #require(fruits.lastIndex(of: "cherry"))
      #expect(fruits.distance(from: firstIndex, to: firstCherry) == +3)
      #expect(lastCherry == firstCherry)
      #expect(fruits[firstCherry] == "cherry")
      #expect(fruits[lastCherry] == "cherry")

      #expect(fruits.firstIndex(of: "date") == nil)
      #expect(fruits.lastIndex(of: "date") == nil)
    }

    @available(macOS 15.0, *)
    @Test("Check if a value is contained in the collection.")
    func containsTests() async throws {
      let empty = StringCollection()
      #expect(!empty.contains("x"))

      let c = StringCollection("a", "b", "c", "b")
      #expect(c.contains("a"))
      #expect(c.contains("b"))
      #expect(c.contains("c"))
      #expect(!c.contains("z"))
    }
  }

  @Suite("Indexing")
  struct IndexManipulationTests {
    @available(macOS 15.0, *)
    @Test("Indices and traversal forward/backward")
    func bidirectionalIndices() async throws {
      let c = StringCollection("a", "b", "cd")

      // You shouldn't really depend on these specific values.
      // I can because I know how the index values work.
      #expect(c.startIndex == 0)
      #expect(c.indices.elementsEqual([0, 3, 6]))

      var ci = c.endIndex
      #expect(ci == 10)
      c.formIndex(before: &ci)
      #expect(ci == 6)
      c.formIndex(before: &ci)
      #expect(ci == 3)
      c.formIndex(before: &ci)
      #expect(ci == 0)
      #expect(ci == c.startIndex)
    }

    @available(macOS 15.0, *)
    @Test("Index navigation on singleton")
    func singletonIndices() async throws {
      let c = StringCollection("only")
      #expect(c.first == "only")
      #expect(c.index(after: c.startIndex) == c.endIndex)
      #expect(c.index(before: c.endIndex) == c.startIndex)
      #expect(c.distance(from: c.startIndex, to: c.endIndex) == +1)
      #expect(c.endIndex - c.startIndex > 1)
    }

    @available(macOS 15.0, *)
    @Test(
      """
      Indices are traversed with index(after:) and\
      are not assumed to be consecutive integers
      """
    )
    func indicesAreNotConsecutiveIntegers() async throws {
      let c = StringCollection("a", "bb", "ccc", "dddd")
      #expect(c.count == 4)

      // Walk indices using collection APIs
      var collected = [String]()
      var i = c.startIndex
      while i != c.endIndex {
        collected.append(c[i])
        c.formIndex(after: &i)
      }
      #expect(collected == ["a", "bb", "ccc", "dddd"])

      // Confirm that having logically consecutive indices doesn't mean they're
      // also consecutive value-wise.
      // (Each embedded string includes 2 metadata end-caps,
      // even for empty strings,
      // so consecutive top-level indices must be at least 2 apart value-wise.)
      let cIndices = Array(c.indices)
      let deltas = Array(zip(cIndices, cIndices.dropFirst() + [c.endIndex]))
      #expect(deltas.count == c.count)
      #expect(
        deltas.count(where: { c.distance(from: $0.0, to: $0.1) == +1 })
          == c.count
      )
      #expect(deltas.count(where: { $0.1 - $0.0 > 1 }) == c.count)
    }
  }

  @Suite("Subscripting")
  struct SubscriptingTests {
    @available(macOS 15.0, *)
    @Test("Subscript by Index returns correct elements")
    func subscriptByIndex() async throws {
      let c = StringCollection("zero", "one", "two")
      var ci = c.startIndex
      #expect(c[ci] == "zero")
      c.formIndex(after: &ci)
      #expect(c[ci] == "one")
      c.formIndex(after: &ci)
      #expect(c[ci] == "two")
    }

    @available(macOS 15.0, *)
    @Test("Subscript by index range returns element bundles (slicing)")
    func slicingBounds() async throws {
      let c = StringCollection("a", "b", "c", "d")
      let idx = Array(c.indices)

      // Prefix slice [a, b)
      let s1 = c[idx[0]..<idx[2]]
      #expect(Array(s1) == ["a", "b"])

      // Middle slice [b, c)
      let s2 = c[idx[1]..<idx[3]]
      #expect(Array(s2) == ["b", "c"])

      // Suffix slice [c, end)
      let s3 = c[idx[2]..<c.endIndex]
      #expect(Array(s3) == ["c", "d"])

      // Empty slice
      let sEmpty = c[idx[1]..<idx[1]]
      #expect(Array(sEmpty).isEmpty)

      // Full slice
      let sFull = c[c.startIndex..<c.endIndex]
      #expect(Array(sFull) == ["a", "b", "c", "d"])
    }
  }

  @Suite("Replacment of elements")
  struct ReplacementTests {
    @available(macOS 15.0, *)
    @Test("Sub-sequence replacement")
    func replaceSubrangeSequence() async throws {
      var c = StringCollection("a", "b", "c", "d")
      let ci = Array(c.indices)
      // Replace middle two
      c.replaceSubrange(ci[1]..<ci[3], with: ["x", "y"])
      #expect(c.count == 4)
      #expect(c.elementsEqual(["a", "x", "y", "d"]))
    }

    @available(macOS 15.0, *)
    @Test("Replacement with an empty collection")
    func replaceSubrangeRemoval() async throws {
      var c = StringCollection("a", "b", "c")
      let ci = Array(c.indices)
      c.replaceSubrange(ci[1]..., with: EmptyCollection())
      #expect(c.count == 1)
      #expect(c.first == "a")
    }

    @available(macOS 15.0, *)
    @Test("Replacment at the end (i.e. appending)")
    func replaceSubrangeInsertionAtEnd() async throws {
      var c = StringCollection("a")
      c.replaceSubrange(c.endIndex..<c.endIndex, with: ["b", "c"])
      #expect(c.count == 3)
      #expect(c.elementsEqual(["a", "b", "c"]))
    }

    @available(macOS 15.0, *)
    @Test("Replacing an entire range")
    func replaceEntireRange() async throws {
      var c = StringCollection("a", "b", "c")
      c.replaceSubrange(c.startIndex..<c.endIndex, with: ["x"])
      #expect(c.count == 1)
      #expect(c.first == "x")
    }
  }

  @Suite("Additive mutating operations")
  struct InsertionTests {
    @available(macOS 15.0, *)
    @Test("Single-element append")
    func appendElement() async throws {
      var c = StringCollection()
      c.append("a")
      #expect(c.elementsEqual(["a"]))

      c.append("")
      #expect(c.elementsEqual(["a", ""]))

      var c2 = StringCollection("x", "y")
      let original = c2
      c2.append("z")
      #expect(c2.elementsEqual(["x", "y", "z"]))
      #expect(original.elementsEqual(["x", "y"]))
    }

    @available(macOS 15.0, *)
    @Test("Appending a sub-sequence")
    func appendContents() async throws {
      var c = StringCollection("a")
      c.append(contentsOf: ["b", "c"])
      #expect(c.elementsEqual(["a", "b", "c"]))

      c.append(contentsOf: EmptyCollection())
      #expect(c.elementsEqual(["a", "b", "c"]))
    }

    @available(macOS 15.0, *)
    @Test("Arbitrary single-element insertion")
    func insertAtIndex() async throws {
      var c = StringCollection()
      c.insert("a", at: c.startIndex)
      #expect(c.elementsEqual(["a"]))

      // Insert at start
      c.insert("0", at: c.startIndex)
      #expect(c.elementsEqual(["0", "a"]))

      // Insert at end
      c.insert("b", at: c.endIndex)
      #expect(c.elementsEqual(["0", "a", "b"]))

      // Insert in middle
      let mid = c.index(after: c.startIndex)
      c.insert("X", at: mid)
      #expect(c.elementsEqual(["0", "X", "a", "b"]))
    }

    @available(macOS 15.0, *)
    @Test("Arbitrary sub-sequence insertion")
    func insertContentsAtIndex() async throws {
      var c = StringCollection("a", "d")

      // Start
      c.insert(contentsOf: ["0", "1"], at: c.startIndex)
      #expect(c.elementsEqual(["0", "1", "a", "d"]))

      // Middle (before "d")
      let iD = c.index(before: c.endIndex)
      c.insert(contentsOf: ["b", "c"], at: iD)
      #expect(c.elementsEqual(["0", "1", "a", "b", "c", "d"]))

      // End
      c.insert(contentsOf: ["e", "f"], at: c.endIndex)
      #expect(c.elementsEqual(["0", "1", "a", "b", "c", "d", "e", "f"]))

      // Empty sequence
      c.insert(contentsOf: EmptyCollection(), at: c.endIndex)
      #expect(c.elementsEqual(["0", "1", "a", "b", "c", "d", "e", "f"]))
    }
  }

  @Suite("Subractive mutating operations")
  struct RemovalTests {
    @available(macOS 15.0, *)
    @Test("Remove last element(s)")
    func removeLastBehavior() async throws {
      var c = StringCollection("a", "b", "c", "d", "e")
      let oldLast = c.removeLast()
      #expect(oldLast == "e")
      #expect(c.count == 4)
      #expect(c.elementsEqual(["a", "b", "c", "d"]))
      c.removeLast(2)
      #expect(c.count == 2)
      #expect(c.elementsEqual(["a", "b"]))
    }

    @available(macOS 15.0, *)
    @Test("Arbitrary single-element removal")
    func removeAtIndex() async throws {
      var c = StringCollection("a", "b", "c", "d")
      let removedStart = c.remove(at: c.startIndex)
      #expect(removedStart == "a")
      #expect(c.elementsEqual(["b", "c", "d"]))

      let mid = c.index(after: c.startIndex)  // "c"
      let removedMid = c.remove(at: mid)
      #expect(removedMid == "c")
      #expect(c.elementsEqual(["b", "d"]))

      let removedEnd = c.remove(at: c.index(before: c.endIndex))
      #expect(removedEnd == "d")
      #expect(c.elementsEqual(["b"]))
    }

    @available(macOS 15.0, *)
    @Test("Arbitrary sub-sequence removal")
    func removeSubrangeTests() async throws {
      var c = StringCollection("a", "b", "c", "d", "e")
      let idx = Array(c.indices)

      // Remove prefix [a, b)
      c.removeSubrange(idx[0]..<idx[2])
      #expect(c.elementsEqual(["c", "d", "e"]))

      // Remove middle [d)
      let midStart = c.index(after: c.startIndex)  // "d"
      let midEnd = c.index(after: midStart)
      c.removeSubrange(midStart..<midEnd)
      #expect(c.elementsEqual(["c", "e"]))

      // Empty range
      c.removeSubrange(c.startIndex..<c.startIndex)
      #expect(c.elementsEqual(["c", "e"]))

      // Remove entire range
      c.removeSubrange(c.startIndex..<c.endIndex)
      #expect(c.isEmpty)
    }

    @available(macOS 15.0, *)
    @Test("Remove first element(s)")
    func removeFirstBehavior() async throws {
      var c = StringCollection("a", "b", "c", "d")

      let first = c.removeFirst()
      #expect(first == "a")
      #expect(c.elementsEqual(["b", "c", "d"]))

      c.removeFirst(0)
      #expect(c.elementsEqual(["b", "c", "d"]))

      c.removeFirst(2)
      #expect(c.elementsEqual(["d"]))

      c.removeFirst(1)
      #expect(c.isEmpty)
    }

    @available(macOS 15.0, *)
    @Test("Predicate-based removal")
    func removeAllWhere() async throws {
      var c = StringCollection("a", "bb", "c", "ddd", "e")
      c.removeAll(where: { $0.count.isMultiple(of: 2) })  // remove "bb"
      #expect(c.elementsEqual(["a", "c", "ddd", "e"]))

      c.removeAll(where: { $0 == "zzz" })  // no-op
      #expect(c.elementsEqual(["a", "c", "ddd", "e"]))

      var d = StringCollection("x", "x", "y", "x")
      d.removeAll(where: { $0 == "x" })
      #expect(d.elementsEqual(["y"]))
    }

    @available(macOS 15.0, *)
    @Test("Removing everything clears the collection")
    func removeAllTest() async throws {
      var c = StringCollection("a", "b")
      c.removeAll()
      #expect(c.isEmpty)
      #expect(c.count == 0)
    }
  }

  @Suite("Copy-on-write Semantics")
  struct CopyOnWriteTests {
    @available(macOS 15.0, *)
    @Test("Mutation should not affect original")
    func copyOnWriteIsolation() async throws {
      let original = StringCollection("a", "b", "c")
      let oi = Array(original.indices)
      var copy = original

      // Mutate copy
      copy.replaceSubrange(oi[1]..<oi[2], with: ["B"])

      // Original remains unchanged
      #expect(original.count == 3)
      #expect(original.elementsEqual(["a", "b", "c"]))

      // Copy reflects mutation
      #expect(copy.count == 3)
      #expect(copy.elementsEqual(["a", "B", "c"]))
    }

    @available(macOS 15.0, *)
    @Test("Copies versus removeAll")
    func copyOnWriteRemoveAll() async throws {
      let original = StringCollection("x", "y")
      var copy = original
      copy.removeAll()
      #expect(original.count == 2)
      #expect(copy.count == 0)
    }
  }
}
