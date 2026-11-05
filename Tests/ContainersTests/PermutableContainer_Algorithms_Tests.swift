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
import InternalCollectionsUtilities
import SpanPreview
import BasicContainers
import DequeModule
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
final class PermutableContainer_Algorithms_Tests: CollectionTestCase {
  func test_heapSort_RigidArray() {
    let count = 100
    withEvery("seed", in: 0 ..< count) { seed in
      withLifetimeTracking { tracker in
        var items = tracker.instances(for: 0 ..< count)
        var rng = RepeatableRandomNumberGenerator(seed: seed)
        items.shuffle(using: &rng)

        var actual = RigidArray(copying: items)
        actual.heapSort()

        expectIterablePayloads(actual, equalTo: 0 ..< count)
      }
    }
  }

  func test_heapSort_by_RigidArray() {
    let count = 100
    withEvery("seed", in: 0 ..< count) { seed in
      withLifetimeTracking { tracker in
        var items = tracker.instances(for: 0 ..< count)
        var rng = RepeatableRandomNumberGenerator(seed: seed)
        items.shuffle(using: &rng)

        var actual = RigidArray(copying: items)
        actual.heapSort(by: >)

        let expected = (0 ..< count).reversed()
        expectIterablePayloads(actual, equalTo: expected)
      }
    }
  }

  func test_moveSubrange_RigidArray() {
    withEvery("count", in: [0, 1, 2, 5]) { count in
      withEveryRange("subrange", in: 0 ..< count) { subrange in
        withEvery("target", in: 0 ... count) { target in
          withLifetimeTracking { tracker in
            var expected = Array(0 ..< count)
            expected.removeSubrange(subrange)
            let i = (
              target < subrange.lowerBound ? target
              : target < subrange.upperBound ? subrange.lowerBound
              : target - subrange.count)
            expected.insert(contentsOf: subrange, at: i)

            var actual = RigidArray(copying: tracker.instances(for: 0 ..< count))
            actual.moveSubrange(subrange, to: target)

            expectIterablePayloads(actual, equalTo: expected)
          }
        }
      }
    }
  }

  func test_moveSubrange_RigidDeque() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 5]) { layout in
      withEveryRange("subrange", in: 0 ..< layout.count) { subrange in
        withEvery("target", in: 0 ... layout.count) { target in
          withLifetimeTracking { tracker in
            var expected = Array(0 ..< layout.count)
            expected.removeSubrange(subrange)
            let i = (
              target < subrange.lowerBound ? target
              : target < subrange.upperBound ? subrange.lowerBound
              : target - subrange.count)
            expected.insert(contentsOf: subrange, at: i)

            var actual = RigidDeque(layout: layout) { tracker.instance(for: $0) }
            actual.moveSubrange(subrange, to: target)

            expectIterablePayloads(actual, equalTo: expected)
          }
        }
      }
    }
  }

  func test_reverse_RigidDeque() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 5]) { layout in
      withLifetimeTracking { tracker in
        let expected = (0 ..< layout.count).reversed()
        var actual = RigidDeque(layout: layout) { tracker.instance(for: $0) }
        actual.reverse()

        expectIterablePayloads(actual, equalTo: expected)
      }
    }
  }

  func test_reverseSubrange_RigidDeque() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 5]) { layout in
      withEveryRange("subrange", in: 0 ..< layout.count) { subrange in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< layout.count)
          expected[subrange].reverse()

          var actual = RigidDeque(layout: layout) { tracker.instance(for: $0) }
          actual.reverseSubrange(subrange)

          expectIterablePayloads(actual, equalTo: expected)
        }
      }
    }
  }

  func test_shuffle_RigidDeque() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 5]) { layout in
      withEvery("seed", in: 0 ..< 100) { seed in
        withLifetimeTracking { tracker in
          var rng1 = RepeatableRandomNumberGenerator(seed: seed)
          var expected = Array(0 ..< layout.count)
          expected.shuffle(using: &rng1)

          var rng2 = RepeatableRandomNumberGenerator(seed: seed)
          var actual = RigidDeque(layout: layout) { tracker.instance(for: $0) }
          actual.shuffle(using: &rng2)

          expectIterablePayloads(actual, equalTo: expected)
        }
      }
    }
  }
}
#endif
