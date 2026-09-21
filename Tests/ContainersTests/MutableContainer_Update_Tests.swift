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
import ContainersPreview
import InternalCollectionsUtilities
import BasicContainers
import DequeModule
#endif

#if compiler(>=6.4) && UnstableContainersPreview
#if !COLLECTIONS_SINGLE_MODULE
// For testing piecewise contiguous MutableContainer operations.
// (FIXME: Use something like an extended StaccatoContainer instead.)
struct DequeLayout: Hashable, CustomStringConvertible {
  let capacity: Int
  let startSlot: Int
  let count: Int
  let startValue: Int

  init(capacity: Int, startSlot: Int, count: Int, startValue: Int = 0) {
    self.capacity = capacity
    self.startSlot = startSlot
    self.count = count
    self.startValue = startValue
  }

  var freeCapacity: Int { capacity - count }
  var valueRange: Range<Int> { startValue ..< startValue + count }

  var description: String {
    var result = "DequeLayout(capacity: \(capacity), startSlot: \(startSlot), count: \(count)"
    if count > 0 {
      result += ", startValue: \(startValue)"
    }
    result += ")"
    return result
  }

  var isWrapped: Bool {
    startSlot + count > capacity
  }
}

@available(SwiftStdlib 5.0, *)
internal struct RigidTestData<Element>: ~Copyable {
  var deque: RigidDeque<Element>
  var contents: [Element]

  init(_ deque: consuming RigidDeque<Element>, _ contents: [Element]) {
    self.deque = deque
    self.contents = contents
  }

  mutating func take() -> RigidDeque<Element> {
    exchange(&self.deque, with: .init())
  }

  consuming func consume() -> RigidDeque<Element> {
    exchange(&self.deque, with: .init())
  }
}

extension LifetimeTracker {
  @available(SwiftStdlib 5.0, *)
  func rigidDeque(
    with layout: DequeLayout
  ) -> RigidTestData<LifetimeTracked<Int>> {
    let contents = self.instances(for: layout.valueRange)
    let deque = RigidDeque(layout: layout, contents: contents)
    return RigidTestData(deque, contents)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  init<C: Collection<Element>>(layout: DequeLayout, contents: C) {
    precondition(contents.count == layout.count)
    self.init(
      _capacity: layout.capacity,
      startSlot: layout.startSlot,
      copying: contents)
  }
}
#endif

private func withEveryFullDeque<C: Collection>(
  _ label: String,
  ofCapacities capacities: C,
  startValue: Int = 0,
  file: StaticString = #filePath, line: UInt = #line,
  _ body: (DequeLayout) throws -> Void
) rethrows -> Void where C.Element == Int {
  // Exhaustive tests for all deque layouts of various capacities
  for capacity in capacities {
    for startSlot in 0 ..< capacity {
      let layout = DequeLayout(
        capacity: capacity,
        startSlot: startSlot,
        count: capacity,
        startValue: startValue)
      let entry = TestContext.current.push("\(label): \(layout)", file: file, line: line)
      defer { TestContext.current.pop(entry) }
      try body(layout)
    }
  }
}

@available(SwiftStdlib 6.4, *)
final class MutableContainer_Update_Tests: CollectionTestCase {
  func test_updateSubrange_updatingWith() {
    withEveryFullDeque("layout", ofCapacities: [0, 1, 10]) { layout in
      withEveryRange("subrange", in: 0 ..< layout.count) { subrange in
        withLifetimeTracking { tracker in
          var expected = Array(0 ..< layout.count)
          let replacements1 = layout.count ..< (layout.count + subrange.count)
          expected.replaceSubrange(subrange, with: replacements1)

          var actual = tracker.rigidDeque(with: layout)
          var i = layout.count
          actual.deque.updateSubrange(subrange) { span in
            var items = UniqueArray(copying: tracker.instances(
              count: span.count, generator: { i + $0 }))
            i += span.count
            items.edit { src in
              span._updateAll(moving: &src)
            }
          }
          expectIterablePayloads(actual.deque, equalTo: expected)
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

            var actual = tracker.rigidDeque(with: layout)
            var replacements2 = CustomProducer<LifetimeTracked<Int>, Never>(
              underestimatedCount: 0,
            ) { offset in
              guard offset < end - start else { return nil }
              return tracker.instance(for: layout.count + offset)
            }

            var i = start
            actual.deque.updateElements(after: &i, from: &replacements2)

            expectIterablePayloads(actual.deque, equalTo: expected)
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

              var actual = tracker.rigidDeque(with: layout)
              var replacements2 = CustomCountedProducer<LifetimeTracked<Int>, Never>(
                count: length,
                chunkSize: chunkSize
              ) { offset in
                tracker.instance(for: layout.count + offset)
              }

              var i = start
              actual.deque.updateElements(after: &i, from: &replacements2)

              expectIterablePayloads(actual.deque, equalTo: expected)
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

            var actual = tracker.rigidDeque(with: targetLayout).consume()
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
            var expected = Array(0 ..< targetLayout.count)
            let replacements1 = targetLayout.count ..< (targetLayout.count + subrange.count)
            expected.replaceSubrange(subrange, with: replacements1)

            var actual = tracker.rigidDeque(with: targetLayout).consume()
            var replacements2 = tracker.rigidDeque(with: sourceLayout).consume()
            actual.updateSubrange(subrange, from: replacements2.consumeAll())

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

              var actual = tracker.rigidDeque(with: layout)
              var replacements2 = CustomBorrowingIterator<LifetimeTracked<Int>, Never>(
                underestimatedCount: 0,
                chunkSize: chunkSize
              ) { offset in
                guard offset < end - start else { return nil }
                return tracker.instance(for: layout.count + offset)
              }

              var i = start
              actual.deque.updateElements(after: &i, copying: &replacements2)

              expectIterablePayloads(actual.deque, equalTo: expected)
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

            var actual = tracker.rigidDeque(with: targetLayout).consume()
            let replacements2 = tracker.rigidDeque(with: sourceLayout).consume()
            actual.updateSubrange(subrange, copying: replacements2)

            expectIterablePayloads(actual, equalTo: expected)
          }
        }
      }
    }
  }

}
#endif
