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
import PriorityQueueModule

final class HeapTests: XCTestCase {
  func test_isEmpty() {
    var heap = Heap<Int>()
    XCTAssertTrue(heap.isEmpty)

    heap.insert(42)
    XCTAssertFalse(heap.isEmpty)

    let _ = heap.popMin()
    XCTAssertTrue(heap.isEmpty)
  }

  func test_count() {
    var heap = Heap<Int>()
    XCTAssertEqual(heap.count, 0)

    heap.insert(20)
    XCTAssertEqual(heap.count, 1)

    heap.insert(40)
    XCTAssertEqual(heap.count, 2)

    _ = heap.popMin()
    XCTAssertEqual(heap.count, 1)
  }

  func test_unordered() {
    let heap = Heap<Int>((1...10))
    XCTAssertEqual(Set(heap.unordered), Set(1...10))
  }

  struct Task: Comparable {
    let name: String
    let priority: Int

    static func < (lhs: Task, rhs: Task) -> Bool {
      lhs.priority < rhs.priority
    }
  }

  func test_insert() {
    var heap = Heap<Task>()

    XCTAssertEqual(heap.count, 0)
    heap.insert(Task(name: "Hello, world", priority: 50))
    XCTAssertEqual(heap.count, 1)
  }

  func test_insert_contentsOf() {
    var heap = Heap<Int>()
    heap.insert(contentsOf: (1...10).shuffled())
    XCTAssertEqual(heap.count, 10)
    XCTAssertEqual(heap.popMax(), 10)
    XCTAssertEqual(heap.popMin(), 1)

    heap.insert(contentsOf: (21...50).shuffled())
    XCTAssertEqual(heap.count, 38)
    XCTAssertEqual(heap.max(), 50)
    XCTAssertEqual(heap.min(), 2)

    heap.insert(contentsOf: [-10, -9, -8, -7, -6, -5].shuffled())
    XCTAssertEqual(heap.count, 44)
    XCTAssertEqual(heap.min(), -10)
  }

  func test_insert_contentsOf_withSequenceFunction() {
    func addTwo(_ i: Int) -> Int {
      i + 2
    }

    let evens = sequence(first: 0, next: addTwo(_:)).prefix(20)
    var heap = Heap(evens)
    XCTAssertEqual(heap.count, 20)

    heap.insert(contentsOf: sequence(first: 1, next: addTwo(_:)).prefix(20))
    XCTAssertEqual(heap.count, 40)

    var i = 0
    while let min = heap.popMin() {
      XCTAssertEqual(min, i)
      i += 1
    }
    XCTAssertEqual(i, 40)
  }

  func test_min() {
    var heap = Heap<Int>()
    XCTAssertNil(heap.min())

    heap.insert(5)
    XCTAssertEqual(5, heap.min())

    heap.insert(12)
    XCTAssertEqual(5, heap.min())

    heap.insert(2)
    XCTAssertEqual(2, heap.min())

    heap.insert(1)
    XCTAssertEqual(1, heap.min())
  }

  func test_max() {
    var heap = Heap<Int>()
    XCTAssertNil(heap.max())

    heap.insert(42)
    XCTAssertEqual(42, heap.max())

    heap.insert(20)
    XCTAssertEqual(42, heap.max())

    heap.insert(63)
    XCTAssertEqual(63, heap.max())

    heap.insert(90)
    XCTAssertEqual(90, heap.max())
  }

  func test_popMin() {
    var heap = Heap<Int>()
    XCTAssertNil(heap.popMin())

    heap.insert(7)
    XCTAssertEqual(heap.popMin(), 7)

    heap.insert(12)
    heap.insert(9)
    XCTAssertEqual(heap.popMin(), 9)

    heap.insert(13)
    heap.insert(1)
    heap.insert(4)
    XCTAssertEqual(heap.popMin(), 1)

    for i in (1...20).shuffled() {
      heap.insert(i)
    }

    XCTAssertEqual(heap.popMin(), 1)
    XCTAssertEqual(heap.popMin(), 2)
    XCTAssertEqual(heap.popMin(), 3)
    XCTAssertEqual(heap.popMin(), 4)
    XCTAssertEqual(heap.popMin(), 4)  // One 4 was still in the heap from before
    XCTAssertEqual(heap.popMin(), 5)
    XCTAssertEqual(heap.popMin(), 6)
    XCTAssertEqual(heap.popMin(), 7)
    XCTAssertEqual(heap.popMin(), 8)
    XCTAssertEqual(heap.popMin(), 9)
    XCTAssertEqual(heap.popMin(), 10)
    XCTAssertEqual(heap.popMin(), 11)
    XCTAssertEqual(heap.popMin(), 12)
    XCTAssertEqual(heap.popMin(), 12)  // One 12 was still in the heap from before
    XCTAssertEqual(heap.popMin(), 13)
    XCTAssertEqual(heap.popMin(), 13)  // One 13 was still in the heap from before
    XCTAssertEqual(heap.popMin(), 14)
    XCTAssertEqual(heap.popMin(), 15)
    XCTAssertEqual(heap.popMin(), 16)
    XCTAssertEqual(heap.popMin(), 17)
    XCTAssertEqual(heap.popMin(), 18)
    XCTAssertEqual(heap.popMin(), 19)
    XCTAssertEqual(heap.popMin(), 20)

    XCTAssertNil(heap.popMin())
  }

