import XCTest
@testable import PriorityQueueModule

final class PriorityQueueTests: XCTestCase {
  func test_isEmpty() {
    var queue = PriorityQueue<Int>()
    XCTAssertTrue(queue.isEmpty)

    queue.insert(42)
    XCTAssertFalse(queue.isEmpty)

    let _ = queue.popMin()
    XCTAssertTrue(queue.isEmpty)
  }

  func test_count() {
    var queue = PriorityQueue<Int>()
    XCTAssertEqual(queue.count, 0)

    queue.insert(20)
    XCTAssertEqual(queue.count, 1)

    queue.insert(40)
    XCTAssertEqual(queue.count, 2)

    _ = queue.popMin()
    XCTAssertEqual(queue.count, 1)
  }

  func test_unordered() {
    let queue = PriorityQueue<Int>((1...10))
    XCTAssertEqual(Set(queue.unordered), Set(1...10))
  }

  struct Task: Comparable {
    let name: String
    let priority: Int

    static func < (lhs: Task, rhs: Task) -> Bool {
      lhs.priority < rhs.priority
    }
  }

  func test_insert() {
    var queue = PriorityQueue<Task>()

    XCTAssertEqual(queue.count, 0)
    queue.insert(Task(name: "Hello, world", priority: 50))
    XCTAssertEqual(queue.count, 1)
  }

  func test_min() {
    var queue = PriorityQueue<Int>()
    XCTAssertNil(queue.min())

    queue.insert(5)
    XCTAssertEqual(5, queue.min())

    queue.insert(12)
    XCTAssertEqual(5, queue.min())

    queue.insert(2)
    XCTAssertEqual(2, queue.min())

    queue.insert(1)
    XCTAssertEqual(1, queue.min())
  }

  func test_max() {
    var queue = PriorityQueue<Int>()
    XCTAssertNil(queue.max())

    queue.insert(42)
    XCTAssertEqual(42, queue.max())

    queue.insert(20)
    XCTAssertEqual(42, queue.max())

    queue.insert(63)
    XCTAssertEqual(63, queue.max())

    queue.insert(90)
    XCTAssertEqual(90, queue.max())
  }

  func test_popMin() {
    var queue = PriorityQueue<Int>()
    XCTAssertNil(queue.popMin())

    queue.insert(7)
    XCTAssertEqual(queue.popMin(), 7)

    queue.insert(12)
    queue.insert(9)
    XCTAssertEqual(queue.popMin(), 9)

    queue.insert(13)
    queue.insert(1)
    queue.insert(4)
    XCTAssertEqual(queue.popMin(), 1)

    for i in (1...20).shuffled() {
      queue.insert(i)
    }

    XCTAssertEqual(queue.popMin(), 1)
    XCTAssertEqual(queue.popMin(), 2)
    XCTAssertEqual(queue.popMin(), 3)
    XCTAssertEqual(queue.popMin(), 4)
    XCTAssertEqual(queue.popMin(), 4)  // One 4 was still in the queue from before
    XCTAssertEqual(queue.popMin(), 5)
    XCTAssertEqual(queue.popMin(), 6)
    XCTAssertEqual(queue.popMin(), 7)
    XCTAssertEqual(queue.popMin(), 8)
    XCTAssertEqual(queue.popMin(), 9)
    XCTAssertEqual(queue.popMin(), 10)
    XCTAssertEqual(queue.popMin(), 11)
    XCTAssertEqual(queue.popMin(), 12)
    XCTAssertEqual(queue.popMin(), 12)  // One 12 was still in the queue from before
    XCTAssertEqual(queue.popMin(), 13)
    XCTAssertEqual(queue.popMin(), 13)  // One 13 was still in the queue from before
    XCTAssertEqual(queue.popMin(), 14)
    XCTAssertEqual(queue.popMin(), 15)
    XCTAssertEqual(queue.popMin(), 16)
    XCTAssertEqual(queue.popMin(), 17)
    XCTAssertEqual(queue.popMin(), 18)
    XCTAssertEqual(queue.popMin(), 19)
    XCTAssertEqual(queue.popMin(), 20)

    XCTAssertNil(queue.popMin())
  }

