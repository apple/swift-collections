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

import XCTest
import Collections

// Verify that importing `Collections` makes available the expected types,
// including their member APIs, as if it was reexporting its component modules.
// (Accessing member APIs is incompatible with `MemberImportVisibility`, but
// that is not by itself source breaking.)

public func check(_ items: OrderedSet<Int>) -> Int {
  items[items.startIndex]
}

public func check(_ items: OrderedDictionary<Int, Int>) -> Int {
  items[42] ?? 23
}

public func check(_ items: Deque<Int>) -> Int {
  items[items.startIndex]
}

public func check(_ items: BitSet) -> Int {
  items[items.startIndex]
}

public func check(_ items: BitArray) -> Int {
  items.count
}

public func check2(_ items: BitArray) -> Int {
  Int(items)
}

public func check(_ items: inout Heap<Int>) -> Int {
  items.removeMin()
}

public func check(_ items: TreeSet<Int>) -> Int {
  items[items.startIndex]
}

public func check(_ items: TreeDictionary<Int, Int>) -> Int {
  items[42] ?? 23
}


class CollectionsTests: XCTestCase {
  func testDummy() {
    var items = Deque<Int>()
    items.prepend(42)
    XCTAssertEqual(items.first, 42)
  }

  func testOrderedSetMemberImportVisibility() {
    var values: OrderedSet<String> = []
    let insert = values.append("hello")

    XCTAssertEqual(insert.index, values.startIndex)
    XCTAssertEqual(values[values.startIndex], "hello")
  }
}
