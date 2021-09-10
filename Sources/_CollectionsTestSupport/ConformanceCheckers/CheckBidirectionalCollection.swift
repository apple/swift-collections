//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Loosely adapted from https://github.com/apple/swift/tree/main/stdlib/private/StdlibCollectionUnittest

// FIXME: Port all of the collection validation tests from the Swift compiler codebase.

import XCTest

extension BidirectionalCollection {
  func _indicesByIndexBefore() -> [Index] {
    var result: [Index] = []
    var i = endIndex
    while i != startIndex {
      i = index(before: i)
      result.append(i)
    }
    result.reverse()
    return result
  }

  func _indicesByFormIndexBefore() -> [Index] {
    var result: [Index] = []
    var i = endIndex
    while i != startIndex {
      formIndex(before: &i)
      result.append(i)
    }
    result.reverse()
    return result
  }
}

public func checkBidirectionalCollection<C: BidirectionalCollection, S: Sequence>(
  _ collection: C,
  expectedContents: S,
  file: StaticString = #file,
  line: UInt = #line
) where C.Element: Equatable, S.Element == C.Element {
  checkBidirectionalCollection(
    collection,
    expectedContents: expectedContents,
    by: ==,
    file: file,
    line: line)
}

public func checkBidirectionalCollection<C: BidirectionalCollection, S: Sequence>(
  _ collection: C,
  expectedContents: S,
  by areEquivalent: (S.Element, S.Element) -> Bool,
  file: StaticString = #file,
  line: UInt = #line
) where S.Element == C.Element {
  checkSequence(
    { collection }, expectedContents: expectedContents,
    by: areEquivalent,
    file: file, line: line)
  _checkCollection(
    collection, expectedContents: expectedContents,
    by: areEquivalent,
    file: file, line: line)
  _checkBidirectionalCollection(
    collection, expectedContents: expectedContents,
    by: areEquivalent,
    file: file, line: line)
}

public func _checkBidirectionalCollection<C: BidirectionalCollection, S: Sequence>(
  _ collection: C,
  expectedContents: S,
  by areEquivalent: (S.Element, S.Element) -> Bool,
  file: StaticString = #file,
  line: UInt = #line
) where S.Element == C.Element {
  let entry = TestContext.current.push("checkBidirectionalCollection", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  let expectedContents = Array(expectedContents)

  // Check that `index(before:)` and `formIndex(before:)` are consistent with `index(after:)`.
  let indicesByIndexAfter = collection._indicesByIndexAfter()
  let indicesByIndexBefore = collection._indicesByIndexBefore()
  let indicesByFormIndexBefore = collection._indicesByFormIndexBefore()
  expectEqual(indicesByIndexBefore, indicesByIndexAfter)
  expectEqual(indicesByFormIndexBefore, indicesByIndexAfter)

  // Check contents using indexing.
  let indexContents1 = indicesByIndexBefore.map { collection[$0] }
  expectEquivalentElements(
    indexContents1, expectedContents,
    by: areEquivalent,
    "\(expectedContents)")
  let indexContents2 = indicesByFormIndexBefore.map { collection[$0] }
  expectEquivalentElements(
    indexContents2, expectedContents,
    by: areEquivalent,
    "\(expectedContents)")

  // Check the Indices associated type
  if C.self != C.Indices.self {
    checkBidirectionalCollection(collection.indices, expectedContents: indicesByIndexAfter)
  }

  var allIndices = indicesByIndexAfter
  allIndices.append(collection.endIndex)

  // Check `index(_,offsetBy:)`
  for (startOffset, start) in allIndices.enumerated() {
    for endOffset in 0 ..< allIndices.count {
      let end = collection.index(start, offsetBy: endOffset - startOffset)
      expectEqual(end, allIndices[endOffset])
      if endOffset < expectedContents.count {
        expectEquivalent(
          collection[end], expectedContents[endOffset],
          by: areEquivalent)
      }
    }
  }

  // Check `distance(from:to:)`
  for i in allIndices.indices {
    for j in allIndices.indices {
      let d = collection.distance(from: allIndices[i], to: allIndices[j])
      expectEqual(d, j - i)
    }
  }

  // Check slicing.
  for i in 0 ..< allIndices.count {
    for j in i ..< allIndices.count {
      let range = allIndices[i] ..< allIndices[j]
      let slice = collection[range]
      expectEqualElements(slice._indicesByIndexBefore(), allIndices[i ..< j])
      expectEqualElements(slice._indicesByFormIndexBefore(), allIndices[i ..< j])
    }
  }
}
