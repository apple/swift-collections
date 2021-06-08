import XCTest
@testable import PriorityQueueModule

final class PriorityQueueTests: XCTestCase {
    func test_isEmpty() {
        var queue = PriorityQueue<Int>()
        XCTAssertTrue(queue.isEmpty)

        queue.insert(42)
        XCTAssertFalse(queue.isEmpty)

        let _ = queue.removeMin()
        XCTAssertTrue(queue.isEmpty)
    }

    func test_count() {
        var queue = PriorityQueue<Int>()
        XCTAssertEqual(queue.count, 0)

        queue.insert(20)
        XCTAssertEqual(queue.count, 1)

        queue.insert(40)
        XCTAssertEqual(queue.count, 2)

        _ = queue.removeMin()
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

    func test_removeMin() {
        var queue = PriorityQueue<Int>()
        XCTAssertNil(queue.removeMin())

        queue.insert(7)
        XCTAssertEqual(queue.removeMin(), 7)

        queue.insert(12)
        queue.insert(9)
        XCTAssertEqual(queue.removeMin(), 9)

        queue.insert(13)
        queue.insert(1)
        queue.insert(4)
        XCTAssertEqual(queue.removeMin(), 1)

        for i in (1...20).shuffled() {
            queue.insert(i)
        }

        XCTAssertEqual(queue.removeMin(), 1)
        XCTAssertEqual(queue.removeMin(), 2)
        XCTAssertEqual(queue.removeMin(), 3)
        XCTAssertEqual(queue.removeMin(), 4)
        XCTAssertEqual(queue.removeMin(), 4)  // One 4 was still in the queue from before
        XCTAssertEqual(queue.removeMin(), 5)
        XCTAssertEqual(queue.removeMin(), 6)
        XCTAssertEqual(queue.removeMin(), 7)
        XCTAssertEqual(queue.removeMin(), 8)
        XCTAssertEqual(queue.removeMin(), 9)
        XCTAssertEqual(queue.removeMin(), 10)
        XCTAssertEqual(queue.removeMin(), 11)
        XCTAssertEqual(queue.removeMin(), 12)
        XCTAssertEqual(queue.removeMin(), 12)  // One 12 was still in the queue from before
        XCTAssertEqual(queue.removeMin(), 13)
        XCTAssertEqual(queue.removeMin(), 13)  // One 13 was still in the queue from before
        XCTAssertEqual(queue.removeMin(), 14)
        XCTAssertEqual(queue.removeMin(), 15)
        XCTAssertEqual(queue.removeMin(), 16)
        XCTAssertEqual(queue.removeMin(), 17)
        XCTAssertEqual(queue.removeMin(), 18)
        XCTAssertEqual(queue.removeMin(), 19)
        XCTAssertEqual(queue.removeMin(), 20)
    }

    func test_removeMax() {
        var queue = PriorityQueue<Int>()
        XCTAssertNil(queue.removeMax())

        queue.insert(7)
        XCTAssertEqual(queue.removeMax(), 7)

        queue.insert(12)
        queue.insert(9)
        XCTAssertEqual(queue.removeMax(), 12)

        queue.insert(13)
        queue.insert(1)
        queue.insert(4)
        XCTAssertEqual(queue.removeMax(), 13)

        for i in (1...20).shuffled() {
            queue.insert(i)
        }

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
        XCTAssertEqual(queue.removeMax(), 9)  // One 9 was still in the queue from before
        XCTAssertEqual(queue.removeMax(), 8)
        XCTAssertEqual(queue.removeMax(), 7)
        XCTAssertEqual(queue.removeMax(), 6)
        XCTAssertEqual(queue.removeMax(), 5)
        XCTAssertEqual(queue.removeMax(), 4)
        XCTAssertEqual(queue.removeMax(), 4)  // One 4 was still in the queue from before
        XCTAssertEqual(queue.removeMax(), 3)
        XCTAssertEqual(queue.removeMax(), 2)
        XCTAssertEqual(queue.removeMax(), 1)
        XCTAssertEqual(queue.removeMax(), 1)  // One 1 was still in the queue from before
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

    func test_removeMin_struct() {
        var queue = PriorityQueue<Task>()
        XCTAssertNil(queue.removeMin())

        let lowPriorityTask = Task(name: "Do something when you have time", priority: 1)
        queue.insert(lowPriorityTask)

        let highPriorityTask = Task(name: "Get this done today", priority: 50)
        queue.insert(highPriorityTask)

        let urgentTask = Task(name: "Urgent", priority: 100)
        queue.insert(urgentTask)

        XCTAssertEqual(queue.removeMin(), lowPriorityTask)
        XCTAssertEqual(queue.removeMin(), highPriorityTask)
        XCTAssertEqual(queue.removeMin(), urgentTask)
        XCTAssertNil(queue.removeMin())
    }

    func test_removeMax_struct() {
        var queue = PriorityQueue<Task>()
        XCTAssertNil(queue.removeMax())

        let lowPriorityTask = Task(name: "Do something when you have time", priority: 1)
        queue.insert(lowPriorityTask)

        let highPriorityTask = Task(name: "Get this done today", priority: 50)
        queue.insert(highPriorityTask)

        let urgentTask = Task(name: "Urgent", priority: 100)
        queue.insert(urgentTask)

        XCTAssertEqual(queue.removeMax(), urgentTask)
        XCTAssertEqual(queue.removeMax(), highPriorityTask)
        XCTAssertEqual(queue.removeMax(), lowPriorityTask)
        XCTAssertNil(queue.removeMax())
    }

    // MARK: -

    func test_levelCalculation() {
        // Check alternating min and max levels in the queue
        var isMin = true
        for exp in 0...12 {
            // Check [2^exp, 2^(exp + 1))
            for i in Int(pow(2, Double(exp)))..<Int(pow(2, Double(exp + 1))) {
                if isMin {
                    XCTAssertTrue(_minMaxHeapIsMinLevel(i), "\(i) should be on a max level")
                } else {
                    XCTAssertFalse(_minMaxHeapIsMinLevel(i), "\(i) should be on a min level")
                }
            }

            isMin.toggle()
        }
    }

    func test_initializer_fromCollection() {
        var queue = PriorityQueue((1...20).shuffled())
        XCTAssertEqual(queue.max(), 20)

        XCTAssertEqual(queue.removeMin(), 1)
        XCTAssertEqual(queue.removeMax(), 20)
        XCTAssertEqual(queue.removeMin(), 2)
        XCTAssertEqual(queue.removeMax(), 19)
        XCTAssertEqual(queue.removeMin(), 3)
        XCTAssertEqual(queue.removeMax(), 18)
        XCTAssertEqual(queue.removeMin(), 4)
        XCTAssertEqual(queue.removeMax(), 17)
        XCTAssertEqual(queue.removeMin(), 5)
        XCTAssertEqual(queue.removeMax(), 16)
        XCTAssertEqual(queue.removeMin(), 6)
        XCTAssertEqual(queue.removeMax(), 15)
        XCTAssertEqual(queue.removeMin(), 7)
        XCTAssertEqual(queue.removeMax(), 14)
        XCTAssertEqual(queue.removeMin(), 8)
        XCTAssertEqual(queue.removeMax(), 13)
        XCTAssertEqual(queue.removeMin(), 9)
        XCTAssertEqual(queue.removeMax(), 12)
        XCTAssertEqual(queue.removeMin(), 10)
        XCTAssertEqual(queue.removeMax(), 11)
    }
}
