//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import SpanPreview
#endif

#if UnstableContainersPreview
final class InputSpanTests: CollectionTestCase {
  // FIXME
  func test_dummy() {

  }

  func withInputSpan(
    capacity: Int,
    count: Int,
    tracker: LifetimeTracker,
    _ body: (inout InputSpan<LifetimeTracked<Int>>) -> Void
  ) {
    let buffer = UnsafeMutableBufferPointer<LifetimeTracked<Int>>
      .allocate(capacity: capacity)
    for i in 0 ..< count {
      unsafe buffer.initializeElement(
        at: capacity - count + i, to: tracker.instance(for: i))
    }
    var span = unsafe InputSpan(buffer: buffer, initializedCount: count)
    body(&span)
    _ = consume span
    unsafe buffer.deallocate()
  }

  func test_removeAll() {
    for capacity in [0, 1, 5, 10] {
      for count in 0 ... capacity {
        withLifetimeTracking { tracker in
          withInputSpan(
            capacity: capacity, count: count, tracker: tracker
          ) { span in
            span.removeAll()
            expectTrue(span.isEmpty)
            expectEqual(tracker.instances, 0)
          }
        }
      }
    }
  }
}
#endif
