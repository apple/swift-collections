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
import SpanPreview
import InternalCollectionsUtilities
import BasicContainers
import DequeModule
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
final class MutableContainer_Update_Tests: CollectionTestCase {
  func test_updateSubrange_updatingWith() {
    withEveryFullDeque("layout", ofCapacities: [0, 1, 10]) { layout in
      withEveryRange("subrange", in: 0 ..< layout.count) { subrange in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< layout.count)
          let replacements1 = layout.count ..< (layout.count + subrange.count)
          expected.replaceSubrange(subrange, with: replacements1)

          var actual = RigidDeque(layout: layout) { tracker.instance(for: $0) }
          var i = layout.count
          actual.updateSubrange(subrange) { span in
            var items = UniqueArray(copying: tracker.instances(
              count: span.count, generator: { i + $0 }))
            i += span.count
            items.edit { src in
              span._updateAll(moving: &src)
            }
          }
          expectIterablePayloads(actual, equalTo: expected)
        }
      }
    }
  }

  func test_updateElements_after_from_Producer() {
    // Note: We don't test throwing producers, as prematurely terminating
    // producers end up covering the same code paths. (FIXME: Do it anyway)
    withEveryFullDeque("layout", ofCapacities: [0, 1, 10]) { layout in
      withEvery("start", in: 0 ..< layout.count) { start in
        withEvery("length", in: 0 ..< layout.count - start + 2) { length in
          withLifetimeTracking { tracker in
            var expected = Array(0 ..< layout.count)
            let replacements1 = layout.count ..< (layout.count + length)
            let end = Swift.min(start + length, layout.count)
            expected.replaceSubrange(
              start ..< end,
              with: replacements1.prefix(end - start))

            var actual = RigidDeque(layout: layout) { tracker.instance(for: $0) }
            var replacements2 = CustomProducer<LifetimeTracked<Int>, Never>(
              underestimatedCount: 0,
            ) { offset in
              guard offset < end - start else { return nil }
              return tracker.instance(for: layout.count + offset)
            }

            var i = start
            actual.updateElements(after: &i, from: &replacements2)

            expectIterablePayloads(actual, equalTo: expected)
            expectEqual(i, end)
          }
        }
      }
    }
  }

  func test_updateElements_after_from_CountedProducer() {
    withEveryFullDeque("layout", ofCapacities: [0, 1, 10]) { layout in
      withEvery("start", in: 0 ..< layout.count) { start in
        withEvery("length", in: 0 ..< layout.count - start + 2) { length in
          withEvery("chunkSize", in: [1, 2, length] as Set) { chunkSize in
            withLifetimeTracking { tracker in
              var expected = Array(0 ..< layout.count)
              let replacements1 = layout.count ..< (layout.count + length)
              let end = Swift.min(start + length, layout.count)
              expected.replaceSubrange(
                start ..< end,
                with: replacements1.prefix(end - start))

              var actual = RigidDeque(layout: layout) { tracker.instance(for: $0) }
              var replacements2 = CustomCountedProducer<LifetimeTracked<Int>, Never>(
                count: length,
                chunkSize: chunkSize
              ) { offset in
                tracker.instance(for: layout.count + offset)
              }

              var i = start
              actual.updateElements(after: &i, from: &replacements2)

              expectIterablePayloads(actual, equalTo: expected)
              expectEqual(i, end)
            }
          }
        }
      }
    }
  }

  func test_updateSubrange_from_CountedProducer() {
    withEveryFullDeque("targetLayout", ofCapacities: [0, 1, 10]) { targetLayout in
      withEveryRange("subrange", in: 0 ..< targetLayout.count) { subrange in
        withEvery("chunkSize", in: [1, 2, subrange.count] as Set) { chunkSize in
          withLifetimeTracking { tracker in
            var expected = Array(0 ..< targetLayout.count)
            let replacements1 = targetLayout.count ..< (targetLayout.count + subrange.count)
            expected.replaceSubrange(subrange, with: replacements1)

            var actual = RigidDeque(layout: targetLayout) { tracker.instance(for: $0) }
            let replacements2 = CustomCountedProducer<LifetimeTracked<Int>, Never>(
              count: subrange.count,
              chunkSize: chunkSize
            ) { offset in
              tracker.instance(for: targetLayout.count + offset)
            }
            actual.updateSubrange(subrange, from: replacements2)
            expectIterablePayloads(actual, equalTo: expected)
          }
        }
      }
    }
  }

  func test_updateSubrange_from_Drain() {
    withEveryFullDeque("targetLayout", ofCapacities: [0, 1, 10]) { targetLayout in
      withEveryRange("subrange", in: 0 ..< targetLayout.count) { subrange in
        withEveryFullDeque(
          "sourceLayout",
          ofCapacities: [subrange.count],
          startValue: targetLayout.count
        ) { sourceLayout in
          withLifetimeTracking { tracker in
            var expected = Array(targetLayout.valueRange)
            expected.replaceSubrange(subrange, with: sourceLayout.valueRange)

            var actual = RigidDeque(layout: targetLayout) { tracker.instance(for: $0) }
            var replacements = RigidDeque(layout: sourceLayout) {
              tracker.instance(for: $0)
            }
            actual.updateSubrange(subrange, from: replacements.consumeAll())

            expectIterablePayloads(actual, equalTo: expected)
          }
        }
      }
    }
  }

  func test_updateElements_after_copying_BorrowingIteratorProtocol() {
    // Note: We don't test throwing producers, as prematurely terminating
    // producers end up covering the same code paths. (FIXME: Do it anyway)
    withEveryFullDeque("layout", ofCapacities: [0, 1, 10]) { layout in
      withEvery("start", in: 0 ..< layout.count) { start in
        withEvery("length", in: 0 ..< layout.count - start + 2) { length in
          withEvery("chunkSize", in: [1, 2, length] as Set) { chunkSize in
            withLifetimeTracking { tracker in
              var expected = Array(0 ..< layout.count)
              let replacements1 = layout.count ..< (layout.count + length)
              let end = Swift.min(start + length, layout.count)
              expected.replaceSubrange(
                start ..< end,
                with: replacements1.prefix(end - start))

              var actual = RigidDeque(layout: layout) { tracker.instance(for: $0) }
              var replacements2 = CustomBorrowingIterator<LifetimeTracked<Int>, Never>(
                underestimatedCount: 0,
                chunkSize: chunkSize
              ) { offset in
                guard offset < end - start else { return nil }
                return tracker.instance(for: layout.count + offset)
              }

              var i = start
              actual.updateElements(after: &i, copying: &replacements2)

              expectIterablePayloads(actual, equalTo: expected)
              expectEqual(i, end)
            }
          }
        }
      }
    }
  }

  func test_updateSubrange_copying_Container() {
    withEveryFullDeque("targetLayout", ofCapacities: [0, 1, 10]) { targetLayout in
      withEveryRange("subrange", in: 0 ..< targetLayout.count) { subrange in
        withEveryFullDeque(
          "sourceLayout",
          ofCapacities: [subrange.count],
          startValue: targetLayout.count
        ) { sourceLayout in
          withLifetimeTracking { tracker in
            var expected = Array(0 ..< targetLayout.count)
            let replacements1 = targetLayout.count ..< (targetLayout.count + subrange.count)
            expected.replaceSubrange(subrange, with: replacements1)

            var actual = RigidDeque(layout: targetLayout) { tracker.instance(for: $0) }
            let replacements2 = RigidDeque(layout: sourceLayout) {
              tracker.instance(for: $0)
            }
            actual.updateSubrange(subrange, copying: replacements2)

            expectIterablePayloads(actual, equalTo: expected)
          }
        }
      }
    }
  }

}
#endif