  func test_popMax() {
    var queue = PriorityQueue<Int>()
    XCTAssertNil(queue.popMax())

    queue.insert(7)
    XCTAssertEqual(queue.popMax(), 7)

    queue.insert(12)
    queue.insert(9)
    XCTAssertEqual(queue.popMax(), 12)

    queue.insert(13)
    queue.insert(1)
    queue.insert(4)
    XCTAssertEqual(queue.popMax(), 13)

    for i in (1...20).shuffled() {
      queue.insert(i)
    }

    XCTAssertEqual(queue.popMax(), 20)
    XCTAssertEqual(queue.popMax(), 19)
    XCTAssertEqual(queue.popMax(), 18)
    XCTAssertEqual(queue.popMax(), 17)
    XCTAssertEqual(queue.popMax(), 16)
    XCTAssertEqual(queue.popMax(), 15)
    XCTAssertEqual(queue.popMax(), 14)
    XCTAssertEqual(queue.popMax(), 13)
    XCTAssertEqual(queue.popMax(), 12)
    XCTAssertEqual(queue.popMax(), 11)
    XCTAssertEqual(queue.popMax(), 10)
    XCTAssertEqual(queue.popMax(), 9)
    XCTAssertEqual(queue.popMax(), 9)  // One 9 was still in the queue from before
    XCTAssertEqual(queue.popMax(), 8)
    XCTAssertEqual(queue.popMax(), 7)
    XCTAssertEqual(queue.popMax(), 6)
    XCTAssertEqual(queue.popMax(), 5)
    XCTAssertEqual(queue.popMax(), 4)
    XCTAssertEqual(queue.popMax(), 4)  // One 4 was still in the queue from before
    XCTAssertEqual(queue.popMax(), 3)
    XCTAssertEqual(queue.popMax(), 2)
    XCTAssertEqual(queue.popMax(), 1)
    XCTAssertEqual(queue.popMax(), 1)  // One 1 was still in the queue from before

    XCTAssertNil(queue.popMax())
  }

  func test_removeMin() {
    var queue = PriorityQueue<Int>((1...20).shuffled())

    XCTAssertEqual(queue.removeMin(), 1)
    XCTAssertEqual(queue.removeMin(), 2)
    XCTAssertEqual(queue.removeMin(), 3)
    XCTAssertEqual(queue.removeMin(), 4)
    XCTAssertEqual(queue.removeMin(), 5)
    XCTAssertEqual(queue.removeMin(), 6)
    XCTAssertEqual(queue.removeMin(), 7)
    XCTAssertEqual(queue.removeMin(), 8)
    XCTAssertEqual(queue.removeMin(), 9)
    XCTAssertEqual(queue.removeMin(), 10)
    XCTAssertEqual(queue.removeMin(), 11)
    XCTAssertEqual(queue.removeMin(), 12)
    XCTAssertEqual(queue.removeMin(), 13)
    XCTAssertEqual(queue.removeMin(), 14)
    XCTAssertEqual(queue.removeMin(), 15)
    XCTAssertEqual(queue.removeMin(), 16)
    XCTAssertEqual(queue.removeMin(), 17)
    XCTAssertEqual(queue.removeMin(), 18)
    XCTAssertEqual(queue.removeMin(), 19)
    XCTAssertEqual(queue.removeMin(), 20)
  }

  func test_removeMax() {
    var queue = PriorityQueue<Int>((1...20).shuffled())

    XCTAssertEqual(queue.removeMax(), 20)
    XCTAssertEqual(queue.removeMax(), 19)
    XCTAssertEqual(queue.removeMax(), 18)
    XCTAssertEqual(queue.removeMax(), 17)
    XCTAssertEqual(queue.removeMax(), 16)
    XCTAssertEqual(queue.removeMax(), 15)
    XCTAssertEqual(queue.removeMax(), 14)
    XCTAssertEqual(queue.removeMax(), 13)
    XCTAssertEqual(queue.removeMax(), 12)
    XCTAssertEqual(queue.removeMax(), 11)
    XCTAssertEqual(queue.removeMax(), 10)
    XCTAssertEqual(queue.removeMax(), 9)
    XCTAssertEqual(queue.removeMax(), 8)
    XCTAssertEqual(queue.removeMax(), 7)
    XCTAssertEqual(queue.removeMax(), 6)
    XCTAssertEqual(queue.removeMax(), 5)
    XCTAssertEqual(queue.removeMax(), 4)
    XCTAssertEqual(queue.removeMax(), 3)
    XCTAssertEqual(queue.removeMax(), 2)
    XCTAssertEqual(queue.removeMax(), 1)
  }

  // MARK: -

  func test_min_struct() {
    var queue = PriorityQueue<Task>()
    XCTAssertNil(queue.min())

    let firstTask = Task(name: "Do something", priority: 10)
    queue.insert(firstTask)
    XCTAssertEqual(queue.min(), firstTask)

    let higherPriorityTask = Task(name: "Urgent", priority: 100)
    queue.insert(higherPriorityTask)
    XCTAssertEqual(queue.min(), firstTask)

    let lowerPriorityTask = Task(name: "Get this done today", priority: 1)
    queue.insert(lowerPriorityTask)
    XCTAssertEqual(queue.min(), lowerPriorityTask)
  }

