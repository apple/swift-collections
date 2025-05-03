//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import _CollectionsTestSupport
import Future
import Synchronization

@available(SwiftStdlib 6.2, *)
class DynamicArrayTests: CollectionTestCase {
  func test_validate_Container() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let items = DynamicArray(consuming: tracker.rigidArray(layout: layout))
        let expected = (0 ..< layout.count).map { tracker.instance(for: $0) }
        expectEqual(tracker.instances, 2 * layout.count)
        checkContainer(items, expectedContents: expected)
      }
    }
  }

  func test_basics() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      var array = DynamicArray<Value>()
      expectTrue(array.isEmpty)
      expectEqual(array.count, 0)
      expectEqual(array.capacity, 0)
      expectEqual(tracker.instances, 0)

      array.append(tracker.structInstance(for: 10))
      expectFalse(array.isEmpty)
      expectEqual(array.count, 1)
      expectEqual(array.capacity, 1) // This assumes a specific growth behavior
      expectEqual(array[0].payload, 10)
      expectEqual(tracker.instances, 1)

      array.append(tracker.structInstance(for: 20))
      expectFalse(array.isEmpty)
      expectEqual(array.count, 2)
      expectEqual(array.capacity, 2) // This assumes a specific growth behavior
      expectEqual(array[0].payload, 10)
      expectEqual(array[1].payload, 20)
      expectEqual(tracker.instances, 2)

      let old = array.remove(at: 0)
      expectEqual(old.payload, 10)
      expectFalse(array.isEmpty)
      expectEqual(array.count, 1)
      expectEqual(array.capacity, 2) // This assumes a specific growth behavior
      expectEqual(array[0].payload, 20)
      expectEqual(tracker.instances, 2)
      _ = consume old
      expectEqual(tracker.instances, 1)

      let old2 = array.remove(at: 0)
      expectEqual(old2.payload, 20)
      expectEqual(array.count, 0)
      expectEqual(array.capacity, 2) // This assumes a specific growth behavior
      expectTrue(array.isEmpty)
      expectEqual(tracker.instances, 1)
      _ = consume old2
      expectEqual(tracker.instances, 0)
    }
  }

  func test_init_capacity() {
    do {
      let a = DynamicArray<Int>(capacity: 0)
      expectEqual(a.capacity, 0)
      expectEqual(a.count, 0)
      expectEqual(a.freeCapacity, 0)
      expectTrue(a.isEmpty)
    }

    do {
      let a = DynamicArray<Int>(capacity: 10)
      expectEqual(a.capacity, 10)
      expectEqual(a.count, 0)
      expectEqual(a.freeCapacity, 10)
      expectTrue(a.isEmpty)
    }
  }

  func test_init_generator() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = tracker.dynamicArray(layout: layout)
        expectEqual(a.capacity, layout.capacity)
        expectEqual(a.count, layout.count)
        expectEqual(a.freeCapacity, layout.capacity - layout.count)
        expectEqual(a.isEmpty, layout.count == 0)
        expectContainerContents(a, equivalentTo: 0 ..< layout.count, by: { $0.payload == $1 })
      }
    }
  }

  func test_init_repeating() {
    withEvery("c", in: [0, 10, 100]) { c in
      withLifetimeTracking { tracker in
        let value = tracker.instance(for: 0)
        let a = DynamicArray(repeating: value, count: c)
        expectEqual(a.capacity, c)
        expectEqual(a.count, c)
        expectEqual(a.freeCapacity, 0)
        expectEqual(a.isEmpty, c == 0)
        for i in 0 ..< c {
          expectIdentical(a[i], value)
        }
      }
    }
  }

  func test_init_copying_Sequence() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = DynamicArray(
          capacity: layout.capacity,
          copying: (0 ..< layout.count).map { tracker.instance(for: $0) })
        expectEqual(tracker.instances, layout.count)
        expectEqual(a.capacity, layout.capacity)
        expectEqual(a.count, layout.count)
        expectEqual(a.isEmpty, layout.count == 0)
        for i in 0 ..< layout.count {
          expectEqual(a[i].payload, i)
        }
      }
    }
  }

  func test_init_copying_Container() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("spanCounts", in: [
        [1],
        [3, 5, 7],
        [10, 3],
      ] as [[Int]]) { spanCounts in
        withLifetimeTracking { tracker in
          let additions = StaccatoContainer(
            contents: RigidArray(
              copying: (0 ..< layout.count).map { tracker.instance(for: $0) }),
            spanCounts: spanCounts)

          let array = DynamicArray(
            capacity: layout.capacity, copying: additions)
          expectEqual(tracker.instances, layout.count)
          expectEqual(array.capacity, layout.capacity)
          expectEqual(array.count, layout.count)
          for i in 0 ..< layout.count {
            expectEqual(array[i].payload, i)
          }
        }
      }
    }
  }

  func test_span() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = tracker.dynamicArray(layout: layout)
        let span = a.span
        expectEqual(span.count, layout.count)
        for i in 0 ..< span.count {
          expectEqual(span[i].payload, i)
        }
      }
    }
  }

  func test_mutableSpan() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.dynamicArray(layout: layout)
        var span = a.mutableSpan
        expectEqual(span.count, layout.count)
        for i in 0 ..< layout.count {
          expectEqual(span[i].payload, i)
          span[i] = tracker.instance(for: -i)
        }
        for i in 0 ..< layout.count {
          expectEqual(span[i].payload, -i)
        }
        for i in 0 ..< layout.count {
          expectEqual(a[i].payload, -i)
        }
      }
    }
  }

  func test_nextSpan() {
    // DynamicArray is expected to have exactly one span.
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = tracker.dynamicArray(layout: layout)
        let whole = a.span
        var i = 0
        let first = a.nextSpan(after: &i)
        expectEqual(i, layout.count)
        expectTrue(first.isIdentical(to: whole))
        let second = a.nextSpan(after: &i)
        expectEqual(i, layout.count)
        expectTrue(second.isEmpty)
      }
    }
  }

  func test_previousSpan() {
    // RigidArray is expected to have exactly one span.
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = tracker.dynamicArray(layout: layout)
        let whole = a.span
        var i = layout.count
        let first = a.previousSpan(before: &i)
        expectEqual(i, 0)
        expectTrue(first.isIdentical(to: whole))
        let second = a.previousSpan(before: &i)
        expectEqual(i, 0)
        expectTrue(second.isEmpty)
      }
    }
  }

  func test_nextMutableSpan() {
    // RigidArray is expected to have exactly one span.
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.dynamicArray(layout: layout)
        var i = 0
        var span = a.nextMutableSpan(after: &i)
        expectEqual(i, layout.count)
        expectEqual(span.count, layout.count)
        span = a.nextMutableSpan(after: &i)
        expectEqual(i, layout.count)
        expectTrue(span.isEmpty)
      }
    }
  }

  func test_index_properties() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      let a = DynamicArray(layout: layout, using: { $0 })
      expectEqual(a.startIndex, 0)
      expectEqual(a.endIndex, layout.count)
      expectEqual(a.indices, 0 ..< layout.count)
    }
  }

  func test_swapAt() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.dynamicArray(layout: layout)
        withEvery("i", in: 0 ..< layout.count / 2) { i in
          a.swapAt(i, layout.count - 1 - i)
        }
        let expected = (0 ..< layout.count).reversed()
        expectContainerContents(
          a, equivalentTo: expected, by: { $0.payload == $1 })
        expectEqual(tracker.instances, layout.count)
      }
    }
  }

  func test_borrowElement() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = tracker.dynamicArray(layout: layout)
        for i in 0 ..< layout.count {
          let item = a.borrowElement(at: i)
          expectEqual(item[].payload, i)
        }
      }
    }
  }

  func test_mutateElement() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.dynamicArray(layout: layout)
        for i in 0 ..< layout.count {
          var item = a.mutateElement(at: i)
          expectEqual(item[].payload, i)
          item[] = tracker.instance(for: -i)
          expectEqual(tracker.instances, layout.count)
        }
      }
    }
  }

  func test_withUnsafeMutableBufferPointer() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.dynamicArray(layout: layout)
        unsafe a.withUnsafeMutableBufferPointer { buffer, count in
          expectEqual(buffer.count, layout.capacity)
          expectEqual(count, layout.count)
          unsafe buffer.extracting(0 ..< count).deinitialize()
          expectEqual(tracker.instances, 0)
          count = 0
        }
        expectEqual(a.count, 0)

        unsafe a.withUnsafeMutableBufferPointer { buffer, count in
          expectEqual(buffer.count, layout.capacity)
          expectEqual(count, 0)
          for i in 0 ..< buffer.count {
            unsafe buffer.initializeElement(at: i, to: tracker.instance(for: -i))
            count += 1
          }
          expectEqual(tracker.instances, layout.capacity)
        }
        expectEqual(a.count, layout.capacity)

        struct TestError: Error {}

        expectThrows({
          unsafe try a.withUnsafeMutableBufferPointer { buffer, count in
            expectEqual(tracker.instances, layout.capacity)
            while count > 0 {
              if count == layout.count { break }
              unsafe buffer.deinitializeElement(at: count - 1)
              count -= 1
            }
            throw TestError()
          }
        }) { error in
          expectTrue(error is TestError)
        }
        expectContainerContents(
          a,
          equivalentTo: (0 ..< layout.count).map { -$0 },
          by: { $0.payload == $1 })
        expectEqual(tracker.instances, layout.count)
      }
    }
  }

  func test_reallocate() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery(
        "newCapacity",
        in: [
          layout.capacity, layout.count, layout.count + 1, layout.capacity + 1
        ] as Set
      ) { newCapacity in
        withLifetimeTracking { tracker in
          var a = tracker.dynamicArray(layout: layout)
          expectEqual(a.count, layout.count)
          expectEqual(a.capacity, layout.capacity)
          a.reallocate(capacity: newCapacity)
          expectEqual(a.count, layout.count)
          expectEqual(a.capacity, newCapacity)
          expectEqual(tracker.instances, layout.count)
          expectContainerContents(
            a, equivalentTo: 0 ..< layout.count, by: { $0.payload == $1 })
        }
      }
    }
  }

  func test_reserveCapacity() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery(
        "newCapacity",
        in: [
          0, layout.count - 1, layout.count, layout.count + 1,
          layout.capacity, layout.capacity + 1
        ] as Set
      ) { newCapacity in
        withLifetimeTracking { tracker in
          var a = tracker.dynamicArray(layout: layout)
          expectEqual(a.count, layout.count)
          expectEqual(a.capacity, layout.capacity)
          a.reserveCapacity(newCapacity)
          expectEqual(a.count, layout.count)
          expectEqual(a.capacity, Swift.max(layout.capacity, newCapacity))
          expectEqual(tracker.instances, layout.count)
          expectContainerContents(
            a, equivalentTo: 0 ..< layout.count, by: { $0.payload == $1 })
        }
      }
    }
  }

  func test_removeAll() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.dynamicArray(layout: layout)
        a.removeAll()
        expectTrue(a.isEmpty)
        expectEqual(a.capacity, 0)
        expectEqual(tracker.instances, 0)
      }
    }
  }

  func test_removeAll_keepingCapacity() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.dynamicArray(layout: layout)
        a.removeAll(keepingCapacity: true)
        expectTrue(a.isEmpty)
        expectEqual(a.capacity, layout.capacity)
        expectEqual(tracker.instances, 0)
      }
    }
  }

  func test_removeLast() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.dynamicArray(layout: layout)
        withEvery("i", in: 0 ..< layout.count) { i in
          let old = a.removeLast()
          expectEqual(old.payload, layout.count - 1 - i)
          expectEqual(a.count, layout.count - 1 - i)
          expectEqual(a.capacity, layout.capacity)
        }
        expectEqual(tracker.instances, 0)
      }
    }
  }

  func test_removeLast_k() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("k", in: 0 ..< layout.count) { k in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< layout.count)
          expected.removeLast(k)

          var a = tracker.dynamicArray(layout: layout)
          expectEqual(tracker.instances, layout.count)
          a.removeLast(k)
          expectEqual(tracker.instances, layout.count - k)
          expectContainerContents(
            a, equivalentTo: expected, by: { $0.payload == $1 })
        }
      }
    }
  }

  func test_remove_at() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("i", in: 0 ..< layout.count) { i in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< layout.count)
          expected.remove(at: i)

          var a = tracker.dynamicArray(layout: layout)
          let old = a.remove(at: i)
          expectEqual(old.payload, i)
          expectContainerContents(a, equivalentTo: expected, by: { $0.payload == $1 })
        }
      }
    }
  }

  func test_removeSubrange() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEveryRange("range", in: 0 ..< layout.count) { range in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< layout.count)
          expected.removeSubrange(range)

          var a = tracker.dynamicArray(layout: layout)
          a.removeSubrange(range)
          expectContainerContents(a, equivalentTo: expected, by: { $0.payload == $1 })
        }
      }
    }
  }

  func test_removeAll_where() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var expected = Array(0 ..< layout.count)
        expected.removeAll(where: { $0.isMultiple(of: 2) })

        var a = tracker.dynamicArray(layout: layout)
        a.removeAll(where: { $0.payload.isMultiple(of: 2) })
        expectContainerContents(
          a, equivalentTo: expected, by: { $0.payload == $1 })
      }
    }
  }

  func test_popLast() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var expected = Array(0 ..< layout.count)
        let expectedItem = expected.popLast()

        var a = tracker.dynamicArray(layout: layout)
        let item = a.popLast()

        expectEquivalent(item, expectedItem, by: { $0?.payload == $1 })
        expectContainerContents(
          a, equivalentTo: expected, by: { $0.payload == $1 })
      }
    }
  }

  func test_append_geometric_growth() {
    // This test depends on the precise growth curve of DynamicArray,
    // which is not part of its stable API. The test may need to be updated
    // accordingly.
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTracked<Int>

      var array = DynamicArray<Value>()
      expectEqual(array.capacity, 0)

      array.append(tracker.instance(for: 0))
      expectEqual(array.capacity, 1)
      array.append(tracker.instance(for: 1))
      expectEqual(array.capacity, 2)
      array.append(tracker.instance(for: 2))
      expectEqual(array.capacity, 4)
      array.append(tracker.instance(for: 3))
      expectEqual(array.capacity, 4)
      array.append(tracker.instance(for: 4))
      expectEqual(array.capacity, 8)
      array.append(tracker.instance(for: 5))
      expectEqual(array.capacity, 8)
      array.append(tracker.instance(for: 6))
      expectEqual(array.capacity, 8)
      array.append(tracker.instance(for: 7))
      expectEqual(array.capacity, 8)
      array.append(tracker.instance(for: 8))
      expectEqual(array.capacity, 16)

      for i in 9 ..< 100 {
        array.append(tracker.instance(for: i))
      }
      expectEqual(tracker.instances, 100)
      expectEqual(array.count, 100)
      expectEqual(array.capacity, 128)


      array.append(
        copying: RigidArray(count: 300) { tracker.instance(for: 100 + $0) })
      expectEqual(array.capacity, 400)

      expectEqual(tracker.instances, 400)
      for i in 0 ..< 400 {
        expectEqual(array.borrowElement(at: i)[].payload, i)
        expectEqual(array[i].payload, i)
      }

      _ = consume array
      expectEqual(tracker.instances, 0)
    }
  }

  func test_append() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let c = 2 * layout.capacity + 10
        var a = tracker.dynamicArray(layout: layout)
        for i in layout.count ..< c {
          a.append(tracker.instance(for: i))
          expectEqual(a.count, i + 1)
          expectContainerContents(a, equivalentTo: 0 ..< i + 1, by: { $0.payload == $1 })
        }
        expectEqual(tracker.instances, c)
      }
    }
  }

  func test_append_copying_MinimalSequence() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("isContiguous", in: [false, true]) { isContiguous in
        withLifetimeTracking { tracker in
          let c = 2 * layout.capacity + 10
          var a = tracker.dynamicArray(layout: layout)
          a.append(copying: MinimalSequence(
            elements: (layout.count ..< c).map { tracker.instance(for: $0) },
            underestimatedCount: .half,
            isContiguous: isContiguous))
          expectContainerContents(
            a, equivalentTo: 0 ..< c, by: { $0.payload == $1})
          expectEqual(tracker.instances, c)
        }
      }
    }
  }

  func test_append_copying_Span() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("additions", in: [0, 1, 10, 100]) { additions in
        withLifetimeTracking { tracker in
          var a = tracker.dynamicArray(layout: layout)
          let b = RigidArray(count: additions) {
            tracker.instance(for: layout.count + $0)
          }
          a.append(copying: b.span)
          let c = layout.count + additions
          expectContainerContents(
            a, equivalentTo: 0 ..< c, by: { $0.payload == $1 })
          expectEqual(tracker.instances, c)
        }
      }
    }
  }

  func test_append_copying_Container() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("additions", in: [0, 1, 10, 100]) { additions in
        withEvery("spanCount", in: 1 ... Swift.max(1, layout.capacity - layout.count)) { spanCount in
          withLifetimeTracking { tracker in
            var a = tracker.dynamicArray(layout: layout)

            let c = layout.count + additions
            let addition = (layout.count ..< c).map {
              tracker.instance(for: $0)
            }
            let b = StaccatoContainer(
              contents: RigidArray(copying: addition),
              spanCounts: [spanCount])
            a.append(copying: b)
            expectContainerContents(
              a, equivalentTo: 0 ..< c, by: { $0.payload == $1 })
            expectEqual(tracker.instances, c)
          }
        }
      }
    }
  }

  func test_insert_at() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("i", in: 0 ... layout.count) { i in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< layout.count)
          expected.insert(-1, at: i)

          var a = tracker.dynamicArray(layout: layout)
          a.insert(tracker.instance(for: -1), at: i)

          expectContainerContents(
            a, equivalentTo: expected, by: { $0.payload == $1 })
          expectEqual(tracker.instances, layout.count + 1)
        }
      }
    }
  }

  func test_insert_copying_Collection() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("c", in: [0, 1, 10, 100]) { c in
        withEvery("i", in: 0 ... layout.count) { i in
          withLifetimeTracking { tracker in
            let addition = (layout.count ..< layout.count + c)

            var expected = Array(0 ..< layout.count)
            expected.insert(contentsOf: addition, at: i)

            let trackedAddition = addition.map { tracker.instance(for: $0) }
            var a = tracker.dynamicArray(layout: layout)
            a.insert(copying: trackedAddition, at: i)

            expectContainerContents(
              a, equivalentTo: expected, by: { $0.payload == $1 })
            expectEqual(tracker.instances, layout.count + c)
          }
        }
      }
    }
  }

  func test_insert_copying_Span() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("i", in: 0 ... layout.count) { i in
        withEvery("c", in: [0, 1, 10, 100]) { c in
          withLifetimeTracking { tracker in
            let addition = Array(layout.count ..< layout.count + c)

            var expected = Array(0 ..< layout.count)
            expected.insert(contentsOf: addition, at: i)

            let rigidAddition = RigidArray(count: addition.count) {
              tracker.instance(for: addition[$0])
            }
            var a = tracker.dynamicArray(layout: layout)
            a.insert(copying: rigidAddition.span, at: i)

            expectContainerContents(
              a, equivalentTo: expected, by: { $0.payload == $1 })
            expectEqual(tracker.instances, layout.count + c)
          }
        }
      }
    }
  }

  func test_insert_copying_Container() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("i", in: 0 ... layout.count) { i in
        withEvery("c", in: [0, 1, 10, 100]) { c in
          withEvery("spanCount", in: 1 ... Swift.max(1, layout.capacity - layout.count)) { spanCount in
            withLifetimeTracking { tracker in

              var expected = Array(0 ..< layout.count)
              let addition = Array(layout.count ..< layout.count + c)
              expected.insert(contentsOf: addition, at: i)

              var a = tracker.dynamicArray(layout: layout)
              let rigidAddition = StaccatoContainer(
                contents: RigidArray(count: addition.count) {
                  tracker.instance(for: addition[$0])
                },
                spanCounts: [spanCount])
              a.insert(copying: rigidAddition, at: i)

              expectContainerContents(
                a, equivalentTo: expected, by: { $0.payload == $1 })
              expectEqual(tracker.instances, layout.count + c)
            }
          }
        }
      }
    }
  }

  func test_replaceSubrange_copying_Collection() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 5, 10]) { layout in
      withEveryRange("range", in: 0 ..< layout.count) { range in
        withEvery("c", in: [0, 1, 10, 100]) { c in
          withLifetimeTracking { tracker in
            var expected = Array(0 ..< layout.count)
            let addition = (0 ..< c).map { -100 - $0 }
            expected.replaceSubrange(range, with: addition)

            var a = tracker.dynamicArray(layout: layout)
            let trackedAddition = addition.map { tracker.instance(for: $0) }
            a.replaceSubrange(range, copying: trackedAddition)

            expectContainerContents(
              a, equivalentTo: expected, by: { $0.payload == $1 })
            expectEqual(tracker.instances, layout.count - range.count + c)
          }
        }
      }
    }
  }

  func test_replaceSubrange_copying_Span() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 5, 10]) { layout in
      withEveryRange("range", in: 0 ..< layout.count) { range in
        withEvery("c", in: [0, 1, 10, 100]) { c in
          withLifetimeTracking { tracker in
            var expected = Array(0 ..< layout.count)
            let addition = (0 ..< c).map { -100 - $0 }
            expected.replaceSubrange(range, with: addition)

            var a = tracker.dynamicArray(layout: layout)
            let trackedAddition = RigidArray(
              copying: addition.map { tracker.instance(for: $0) })
            a.replaceSubrange(range, copying: trackedAddition.span)

            expectContainerContents(
              a, equivalentTo: expected, by: { $0.payload == $1 })
            expectEqual(tracker.instances, layout.count - range.count + c)
          }
        }
      }
    }
  }

  func test_replaceSubrange_copying_Container() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 5, 10]) { layout in
      withEveryRange("range", in: 0 ..< layout.count) { range in
        withEvery("c", in: [0, 1, 10, 100]) { c in
          withEvery("spanCount", in: 1 ... Swift.max(1, layout.capacity - layout.count)) { spanCount in
            withLifetimeTracking { tracker in
              var expected = Array(0 ..< layout.count)
              let addition = (0 ..< c).map { -100 - $0 }
              expected.replaceSubrange(range, with: addition)

              var a = tracker.dynamicArray(layout: layout)
              let trackedAddition = StaccatoContainer(
                contents: RigidArray(
                  copying: addition.map { tracker.instance(for: $0) }),
                spanCounts: [spanCount])
              a.replaceSubrange(range, copying: trackedAddition)

              expectContainerContents(
                a, equivalentTo: expected, by: { $0.payload == $1 })
              expectEqual(tracker.instances, layout.count - range.count + c)
            }
          }
        }
      }
    }
  }
}
