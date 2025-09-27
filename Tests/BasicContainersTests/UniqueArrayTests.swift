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
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import BasicContainers
#endif

#if compiler(>=6.2)

#if !COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
public func expectContainerContents<
  Element: Equatable,
  C2: Collection<Element>,
>(
  _ left: borrowing UniqueArray<Element>,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #file,
  line: UInt = #line
) {
  expectContainerContents(
    left.span,
    equalTo: right,
    message(), trapping: trapping, file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
public func expectContainerContents<
  E1: ~Copyable,
  C2: Collection,
>(
  _ left: borrowing UniqueArray<E1>,
  equivalentTo right: C2,
  by areEquivalent: (borrowing E1, C2.Element) -> Bool,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #file,
  line: UInt = #line
) {
  expectContainerContents(
    left.span,
    equivalentTo: right,
    by: areEquivalent,
    message(), trapping: trapping, file: file, line: line)
}
#endif


@available(SwiftStdlib 6.2, *)
class UniqueArrayTests: CollectionTestCase {
  func test_validate_Container() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let items = UniqueArray(consuming: tracker.rigidArray(layout: layout))
        let expected = (0 ..< layout.count).map { tracker.instance(for: $0) }
        expectEqual(tracker.instances, 2 * layout.count)
        expectContainerContents(items, equalTo: expected)
#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
        checkContainer(items, expectedContents: expected)
#endif
      }
    }
  }

  func test_basics() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      var array = UniqueArray<Value>()
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
      let a = UniqueArray<Int>(capacity: 0)
      expectEqual(a.capacity, 0)
      expectEqual(a.count, 0)
      expectEqual(a.freeCapacity, 0)
      expectTrue(a.isEmpty)
    }

    do {
      let a = UniqueArray<Int>(capacity: 10)
      expectEqual(a.capacity, 10)
      expectEqual(a.count, 0)
      expectEqual(a.freeCapacity, 10)
      expectTrue(a.isEmpty)
    }
  }

  func test_init_generator() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = tracker.uniqueArray(layout: layout)
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
        let a = UniqueArray(repeating: value, count: c)
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
        let a = UniqueArray(
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

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
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

          let array = UniqueArray(
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
#endif

  func test_span() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = tracker.uniqueArray(layout: layout)
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
        var a = tracker.uniqueArray(layout: layout)
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
    // UniqueArray is expected to have exactly one span.
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = tracker.uniqueArray(layout: layout)
        let whole = a.span
        var i = 0
        let first = a.span(after: &i)
        expectEqual(i, layout.count)
        expectTrue(first.isIdentical(to: whole))
        let second = a.span(after: &i)
        expectEqual(i, layout.count)
        expectTrue(second.isEmpty)
      }
    }
  }

  func test_previousSpan() {
    // RigidArray is expected to have exactly one span.
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = tracker.uniqueArray(layout: layout)
        let whole = a.span
        var i = layout.count
        let first = a.span(before: &i)
        expectEqual(i, 0)
        expectTrue(first.isIdentical(to: whole))
        let second = a.span(before: &i)
        expectEqual(i, 0)
        expectTrue(second.isEmpty)
      }
    }
  }

  func test_nextMutableSpan() {
    // RigidArray is expected to have exactly one span.
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.uniqueArray(layout: layout)
        var i = 0
        var span = a.mutableSpan(after: &i)
        expectEqual(i, layout.count)
        expectEqual(span.count, layout.count)
        span = a.mutableSpan(after: &i)
        expectEqual(i, layout.count)
        expectTrue(span.isEmpty)
      }
    }
  }

  func test_index_properties() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      let a = UniqueArray(layout: layout, using: { $0 })
      expectEqual(a.startIndex, 0)
      expectEqual(a.endIndex, layout.count)
      expectEqual(a.indices, 0 ..< layout.count)
    }
  }

  func test_swapAt() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.uniqueArray(layout: layout)
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

