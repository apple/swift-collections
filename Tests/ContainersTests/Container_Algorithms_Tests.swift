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
final class Container_Algorithms_Tests: CollectionTestCase {
  func test_filter_RigidArray_simple() {
    let count = 100
    precondition(count.isMultiple(of: 10)) // Assumed below
    withLifetimeTracking { tracker in
      let items = RigidArray(copying: tracker.instances(for: 0 ..< count))
      let evens = items.filter { $0.payload.isMultiple(of: 2) }

      expectIterablePayloads(evens, equalTo: (0 ..< count / 2).map { 2 * $0 })
    }
  }

  func test_filter_RigidArray_runs() {
    let count = 100
    precondition(count.isMultiple(of: 10)) // Assumed below
    withLifetimeTracking { tracker in
      let items = RigidArray(copying: tracker.instances(for: 0 ..< count))

      let runs = items.filter { !$0.payload.isMultiple(of: 5) }
      let expectedRuns = (0 ..< count).filter { !$0.isMultiple(of: 5) }
      expectIterablePayloads(runs, equalTo: expectedRuns)

      // Check that container filters can return larger chunks
      expectEqualElements(runs._spanCounts(), repeatElement(4, count: count / 5))
    }
  }

  func test_filter_RigidArray_slices() {
    // Note: this dispatches to Iterable.filter, not ContainerIterator.filter.
    // FIXME: Add a specialized `filter` on Span.BorrowingIterator.
    withEvery("count", in: [0, 1, 5, 10, 20]) { count in
      withLifetimeTracking { tracker in
        let items = tracker.rigidArray(layout: ArrayLayout(capacity: count, count: count))
        withEveryRange("subrange", in: 0 ..< count) { subrange in
          let runs = items.makeBorrowingIterator(in: subrange).filter {
            !$0.payload.isMultiple(of: 3)
          }

          let expectedRuns = subrange.filter { !$0.isMultiple(of: 3) }
          expectBorrowingIteratorPayloads(runs, equalTo: expectedRuns)
        }
      }
    }
  }

  func test_filter_RigidDeque_slices() {
    // Note: this dispatches to Iterable.filter, not ContainerIterator.filter.
    withEveryFullDeque("layout", ofCapacities: [0, 1, 5, 10, 20]) { layout in
      withLifetimeTracking { tracker in
        let items = RigidDeque(layout: layout) { tracker.instance(for: $0) }
        withEveryRange("subrange", in: 0 ..< layout.count) { subrange in
          let runs = items.makeBorrowingIterator(in: subrange).filter {
            !$0.payload.isMultiple(of: 3)
          }

          let expectedRuns = subrange.filter { !$0.isMultiple(of: 3) }
          expectBorrowingIteratorPayloads(runs, equalTo: expectedRuns)
        }
      }
    }
  }
}

#endif
