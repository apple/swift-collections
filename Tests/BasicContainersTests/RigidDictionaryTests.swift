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

class RigidDictionaryTests: CollectionTestCase {
  func test_empty() {
    let s = RigidDictionary<Int, String>()
    expectEqual(s.count, 0)
    expectTrue(s.isEmpty)
    expectTrue(s.isFull)
    expectEqual(s.capacity, 0)
    expectEqual(s.freeCapacity, 0)
  }
  
  func test_init_capacity() {
    withSome("capacity", in: 0 ..< 1000) { capacity in
      let d = RigidDictionary<Int, String>(capacity: capacity)
      expectEqual(d.count, 0)
      expectTrue(d.isEmpty)
      expectEqual(d.isFull, capacity == 0)
      expectEqual(d.capacity, capacity)
      expectEqual(d.freeCapacity, capacity)
    }
  }
  
  func test_insertValue_one() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withLifetimeTracking { tracker in
      var d = RigidDictionary<Key, Value>(capacity: 20)
      let firstKey = tracker.instance(for: 42)
      let firstValue = tracker.instance(for: "forty-two")
      expectNil(d.insertValue(firstValue, forKey: firstKey))
      
      let secondKey = tracker.instance(for: 42)
      let secondValue = tracker.instance(for: "forty-two")
      expectIdentical(
        d.insertValue(secondValue, forKey: secondKey),
        secondValue)
      
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
      let thirdKey = tracker.instance(for: 42)
      expectNotNil(d.value(forKey: thirdKey)) { valueRef in
        expectIdentical(valueRef.value, firstValue)
      }
      _ = consume firstValue
      expectNotNil(d.value(forKey: thirdKey)) { valueRef in
        expectEqual(valueRef.value.payload, "forty-two")
      }
#endif
      
      expectEqual(d.count, 1)
      expectFalse(d.isEmpty)
      expectFalse(d.isFull)
      expectEqual(d.capacity, 20)
      expectEqual(d.freeCapacity, 19)
    }
  }
  
  func test_updateValue_one() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withLifetimeTracking { tracker in
      var d = RigidDictionary<Key, Value>(capacity: 20)
      let firstKey = tracker.instance(for: 42)
      let firstValue = tracker.instance(for: "forty-two")
      expectNil(d.updateValue(firstValue, forKey: firstKey))
      
      let secondKey = tracker.instance(for: 42)
      let secondValue = tracker.instance(for: "forty-two")
      let res = d.updateValue(secondValue, forKey: secondKey)
      expectIdentical(res, firstValue)
      
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
      let thirdKey = tracker.instance(for: 42)
      expectNotNil(d.value(forKey: thirdKey)) { valueRef in
        expectIdentical(valueRef.value, secondValue)
      }
      _ = consume secondValue
      expectNotNil(d.value(forKey: thirdKey)) { valueRef in
        expectEqual(valueRef.value.payload, "forty-two")
      }
#endif
      
      expectEqual(d.count, 1)
      expectFalse(d.isEmpty)
      expectFalse(d.isFull)
      expectEqual(d.capacity, 20)
      expectEqual(d.freeCapacity, 19)
    }
  }
  
  func test_insertValue_full() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withEvery("capacity", in: [0, 1, 2, 10, 100, 1000]) { capacity in
      withLifetimeTracking { tracker in
        var d = RigidDictionary<Key, Value>(capacity: capacity)
        for i in 0 ..< capacity {
          let key = tracker.instance(for: i)
          let value = tracker.instance(for: "\(i)")
          let remnant = d.insertValue(value, forKey: key)
          expectNil(remnant)
        }
        expectEqual(d.count, capacity)
        expectEqual(d.isEmpty, capacity == 0)
        expectTrue(d.isFull)
        expectEqual(d.capacity, capacity)
        expectEqual(d.freeCapacity, 0)
        
        for i in 0 ..< capacity {
          let key = tracker.instance(for: i)
          let value = tracker.instance(for: "\(i)")
          let remnant = d.insertValue(value, forKey: key)
          expectIdentical(remnant, value)
        }
        expectEqual(d.count, capacity)
        expectEqual(d.isEmpty, capacity == 0)
        expectTrue(d.isFull)
        expectEqual(d.capacity, capacity)
        expectEqual(d.freeCapacity, 0)
        
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
        for i in 0 ..< capacity {
          let dupe = tracker.instance(for: i)
          expectNotNil(
            d.value(forKey: dupe),
            "\(dupe.payload) not found"
          ) { valueRef in
            expectEqual(valueRef.value.payload, "\(i)")
          }
        }
#endif
      }
    }
  }
  
  func test_updateValue_full() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withEvery("capacity", in: [0, 1, 2, 10, 100, 1000]) { capacity in
      withLifetimeTracking { tracker in
        var d = RigidDictionary<Key, Value>(capacity: capacity)
        for i in 0 ..< capacity {
          let key = tracker.instance(for: i)
          let value = tracker.instance(for: "\(i)")
          let old = d.updateValue(value, forKey: key)
          expectNil(old)
        }
        expectEqual(d.count, capacity)
        expectEqual(d.isEmpty, capacity == 0)
        expectTrue(d.isFull)
        expectEqual(d.capacity, capacity)
        expectEqual(d.freeCapacity, 0)
        
        for i in 0 ..< capacity {
          let key = tracker.instance(for: i)
          let value = tracker.instance(for: "\(i)")
          let old = d.updateValue(value, forKey: key)
          expectNotNil(old) { old in
            expectNotIdentical(old, value)
            expectEqual(old, value)
          }
        }
        expectEqual(d.count, capacity)
        expectEqual(d.isEmpty, capacity == 0)
        expectTrue(d.isFull)
        expectEqual(d.capacity, capacity)
        expectEqual(d.freeCapacity, 0)
        
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
        for i in 0 ..< capacity {
          let dupe = tracker.instance(for: i)
          expectNotNil(
            d.value(forKey: dupe),
            "\(dupe.payload) not found"
          ) { valueRef in
            expectEqual(valueRef.value.payload, "\(i)")
          }
        }
#endif
      }
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_memoizedValue_one() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withLifetimeTracking { tracker in
      var d = RigidDictionary<Key, Value>(capacity: 20)
      let key1 = tracker.instance(for: 42)
      let value1 = tracker.instance(for: "\(42)")
      do {
        let v1 = d.memoizedValue(forKey: key1) { key in
          expectIdentical(key, key1)
          return value1
        }
        expectIdentical(v1.value, value1)
      }
      
      let key2 = tracker.instance(for: 42)
      let value2 = tracker.instance(for: "\(42)")
      do {
        let v2 = d.memoizedValue(forKey: key2) { key in
          expectFailure("Cached value not found")
          return value2
        }
        expectIdentical(v2.value, value1)
      }
      
      let key3 = tracker.instance(for: 42)
      expectNotNil(d.value(forKey: key3)) { valueRef in
        expectIdentical(valueRef.value, value1)
      }
      
      expectEqual(d.count, 1)
      expectFalse(d.isEmpty)
      expectFalse(d.isFull)
      expectEqual(d.capacity, 20)
      expectEqual(d.freeCapacity, 19)
    }
  }
