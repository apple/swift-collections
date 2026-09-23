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
import ContainersPreview
import InternalCollectionsUtilities
import BasicContainers
import SpanPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
final class MutableSpanUpdateTests: CollectionTestCase {
  func testMutableSpan_edit() {
    withEvery("c", in: [0, 1, 10]) { c in
      withEvery("suffix", in: 0 ..< c) { suffix in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< c)
          expected.removeLast(suffix)
          expected.append(contentsOf: c ..< c + suffix)

          var actual = tracker.structInstances(count: c, generator: { $0 })
          expectEqual(tracker.instances, c)
          var span = actual.mutableSpan
          span._edit { out in
            out.removeLast(suffix)
            expectEqual(tracker.instances, c - suffix)
            for i in 0 ..< suffix {
              out.append(tracker.structInstance(for: c + i))
            }
          }
          expectEqual(tracker.instances, c)
          expectIterablePayloads(actual, equalTo: expected)
        }
      }
    }
  }

  func testMutableSpan_updateSubrange_moving_OutputSpan() {
    withEvery("c", in: [0, 1, 10]) { c in
      withEveryRange("subrange", in: 0 ..< c) { subrange in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< c)
          let replacements1 = c ..< (c + subrange.count)
          expected.replaceSubrange(subrange, with: replacements1)

          var actual = tracker.structInstances(count: c, generator: { $0 })
          var replacements2 = tracker.structInstances(
            count: subrange.count, generator: { c + $0 })
          replacements2.edit { source in
            var span = actual.mutableSpan
            span._updateSubrange(subrange, moving: &source)
          }

          expectTrue(replacements2.isEmpty)
          expectEqual(actual.count, expected.count)
          expectIterablePayloads(actual, equalTo: expected)
        }
      }
    }
  }

#if UnstableContainersPreview
  func testMutableSpan_updateSubrange_moving_InputSpan() {
    withEvery("c", in: [0, 1, 10]) { c in
      withEveryRange("subrange", in: 0 ..< c) { subrange in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< c)
          let replacements1 = c ..< (c + subrange.count)
          expected.replaceSubrange(subrange, with: replacements1)

          var actual = tracker.structInstances(count: c, generator: { $0 })
          var replacements2 = tracker.structInstances(
            count: subrange.count, generator: { c + $0 })
          replacements2.edit { source in
            source._consumeAll { source in
              var span = actual.mutableSpan
              span._updateSubrange(subrange, moving: &source)
            }
          }

          expectTrue(replacements2.isEmpty)
          expectEqual(actual.count, expected.count)
          expectIterablePayloads(actual, equalTo: expected)
        }
      }
    }
  }
#endif

  func testMutableSpan_updateAll_moving_OutputSpan() {
    withEvery("c", in: 0 ..< 10) { c in
      withLifetimeTracking { tracker in
        let expected = c ..< 2 * c

        var actual = tracker.structInstances(count: c, generator: { $0 })
        var replacements2 = tracker.structInstances(
          count: c, generator: { c + $0 })
        replacements2.edit { source in
          var span = actual.mutableSpan
          span._updateAll(moving: &source)
        }

        expectTrue(replacements2.isEmpty)
        expectEqual(actual.count, expected.count)
        expectIterablePayloads(actual, equalTo: expected)
      }
    }
  }

#if UnstableContainersPreview
  func testMutableSpan_updateAll_moving_InputSpan() {
    withEvery("c", in: 0 ..< 10) { c in
      withLifetimeTracking { tracker in
        let expected = c ..< 2 * c

        var actual = tracker.structInstances(count: c, generator: { $0 })
        var replacements2 = tracker.structInstances(
          count: c, generator: { c + $0 })
        replacements2.edit { source in
          source._consumeAll { source in
            var span = actual.mutableSpan
            span._updateAll(moving: &source)
          }
        }

        expectTrue(replacements2.isEmpty)
        expectEqual(actual.count, expected.count)
        expectIterablePayloads(actual, equalTo: expected)
      }
    }
  }
#endif

  func testMutableSpan_updateSubrange_copying_Span() {
    withEvery("c", in: [0, 1, 10]) { c in
      withEveryRange("subrange", in: 0 ..< c) { subrange in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< c)
          let replacements1 = c ..< (c + subrange.count)
          expected.replaceSubrange(subrange, with: replacements1)

          var actual = RigidArray(copying: tracker.instances(count: c, generator: { $0 }))
          let replacements2 = RigidArray(copying: tracker.instances(
            count: subrange.count, generator: { c + $0 }))
          var span = actual.mutableSpan
          span._updateSubrange(subrange, copying: replacements2.span)

          expectEqual(replacements2.count, subrange.count)
          expectEqual(actual.count, expected.count)
          expectIterablePayloads(actual, equalTo: expected)
        }
      }
    }
  }

  func testMutableSpan_updateAll_copying_Span() {
    withEvery("c", in: 0 ..< 10) { c in
      withLifetimeTracking { tracker in
        let expected = c ..< 2 * c

        var actual = RigidArray(copying: tracker.instances(count: c, generator: { $0 }))
        let replacements2 = RigidArray(copying: tracker.instances(count: c, generator: { c + $0 }))

        var span = actual.mutableSpan
        span._updateAll(copying: replacements2.span)

        expectEqual(replacements2.count, c)
        expectEqual(actual.count, expected.count)
        expectIterablePayloads(actual, equalTo: expected)
      }
    }
  }
}
#endif
