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
class UniqueSetTests: CollectionTestCase {
  func test_empty() {
    let s = UniqueSet<Int>()
    expectEqual(s.count, 0)
    expectTrue(s.isEmpty)
    expectTrue(s.isFull)
    expectEqual(s.capacity, 0)
    expectEqual(s.freeCapacity, 0)
  }
  
  func test_insert_one() {
    withLifetimeTracking { tracker in
      var s = UniqueSet<LifetimeTracked<Int>>()
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
      expectGreaterThanOrEqual(s.capacity, 1)
    }
  }

  func test_update_one() {
    withLifetimeTracking { tracker in
      var s = UniqueSet<LifetimeTracked<Int>>()
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
      let set = UniqueSet<Int>(minimumCapacity: i)
      if i > expected[j] {
        j += 1
      }
      expectEqual(set.capacity, expected[j])
      actual.insert(set.capacity)
    }
    expectEqual(actual.sorted(), expected)
  }

  func test_insert_many() {
    let c = 1000
    withLifetimeTracking { tracker in
      var set = UniqueSet<LifetimeTracked<Int>>()
      withEvery("i", in: 0 ..< c) { i in
        let new = tracker.instance(for: i)
        let remnant = set.insert(new)
        expectNil(remnant)
        expectEqual(set.count, i + 1)
        expectTrue(set.contains(new))
      }
      expectEqual(set.count, c)
      expectFalse(set.isEmpty)
      expectGreaterThanOrEqual(set.capacity, c)
        
      withEvery("j", in: 0 ..< c) { j in
        let dupe = tracker.instance(for: j)
        if set.contains(dupe) {
          expectIdentical(set.insert(dupe), dupe)
        } else {
          expectFailure("\(dupe.payload) not found")
        }
      }
    }
  }

  func test_insert_growth() {
    // These are the storage capacities we expect to see for a UniqueSet
    // up to size 1000.
    let expected = [0, 1, 2, 4, 7, 14, 28, 56, 112, 224, 448, 896, 1792]
    var j = 0

    var set = UniqueSet<Int>()
    expectEqual(set.capacity, expected[j])

    withEvery("i", in: 1 ..< 1000) { i in
      set.insert(i)
      if i > expected[j] {
        j += 1
      }
      expectEqual(set.capacity, expected[j])
    }
  }

}
#endif