#endif
  
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
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withEvery("capacity", in: [1, 2, 10, 100, 200]) { capacity in
      withLifetimeTracking { tracker in
        var d = RigidDictionary<Key, Value>(capacity: capacity)
        withEvery("payload", in: 0 ..< capacity) { payload in
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
  }

  @available(SwiftStdlib 6.2, *)
  func test_iteration_indices() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withEvery("capacity", in: [1, 2, 10, 100, 200]) { capacity in
      withLifetimeTracking { tracker in
        var d = RigidDictionary<Key, Value>(capacity: capacity)
        withEvery("payload", in: 0 ..< capacity) { payload in
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
  }

  func test_removeValueForKey_one() {
    typealias Key = LifetimeTracked<Int>
    typealias Value = LifetimeTracked<String>
    withEvery("capacity", in: [1, 2, 10, 100, 200]) { capacity in
      withEvery("count", in: [1, capacity / 3, capacity / 2, 2 * capacity / 3, capacity - 1, capacity] as Set) { count in
        guard count > 0 else { return }
        withSome("key", in: 0 ..< count) { key in
          withLifetimeTracking { tracker in
            var d = RigidDictionary<Key, Value>(capacity: capacity)
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
            expectEqual(d.capacity, capacity)
            
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
    withEvery("capacity", in: [1, 2, 10, 100, 200]) { capacity in
      withLifetimeTracking { tracker in
        var d = RigidDictionary<Key, Value>(capacity: capacity)
        for i in 0 ..< capacity {
          let key = tracker.instance(for: i)
          let value = tracker.instance(for: "\(i)")
          d.insertValue(value, forKey: key)
        }
        
        withEvery("key", in: 0 ..< capacity) { key in
          let oldValue = d.removeValue(forKey: tracker.instance(for: key))
          expectNotNil(oldValue) {
            expectEqual($0.payload, "\(key)")
          }
          expectEqual(d.count, capacity - key - 1)
          expectEqual(d.capacity, capacity)
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
        var d = RigidDictionary<Key, Value>(capacity: capacity)
        for i in 0 ..< capacity {
          let key = tracker.instance(for: i)
          let value = tracker.instance(for: "\(i)")
          d.insertValue(value, forKey: key)
        }
        
        d.removeAll()
        
        expectEqual(d.count, 0)
        expectEqual(d.capacity, capacity)
      }
    }
  }
}

#endif
