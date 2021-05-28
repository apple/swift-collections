import XCTest
import PriorityQueueModule

final class PriorityQueueTests: XCTestCase {
    func test_isEmpty() {
        var queue = PriorityQueue<Int>()
        XCTAssertTrue(queue.isEmpty)

        queue.insert(22)
        XCTAssertFalse(queue.isEmpty)

        let _ = queue.removeMin()
        XCTAssertTrue(queue.isEmpty)
    }

    func test_count() {
        var queue = PriorityQueue<Int>()
        XCTAssertEqual(queue.count, 0)

        for i in 1...10 {
            queue.insert(i)
        }

        XCTAssertEqual(queue.count, 10)
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

    func test_max() {
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

    func test_min() {
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

    func test_removeMax() {
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

    func test_removeMin() {
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
}