#if false // TODO
  func test_borrowElement() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        let a = tracker.uniqueArray(layout: layout)
        for i in 0 ..< layout.count {
          let item = a.borrowElement(at: i)
          expectEqual(item[].payload, i)
        }
      }
    }
  }
#endif

#if false // TODO
  func test_mutateElement() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.uniqueArray(layout: layout)
        for i in 0 ..< layout.count {
          var item = a.mutateElement(at: i)
          expectEqual(item[].payload, i)
          item[] = tracker.instance(for: -i)
          expectEqual(tracker.instances, layout.count)
        }
      }
    }
  }
#endif

  func test_edit() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var a = tracker.uniqueArray(layout: layout)
        a.edit { span in
          expectEqual(span.capacity, layout.capacity)
          expectEqual(span.count, layout.count)
          if layout.capacity > 0 {
            // FIXME: OutputSpan.removeAll crashes when empty in some 6.2 snapshots (rdar://158440246)
            span.removeAll()
          }
          expectEqual(tracker.instances, 0)
        }
        expectEqual(a.count, 0)

        a.edit { span in
          expectEqual(span.capacity, layout.capacity)
          expectEqual(span.count, 0)
          for i in 0 ..< span.capacity {
            span.append(tracker.instance(for: -i))
          }
          expectEqual(tracker.instances, layout.capacity)
        }
        expectEqual(a.count, layout.capacity)

        struct TestError: Error {}

        expectThrows {
          try a.edit { span in
            expectEqual(tracker.instances, layout.capacity)
            while !span.isEmpty {
              if span.count == layout.count { break }
              let old = span.removeLast()
              expectEqual(old.payload, -span.count)
            }
            throw TestError()
          }
        }
        errorHandler: { error in
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
          var a = tracker.uniqueArray(layout: layout)
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
          var a = tracker.uniqueArray(layout: layout)
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
        var a = tracker.uniqueArray(layout: layout)
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
        var a = tracker.uniqueArray(layout: layout)
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
        var a = tracker.uniqueArray(layout: layout)
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

          var a = tracker.uniqueArray(layout: layout)
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

          var a = tracker.uniqueArray(layout: layout)
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

          var a = tracker.uniqueArray(layout: layout)
          a.removeSubrange(range)
          expectContainerContents(a, equivalentTo: expected, by: { $0.payload == $1 })
        }
      }
    }
  }

#if false // TODO
  func test_removeAll_where() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var expected = Array(0 ..< layout.count)
        expected.removeAll(where: { $0.isMultiple(of: 2) })

        var a = tracker.uniqueArray(layout: layout)
        a.removeAll(where: { $0.payload.isMultiple(of: 2) })
        expectContainerContents(
          a, equivalentTo: expected, by: { $0.payload == $1 })
      }
    }
  }
