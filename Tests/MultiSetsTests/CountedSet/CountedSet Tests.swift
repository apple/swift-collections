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

class CountedSetTests: CollectionTestCase {
  func test_empty() {
    let s = CountedSet<Int>()
    expectEqualElements(s, [])
    expectEqual(s.count, 0)
  }

  func test_init_minimumCapacity() {
    let s = CountedSet<Int>(minimumCapacity: 1000)
    expectGreaterThanOrEqual(s.rawValue.capacity, 1000)
  }
}
