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

import XCTest
@_spi(Testing) import OrderedCollections

import CollectionsTestSupport

final class OrderedDictionaryElementsTests: CollectionTestCase {
  func test_elements_getter() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
        let items = zip(keys, values).map { (key: $0.0, value: $0.1) }
        expectEqualElements(d.elements, items)
      }
    }
  }

  func test_elements_modify() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
        let items = zip(keys, values).map { (key: $0.0, value: $0.1) }

        var d2 = OrderedDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>>()

        swap(&d.elements, &d2.elements)

        expectEqualElements(d, [])
        expectEqualElements(d2, items)
      }
    }
  }

  func test_keys_values() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)

        expectEqualElements(d.elements.keys, keys)
        expectEqualElements(d.elements.values, values)

        values.reverse()
        d.elements.values.reverse()
        expectEqualElements(d.elements.values, values)
      }
    }
  }

  func test_index_forKey() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, keys, _) = tracker.orderedDictionary(keys: 0 ..< count)
        withEvery("offset", in: 0 ..< count) { offset in
          expectEqual(d.elements.index(forKey: keys[offset]), offset)
        }
        expectNil(d.elements.index(forKey: tracker.instance(for: -1)))
        expectNil(d.elements.index(forKey: tracker.instance(for: count)))
      }
    }
  }

  func test_RandomAccessCollection() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
        let items = zip(keys, values).map { (key: $0.0, value: $0.1) }
        checkBidirectionalCollection(
          d.elements, expectedContents: items,
          by: { $0 == $1 })
      }
    }
  }

  func test_CustomStringConvertible() {
    let a: OrderedDictionary<Int, Int> = [:]
    expectEqual(a.elements.description, "[:]")

    let b: OrderedDictionary<Int, Int> = [0: 1]
    expectEqual(b.elements.description, "[0: 1]")

    let c: OrderedDictionary<Int, Int> = [0: 1, 2: 3, 4: 5]
    expectEqual(c.elements.description, "[0: 1, 2: 3, 4: 5]")
  }

  func test_CustomDebugStringConvertible() {
    let a: OrderedDictionary<Int, Int> = [:]
    expectEqual(a.elements.debugDescription,
                "OrderedDictionary<Int, Int>.Elements([:])")

    let b: OrderedDictionary<Int, Int> = [0: 1]
    expectEqual(b.elements.debugDescription,
                "OrderedDictionary<Int, Int>.Elements([0: 1])")

    let c: OrderedDictionary<Int, Int> = [0: 1, 2: 3, 4: 5]
    expectEqual(c.elements.debugDescription,
                "OrderedDictionary<Int, Int>.Elements([0: 1, 2: 3, 4: 5])")
  }

  func test_customReflectable() {
    do {
      let d: OrderedDictionary<Int, Int> = [1: 2, 3: 4, 5: 6]
      let mirror = Mirror(reflecting: d.elements)
      expectEqual(mirror.displayStyle, .collection)
      expectNil(mirror.superclassMirror)
      expectTrue(mirror.children.compactMap { $0.label }.isEmpty) // No label
      expectEqualElements(
        mirror.children.compactMap { $0.value as? (key: Int, value: Int) },
        d.map { $0 })
    }
  }

  func test_Equatable_Hashable() {
    let samples: [[OrderedDictionary<Int, Int>]] = [
      [[:], [:]],
      [[1: 100], [1: 100]],
      [[2: 200], [2: 200]],
      [[3: 300], [3: 300]],
      [[100: 1], [100: 1]],
      [[1: 1], [1: 1]],
      [[100: 100], [100: 100]],
      [[1: 100, 2: 200], [1: 100, 2: 200]],
      [[2: 200, 1: 100], [2: 200, 1: 100]],
      [[1: 100, 2: 200, 3: 300], [1: 100, 2: 200, 3: 300]],
      [[2: 200, 1: 100, 3: 300], [2: 200, 1: 100, 3: 300]],
      [[3: 300, 2: 200, 1: 100], [3: 300, 2: 200, 1: 100]],
      [[3: 300, 1: 100, 2: 200], [3: 300, 1: 100, 2: 200]]
    ]
    checkHashable(equivalenceClasses: samples.map { $0.map { $0.elements }})
  }

  func test_swapAt() {
    withEvery("count", in: 0 ..< 20) { count in
      withEvery("i", in: 0 ..< count) { i in
        withEvery("j", in: 0 ..< count) { j in
          withEvery("isShared", in: [false, true]) { isShared in
            withLifetimeTracking { tracker in
              var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
              keys.swapAt(i, j)
              values.swapAt(i, j)
              withHiddenCopies(if: isShared, of: &d) { d in
                d.elements.swapAt(i, j)
                expectEquivalentElements(
                  d, zip(keys, values),
                  by: { $0.key == $1.0 && $0.value == $1.1 })
                expectEqual(d[keys[i]], values[i])
                expectEqual(d[keys[j]], values[j])
              }
            }
          }
        }
      }
    }
  }

  func test_partition() {
    withEvery("seed", in: 0 ..< 10) { seed in
      withEvery("count", in: 0 ..< 30) { count in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var rng = RepeatableRandomNumberGenerator(seed: seed)
            var (d, keys, values) = tracker.orderedDictionary(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            let expectedPivot = items.partition { $0.0.payload < count / 2 }
            withHiddenCopies(if: isShared, of: &d) { d in
              let actualPivot = d.elements.partition { $0.key.payload < count / 2 }
              expectEqual(actualPivot, expectedPivot)
              expectEqualElements(d, items)
            }
          }
        }
      }
    }
  }

  func test_sort() {
    withEvery("seed", in: 0 ..< 10) { seed in
      withEvery("count", in: 0 ..< 30) { count in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var rng = RepeatableRandomNumberGenerator(seed: seed)
            var (d, keys, values) = tracker.orderedDictionary(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            items.sort(by: { $0.0 < $1.0 })
            withHiddenCopies(if: isShared, of: &d) { d in
              d.elements.sort()
              expectEqualElements(d, items)
            }
          }
        }
      }
    }
  }

  func test_sort_by() {
    withEvery("seed", in: 0 ..< 10) { seed in
      withEvery("count", in: 0 ..< 30) { count in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var rng = RepeatableRandomNumberGenerator(seed: seed)
            var (d, keys, values) = tracker.orderedDictionary(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            items.sort(by: { $0.0 > $1.0 })
            withHiddenCopies(if: isShared, of: &d) { d in
              d.elements.sort(by: { $0.key > $1.key })
              expectEqualElements(d, items)
            }
          }
        }
      }
    }
  }

  func test_shuffle() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withEvery("seed", in: 0 ..< 10) { seed in
          var d = OrderedDictionary(
            uniqueKeys: 0 ..< count,
            values: 100 ..< 100 + count)
          var items = (0 ..< count).map { (key: $0, value: 100 + $0) }
          withHiddenCopies(if: isShared, of: &d) { d in
            expectEqualElements(d.elements, items)

            var rng1 = RepeatableRandomNumberGenerator(seed: seed)
            items.shuffle(using: &rng1)

            var rng2 = RepeatableRandomNumberGenerator(seed: seed)
            d.elements.shuffle(using: &rng2)

            items.sort(by: { $0.key < $1.key })
            d.elements.sort()
            expectEqualElements(d, items)
          }
        }
      }
      if count >= 2 {
        // Check that shuffling with the system RNG does permute the elements.
        var d = OrderedDictionary(
          uniqueKeys: 0 ..< count,
          values: 100 ..< 100 + count)
        let original = d
        var success = false
        for _ in 0 ..< 1000 {
          d.elements.shuffle()
          if !d.elementsEqual(
            original,
            by: { $0.key == $1.key && $0.value == $1.value}
          ) {
            success = true
            break
          }
        }
        expectTrue(success)
      }
    }
  }

  func test_reverse() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
          var items = Array(zip(keys, values))
          withHiddenCopies(if: isShared, of: &d) { d in
            items.reverse()
            d.elements.reverse()
            expectEqualElements(d, items)
          }
        }
      }
    }
  }

  func test_removeAll() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (d, _, _) = tracker.orderedDictionary(keys: 0 ..< count)
          withHiddenCopies(if: isShared, of: &d) { d in
            d.elements.removeAll()
            expectEqual(d.keys.__unstable.scale, 0)
            expectEqualElements(d, [])
          }
        }
      }
    }
  }

  func test_removeAll_keepCapacity() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (d, _, _) = tracker.orderedDictionary(keys: 0 ..< count)
          let origScale = d.keys.__unstable.scale
          withHiddenCopies(if: isShared, of: &d) { d in
            d.elements.removeAll(keepingCapacity: true)
            expectEqual(d.keys.__unstable.scale, origScale)
            expectEqualElements(d, [])
          }
        }
      }
    }
  }

  func test_remove_at() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              let actual = d.elements.remove(at: offset)
              let expectedKey = keys.remove(at: offset)
              let expectedValue = values.remove(at: offset)
              expectEqual(actual.key, expectedKey)
              expectEqual(actual.value, expectedValue)
              expectEqualElements(
                d,
                zip(keys, values).map { (key: $0.0, value: $0.1) })
            }
          }
        }
      }
    }
  }

  func test_removeSubrange() {
    withEvery("count", in: 0 ..< 30) { count in
      withEveryRange("range", in: 0 ..< count) { range in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              d.elements.removeSubrange(range)
              keys.removeSubrange(range)
              values.removeSubrange(range)
              expectEqualElements(
                d,
                zip(keys, values).map { (key: $0.0, value: $0.1) })
            }
          }
        }
      }
    }
  }

  func test_removeSubrange_rangeExpression() {
    let d = OrderedDictionary(uniqueKeys: 0 ..< 30, values: 100 ..< 130)
    let item = (0 ..< 30).map { (key: $0, value: 100 + $0) }

    var d1 = d
    d1.elements.removeSubrange(...10)
    expectEqualElements(d1, item[11...])

    var d2 = d
    d2.elements.removeSubrange(..<10)
    expectEqualElements(d2, item[10...])

    var d3 = d
    d3.elements.removeSubrange(10...)
    expectEqualElements(d3, item[0 ..< 10])
  }

  func test_removeLast() {
    withEvery("isShared", in: [false, true]) { isShared in
      withLifetimeTracking { tracker in
        var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< 30)
        withEvery("i", in: 0 ..< d.count) { i in
          withHiddenCopies(if: isShared, of: &d) { d in
            let actual = d.elements.removeLast()
            let expectedKey = keys.removeLast()
            let expectedValue = values.removeLast()
            expectEqual(actual.key, expectedKey)
            expectEqual(actual.value, expectedValue)
            expectEqualElements(
              d,
              zip(keys, values).map { (key: $0.0, value: $0.1) })
          }
        }
      }
    }
  }

  func test_removeFirst() {
    withEvery("isShared", in: [false, true]) { isShared in
      withLifetimeTracking { tracker in
        var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< 30)
        withEvery("i", in: 0 ..< d.count) { i in
          withHiddenCopies(if: isShared, of: &d) { d in
            let actual = d.elements.removeFirst()
            let expectedKey = keys.removeFirst()
            let expectedValue = values.removeFirst()
            expectEqual(actual.key, expectedKey)
            expectEqual(actual.value, expectedValue)
            expectEqualElements(
              d,
              zip(keys, values).map { (key: $0.0, value: $0.1) })
          }
        }
      }
    }
  }

  func test_removeLast_n() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("suffix", in: 0 ..< count) { suffix in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              d.elements.removeLast(suffix)
              keys.removeLast(suffix)
              values.removeLast(suffix)
              expectEqualElements(
                d,
                zip(keys, values).map { (key: $0.0, value: $0.1) })
            }
          }
        }
      }
    }
  }

  func test_removeFirst_n() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("prefix", in: 0 ..< count) { prefix in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              d.elements.removeFirst(prefix)
              keys.removeFirst(prefix)
              values.removeFirst(prefix)
              expectEqualElements(
                d,
                zip(keys, values).map { (key: $0.0, value: $0.1) })
            }
          }
        }
      }
    }
  }

  func test_removeAll_where() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("n", in: [2, 3, 4]) { n in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            var items = zip(keys, values).map { (key: $0.0, value: $0.1) }
            withHiddenCopies(if: isShared, of: &d) { d in
              d.elements.removeAll(where: { !$0.key.payload.isMultiple(of: n) })
              items.removeAll(where: { !$0.key.payload.isMultiple(of: n) })
              expectEqualElements(d, items)
            }
          }
        }
      }
    }
  }

  func test_slice_keys() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, keys, _) = tracker.orderedDictionary(keys: 0 ..< count)
        withEveryRange("range", in: 0 ..< count) { range in
          expectEqual(d.elements[range].keys, d.keys[range])
          expectEqualElements(d.elements[range].keys, keys[range])
        }
      }
    }
  }

  func test_slice_values() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, _, values) = tracker.orderedDictionary(keys: 0 ..< count)
        withEveryRange("range", in: 0 ..< count) { range in
          expectEqualElements(d.elements[range].values, d.values[range])
          expectEqualElements(d.elements[range].values, values[range])
        }
      }
    }
  }

  func test_slice_index_forKey() {
    withEvery("count", in: 0 ..< 30) { count in
      withEveryRange("range", in: 0 ..< count) { range in
        withLifetimeTracking { tracker in
          let (d, keys, _) = tracker.orderedDictionary(keys: 0 ..< count)
          withEvery("offset", in: 0 ..< count) { offset in
            let actual = d.elements[range].index(forKey: keys[offset])
            let expected = range.contains(offset) ? offset : nil
            expectEqual(actual, expected)
          }
          expectNil(d.elements[range].index(forKey: tracker.instance(for: -1)))
          expectNil(d.elements[range].index(forKey: tracker.instance(for: count)))
        }
      }
    }
  }
}