#endif

  func test_popLast() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withLifetimeTracking { tracker in
        var expected = Array(0 ..< layout.count)
        let expectedItem = expected.popLast()

        var a = tracker.uniqueArray(layout: layout)
        let item = a.popLast()

        expectEquivalent(item, expectedItem, by: { $0?.payload == $1 })
        expectContainerContents(
          a, equivalentTo: expected, by: { $0.payload == $1 })
      }
    }
  }

  func test_append_geometric_growth() {
    // This test depends on the precise growth curve of UniqueArray,
    // which is not part of its stable API. The test may need to be updated
    // accordingly.
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTracked<Int>

      var array = UniqueArray<Value>()
      expectEqual(array.capacity, 0)

      array.append(tracker.instance(for: 0))
      expectEqual(array.capacity, 1)
      array.append(tracker.instance(for: 1))
      expectEqual(array.capacity, 2)
      array.append(tracker.instance(for: 2))
      expectEqual(array.capacity, 3)
      array.append(tracker.instance(for: 3))
      expectEqual(array.capacity, 5)
      array.append(tracker.instance(for: 4))
      expectEqual(array.capacity, 5)
      array.append(tracker.instance(for: 5))
      expectEqual(array.capacity, 8)
      array.append(tracker.instance(for: 6))
      expectEqual(array.capacity, 8)
      array.append(tracker.instance(for: 7))
      expectEqual(array.capacity, 8)
      array.append(tracker.instance(for: 8))
      expectEqual(array.capacity, 12)

      for i in 9 ..< 100 {
        array.append(tracker.instance(for: i))
      }
      expectEqual(tracker.instances, 100)
      expectEqual(array.count, 100)
      expectEqual(array.capacity, 140)

      do {
        let additions = RigidArray(capacity: 300) { span in
          for i in 0 ..< 300 {
            span.append(tracker.instance(for: 100 + i))
          }
        }
        array.append(copying: additions.span)
      }
      expectEqual(array.capacity, 400)

      expectEqual(tracker.instances, 400)
      for i in 0 ..< 400 {
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
        var a = tracker.uniqueArray(layout: layout)
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
          var a = tracker.uniqueArray(layout: layout)
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
          var a = tracker.uniqueArray(layout: layout)
          let b = RigidArray(capacity: additions) { span in
            for i in 0 ..< additions {
              span.append(tracker.instance(for: layout.count + i))
            }
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

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_append_copying_Container() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("additions", in: [0, 1, 10, 100]) { additions in
        withEvery("spanCount", in: 1 ... Swift.max(1, layout.capacity - layout.count)) { spanCount in
          withLifetimeTracking { tracker in
            var a = tracker.uniqueArray(layout: layout)

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
#endif

  func test_insert_at() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("i", in: 0 ... layout.count) { i in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< layout.count)
          expected.insert(-1, at: i)

          var a = tracker.uniqueArray(layout: layout)
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
            var a = tracker.uniqueArray(layout: layout)
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

            let rigidAddition = RigidArray(
              copying: (0 ..< addition.count).lazy.map { tracker.instance(for: addition[$0]) }
            )
            var a = tracker.uniqueArray(layout: layout)
            a.insert(copying: rigidAddition.span, at: i)

            expectContainerContents(
              a, equivalentTo: expected, by: { $0.payload == $1 })
            expectEqual(tracker.instances, layout.count + c)
          }
        }
      }
    }
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_insert_copying_Container() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 10, 100]) { layout in
      withEvery("i", in: 0 ... layout.count) { i in
        withEvery("c", in: [0, 1, 10, 100]) { c in
          withEvery("spanCount", in: 1 ... Swift.max(1, layout.capacity - layout.count)) { spanCount in
            withLifetimeTracking { tracker in

              var expected = Array(0 ..< layout.count)
              let addition = Array(layout.count ..< layout.count + c)
              expected.insert(contentsOf: addition, at: i)

              var a = tracker.uniqueArray(layout: layout)
              let rigidAddition = StaccatoContainer(
                contents: RigidArray(capacity: addition.count) {
                  for item in addition {
                    $0.append(tracker.instance(for: item))
                  }
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
#endif

  func test_replaceSubrange_copying_Collection() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 5, 10]) { layout in
      withEveryRange("range", in: 0 ..< layout.count) { range in
        withEvery("c", in: [0, 1, 10, 100]) { c in
          withLifetimeTracking { tracker in
            var expected = Array(0 ..< layout.count)
            let addition = (0 ..< c).map { -100 - $0 }
            expected.replaceSubrange(range, with: addition)

            var a = tracker.uniqueArray(layout: layout)
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

            var a = tracker.uniqueArray(layout: layout)
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

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_replaceSubrange_copying_Container() {
    withSomeArrayLayouts("layout", ofCapacities: [0, 5, 10]) { layout in
      withEveryRange("range", in: 0 ..< layout.count) { range in
        withEvery("c", in: [0, 1, 10, 100]) { c in
          withEvery("spanCount", in: 1 ... Swift.max(1, layout.capacity - layout.count)) { spanCount in
            withLifetimeTracking { tracker in
              var expected = Array(0 ..< layout.count)
              let addition = (0 ..< c).map { -100 - $0 }
              expected.replaceSubrange(range, with: addition)

              var a = tracker.uniqueArray(layout: layout)
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
#endif
}
#endif
