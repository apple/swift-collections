import XCTest
@testable import PriorityQueueModule

final class MinMaxHeapTests: XCTestCase {
    func test_isEmpty() {
        var heap = MinMaxHeap<Int>()
        XCTAssertTrue(heap.isEmpty)

        heap.insert(42)
        XCTAssertFalse(heap.isEmpty)
    }

    func test_count() {
        var heap = MinMaxHeap<Int>()
        XCTAssertEqual(heap.count, 0)

        heap.insert(20)
        XCTAssertEqual(heap.count, 1)

        heap.insert(40)
        XCTAssertEqual(heap.count, 2)

        _ = heap.removeMin()
        XCTAssertEqual(heap.count, 1)
    }

    func test_min() {
        var heap = MinMaxHeap<Int>()
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
        var heap = MinMaxHeap<Int>()
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

    func test_removeMin() {
        var heap = MinMaxHeap<Int>()
        XCTAssertNil(heap.removeMin())

        heap.insert(7)
        XCTAssertEqual(heap.removeMin(), 7)

        heap.insert(12)
        heap.insert(9)
        XCTAssertEqual(heap.removeMin(), 9)

        heap.insert(13)
        heap.insert(1)
        heap.insert(4)
        XCTAssertEqual(heap.removeMin(), 1)

        for i in (1...20).shuffled() {
            heap.insert(i)
        }

        XCTAssertEqual(heap.removeMin(), 1)
        XCTAssertEqual(heap.removeMin(), 2)
        XCTAssertEqual(heap.removeMin(), 3)
        XCTAssertEqual(heap.removeMin(), 4)
        XCTAssertEqual(heap.removeMin(), 4)  // One 4 was still in the heap from before
        XCTAssertEqual(heap.removeMin(), 5)
        XCTAssertEqual(heap.removeMin(), 6)
        XCTAssertEqual(heap.removeMin(), 7)
        XCTAssertEqual(heap.removeMin(), 8)
        XCTAssertEqual(heap.removeMin(), 9)
        XCTAssertEqual(heap.removeMin(), 10)
        XCTAssertEqual(heap.removeMin(), 11)
        XCTAssertEqual(heap.removeMin(), 12)
        XCTAssertEqual(heap.removeMin(), 12)  // One 12 was still in the heap from before
        XCTAssertEqual(heap.removeMin(), 13)
        XCTAssertEqual(heap.removeMin(), 13)  // One 13 was still in the heap from before
        XCTAssertEqual(heap.removeMin(), 14)
        XCTAssertEqual(heap.removeMin(), 15)
        XCTAssertEqual(heap.removeMin(), 16)
        XCTAssertEqual(heap.removeMin(), 17)
        XCTAssertEqual(heap.removeMin(), 18)
        XCTAssertEqual(heap.removeMin(), 19)
        XCTAssertEqual(heap.removeMin(), 20)
    }

    func test_removeMax() {
        var heap = MinMaxHeap<Int>()
        XCTAssertNil(heap.removeMax())

        heap.insert(7)
        XCTAssertEqual(heap.removeMax(), 7)

        heap.insert(12)
        heap.insert(9)
        XCTAssertEqual(heap.removeMax(), 12)

        heap.insert(13)
        heap.insert(1)
        heap.insert(4)
        XCTAssertEqual(heap.removeMax(), 13)

        for i in (1...20).shuffled() {
            heap.insert(i)
        }

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
        XCTAssertEqual(heap.removeMax(), 9)  // One 9 was still in the heap from before
        XCTAssertEqual(heap.removeMax(), 8)
        XCTAssertEqual(heap.removeMax(), 7)
        XCTAssertEqual(heap.removeMax(), 6)
        XCTAssertEqual(heap.removeMax(), 5)
        XCTAssertEqual(heap.removeMax(), 4)
        XCTAssertEqual(heap.removeMax(), 4)  // One 4 was still in the heap from before
        XCTAssertEqual(heap.removeMax(), 3)
        XCTAssertEqual(heap.removeMax(), 2)
        XCTAssertEqual(heap.removeMax(), 1)
        XCTAssertEqual(heap.removeMax(), 1)  // One 1 was still in the heap from before
    }

    func test_levelCalculation() {
        // Check alternating min and max levels in the heap
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
        var heap = MinMaxHeap((1...20).shuffled())
        XCTAssertEqual(heap.max(), 20)

        XCTAssertEqual(heap.removeMin(), 1)
        XCTAssertEqual(heap.removeMax(), 20)
        XCTAssertEqual(heap.removeMin(), 2)
        XCTAssertEqual(heap.removeMax(), 19)
        XCTAssertEqual(heap.removeMin(), 3)
        XCTAssertEqual(heap.removeMax(), 18)
        XCTAssertEqual(heap.removeMin(), 4)
        XCTAssertEqual(heap.removeMax(), 17)
        XCTAssertEqual(heap.removeMin(), 5)
        XCTAssertEqual(heap.removeMax(), 16)
        XCTAssertEqual(heap.removeMin(), 6)
        XCTAssertEqual(heap.removeMax(), 15)
        XCTAssertEqual(heap.removeMin(), 7)
        XCTAssertEqual(heap.removeMax(), 14)
        XCTAssertEqual(heap.removeMin(), 8)
        XCTAssertEqual(heap.removeMax(), 13)
        XCTAssertEqual(heap.removeMin(), 9)
        XCTAssertEqual(heap.removeMax(), 12)
        XCTAssertEqual(heap.removeMin(), 10)
        XCTAssertEqual(heap.removeMax(), 11)
    }
}
