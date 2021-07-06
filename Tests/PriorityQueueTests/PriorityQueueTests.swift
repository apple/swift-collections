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
@testable import PriorityQueueModule

final class PriorityQueueTests: XCTestCase {
  func test_isEmpty() {
    var queue = PriorityQueue<String, Double>()
    XCTAssertTrue(queue.isEmpty)

    queue.insert("Hello", priority: 0.1)
    XCTAssertFalse(queue.isEmpty)

    let _ = queue.popMin()
    XCTAssertTrue(queue.isEmpty)
  }

  func test_count() {
    var queue = PriorityQueue<String, Double>()
    XCTAssertEqual(queue.count, 0)

    queue.insert("Hello", priority: 0.1)
    XCTAssertEqual(queue.count, 1)
    queue.insert("World", priority: 0.5)
    XCTAssertEqual(queue.count, 2)

    let _ = queue.popMax()
    XCTAssertEqual(queue.count, 1)
  }

  func test_min() {
    var queue = PriorityQueue<String, Int>()
    XCTAssertNil(queue.min())

    queue.insert("Medium", priority: 5)
    XCTAssertEqual(queue.min(), "Medium")

    queue.insert("High", priority: 10)
    XCTAssertEqual(queue.min(), "Medium")

    queue.insert("Low", priority: 1)
    XCTAssertEqual(queue.min(), "Low")
  }

  func test_max() {
    var queue = PriorityQueue<String, Int>()
    XCTAssertNil(queue.max())

    queue.insert("Medium", priority: 5)
    XCTAssertEqual(queue.max(), "Medium")

    queue.insert("Low", priority: 1)
    XCTAssertEqual(queue.max(), "Medium")

    queue.insert("High", priority: 10)
    XCTAssertEqual(queue.max(), "High")
  }

  func test_popMin() {
    var queue = PriorityQueue<String, Int>()
    XCTAssertNil(queue.popMin())

    queue.insert("Low", priority: 1)
    queue.insert("High", priority: 10)
    queue.insert("Medium", priority: 5)

    XCTAssertEqual(queue.popMin(), "Low")
    XCTAssertEqual(queue.popMin(), "Medium")
    XCTAssertEqual(queue.popMin(), "High")
    XCTAssertNil(queue.popMin())
  }

  func test_popMax() {
    var queue = PriorityQueue<String, Int>()
    XCTAssertNil(queue.popMax())

    queue.insert("Low", priority: 1)
    queue.insert("High", priority: 10)
    queue.insert("Medium", priority: 5)

    XCTAssertEqual(queue.popMax(), "High")
    XCTAssertEqual(queue.popMax(), "Medium")
    XCTAssertEqual(queue.popMax(), "Low")
    XCTAssertNil(queue.popMax())
  }

  // MARK: -

  func test_elementsWithEqualPriorityDequeuedInFIFOOrder() {
    var queue = PriorityQueue<String, Int>()

    queue.insert("Foo 0", priority: 0)
    queue.insert("Foo 1", priority: 1)
    queue.insert("Bar 0", priority: 0)
    queue.insert("Bar 1", priority: 1)
    queue.insert("Baz 0", priority: 0)
    queue.insert("Baz 1", priority: 1)

    let ordered = Array(queue.ascending)

    XCTAssertEqual(
      ordered,
      ["Foo 0", "Bar 0", "Baz 0", "Foo 1", "Bar 1", "Baz 1"]
    )
  }

  // MARK: - Initializers

  func test_initializer_fromSequence() {
    let queue = PriorityQueue<String, Int>(
      (1...).prefix(20).map({ ($0.description, $0) })
    )
    XCTAssertEqual(queue.count, 20)
  }

  func test_initializer_fromArrayLiteral() {
    var queue: PriorityQueue = [
      ("One", 1), ("Three", 3), ("Five", 5), ("Seven", 7), ("Nine", 9)
    ]
    XCTAssertEqual(queue.count, 5)

    XCTAssertEqual(queue.popMax(), "Nine")
    XCTAssertEqual(queue.popMax(), "Seven")
    XCTAssertEqual(queue.popMax(), "Five")
    XCTAssertEqual(queue.popMax(), "Three")
    XCTAssertEqual(queue.popMax(), "One")
  }

  func test_initializer_fromDictionaryLiteral() {
    var queue: PriorityQueue = [
      "Urgent": 100,
      "Low": 1,
      "Medium": 40,
      "High": 60
    ]
    XCTAssertEqual(queue.count, 4)

    XCTAssertEqual(queue.popMax(), "Urgent")
    XCTAssertEqual(queue.popMin(), "Low")
  }

  // MARK: -

  func test_sequenceConformance() {
    let queue = PriorityQueue<Int, Int>(
      (0..<50).map({ ($0, $0) }).shuffled()
    )

    for (idx, val) in queue.ascending.enumerated() {
      XCTAssertEqual(idx, val)
    }

    for (idx, val) in queue.descending.enumerated() {
      XCTAssertEqual(50 - (idx + 1), val)
    }
  }
}
