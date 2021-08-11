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

class SparseSetValueTests: CollectionTestCase {
  func test_values_getter() {
    let s: SparseSet = [
      1: "one",
      2: "two",
      3: "three",
      4: "four",
    ]
    expectEqualElements(s.values, ["one", "two", "three", "four"])
  }

  func test_values_RandomAccessCollection() {
    withEvery("count", in: 0 ..< 30) { count in
      let keys = 0 ..< count
      let values = keys.map { $0 + 100 }
      let s = SparseSet(uniqueKeys: keys, values: values)
      checkBidirectionalCollection(s.values, expectedContents: values)
    }
  }

  func test_values_subscript_assignment() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet.values[offset] = replacement
              values[offset] = replacement
              expectEqualElements(sparseSet.values, values)
              expectEqual(sparseSet[keys[offset]], values[offset])
            }
          }
        }
      }
    }
  }

  func test_values_subscript_inPlaceMutation() {
    func checkMutation(
      _ item: inout LifetimeTracked<Int>,
      tracker: LifetimeTracker,
      delta: Int,
      file: StaticString = #file,
      line: UInt = #line
    ) {
      expectTrue(isKnownUniquelyReferenced(&item))
      item = tracker.instance(for: item.payload + delta)
    }

    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withLifetimeTracking { tracker in
          var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
          // Discard `values` and recreate it from scratch to make sure its
          // elements are uniquely referenced.
          values = tracker.instances(for: values.lazy.map { $0.payload })

          checkMutation(&values[offset], tracker: tracker, delta: 10)
          checkMutation(&sparseSet.values[offset], tracker: tracker, delta: 10)

          expectEqualElements(sparseSet.values, values)
          expectEqual(sparseSet[keys[offset]], values[offset])
        }
      }
    }
  }

  func test_swapAt() {
    withEvery("count", in: 0 ..< 20) { count in
      withEvery("i", in: 0 ..< count) { i in
        withEvery("j", in: 0 ..< count) { j in
          withEvery("isShared", in: [false, true]) { isShared in
            withLifetimeTracking { tracker in
              var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
              values.swapAt(i, j)
              withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
                sparseSet.values.swapAt(i, j)
                expectEqualElements(sparseSet.values, values)
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
            let expectedPivot = values.partition { $0.payload < 100 + count / 2 }
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let actualPivot = sparseSet.values.partition { $0.payload < 100 + count / 2 }
              expectEqual(actualPivot, expectedPivot)
              expectEqualElements(sparseSet.values, values)
              withEvery("i", in: 0 ..< count) { i in
                expectEqual(sparseSet[keys[i]], values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_withUnsafeBufferPointer() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (sparseSet, _, values) = tracker.sparseSet(keys: 0 ..< count)
          typealias R = [LifetimeTracked<Int>]
          let actual =
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet -> R in
            sparseSet.values.withUnsafeBufferPointer { buffer -> R in
              Array(buffer)
            }
          }
          expectEqualElements(actual, values)
        }
      }
    }
  }

  func test_withUnsafeMutableBufferPointer() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
          let replacement = tracker.instances(for: (0 ..< count).map { -$0 })
          typealias R = [LifetimeTracked<Int>]
          let actual =
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet -> R in
            sparseSet.values.withUnsafeMutableBufferPointer { buffer -> R in
              let result = Array(buffer)
              expectEqual(buffer.count, replacement.count, trapping: true)
              for i in 0 ..< replacement.count {
                buffer[i] = replacement[i]
              }
              return result
            }
          }
          expectEqualElements(actual, values)
          expectEqualElements(sparseSet.values, replacement)
          withEvery("i", in: 0 ..< count) { i in
            expectEqual(sparseSet[keys[i]], replacement[i])
          }
        }
      }
    }
  }

  func test_withContiguousMutableStorageIfAvailable() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (d, keys, values) = tracker.sparseSet(keys: 0 ..< count)
          let replacement = tracker.instances(for: (0 ..< count).map { -$0 })
          typealias R = [LifetimeTracked<Int>]
          let actual =
          withHiddenCopies(if: isShared, of: &d) { sparseSet -> R? in
            sparseSet.values.withContiguousMutableStorageIfAvailable { buffer -> R in
              let result = Array(buffer)
              expectEqual(buffer.count, replacement.count, trapping: true)
              for i in 0 ..< replacement.count {
                buffer[i] = replacement[i]
              }
              return result
            }
          }
          if let actual = actual {
            expectEqualElements(actual, values)
            expectEqualElements(d.values, replacement)
            withEvery("i", in: 0 ..< count) { i in
              expectEqual(d[keys[i]], replacement[i])
            }
          } else {
            expectFailure("SparseSet.Value isn't contiguous?")
          }
        }
      }
    }
  }
}
