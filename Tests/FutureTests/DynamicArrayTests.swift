import XCTest
import _CollectionsTestSupport
import Future
import Synchronization

class DynamicArrayTests: CollectionTestCase {
  func test_validate_Container() {
    let c = 100

    withLifetimeTracking { tracker in
      let expected = (0 ..< c).map { tracker.instance(for: $0) }
      let items = DynamicArray(count: c, initializedBy: { expected[$0] })
      checkContainer(items, expectedContents: expected)
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

      array.append(tracker.structInstance(for: 42))
      expectFalse(array.isEmpty)
      expectEqual(array.count, 1)
      expectEqual(array[0].payload, 42)
      expectEqual(tracker.instances, 1)

      array.append(tracker.structInstance(for: 23))
      expectFalse(array.isEmpty)
      expectEqual(array.count, 2)
      expectEqual(array[0].payload, 42)
      expectEqual(array[1].payload, 23)
      expectEqual(tracker.instances, 2)

      let old = array.remove(at: 0)
      expectEqual(old.payload, 42)
      expectFalse(array.isEmpty)
      expectEqual(array.count, 1)
      expectEqual(array[0].payload, 23)
      expectEqual(tracker.instances, 2)
      _ = consume old
      expectEqual(tracker.instances, 1)

      let old2 = array.remove(at: 0)
      expectEqual(old2.payload, 23)
      expectEqual(array.count, 0)
      expectTrue(array.isEmpty)
      expectEqual(tracker.instances, 1)
      _ = consume old2
      expectEqual(tracker.instances, 0)
    }
  }

  func test_read_access() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      let c = 100
      let array = DynamicArray<Value>(count: c) { tracker.structInstance(for: $0) }

      for i in 0 ..< c {
        expectEqual(array.borrowElement(at: i)[].payload, i)
        expectEqual(array[i].payload, i)
      }
    }
  }

  func test_update_access() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      let c = 100
      var array = DynamicArray<Value>(count: c) { tracker.structInstance(for: $0) }

      for i in 0 ..< c {
        // FIXME: 'exclusive' or something instead of mutating subscript
        var me = array.mutateElement(at: i)
        me[].payload += 100
        array[i].payload += 100
      }

      for i in 0 ..< c {
        expectEqual(array[i].payload, 200 + i)
      }

      expectEqual(tracker.instances, c)
      _ = consume array
      expectEqual(tracker.instances, 0)
    }
  }

  func test_append() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      var array = DynamicArray<Value>()
      let c = 100
      for i in 0 ..< c {
        array.append(tracker.structInstance(for: 100 + i))
      }
      expectEqual(tracker.instances, c)
      expectEqual(array.count, c)

      for i in 0 ..< c {
        expectEqual(array.borrowElement(at: i)[].payload, 100 + i)
        expectEqual(array[i].payload, 100 + i)
      }

      _ = consume array
      expectEqual(tracker.instances, 0)
    }
  }

  func test_insert() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      var array = DynamicArray<Value>()
      let c = 100
      for i in 0 ..< c {
        array.insert(tracker.structInstance(for: 100 + i), at: 0)
      }
      expectEqual(tracker.instances, c)
      expectEqual(array.count, c)

      for i in 0 ..< c {
        expectEqual(array.borrowElement(at: i)[].payload, c + 99 - i)
        expectEqual(array[i].payload, c + 99 - i)
      }

      _ = consume array
      expectEqual(tracker.instances, 0)
    }
  }

  func test_remove() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      let c = 100
      var array = DynamicArray<Value>(count: c) { tracker.structInstance(for: 100 + $0) }
      expectEqual(tracker.instances, c)
      expectEqual(array.count, c)

      for i in 0 ..< c {
        array.remove(at: 0)
        expectEqual(array.count, c - 1 - i)
        expectEqual(tracker.instances, c - 1 - i)
      }

      expectTrue(array.isEmpty)
      expectEqual(tracker.instances, 0)
    }
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  func test_iterate_full() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      let c = 100
      let array = DynamicArray<Value>(count: c) { tracker.structInstance(for: 100 + $0) }

      var index = 0
      do {
        let span = array.nextSpan(after: &index)
        expectEqual(span.count, c)
        for i in 0 ..< span.count {
          expectEqual(span[i].payload, 100 + i)
        }
      }
      do {
        let span2 = array.nextSpan(after: &index)
        expectEqual(span2.count, 0)
      }
    }
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  func test_iterate_stepped() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      let c = 100
      let array = DynamicArray<Value>(count: c) { tracker.structInstance(for: $0) }

      withEvery("stride", in: 1 ... c) { stride in
        var index = 0
        var i = 0
        while true {
          expectEqual(index, i)
          let span = array.nextSpan(after: &index, maximumCount: stride)
          expectEqual(index, i + span.count)
          if span.isEmpty { break }
          expectEqual(span.count, i + stride <= c ? stride : c % stride)
          for j in 0 ..< span.count {
            expectEqual(span[j].payload, i)
            i += 1
          }
        }
        expectEqual(i, c)
        expectEqual(array.nextSpan(after: &index, maximumCount: Int.max).count, 0)
        expectEqual(index, i)
      }
    }
  }
}
