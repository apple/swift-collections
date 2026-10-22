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
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
final class ProducerTests: CollectionTestCase {
  /// A producer over `0 ..< count`.
  @_lifetime(immortal)
  func range(_ count: Int) -> UnfoldProducer<Int, Never, Int> {
    producer(state: 0) { (state: inout Int) -> Int? in
      guard state < count else { return nil }
      defer { state += 1 }
      return state
    }
  }

  /// Generate into a span of the given capacity, returning the generated items
  /// and the value returned by `generate(into:)`.
  func generate<P: Producer<Int, Never> & ~Copyable & ~Escapable>(
    _ producer: inout P, capacity: Int
  ) -> (returned: Int, items: [Int]) {
    var items: [Int] = []
    let returned = withUnsafeTemporaryAllocation(
      of: Int.self, capacity: capacity
    ) { buffer in
      var span = unsafe OutputSpan(buffer: buffer, initializedCount: 0)
      let returned = producer.generate(into: &span)
      span._consumeAll { src in
        while let item = src.popFirst() { items.append(item) }
      }
      return returned
    }
    return (returned, items)
  }

  func test_map_generate_fills_target() {
    withEvery("capacity", in: [1, 7, 8, 9, 16, 33, 100, 150]) { capacity in
      var p = range(100).map { $0 * 2 }
      let (returned, items) = generate(&p, capacity: capacity)
      let expected = Swift.min(capacity, 100)
      expectEqual(returned, expected)
      expectEqualElements(items, (0 ..< expected).map { $0 * 2 })
    }
  }

  func test_filter_generate_fills_target() {
    withEvery("capacity", in: [1, 7, 8, 9, 16, 33, 50, 80]) { capacity in
      var p = range(100).filter { $0 % 2 == 0 }
      let (returned, items) = generate(&p, capacity: capacity)
      let expected = Swift.min(capacity, 50)
      expectEqual(returned, expected)
      expectEqualElements(items, (0 ..< expected).map { $0 * 2 })
    }
  }

  func test_filter_underestimatedCount() {
    let p = range(100).filter { $0 % 2 == 0 }
    expectEqual(p.underestimatedCount, 0)
  }

  func test_reduce_over_map_and_filter() {
    expectEqual(range(100).map { $0 }.reduce(0, +), 4950)
    expectEqual(range(100).filter { $0 % 2 == 0 }.reduce(0, +), 2450)
  }

  func test_default_skip_by_does_not_overshoot() {
    withEvery("n", in: [1, 5, 8, 10, 16, 40, 100, 150]) { n in
      var p = range(100).filter { $0 % 2 == 0 }
      var remaining = n
      p.skip(by: &remaining)
      let skipped = Swift.min(n, 50)
      expectEqual(remaining, n - skipped)
      expectEqual(p.next(), skipped < 50 ? skipped * 2 : nil)
    }
  }
}

#endif