  func test_popMax() {
    var heap = Heap<Int>()
    XCTAssertNil(heap.popMax())

    heap.insert(7)
    XCTAssertEqual(heap.popMax(), 7)

    heap.insert(12)
    heap.insert(9)
    XCTAssertEqual(heap.popMax(), 12)

    heap.insert(13)
    heap.insert(1)
    heap.insert(4)
    XCTAssertEqual(heap.popMax(), 13)

    for i in (1...20).shuffled() {
      heap.insert(i)
    }

    XCTAssertEqual(heap.popMax(), 20)
    XCTAssertEqual(heap.popMax(), 19)
    XCTAssertEqual(heap.popMax(), 18)
    XCTAssertEqual(heap.popMax(), 17)
    XCTAssertEqual(heap.popMax(), 16)
    XCTAssertEqual(heap.popMax(), 15)
    XCTAssertEqual(heap.popMax(), 14)
    XCTAssertEqual(heap.popMax(), 13)
    XCTAssertEqual(heap.popMax(), 12)
    XCTAssertEqual(heap.popMax(), 11)
    XCTAssertEqual(heap.popMax(), 10)
    XCTAssertEqual(heap.popMax(), 9)
    XCTAssertEqual(heap.popMax(), 9)  // One 9 was still in the heap from before
    XCTAssertEqual(heap.popMax(), 8)
    XCTAssertEqual(heap.popMax(), 7)
    XCTAssertEqual(heap.popMax(), 6)
    XCTAssertEqual(heap.popMax(), 5)
    XCTAssertEqual(heap.popMax(), 4)
    XCTAssertEqual(heap.popMax(), 4)  // One 4 was still in the heap from before
    XCTAssertEqual(heap.popMax(), 3)
    XCTAssertEqual(heap.popMax(), 2)
    XCTAssertEqual(heap.popMax(), 1)
    XCTAssertEqual(heap.popMax(), 1)  // One 1 was still in the heap from before

    XCTAssertNil(heap.popMax())
  }

  func test_removeMin() {
    var heap = Heap<Int>((1...20).shuffled())

    XCTAssertEqual(heap.removeMin(), 1)
    XCTAssertEqual(heap.removeMin(), 2)
    XCTAssertEqual(heap.removeMin(), 3)
    XCTAssertEqual(heap.removeMin(), 4)
    XCTAssertEqual(heap.removeMin(), 5)
    XCTAssertEqual(heap.removeMin(), 6)
    XCTAssertEqual(heap.removeMin(), 7)
    XCTAssertEqual(heap.removeMin(), 8)
    XCTAssertEqual(heap.removeMin(), 9)
    XCTAssertEqual(heap.removeMin(), 10)
    XCTAssertEqual(heap.removeMin(), 11)
    XCTAssertEqual(heap.removeMin(), 12)
    XCTAssertEqual(heap.removeMin(), 13)
    XCTAssertEqual(heap.removeMin(), 14)
    XCTAssertEqual(heap.removeMin(), 15)
    XCTAssertEqual(heap.removeMin(), 16)
    XCTAssertEqual(heap.removeMin(), 17)
    XCTAssertEqual(heap.removeMin(), 18)
    XCTAssertEqual(heap.removeMin(), 19)
    XCTAssertEqual(heap.removeMin(), 20)
  }

  func test_removeMax() {
    var heap = Heap<Int>((1...20).shuffled())

    XCTAssertEqual(heap.removeMax(), 20)
    XCTAssertEqual(heap.removeMax(), 19)
    XCTAssertEqual(heap.removeMax(), 18)
    XCTAssertEqual(heap.removeMax(), 17)
    XCTAssertEqual(heap.removeMax(), 16)
    XCTAssertEqual(heap.removeMax(), 15)
    XCTAssertEqual(heap.removeMax(), 14)
    XCTAssertEqual(heap.removeMax(), 13)
    XCTAssertEqual(heap.removeMax(), 12)
    XCTAssertEqual(heap.removeMax(), 11)
    XCTAssertEqual(heap.removeMax(), 10)
    XCTAssertEqual(heap.removeMax(), 9)
    XCTAssertEqual(heap.removeMax(), 8)
    XCTAssertEqual(heap.removeMax(), 7)
    XCTAssertEqual(heap.removeMax(), 6)
    XCTAssertEqual(heap.removeMax(), 5)
    XCTAssertEqual(heap.removeMax(), 4)
    XCTAssertEqual(heap.removeMax(), 3)
    XCTAssertEqual(heap.removeMax(), 2)
    XCTAssertEqual(heap.removeMax(), 1)
  }

