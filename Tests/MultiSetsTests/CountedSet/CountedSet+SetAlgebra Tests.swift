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
import MultiSets

import _CollectionsTestSupport


private let x: CountedSet<Character> = ["a": 1, "b": 2, "c": 3, "d": 4]
private let y: CountedSet<Character> = ["e", "f", "a", "f"]

class CountedSetSetAlgebraTests: CollectionTestCase {
  /// `S() == []`
  func testEmptyArrayLiteralInitialization() {
    XCTAssertEqual(CountedSet<Never>(), [])
  }

  /// `x.intersection(x) == x`
  func testIdempotentIntersection() {
    XCTAssertEqual(x.intersection(x), x)
  }

  /// `x.intersection([]) == []`
  func testEmptyIntersection() {
    XCTAssertEqual(x.intersection([]), [])
  }

  /// `x.union(x) == x`
  func testIdempotentUnion() {
    XCTAssertEqual(x.union(x), x)
  }

  /// `x.union([]) == x`
  func testEmptyUnion() {
    XCTAssertEqual(x.union([]), x)
  }

  /// `x.contains(e)` implies `x.union(y).contains(e)`
  func testUnionContainsElementsOfCurrentSet() {
    let union = x.union(y)
    x.rawValue.keys.forEach { e in XCTAssert(union.contains(e)) }
  }

  /// `x.union(y).contains(e)` implies `x.contains(e) || y.contains(e)`
  func testUnionContainsOnlyElementsOfCurrentOrGivenSets() {
    x.union(y).rawValue.keys.forEach { e in
      XCTAssert(x.contains(e) || y.contains(e))
    }
  }

  /// `x.contains(e) && y.contains(e)` if and only if
  ///   `x.intersection(y).contains(e)`
  func testIntersectionContainsOnlyAllElementsOfCurrentOrGivenSets() {
    XCTAssertEqual(
      x.rawValue.keys.filter { (e: Character) in y.contains(e) },
      Array(x.intersection(y).rawValue.keys)
    )
  }

  /// `x.isSubset(of: y)` implies `x.union(y) == y`
  func testSubsetDomination() {
    let y: CountedSet<Character> = ["a": 1, "b": 2, "c": 3, "d": 4, "n": 9]
    assert(x.isSubset(of: y), "Antecedent not satisfied")
    XCTAssertEqual(x.union(y), y)
  }

  /// `x.isSuperset(of: y)` implies `x.union(y) == x`
  func testSupersetAbsorption() {
    let y: CountedSet<Character> = ["b", "b"]
    assert(x.isSuperset(of: y), "Antecedent not satisfied")
    XCTAssertEqual(x.union(y), x)
  }

  /// `x.isSubset(of: y)` if and only if `y.isSuperset(of: x)`
  func testSubsetOfSuperset() {
    XCTAssertEqual(x.isSubset(of: y), y.isSuperset(of: x))
    let y: CountedSet<Character> = ["b", "b"]
    XCTAssertEqual(x.isSubset(of: y), y.isSuperset(of: x))
  }

  /// `x.isStrictSuperset(of: y)` if and only if `x.isSuperset(of: y) && x != y`
  func testStrictSuperset() {
    var y = x
    XCTAssertEqual(x.isStrictSuperset(of: y), x.isSuperset(of: y) && x != y)
    y.remove("a")
    XCTAssertEqual(x.isStrictSuperset(of: y), x.isSuperset(of: y) && x != y)
  }

  /// `x.isStrictSubset(of: y)` if and only if `x.isSubset(of: y) && x != y`
  func testStrictSubset() {
    var y = x
    XCTAssertEqual(x.isStrictSubset(of: y), x.isSubset(of: y) && x != y)
    y.insert("n")
    XCTAssertEqual(x.isStrictSubset(of: y), x.isSubset(of: y) && x != y)
  }

  func testSymmetricDifference() {
    XCTAssertEqual(
      x.symmetricDifference(y),
      ["b": 2, "c": 3, "d": 4, "e": 1, "f": 2]
    )
  }

  func testSymmetricDifferenceWithLargerOperand() {
    XCTAssertEqual(
      x.symmetricDifference(["b": 5]),
      ["a": 1, "b": 3, "c": 3, "d": 4]
    )
  }

  func testUpdateExisting() {
    var referenceStrings: CountedSet<NSMutableString> = [
      "testing",
      "testing",
      "one",
      "two",
      "three",
    ]

    let newTestingString: NSMutableString = "testing"
    assert(
      referenceStrings.first { $0 == "testing" }! !== newTestingString,
      "The new string is identical to what it is meant to replace"
    )
    referenceStrings.update(with: newTestingString)
    XCTAssertIdentical(
      referenceStrings.first { $0 == "testing" }!,
      newTestingString
    )
    XCTAssertEqual(referenceStrings.rawValue["testing"], 3)
  }

  func testUpdateNew() {
    var s: CountedSet = ["dog"]
    s.update(with: "cow")
    XCTAssertEqual(s, ["dog", "cow"])
  }

  func testRemoveEmpty() {
    var s = CountedSet<Int>()
    XCTAssertNil(s.remove(42))
    XCTAssert(s.isEmpty)
  }

  func testRemoveExisting() {
    var s: CountedSet = ["testing", "testing"]
    XCTAssertEqual(s.remove("testing"), "testing")
    XCTAssertEqual(s, ["testing"])
  }
}
