//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
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

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

class RigidSetTests: CollectionTestCase {
  func test_empty() {
    let s = RigidSet<Int>()
    expectEqual(s.count, 0)
    expectTrue(s.isEmpty)
    expectTrue(s.isFull)
    expectEqual(s.capacity, 0)
    expectEqual(s.freeCapacity, 0)
  }
  
  func test_init_capacity() {
    withSome("capacity", in: 0 ..< 1000) { capacity in
      let s = RigidSet<Int>(capacity: capacity)
      expectEqual(s.count, 0)
      expectTrue(s.isEmpty)
      expectEqual(s.isFull, capacity == 0)
      expectEqual(s.capacity, capacity)
      expectEqual(s.freeCapacity, capacity)
    }
  }
  
  func test_insert_one() {
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
    }
  }
  
  func test_update_one() {
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
    // FIXME: This isn't really testing anything; figure out how to handle this
    let c1 = 500
    let scale = _HTable.minimumScale(forCapacity: c1)
    let c2 = _HTable.maximumCapacity(forScale: scale)
    var set = RigidSet<Int>(capacity: c2)
    for i in 0 ..< c2 {
      set.insert(i)
    }
    set._dump(bitmap: true, chains: true)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_iterate() {
    withEvery("capacity", in: [0, 1, 2, 3, 4, 10, 100, 1000]) { capacity in
      withEvery("maximumCount", in: [1, 2, 3, Int.max]) { maximumCount in
        withLifetimeTracking { tracker in
          var s = RigidSet<LifetimeTracked<Int>>(capacity: capacity)
          withEvery("i", in: 0 ..< capacity) { i in
            s.insert(tracker.instance(for: i))
            
            var expected = Set(0 ... i)
            var it = s.makeBorrowingIterator()
            while true {
              let next = it.nextSpan(maximumCount: maximumCount)
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
        }
        expectEqual(set.count, 0)
      }
    }
  }
}
#endif