  func test_max_struct() {
    var queue = PriorityQueue<Task>()
    XCTAssertNil(queue.max())

    let firstTask = Task(name: "Do something", priority: 10)
    queue.insert(firstTask)
    XCTAssertEqual(queue.max(), firstTask)

    let lowerPriorityTask = Task(name: "Get this done today", priority: 1)
    queue.insert(lowerPriorityTask)
    XCTAssertEqual(queue.max(), firstTask)

    let higherPriorityTask = Task(name: "Urgent", priority: 100)
    queue.insert(higherPriorityTask)
    XCTAssertEqual(queue.max(), higherPriorityTask)
  }

  func test_popMin_struct() {
    var queue = PriorityQueue<Task>()
    XCTAssertNil(queue.popMin())

    let lowPriorityTask = Task(name: "Do something when you have time", priority: 1)
    queue.insert(lowPriorityTask)

    let highPriorityTask = Task(name: "Get this done today", priority: 50)
    queue.insert(highPriorityTask)

    let urgentTask = Task(name: "Urgent", priority: 100)
    queue.insert(urgentTask)

    XCTAssertEqual(queue.popMin(), lowPriorityTask)
    XCTAssertEqual(queue.popMin(), highPriorityTask)
    XCTAssertEqual(queue.popMin(), urgentTask)
    XCTAssertNil(queue.popMin())
  }

  func test_popMax_struct() {
    var queue = PriorityQueue<Task>()
    XCTAssertNil(queue.popMax())

    let lowPriorityTask = Task(name: "Do something when you have time", priority: 1)
    queue.insert(lowPriorityTask)

    let highPriorityTask = Task(name: "Get this done today", priority: 50)
    queue.insert(highPriorityTask)

    let urgentTask = Task(name: "Urgent", priority: 100)
    queue.insert(urgentTask)

    XCTAssertEqual(queue.popMax(), urgentTask)
    XCTAssertEqual(queue.popMax(), highPriorityTask)
    XCTAssertEqual(queue.popMax(), lowPriorityTask)
    XCTAssertNil(queue.popMax())
  }

  // MARK: -

  func test_levelCalculation() {
    // Check alternating min and max levels in the queue
    let q = PriorityQueue<Int>()
    var isMin = true
    for exp in 0...12 {
      // Check [2^exp, 2^(exp + 1))
      for i in Int(pow(2, Double(exp)))..<Int(pow(2, Double(exp + 1))) {
        if isMin {
          XCTAssertTrue(q._minMaxHeapIsMinLevel(i), "\(i) should be on a max level")
        } else {
          XCTAssertFalse(q._minMaxHeapIsMinLevel(i), "\(i) should be on a min level")
        }
      }

      isMin.toggle()
    }
  }

  func test_initializer_fromCollection() {
    var queue = PriorityQueue((1...20).shuffled())
    XCTAssertEqual(queue.max(), 20)

    XCTAssertEqual(queue.popMin(), 1)
    XCTAssertEqual(queue.popMax(), 20)
    XCTAssertEqual(queue.popMin(), 2)
    XCTAssertEqual(queue.popMax(), 19)
    XCTAssertEqual(queue.popMin(), 3)
    XCTAssertEqual(queue.popMax(), 18)
    XCTAssertEqual(queue.popMin(), 4)
    XCTAssertEqual(queue.popMax(), 17)
    XCTAssertEqual(queue.popMin(), 5)
    XCTAssertEqual(queue.popMax(), 16)
    XCTAssertEqual(queue.popMin(), 6)
    XCTAssertEqual(queue.popMax(), 15)
    XCTAssertEqual(queue.popMin(), 7)
    XCTAssertEqual(queue.popMax(), 14)
    XCTAssertEqual(queue.popMin(), 8)
    XCTAssertEqual(queue.popMax(), 13)
    XCTAssertEqual(queue.popMin(), 9)
    XCTAssertEqual(queue.popMax(), 12)
    XCTAssertEqual(queue.popMin(), 10)
    XCTAssertEqual(queue.popMax(), 11)
  }

  func test_initializer_fromSequence() {
    let queue = PriorityQueue((1...).prefix(20))
    XCTAssertEqual(queue.count, 20)
  }

  func test_initializer_fromArrayLiteral() {
    var queue: PriorityQueue = [1, 3, 5, 7, 9]
    XCTAssertEqual(queue.count, 5)

    XCTAssertEqual(queue.popMax(), 9)
    XCTAssertEqual(queue.popMax(), 7)
    XCTAssertEqual(queue.popMax(), 5)
    XCTAssertEqual(queue.popMax(), 3)
    XCTAssertEqual(queue.popMax(), 1)
  }

  func test_sequenceConformance() {
    let queue = PriorityQueue<Int>((0...50).shuffled())

    var increment = 0
    for val in queue.ascending {
      XCTAssertEqual(increment, val)
      increment += 1
    }

    increment = 50
    for val in queue.descending {
      XCTAssertEqual(increment, val)
      increment -= 1
    }
  }
}
