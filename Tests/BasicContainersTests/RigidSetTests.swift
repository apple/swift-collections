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
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import BasicContainers
#endif

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_HASHED_CONTAINERS

fileprivate struct Pair: Hashable {
  var first: Int
  var second: Int

  init(_ first: Int, _ second: Int) {
    self.first = first
    self.second = second
  }

  static func ==(left: Self, right: Self) -> Bool {
    left.first == right.first && left.second == right.second
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(first)
    hasher.combine(second)
  }
}


func expectConsistentSet<Element: ~Copyable>(
  _ set: borrowing RigidSet<Element>,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  var failed = false
  set._checkInvariants { message in
    if !failed {
      set._dump(bitmap: true, buckets: true)
      failed = true
    }
    expectFailure(message, file: file, line: line)
  }
}

class RigidSetTests: CollectionTestCase {
  func test_empty() {
    let s = RigidSet<Int>()
    expectEqual(s.count, 0)
    expectTrue(s.isEmpty)
    expectTrue(s.isFull)
    expectEqual(s.capacity, 0)
    expectEqual(s.freeCapacity, 0)
    expectConsistentSet(s)
  }

  func test_init_capacity() {
    withSome("capacity", in: 0 ..< 1000) { capacity in
      let s = RigidSet<Int>(capacity: capacity)
      expectEqual(s.count, 0)
      expectTrue(s.isEmpty)
      expectEqual(s.isFull, capacity == 0)
      expectEqual(s.capacity, capacity)
      expectEqual(s.freeCapacity, capacity)
      expectConsistentSet(s)
    }
  }

  func test_insert_one_small() {
    withLifetimeTracking { tracker in
      var s = RigidSet<LifetimeTracked<Int>>(capacity: 5)
      let first = tracker.instance(for: 42)
      expectNil(s.insert(first))
      let second = tracker.instance(for: 42)
      expectIdentical(s.insert(second), second)

      expectTrue(s.contains(first))
      expectTrue(s.contains(second))
      _ = consume first
      expectTrue(s.contains(second))

      expectEqual(s.count, 1)
      expectFalse(s.isEmpty)
      expectFalse(s.isFull)
      expectEqual(s.capacity, 5)
      expectEqual(s.freeCapacity, 4)

      expectConsistentSet(s)
    }
  }

  func test_insert_one_large() {
    withLifetimeTracking { tracker in
      var s = RigidSet<LifetimeTracked<Int>>(capacity: 20)
      let first = tracker.instance(for: 42)
      expectNil(s.insert(first))
      let second = tracker.instance(for: 42)
      expectIdentical(s.insert(second), second)

      expectTrue(s.contains(first))
      expectTrue(s.contains(second))
      _ = consume first
      expectTrue(s.contains(second))

      expectEqual(s.count, 1)
      expectFalse(s.isEmpty)
      expectFalse(s.isFull)
      expectEqual(s.capacity, 20)
      expectEqual(s.freeCapacity, 19)

      expectConsistentSet(s)
    }
  }

  func test_update_one_small() {
    withLifetimeTracking { tracker in
      var s = RigidSet<LifetimeTracked<Int>>(capacity: 5)
      let first = tracker.instance(for: 42)
      expectNil(s.update(with: first))
      let second = tracker.instance(for: 42)
      expectIdentical(s.update(with: second), first)

      expectTrue(s.contains(first))
      expectTrue(s.contains(second))
      _ = consume second
      expectTrue(s.contains(first))

      expectEqual(s.count, 1)
      expectFalse(s.isEmpty)
      expectFalse(s.isFull)
      expectEqual(s.capacity, 5)
      expectEqual(s.freeCapacity, 4)

      expectConsistentSet(s)
    }
  }

  func test_update_one_large() {
    withLifetimeTracking { tracker in
      var s = RigidSet<LifetimeTracked<Int>>(capacity: 20)
      let first = tracker.instance(for: 42)
      expectNil(s.update(with: first))
      let second = tracker.instance(for: 42)
      expectIdentical(s.update(with: second), first)

      expectTrue(s.contains(first))
      expectTrue(s.contains(second))
      _ = consume second
      expectTrue(s.contains(first))

      expectEqual(s.count, 1)
      expectFalse(s.isEmpty)
      expectFalse(s.isFull)
      expectEqual(s.capacity, 20)
      expectEqual(s.freeCapacity, 19)

      expectConsistentSet(s)
    }
  }

