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
import ContainersPreview
#endif

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

class UniqueDictionaryTests: CollectionTestCase {
  func test_empty() {
    let s = UniqueDictionary<Int, String>()
    expectEqual(s.count, 0)
    expectTrue(s.isEmpty)
    expectTrue(s.isFull)
    expectEqual(s.capacity, 0)
    expectEqual(s.freeCapacity, 0)
  }
  
  func test_init_minimumCapacity() {
    withSome("capacity", in: 0 ..< 1000) { capacity in
      let d = UniqueDictionary<Int, String>(minimumCapacity: capacity)
      expectEqual(d.count, 0)
      expectTrue(d.isEmpty)
      expectEqual(d.isFull, capacity == 0)
      expectGreaterThanOrEqual(d.capacity, capacity)
      expectEqual(d.freeCapacity, d.capacity)
    }
  }
  
  func test_insert_one() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withLifetimeTracking { tracker in
      var s = UniqueDictionary<Key, Value>()
      let firstKey = tracker.instance(for: 42)
      let firstValue = tracker.instance(for: "42")
      expectNil(s.insertValue(firstValue, forKey: firstKey))
      
      expectTrue(s.containsKey(firstKey))
      expectNotNil(s.withValue(forKey: firstKey) { $0 }) {
        expectIdentical($0, firstValue)
      }
      
      let secondKey = tracker.instance(for: 42)
      let secondValue = tracker.instance(for: "42")
      expectIdentical(s.insertValue(secondValue, forKey: secondKey), secondValue)
      
      expectTrue(s.containsKey(firstKey))
      expectTrue(s.containsKey(secondKey))
      _ = consume firstKey
      expectTrue(s.containsKey(secondKey))
      
      expectNotNil(s.withValue(forKey: secondKey) { $0 }) {
        expectIdentical($0, firstValue)
      }
      
      expectEqual(s.count, 1)
      expectFalse(s.isEmpty)
      expectGreaterThanOrEqual(s.capacity, 1)
    }
  }
  
  func test_update_one() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withLifetimeTracking { tracker in
      var s = UniqueDictionary<Key, Value>()
      let firstKey = tracker.instance(for: 42)
      let firstValue = tracker.instance(for: "42")
      expectNil(s.updateValue(firstValue, forKey: firstKey))
      
      expectTrue(s.containsKey(firstKey))
      expectNotNil(s.withValue(forKey: firstKey) { $0 }) {
        expectIdentical($0, firstValue)
      }
      
      let secondKey = tracker.instance(for: 42)
      let secondValue = tracker.instance(for: "42")
      expectIdentical(s.updateValue(secondValue, forKey: secondKey), firstValue)
      
      expectTrue(s.containsKey(firstKey))
      expectTrue(s.containsKey(secondKey))
      _ = consume secondKey
      expectTrue(s.containsKey(firstKey))
      
      expectNotNil(s.withValue(forKey: firstKey) { $0 }) {
        expectIdentical($0, secondValue)
      }
      
      expectEqual(s.count, 1)
      expectFalse(s.isEmpty)
      expectGreaterThanOrEqual(s.capacity, 1)
    }
  }
  
  func test_init_minimumCapacity_growth() {
    // These are the storage capacities we expect to see for a UniqueSet
    // up to size 1000.
    let expected = [0, 1, 2, 4, 7, 14, 28, 56, 112, 224, 448, 896, 1792]
    var actual: Set<Int> = []
    
    // Check that we get the expected capacities for each size. UniqueSet
    // should not prematurely allocate more than the size of the closest
    // expected size.
    var j = 0
    withEvery("i", in: 0 ..< 1000) { i in
      let set = UniqueDictionary<Int, String>(minimumCapacity: i)
      if i > expected[j] {
        j += 1
      }
      expectEqual(set.capacity, expected[j])
      actual.insert(set.capacity)
    }
    expectEqual(actual.sorted(), expected)
  }
  
  
  func test_withKeys() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withEvery("capacity", in: [0, 1, 2, 10, 100, 1000]) { capacity in
      withLifetimeTracking { tracker in
        var d = RigidDictionary<Key, Value>(capacity: capacity)
        withEvery("i", in: 0 ..< capacity) { i in
          let key = tracker.instance(for: i)
          let value = tracker.instance(for: "\(i)")
          d.insertValue(value, forKey: key)
          
          d.withKeys { keys in
            expectEqual(keys.count, i + 1)
            expectEqual(keys.capacity, capacity)
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
            var it = keys.makeBorrowingIterator()
            var actual: Set<Int> = []
            while true {
              let next = it.nextSpan()
              guard !next.isEmpty else { break }
              for i in next.indices {
                expectTrue(
                  actual.insert(next[i].payload).inserted,
                  "Duplicate value \(next[i].payload)")
              }
            }
            expectEqualElements(actual.sorted(), 0 ... i)
#else
            for j in 0 ... i {
              expectTrue(keys.contains(tracker.instance(for: j)))
            }
#endif
          }
        }
      }
    }
  }
  
  func test_iteration_indexAfter() {
    let c = 1000
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withLifetimeTracking { tracker in
      var d = UniqueDictionary<Key, Value>()
      withEvery("payload", in: 0 ..< c) { payload in
        let key = tracker.instance(for: payload)
        let value = tracker.instance(for: "\(payload)")
        d.insertValue(value, forKey: key)
        
        var seen: Set<Int> = []
        
        var i = d.startIndex
        while i != d.endIndex {
          let item = d[i]
          let payload = item.key.payload
          expectEqual(item.value.payload, "\(payload)")
          expectTrue(seen.insert(payload).inserted, "Duplicate item \(payload)")
          i = d.index(after: i)
        }
        expectEqual(seen.count, payload + 1)
      }
    }
  }
  
  @available(SwiftStdlib 6.2, *)
  func test_iteration_indices() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    let c = 200
    withLifetimeTracking { tracker in
      var d = UniqueDictionary<Key, Value>()
      withEvery("payload", in: 0 ..< c) { payload in
        let key = tracker.instance(for: payload)
        let value = tracker.instance(for: "\(payload)")
        d.insertValue(value, forKey: key)
        
        var seen: Set<Int> = []
        let indices = d.indices
        var it = indices.makeBorrowingIterator()
        while true {
          let next = it.nextSpan()
          if next.isEmpty { break }
          expectEqual(next.count, 1)
          var i = 0
          while i < next.count {
            let index = next[i]
            let item = d[index]
            expectTrue(
              seen.insert(item.key.payload).inserted,
              "Duplicate item \(item.key.payload)")
            expectEqual(item.value.payload, "\(item.key.payload)")
            i += 1
          }
        }
        expectEqual(seen.count, payload + 1)
      }
    }
  }

  func test_removeValueForKey_one() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withEvery("minCap", in: [1, 2, 10, 100, 200]) { minCap in
      withEvery("count", in: [1, minCap / 3, minCap / 2, 2 * minCap / 3, minCap - 1, minCap] as Set) { count in
        guard count > 0 else { return }
        withSome("key", in: 0 ..< count) { key in
          withLifetimeTracking { tracker in
            var d = UniqueDictionary<Key, Value>(minimumCapacity: minCap)
            for i in 0 ..< count {
              let key = tracker.instance(for: i)
              let value = tracker.instance(for: "\(i)")
              d.insertValue(value, forKey: key)
            }
            
            let oldValue = d.removeValue(forKey: tracker.instance(for: key))
            expectNotNil(oldValue) {
              expectEqual($0.payload, "\(key)")
            }
            expectEqual(d.count, count - 1)
            
            for i in 0 ..< count {
              let value = d.withValue(forKey: tracker.instance(for: i)) { $0 }
              if i == key {
                expectNil(value)
              } else {
                expectEqual(value?.payload, "\(i)")
              }
            }
          }
        }
      }
    }
  }
  
  func test_removeValueForKey_all() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withEvery("minCap", in: [1, 2, 10, 100, 200]) { minCap in
      withLifetimeTracking { tracker in
        var d = UniqueDictionary<Key, Value>(minimumCapacity: minCap)
        let capacity = d.capacity
        for i in 0 ..< d.capacity {
          let key = tracker.instance(for: i)
          let value = tracker.instance(for: "\(i)")
          d.insertValue(value, forKey: key)
        }
        expectEqual(d.capacity, capacity)

        withEvery("key", in: 0 ..< d.capacity) { key in
          let oldValue = d.removeValue(forKey: tracker.instance(for: key))
          expectNotNil(oldValue) {
            expectEqual($0.payload, "\(key)")
          }
          expectEqual(d.count, capacity - key - 1)
        }
        expectEqual(d.count, 0)
      }
    }
  }
  
  func test_removeAll() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withEvery("capacity", in: [1, 2, 10, 100, 200]) { capacity in
      withLifetimeTracking { tracker in
        var d = UniqueDictionary<Key, Value>(minimumCapacity: capacity)
        for i in 0 ..< capacity {
          let key = tracker.instance(for: i)
          let value = tracker.instance(for: "\(i)")
          d.insertValue(value, forKey: key)
        }
        
        d.removeAll()
        
        expectEqual(d.count, 0)
        expectEqual(d.capacity, 0)
      }
    }
  }

  func test_removeAll_keepingCapacity() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withEvery("capacity", in: [1, 2, 10, 100, 200]) { capacity in
      withLifetimeTracking { tracker in
        var d = UniqueDictionary<Key, Value>(minimumCapacity: capacity)
        for i in 0 ..< capacity {
          let key = tracker.instance(for: i)
          let value = tracker.instance(for: "\(i)")
          d.insertValue(value, forKey: key)
        }
        
        d.removeAll(keepingCapacity: true)
        
        expectEqual(d.count, 0)
        expectGreaterThanOrEqual(d.capacity, capacity)
      }
    }
  }

}

#endif
