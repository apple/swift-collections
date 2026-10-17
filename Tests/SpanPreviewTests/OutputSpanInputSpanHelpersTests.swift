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

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import SpanPreview
#endif

#if UnstableContainersPreview
final class OutputSpanInputSpanHelpersTests: CollectionTestCase {
  struct TestError: Error, Equatable {}

  func withOutputSpan(
    capacity: Int,
    count: Int,
    tracker: LifetimeTracker,
    _ body: (inout OutputSpan<LifetimeTracked<Int>>) -> Void
  ) {
    let buffer: UnsafeMutableBufferPointer<LifetimeTracked<Int>>
    unsafe buffer = .allocate(capacity: capacity)
    for i in 0 ..< count {
      unsafe buffer.initializeElement(at: i, to: tracker.instance(for: i))
    }
    var span = unsafe OutputSpan(buffer: buffer, initializedCount: count)
    body(&span)
    _ = consume span
    unsafe buffer.deallocate()
  }

  func test_consumeAll() {
    for capacity in [0, 1, 5, 10] {
      for count in 0 ... capacity {
        withLifetimeTracking {
          withOutputSpan(
            capacity: capacity, count: count, tracker: $0
          ) {
            $0._consumeAll { expectEqual($0.count, count) }
            expectTrue($0.isEmpty)
          }
          expectEqual($0.instances, 0)
        }
      }
    }
  }

  func test_consumeAll_throwingConsumer() {
    for capacity in [1, 5, 10] {
      for count in 1 ... capacity {
        withLifetimeTracking {
          withOutputSpan(
            capacity: capacity, count: count, tracker: $0
          ) {
            do throws(TestError) {
              try $0._consumeAll {
                span throws(TestError) in
                expectEqual(span.count, count)
                throw TestError()
              }
              expectFailure("Consumer should have thrown")
            } catch {
              expectEqual(error, TestError())
            }
            expectEqual(
              $0.count, 0,
              "OutputSpan still claims ownership of destroyed items"
            )
            // unsafe $0.withUnsafeMutableBufferPointer { $1 = 0 }
          }
          expectEqual(
            $0.instances, 0,
            "Unconsumed items should be destroyed along with the InputSpan"
          )
        }
      }
    }
  }
}
#endif