  // MARK: -

  func test_min_struct() {
    var heap = Heap<Task>()
    XCTAssertNil(heap.min())

    let firstTask = Task(name: "Do something", priority: 10)
    heap.insert(firstTask)
    XCTAssertEqual(heap.min(), firstTask)

    let higherPriorityTask = Task(name: "Urgent", priority: 100)
    heap.insert(higherPriorityTask)
    XCTAssertEqual(heap.min(), firstTask)

    let lowerPriorityTask = Task(name: "Get this done today", priority: 1)
    heap.insert(lowerPriorityTask)
    XCTAssertEqual(heap.min(), lowerPriorityTask)
  }

  func test_max_struct() {
    var heap = Heap<Task>()
    XCTAssertNil(heap.max())

    let firstTask = Task(name: "Do something", priority: 10)
    heap.insert(firstTask)
    XCTAssertEqual(heap.max(), firstTask)

    let lowerPriorityTask = Task(name: "Get this done today", priority: 1)
    heap.insert(lowerPriorityTask)
    XCTAssertEqual(heap.max(), firstTask)

    let higherPriorityTask = Task(name: "Urgent", priority: 100)
    heap.insert(higherPriorityTask)
    XCTAssertEqual(heap.max(), higherPriorityTask)
  }

  func test_popMin_struct() {
    var heap = Heap<Task>()
    XCTAssertNil(heap.popMin())

    let lowPriorityTask = Task(name: "Do something when you have time", priority: 1)
    heap.insert(lowPriorityTask)

    let highPriorityTask = Task(name: "Get this done today", priority: 50)
    heap.insert(highPriorityTask)

    let urgentTask = Task(name: "Urgent", priority: 100)
    heap.insert(urgentTask)

    XCTAssertEqual(heap.popMin(), lowPriorityTask)
    XCTAssertEqual(heap.popMin(), highPriorityTask)
    XCTAssertEqual(heap.popMin(), urgentTask)
    XCTAssertNil(heap.popMin())
  }

  func test_popMax_struct() {
    var heap = Heap<Task>()
    XCTAssertNil(heap.popMax())

    let lowPriorityTask = Task(name: "Do something when you have time", priority: 1)
    heap.insert(lowPriorityTask)

    let highPriorityTask = Task(name: "Get this done today", priority: 50)
    heap.insert(highPriorityTask)

    let urgentTask = Task(name: "Urgent", priority: 100)
    heap.insert(urgentTask)

    XCTAssertEqual(heap.popMax(), urgentTask)
    XCTAssertEqual(heap.popMax(), highPriorityTask)
    XCTAssertEqual(heap.popMax(), lowPriorityTask)
    XCTAssertNil(heap.popMax())
  }

  // MARK: -

  func test_initializer_fromCollection() {
    var heap = Heap((1...20).shuffled())
    XCTAssertEqual(heap.max(), 20)

    XCTAssertEqual(heap.popMin(), 1)
    XCTAssertEqual(heap.popMax(), 20)
    XCTAssertEqual(heap.popMin(), 2)
    XCTAssertEqual(heap.popMax(), 19)
    XCTAssertEqual(heap.popMin(), 3)
    XCTAssertEqual(heap.popMax(), 18)
    XCTAssertEqual(heap.popMin(), 4)
    XCTAssertEqual(heap.popMax(), 17)
    XCTAssertEqual(heap.popMin(), 5)
    XCTAssertEqual(heap.popMax(), 16)
    XCTAssertEqual(heap.popMin(), 6)
    XCTAssertEqual(heap.popMax(), 15)
    XCTAssertEqual(heap.popMin(), 7)
    XCTAssertEqual(heap.popMax(), 14)
    XCTAssertEqual(heap.popMin(), 8)
    XCTAssertEqual(heap.popMax(), 13)
    XCTAssertEqual(heap.popMin(), 9)
    XCTAssertEqual(heap.popMax(), 12)
    XCTAssertEqual(heap.popMin(), 10)
    XCTAssertEqual(heap.popMax(), 11)
  }

  func test_initializer_fromSequence() {
    let heap = Heap((1...).prefix(20))
    XCTAssertEqual(heap.count, 20)
  }

  func test_initializer_fromArrayLiteral() {
    var heap: Heap = [1, 3, 5, 7, 9]
    XCTAssertEqual(heap.count, 5)

    XCTAssertEqual(heap.popMax(), 9)
    XCTAssertEqual(heap.popMax(), 7)
    XCTAssertEqual(heap.popMax(), 5)
    XCTAssertEqual(heap.popMax(), 3)
    XCTAssertEqual(heap.popMax(), 1)
  }
}