  func test_insert_full() {
    withEvery("capacity", in: [0, 1, 2, 10, 100, 1000]) { capacity in
      withLifetimeTracking { tracker in
        var s = RigidSet<LifetimeTracked<Int>>(capacity: capacity)
        for i in 0 ..< capacity {
          let new = tracker.instance(for: i)
          let remnant = s.insert(new)
          expectNil(remnant)
          expectConsistentSet(s)
        }
        expectEqual(s.count, capacity)
        expectEqual(s.isEmpty, capacity == 0)
        expectTrue(s.isFull)
        expectEqual(s.capacity, capacity)
        expectEqual(s.freeCapacity, 0)

        for i in 0 ..< capacity {
          let dupe = tracker.instance(for: i)
          if s.contains(dupe) {
            expectIdentical(s.insert(dupe), dupe)
          } else {
            expectFailure("\(dupe.payload) not found")
          }
        }

        expectConsistentSet(s)
      }
    }
  }

  func test_update_full() {
    withEvery("capacity", in: [0, 1, 2, 10, 100, 200, 1000]) { capacity in
      withLifetimeTracking { tracker in
        var s = RigidSet<LifetimeTracked<Int>>(capacity: capacity)
        for i in 0 ..< capacity {
          let new = tracker.instance(for: i)
          let old = s.update(with: new)
          expectNil(old)
          expectConsistentSet(s)
        }
        expectEqual(s.count, capacity)
        expectEqual(s.isEmpty, capacity == 0)
        expectTrue(s.isFull)
        expectEqual(s.capacity, capacity)
        expectEqual(s.freeCapacity, 0)

        for i in 0 ..< capacity {
          let new = tracker.instance(for: i)
          let old = s.update(with: new)
          expectNotNil(old) { old in
            expectNotIdentical(old, new)
          }
        }
        expectEqual(s.count, capacity)
        expectEqual(s.isEmpty, capacity == 0)
        expectTrue(s.isFull)
        expectEqual(s.capacity, capacity)
        expectEqual(s.freeCapacity, 0)

        for i in 0 ..< capacity {
          let dupe = tracker.instance(for: i)
          expectTrue(s.contains(dupe), "\(dupe) not found")
        }

        expectConsistentSet(s)
      }
    }
  }

  func test_bucketIterator_consistency() {
    withEvery("capacity", in: [0, 1, 2, 3, 4, 10, 100, 200]) { capacity in
      withEvery("maximumCount", in: [1, 2, 3, Int.max]) { maximumCount in
        withLifetimeTracking { tracker in
          var s = RigidSet<LifetimeTracked<Int>>(capacity: capacity)
          withEvery("i", in: 0 ..< capacity) { i in
            s.insert(tracker.instance(for: i))

            var it = s._table.makeBucketIterator()
            var j = s._table.startBucket
            while let next = it.nextOccupiedRegion(maximumCount: maximumCount) {
              expectFalse(next.isEmpty, "Empty chunk; j: \(j), next: \(next)")
              expectLessThanOrEqual(
                next.upperBound.offset - next.lowerBound.offset,
                maximumCount,
                "Overlong chunk")
              if maximumCount == Int.max, j > s._table.startBucket {
                expectGreaterThan(
                  next.lowerBound, j,
                  "Unnecessarily split run of occupied buckets")
              }
              while j < next.lowerBound {
                context.withTrace("j: \(j)") {
                  expectFalse(s._table.bitmap.isOccupied(j))
                }
                s._table.formBucket(after: &j)
              }
              while j < next.upperBound {
                context.withTrace("j: \(j)") {
                  expectTrue(s._table.isOccupied(j))
                }
                s._table.formBucket(after: &j)
              }
            }
          }
        }
      }
    }
  }

