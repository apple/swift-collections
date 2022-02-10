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

class CountedSetSumTests: CollectionTestCase {
  func testSum() {
    XCTAssertEqual(
      x + y,
      ["a": 2, "b": 2, "c": 3, "d": 4, "e": 1, "f": 2]
    )
  }
}
