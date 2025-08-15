//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if DEBUG
import _CollectionsTestSupport
@_spi(Testing) @testable import SortedCollections

final class SortedDictionaryTests: CollectionTestCase {
  func test_empty() {
    let d = SortedDictionary<Int, String>()
    expectEqualElements(d, [])
    expectEqual(d.count, 0)
  }
  
  func test_keysWithValues_unique() {
    let items: KeyValuePairs<Int, String> = [
      3: "three",
      1: "one",
      0: "zero",
      2: "two",
    ]
    let d = SortedDictionary<Int, String>(keysWithValues: items)
    expectEqualElements(d, [
      (key: 0, value: "zero"),
      (key: 1, value: "one"),
      (key: 2, value: "two"),
      (key: 3, value: "three")
    ])
  }
  
  func test_keysWithValues_bulk() {
    withEvery("count", in: [0, 1, 2, 4, 8, 16, 32, 64, 128, 1024, 4096]) { count in
      let kvs = (0..<count).map { (key: $0, value: $0) }
      let sortedDictionary = SortedDictionary<Int, Int>(keysWithValues: kvs)
      expectEqual(sortedDictionary.count, count)
    }
  }
  
  func test_keysWithValues_duplicates() {
    let items: KeyValuePairs<Int, String> = [
      3: "three",
      1: "one",
      1: "one-1",
      0: "zero",
      3: "three-1",
      2: "two",
    ]
    let d = SortedDictionary<Int, String>(keysWithValues: items)
    expectEqualElements(d, [
      (key: 0, value: "zero"),
      (key: 1, value: "one-1"),
      (key: 2, value: "two"),
      (key: 3, value: "three-1")
    ])
  }
  
  func test_grouping_initializer() {
    let items: [String] = [
      "one", "two", "three", "four", "five",
      "six", "seven", "eight", "nine", "ten"
    ]
    let d = SortedDictionary<Int, [String]>(grouping: items, by: { $0.count })
    expectEqualElements(d, [
      (key: 3, value: ["one", "two", "six", "ten"]),
      (key: 4, value: ["four", "five", "nine"]),
      (key: 5, value: ["three", "seven", "eight"]),
    ])
  }
  
  func test_ExpressibleByDictionaryLiteral() {
    let d0: SortedDictionary<Int, String> = [:]
    expectTrue(d0.isEmpty)

    let d1: SortedDictionary<Int, String> = [
      1: "one",
      2: "two",
      3: "three",
      4: "four",
    ]
    expectEqualElements(d1.map { $0.key }, [1, 2, 3, 4])
    expectEqualElements(d1.map { $0.value }, ["one", "two", "three", "four"])
  }
  