  func test_probeLengths() {
    let c1 = 500
    let scale = _HTable.minimumScale(forCapacity: c1)
    let c2 = _HTable.maximumCapacity(forScale: scale)
    var set = RigidSet<Int>(capacity: c2)
    for i in 0 ..< c2 {
      set.insert(i)
    }
    expectConsistentSet(set)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_borrowing_iterator() {
    withEvery("capacity", in: [0, 1, 2, 3, 4, 10, 100, 1000]) { capacity in
      withEvery("maximumCount", in: [1, 2, 3, Int.max]) { maximumCount in
        withLifetimeTracking { tracker in
          var s = RigidSet<LifetimeTracked<Int>>(capacity: capacity)
          withEvery("i", in: 0 ..< capacity) { i in
            s.insert(tracker.instance(for: i))

            var expected = Set(0 ... i)
            var it = s.makeBorrowingIterator_()
            while true {
              let next = it.nextSpan_(maximumCount: maximumCount)
              guard !next.isEmpty else { break }
              expectLessThanOrEqual(next.count, maximumCount)
              for j in next.indices {
                let v = next[j].payload
                expectEqual(expected.remove(v), v, "Unexpected item \(v)")
              }
            }
            expectEqual(expected.count, 0, "Iterator skipped items \(expected)")
          }
        }
      }
    }
  }
#endif

  func test_iteration_order_for_small_sets() {
    let c = _HTable.maximumUnhashedCount
    var set = RigidSet<Int>(capacity: c)
    for i in 0 ..< c {
      set.insert(i)
    }
    var items: [Int] = []
    var i = set.startIndex
    while i != set.endIndex {
      items.append(set[i])
      i = set.index(after: i)
    }
    // The order of items is deterministic, but it should appear somewhat random
    expectEqualElements(items, [1, 3, 5, 6, 0, 4, 2])
  }

  func test_iteration_indexAfter() {
    withEvery("capacity", in: [0, 1, 2, 10, 100, 200]) { capacity in
      withLifetimeTracking { tracker in
        var s = RigidSet<LifetimeTracked<Int>>(capacity: capacity)
        withEvery("payload", in: 0 ..< capacity) { payload in
          let item = tracker.instance(for: payload)
          s.insert(item)

          var seen: Set<Int> = []
          var i = s.startIndex
          while i != s.endIndex {
            let payload = s[i].payload
            expectTrue(seen.insert(payload).inserted, "Duplicate item \(payload)")
            i = s.index(after: i)
          }
          expectEqual(seen.count, payload + 1)
        }
      }
    }
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_insert_producer() {
    withEvery("capacity", in: [0, 1, 2, 4, 10, 100, 200]) { capacity in
      withEvery("count", in: 0 ..< capacity) { count in
        withEvery("chunkSize", in: [1, 2, 10, 100, Int.max]) { chunkSize in
          withLifetimeTracking { tracker in
            var s = RigidSet<LifetimeTracked<Int>>(capacity: capacity)

            var i = 0
            var p = CustomProducer<LifetimeTracked<Int>, Never>(
              underestimatedCount: 0,
              chunkSize: chunkSize
            ) {
              guard i < count else { return nil }
              defer { i += 1 }
              return tracker.instance(for: i)
            }
            s.insert(from: &p)
            expectConsistentSet(s)

            expectEqual(s.capacity, capacity)
            expectEqual(s.count, count)

            var seen: Set<Int> = []
            var index = s.startIndex
            while index != s.endIndex {
              let payload = s[index].payload
              expectTrue(seen.insert(payload).inserted, "Duplicate item \(payload)")
              index = s.index(after: index)
            }
          }
        }
      }
    }
  }
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_insert_drain() {
    withEvery("capacity", in: [0, 1, 2, 4, 10, 100, 200]) { capacity in
      withEvery("count", in: 0 ..< capacity) { count in
        withEvery("chunkSize", in: [1, 2, 10, 100, 1000]) { chunkSize in
          withLifetimeTracking { tracker in
            var s = RigidSet<LifetimeTracked<Int>>(capacity: capacity)

            var i = 0
            var drain = CustomDrain<LifetimeTracked<Int>>(
              underestimatedCount: 0,
              chunkSize: chunkSize
            ) {
              guard i < count else { return nil }
              defer { i += 1 }
              return tracker.instance(for: i)
            }
            s.insert(from: &drain)
            expectConsistentSet(s)

            expectEqual(s.capacity, capacity)
            expectEqual(s.count, count)

            var seen: Set<Int> = []
            var index = s.startIndex
            while index != s.endIndex {
              let payload = s[index].payload
              expectTrue(seen.insert(payload).inserted, "Duplicate item \(payload)")
              index = s.index(after: index)
            }
          }
        }
      }
    }
  }

  func test_insert_drain_maximumCount() {
    withEvery("capacity", in: [5, 10, 100]) { capacity in
      withEvery("drainLength", in: [0, 1, 2, 4, 10, capacity]) { drainLength in
        withEvery("maxCount", in: [0, 1, 2, 3, 5]) { maxCount in
          withEvery("chunkSize", in: [1, 2, 3, 10]) { chunkSize in
            withLifetimeTracking { tracker in
              var s = RigidSet<LifetimeTracked<Int>>(capacity: capacity)

              var i = 0
              var drain = CustomDrain<LifetimeTracked<Int>>(
                underestimatedCount: 0,
                chunkSize: chunkSize
              ) {
                guard i < drainLength else { return nil }
                defer { i += 1 }
                return tracker.instance(for: i)
              }
              s.insert(maximumCount: maxCount, from: &drain)
              expectConsistentSet(s)

              let expectedCount = Swift.min(maxCount, drainLength)
              expectEqual(s.count, expectedCount)
              expectEqual(i, expectedCount)
            }
          }
        }
      }
    }
  }
#endif

  func test_remove_one() {
    withEvery("count", in: [0, 1, 2, 4, 10, 100, 500]) { count in
      withEvery("item", in: 0 ..< count) { item in
        withLifetimeTracking { tracker in
          var set = RigidSet<LifetimeTracked<Int>>(capacity: count)
          for i in 0 ..< count {
            let instance = tracker.instance(for: i)
            set.insert(instance)
          }
          expectEqual(set.count, count)

          let dupe = tracker.instance(for: item)
          let removed = set.remove(dupe)
          expectNotNil(removed) {
            expectNotIdentical($0, dupe)
            expectEqual($0.payload, item)
          }
          expectConsistentSet(set)

          expectEqual(set.count, count - 1)

          withEvery("j", in: 0 ..< count) { j in
            let found = set.contains(tracker.instance(for: j))
            expectEqual(found, j != item)
          }
        }
      }
    }
  }

  func test_remove_all() {
    withEvery("count", in: [0, 1, 2, 4, 10, 100, 1000]) { count in
      withLifetimeTracking { tracker in
        var set = RigidSet<LifetimeTracked<Int>>(capacity: count)
        for i in 0 ..< count {
          let instance = tracker.instance(for: i)
          set.insert(instance)
        }
        expectEqual(set.count, count)

        withEvery("i", in: 0 ..< count) { i in
          let dupe = tracker.instance(for: i)
          let removed = set.remove(dupe)
          expectNotNil(removed) {
            expectNotIdentical($0, dupe)
            expectEqual($0.payload, i)
          }
          expectConsistentSet(set)
        }
        expectEqual(set.count, 0)
      }
    }
  }

  func test_removeAll() {
    withEvery("count", in: [0, 1, 2, 4, 10, 100, 1000]) { count in
      withLifetimeTracking { tracker in
        var set = RigidSet<LifetimeTracked<Int>>(capacity: count)
        for i in 0 ..< count {
          let instance = tracker.instance(for: i)
          set.insert(instance)
        }
        expectEqual(set.count, count)

        set.removeAll()
        expectEqual(set.count, 0)
        expectEqual(set.capacity, count)
        expectConsistentSet(set)
      }
    }
  }

  func test_insert_exercise() {
    // Exercise insertions with lots of distinct hash layouts
    withEvery("seed", in: 0 ..< 10_000) { seed in
      withEvery("scale", in: _HTable.minimumScale ..< _HTable.minimumScale + 3) { scale in
        let count = _HTable.maximumCapacity(forScale: scale)
        var set = RigidSet<Pair>(capacity: count)
        for i in 0 ..< count {
          set.insert(Pair(seed, i))
          expectConsistentSet(set)
        }
        expectEqual(set.count, count)

        withEvery("i", in: 0 ..< count) { i in
          expectTrue(set.contains(Pair(seed, i)))
        }
      }
    }
  }

  func test_remove_exercise() {
    // Exercise removals with lots of distinct hash layouts
    withEvery("seed", in: 0 ..< 10_000) { seed in
      withEvery("scale", in: _HTable.minimumScale ..< _HTable.minimumScale + 3) { scale in
        let count = _HTable.maximumCapacity(forScale: scale)
        var set = RigidSet<Pair>(capacity: count)
        for i in 0 ..< count {
          set.insert(Pair(seed, i))
        }
        expectEqual(set.count, count)

        withEvery("i", in: 0 ..< count) { i in
          let item = Pair(seed, i)
          let removed = set.remove(item)
          expectNotNil(removed) {
            expectEqual($0, item)
          }
          expectConsistentSet(set)
        }
        expectEqual(set.count, 0)
      }
    }
  }
}
#endif
