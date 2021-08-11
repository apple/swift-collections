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
import CollectionsTestSupport
@testable import SparseSetModule

class SparseSetElementsTests: CollectionTestCase {
  func test_elements_getter() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
        let items = zip(keys, values).map { (key: $0.0, value: $0.1) }
        expectEqualElements(sparseSet.elements, items)
      }
    }
  }

  func test_elements_modify() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
        let items = zip(keys, values).map { (key: $0.0, value: $0.1) }

        var sparseSet2 = SparseSet<Int, LifetimeTracked<Int>>()

        swap(&sparseSet.elements, &sparseSet2.elements)

        expectEqualElements(sparseSet, [])
        expectEqualElements(sparseSet2, items)
      }
    }
  }

  func test_keys_values() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)

        expectEqualElements(sparseSet.elements.keys, keys)
        expectEqualElements(sparseSet.elements.values, values)

        values.reverse()
        sparseSet.elements.values.reverse()
        expectEqualElements(sparseSet.elements.values, values)
      }
    }
  }

  func test_index_forKey() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (sparseSet, keys, _) = tracker.sparseSet(keys: 0 ..< count)
        withEvery("offset", in: 0 ..< count) { offset in
          expectEqual(sparseSet.elements.index(forKey: keys[offset]), offset)
        }
        expectNil(sparseSet.elements.index(forKey: -1))
        expectNil(sparseSet.elements.index(forKey: count))
      }
    }
  }

  func test_RandomAccessCollection() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
        let items = zip(keys, values).map { (key: $0.0, value: $0.1) }
        checkBidirectionalCollection(
          sparseSet.elements, expectedContents: items,
          by: { $0 == $1 })
      }
    }
  }

  func test_CustomStringConvertible() {
    let a: SparseSet<Int, Int> = [:]
    expectEqual(a.elements.description, "[:]")

    let b: SparseSet<Int, Int> = [0: 1]
    expectEqual(b.elements.description, "[0: 1]")

    let c: SparseSet<Int, Int> = [0: 1, 2: 3, 4: 5]
    expectEqual(c.elements.description, "[0: 1, 2: 3, 4: 5]")
  }

  func test_CustomDebugStringConvertible() {
    let a: SparseSet<Int, Int> = [:]
    expectEqual(a.elements.debugDescription,
                "SparseSet<Int, Int>.Elements([:])")

    let b: SparseSet<Int, Int> = [0: 1]
    expectEqual(b.elements.debugDescription,
                "SparseSet<Int, Int>.Elements([0: 1])")

    let c: SparseSet<Int, Int> = [0: 1, 2: 3, 4: 5]
    expectEqual(c.elements.debugDescription,
                "SparseSet<Int, Int>.Elements([0: 1, 2: 3, 4: 5])")
  }

  func test_customReflectable() {
    do {
      let sparseSet: SparseSet<Int, Int> = [1: 2, 3: 4, 5: 6]
      let mirror = Mirror(reflecting: sparseSet.elements)
      expectEqual(mirror.displayStyle, .collection)
      expectNil(mirror.superclassMirror)
      expectTrue(mirror.children.compactMap { $0.label }.isEmpty) // No label
      expectEqualElements(
        mirror.children.compactMap { $0.value as? (key: Int, value: Int) },
        sparseSet.map { $0 })
    }
  }

  func test_Equatable_Hashable() {
    let samples: [[SparseSet<Int, Int>]] = [
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
              var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
              keys.swapAt(i, j)
              values.swapAt(i, j)
              withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
                sparseSet.elements.swapAt(i, j)
                expectEquivalentElements(
                  sparseSet, zip(keys, values),
                  by: { $0.key == $1.0 && $0.value == $1.1 })
                expectEqual(sparseSet[keys[i]], values[i])
                expectEqual(sparseSet[keys[j]], values[j])
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
            var (sparseSet, keys, values) = tracker.sparseSet(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            let expectedPivot = items.partition { $0.0 < count / 2 }
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let actualPivot = sparseSet.elements.partition { $0.key < count / 2 }
              expectEqual(actualPivot, expectedPivot)
              expectEqualElements(sparseSet, items)
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
            var (sparseSet, keys, values) = tracker.sparseSet(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            items.sort(by: { $0.0 < $1.0 })
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet.elements.sort()
              expectEqualElements(sparseSet, items)
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
            var (sparseSet, keys, values) = tracker.sparseSet(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            items.sort(by: { $0.0 > $1.0 })
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet.elements.sort(by: { $0.key > $1.key })
              expectEqualElements(sparseSet, items)
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
          var sparseSet = SparseSet(
            uniqueKeys: 0 ..< count,
            values: 100 ..< 100 + count)
          var items = (0 ..< count).map { (key: $0, value: 100 + $0) }
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            expectEqualElements(sparseSet.elements, items)

            var rng1 = RepeatableRandomNumberGenerator(seed: seed)
            items.shuffle(using: &rng1)

            var rng2 = RepeatableRandomNumberGenerator(seed: seed)
            sparseSet.elements.shuffle(using: &rng2)

            items.sort(by: { $0.key < $1.key })
            sparseSet.elements.sort()
            expectEqualElements(sparseSet, items)
          }
        }
      }
      if count >= 2 {
        // Check that shuffling with the system RNG does permute the elements.
        var sparseSet = SparseSet(
          uniqueKeys: 0 ..< count,
          values: 100 ..< 100 + count)
        let original = sparseSet
        var success = false
        for _ in 0 ..< 1000 {
          sparseSet.elements.shuffle()
          if !sparseSet.elementsEqual(
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
          var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
          var items = Array(zip(keys, values))
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            items.reverse()
            sparseSet.elements.reverse()
            expectEqualElements(sparseSet, items)
          }
        }
      }
    }
  }

  func test_removeAll() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (sparseSet, _, _) = tracker.sparseSet(keys: 0 ..< count)
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            sparseSet.elements.removeAll()
            expectEqual(sparseSet.universeSize, 0)
            expectEqualElements(sparseSet, [])
          }
        }
      }
    }
  }

  func test_removeAll_keepCapacity() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (sparseSet, _, _) = tracker.sparseSet(keys: 0 ..< count)
          let origUniverseSize = sparseSet.universeSize
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            sparseSet.elements.removeAll(keepingCapacity: true)
            expectEqual(sparseSet.universeSize, origUniverseSize)
            expectEqualElements(sparseSet, [])
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
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let actual = sparseSet.elements.remove(at: offset)
              // Mimic expected sparse set removal: remove the element at
              // offset, replacing it with the final element.
              keys.swapAt(offset, keys.endIndex - 1)
              let expectedKey = keys.removeLast()
              values.swapAt(offset, values.endIndex - 1)
              let expectedValue = values.removeLast()
              expectEqual(actual.key, expectedKey)
              expectEqual(actual.value, expectedValue)
              expectEqualElements(
                sparseSet,
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
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet.elements.removeSubrange(range)
              // Mimic expected sparse set removal: remove the subrange and
              // close the gap with elements from the end (preserving their
              // order).
              let movedKeys = keys[range.endIndex...].suffix(range.count)
              keys.removeLast(movedKeys.count)
              keys.insert(contentsOf: movedKeys, at: range.endIndex)
              keys.removeSubrange(range)
              let movedValues = values[range.endIndex...].suffix(range.count)
              values.removeLast(movedValues.count)
              values.insert(contentsOf: movedValues, at: range.endIndex)
              values.removeSubrange(range)
              expectEqualElements(
                sparseSet,
                zip(keys, values).map { (key: $0.0, value: $0.1) })
            }
          }
        }
      }
    }
  }

  func test_removeSubrange_rangeExpression() {
    let s = SparseSet(uniqueKeys: 0 ..< 30, values: 100 ..< 130)
    let items = (0 ..< 30).map { (key: $0, value: 100 + $0) }

    var s1 = s
    s1.elements.removeSubrange(...10)
    let idx1 = items[11...].suffix(11).startIndex
    expectEqualElements(s1, items[11...].suffix(11) + items[11 ..< idx1])

    var s2 = s
    s2.elements.removeSubrange(..<10)
    let idx2 = items[10...].suffix(10).startIndex
    expectEqualElements(s2, items[10...].suffix(10) + items[10 ..< idx2])

    var s3 = s
    s3.elements.removeSubrange(10...)
    expectEqualElements(s3, items[0 ..< 10])
  }

  func test_removeLast() {
    withEvery("isShared", in: [false, true]) { isShared in
      withLifetimeTracking { tracker in
        var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< 30)
        withEvery("i", in: 0 ..< sparseSet.count) { i in
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            let actual = sparseSet.elements.removeLast()
            let expectedKey = keys.removeLast()
            let expectedValue = values.removeLast()
            expectEqual(actual.key, expectedKey)
            expectEqual(actual.value, expectedValue)
            expectEqualElements(
              sparseSet,
              zip(keys, values).map { (key: $0.0, value: $0.1) })
          }
        }
      }
    }
  }

  func test_removeFirst() {
    withEvery("isShared", in: [false, true]) { isShared in
      withLifetimeTracking { tracker in
        var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< 30)
        withEvery("i", in: 0 ..< sparseSet.count) { i in
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            let actual = sparseSet.elements.removeFirst()
            // Mimic expected sparse set removal: remove the first element,
            // replacing it with the final element.
            keys.swapAt(0, keys.endIndex - 1)
            let expectedKey = keys.removeLast()
            values.swapAt(0, values.endIndex - 1)
            let expectedValue = values.removeLast()
            expectEqual(actual.key, expectedKey)
            expectEqual(actual.value, expectedValue)
            expectEqualElements(
              sparseSet,
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
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet.elements.removeLast(suffix)
              keys.removeLast(suffix)
              values.removeLast(suffix)
              expectEqualElements(
                sparseSet,
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
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet.elements.removeFirst(prefix)
              // Mimic expected sparse set removal: remove initial elements,
              // replacing them with elements from the end (preserving their
              // order).
              let movedKeys = Array(keys[prefix...].suffix(prefix))
              keys.removeLast(movedKeys.count)
              keys.insert(contentsOf: movedKeys, at: prefix)
              keys.removeFirst(prefix)
              let movedValues = Array(values[prefix...].suffix(prefix))
              values.removeLast(movedKeys.count)
              values.insert(contentsOf: movedValues, at: prefix)
              values.removeFirst(prefix)
              expectEqualElements(
                sparseSet,
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
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            var items = zip(keys, values).map { (key: $0.0, value: $0.1) }
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet.elements.removeAll(where: { !$0.key.isMultiple(of: n) })
              items.removeAll(where: { !$0.key.isMultiple(of: n) })
              // Note: SparseSet doesn't guarantee that ordering is preserved
              // after calling `removeAll(where:)`.
              let dict1 = Dictionary(uniqueKeysWithValues: items)
              let dict2 = Dictionary(uniqueKeysWithValues: sparseSet.elements.lazy.map { ($0.key, $0.value) })
              expectEqual(dict1, dict2)
            }
          }
        }
      }
    }
  }

  func test_slice_keys() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (sparseSet, keys, _) = tracker.sparseSet(keys: 0 ..< count)
        withEveryRange("range", in: 0 ..< count) { range in
          expectEqual(sparseSet.elements[range].keys, sparseSet.keys[range])
          expectEqualElements(sparseSet.elements[range].keys, keys[range])
        }
      }
    }
  }

  func test_slice_values() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (sparseSet, _, values) = tracker.sparseSet(keys: 0 ..< count)
        withEveryRange("range", in: 0 ..< count) { range in
          expectEqualElements(sparseSet.elements[range].values, sparseSet.values[range])
          expectEqualElements(sparseSet.elements[range].values, values[range])
        }
      }
    }
  }

  func test_slice_index_forKey() {
    withEvery("count", in: 0 ..< 30) { count in
      withEveryRange("range", in: 0 ..< count) { range in
        withLifetimeTracking { tracker in
          let (sparseSet, keys, _) = tracker.sparseSet(keys: 0 ..< count)
          withEvery("offset", in: 0 ..< count) { offset in
            let actual = sparseSet.elements[range].index(forKey: keys[offset])
            let expected = range.contains(offset) ? offset : nil
            expectEqual(actual, expected)
          }
          expectNil(sparseSet.elements[range].index(forKey: -1))
          expectNil(sparseSet.elements[range].index(forKey: count))
        }
      }
    }
  }
}