  func test_counts() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, _) = tracker.sortedDictionary(keys: 0 ..< count)
        expectEqual(d.isEmpty, count == 0)
        expectEqual(d.count, count)
        expectEqual(d.underestimatedCount, count)
      }
    }
  }
  
  func test_bidirectionalCollection() {
    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64]) { count in
      withLifetimeTracking { tracker in
        let (d, kvs) = tracker.sortedDictionary(keys: 0 ..< count)
        
        checkBidirectionalCollection(
          d,
          expectedContents: kvs,
          by: { $0.key == $1.key && $0.value == $1.value }
        )
      }
    }
  }
  
  func test_orderedInsertion() {
    withEvery("count", in: [0, 1, 2, 3, 4, 8, 16, 64]) { count in
      var sortedDictionary: SortedDictionary<Int, Int> = [:]
      
      for i in 0..<count {
        sortedDictionary[i] = i * 2
      }
      
      expectEqual(sortedDictionary.count, count)
      expectEqual(sortedDictionary.underestimatedCount, count)
      expectEqual(sortedDictionary.isEmpty, count == 0)
      
      for i in 0..<count {
        expectEqual(sortedDictionary[i], i * 2)
      }
    }
  }
  
  func test_reversedInsertion() {
    withEvery("count", in: [0, 1, 2, 3, 4, 8, 16, 64]) { count in
      var sortedDictionary: SortedDictionary<Int, Int> = [:]
      
      for i in (0..<count).reversed() {
        sortedDictionary[i] = i * 2
      }
      
      expectEqual(sortedDictionary.count, count)
      expectEqual(sortedDictionary.underestimatedCount, count)
      expectEqual(sortedDictionary.isEmpty, count == 0)
      
      for i in 0..<count {
        expectEqual(sortedDictionary[i], i * 2)
      }
    }
  }
  
  func test_arbitraryInsertion() {
    withEvery("count", in: [0, 1, 2, 3, 4, 8, 16, 64]) { count in
      for i in 0...count {
        let kvs = (0..<count).map { (key: $0 * 2 + 1, value: $0) }
        var sortedDictionary = SortedDictionary<Int, Int>(keysWithValues: kvs)
        sortedDictionary[i * 2] = -i
        
        var comparison = Array(kvs)
        comparison.insert((key: i * 2, value: -i), at: i)
        
        expectEqualElements(comparison, sortedDictionary)
      }
    }
  }
  
  func test_subscriptSet() {
    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64, 512]) { count in
      var sortedDictionary: SortedDictionary<Int, Int> = [:]
      
      for i in 0..<count {
        sortedDictionary[i] = i
        sortedDictionary[i] = -sortedDictionary[i]!
      }
      
      for i in 0..<count {
        expectEqual(sortedDictionary[i], -i)
      }
    }
  }
  
  func test_modifyValue_forKey_default_closure_update() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, kvs) = tracker.sortedDictionary(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            let fallback = tracker.instance(for: -2)
            withHiddenCopies(if: isShared, of: &d) { d in
              let (key, expectedValue) = kvs[offset]
              d.modifyValue(forKey: key, default: fallback) { value in
                expectEqual(value, expectedValue)
                value = replacement
              }
              kvs[offset].1 = replacement
              withEvery("kv", in: kvs) { (k, v) in
                let actualValue = d[k]
                expectEqual(actualValue, v)
              }
            }
          }
        }
      }
    }
  }

  func test_modifyValue_forKey_default_closure_insert() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let keys = tracker.instances(for: 0 ..< count)
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var d: SortedDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>> = [:]
          let fallback = tracker.instance(for: -2)
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[offset]
              d.modifyValue(forKey: key, default: fallback) { value in
                expectEqual(value, fallback)
                value = values[offset]
              }
              expectEqual(d.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let v = d[keys[i]]
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }
  
  func test_modifySubscriptRemoval() {
    func modify(_ value: inout Int?, setTo newValue: Int?) {
      value = newValue
    }
    
    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64, 512]) { count in
      let kvs = (0..<count).map { (key: $0, value: -$0) }
      
      withEvery("key", in: 0..<count) { key in
        var d = SortedDictionary<Int, Int>(keysWithValues: kvs)
        
        withEvery("isShared", in: [false, true]) { isShared in
          withHiddenCopies(if: isShared, of: &d) { d in
            modify(&d[key], setTo: nil)
            var comparisonKeys = Array(0..<count)
            comparisonKeys.remove(at: key)
          
            expectEqual(d.count, count - 1)
            expectEqualElements(d.map { $0.key }, comparisonKeys)
          }
        }
      }
    }
  }
  
  func test_modifySubscriptInsertUpdate() {
    func modify(_ value: inout Int?, setTo newValue: Int?) {
      value = newValue
    }

    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64, 512]) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        var d: SortedDictionary<Int, Int> = [:]

        withHiddenCopies(if: isShared, of: &d) { d in
          for i in 0..<count {
            modify(&d[i], setTo: i)
            modify(&d[i], setTo: -i)
          }

          for i in 0..<count {
            expectEqual(d[i], -i)
          }
        }
      }
    }
  }
}

#endif
