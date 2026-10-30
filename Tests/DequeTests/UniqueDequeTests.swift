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
import DequeModule
import BasicContainers
#endif
import ContainersPreview

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
internal func expectUniqueDequeContents<
  Element: Equatable,
  C2: Collection<Element>,
>(
  _ left: borrowing UniqueDeque<Element>,
  equalTo right: C2,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  expectUniqueDequeContents(
    left,
    equivalentTo: right,
    by: ==,
    message(), trapping: trapping, file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
internal func expectUniqueDequeContents<
  E1,
  C2: Collection,
>(
  _ left: borrowing UniqueDeque<E1>,
  equivalentTo right: C2,
  by areEquivalent: (borrowing E1, C2.Element) -> Bool,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  expectUniqueDequeContents(
    left,
    equivalentTo: right,
    by: areEquivalent,
    printer: { "\($0)" },
    message(),
    file: file,
    line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
internal func expectUniqueDequeContents<
  E1: ~Copyable,
  C2: Collection,
>(
  _ left: borrowing UniqueDeque<E1>,
  equivalentTo right: C2,
  by areEquivalent: (borrowing E1, C2.Element) -> Bool,
  printer: (borrowing E1) -> String,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
#if compiler(>=6.4) && UnstableContainersPreview
  if #available(SwiftStdlib 6.4, *) {
    expectIterableContents(
      left,
      equivalentTo: right,
      by: areEquivalent,
      printer: printer,
      message(),
      trapping: trapping,
      file: file,
      line: line)
    return
  }
#endif
  var c = 0
  var j = right.startIndex
  for i in 0 ..< left.count {
    expectEquivalent(
      left[i],
      right[j],
      by: areEquivalent,
      printer: printer,
      "offset: \(c) \(message())",
      trapping: trapping,
      file: file, line: line)
    right.formIndex(after: &j)
    c += 1
  }
}

final class UniqueDequeTests: CollectionTestCase {
  struct TestError: Error, Equatable {
    let value: Int
    init(_ value: Int) { self.value = value }
  }

#if compiler(>=6.4) && UnstableContainersPreview
  @available(SwiftStdlib 6.4, *)
  func test_validate_Container() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        let data = tracker.uniqueDeque(with: layout)
        expectEqual(tracker.instances, layout.count)
        checkContainer(data.deque, expectedContents: data.contents)
      }
    }
  }

  @available(SwiftStdlib 6.4, *)
  func test_validate_DrainableContainer() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      checkDrainableContainer(count: layout.count) { contents in
        UniqueDeque(layout: layout) { contents[$0] }
      }
    }
  }
#endif

  func test_basicProperties() {
    var deque = UniqueDeque<Int>()

    // Empty deque
    expectEqual(deque.isEmpty, true)
    expectEqual(deque._isFull, true)
    expectEqual(deque.count, 0)
    expectEqual(deque.capacity, 0)
    expectEqual(deque.freeCapacity, 0)
    expectEqual(deque.startIndex, 0)
    expectEqual(deque.endIndex, 0)
    expectEqual(deque.indices, 0 ..< 0)

    deque.append(1)
    deque.append(2)
    deque.append(3)

    expectEqual(deque.isEmpty, false)
    expectEqual(deque._isFull, true)
    expectEqual(deque.count, 3)
    expectEqual(deque.capacity, 3)
    expectEqual(deque.freeCapacity, 0)
    expectEqual(deque.startIndex, 0)
    expectEqual(deque.endIndex, 3)
    expectEqual(deque.indices, 0 ..< 3)

    for i in 4...10 {
      deque.prepend(i)
    }

    expectEqual(deque.isEmpty, false)
    expectEqual(deque.count, 10)
    expectEqual(deque.capacity, 12)
    expectEqual(deque.freeCapacity, 2)
    expectEqual(deque.indices, 0 ..< 10)
  }

  func test_subscriptBorrow() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        let data = tracker.uniqueDeque(with: layout)
        withEvery("i", in: 0 ..< layout.count) { i in
          expectEqual(data.deque[i], data.contents[i])
        }
      }
    }
  }

  func test_subscriptMutate() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("i", in: 0 ..< layout.count) { i in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)
          let new = tracker.instance(for: 100)
          data.deque[i] = new
          data.contents[i] = new
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

  func test_swapAt() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      withEvery("i", in: 0 ..< layout.count) { i in
        withEvery("j", in: 0 ..< layout.count) { j in
          withLifetimeTracking { tracker in
            var data = tracker.uniqueDeque(with: layout)
            data.deque.swapAt(i, j)
            data.contents.swapAt(i, j)
            expectUniqueDequeContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }

  func test_replace_removing_addingCount() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("from", in: 0 ... layout.count) { from in
        withEvery("to", in: from ... layout.count) { to in
          withEvery("newCount", in: 0 ... 4) { newCount in
            withLifetimeTracking { tracker in
              var data = tracker.uniqueDeque(with: layout)
              let newItems = tracker.instances(for: 100 ..< 100 + newCount)
              var src = newItems.makeIterator()
              data.deque.replaceSubrange(from ..< to, addingCount: newCount) { target in
                while !target.isFull, let item = src.next() {
                  target.append(item)
                }
              }
              data.contents.replaceSubrange(from ..< to, with: newItems)
              expectEqual(data.deque.count, data.contents.count)
              expectUniqueDequeContents(data.deque, equalTo: data.contents)
            }
          }
        }
      }
    }
  }

#if compiler(>=6.4) && UnstableContainersPreview
  @available(SwiftStdlib 6.4, *)
  func test_prepend_Producer_preserves_order() {
    // Regression test for https://github.com/apple/swift-collections/issues/763:
    // prepend(from:) was inserting each batch at index 0, reversing batch order.
    withEvery("existingCount", in: [0, 1, 3]) { existingCount in
      withEvery("newCount", in: [0, 1, 7, 8, 9, 20]) { newCount in
        withLifetimeTracking { tracker in
          var deque = UniqueDeque<LifetimeTracked<Int>>()
          let existing = tracker.instances(for: 1000 ..< 1000 + existingCount)
          for item in existing { deque.append(item) }

          var items = tracker.instances(for: 0 ..< newCount)
          let producer = CustomProducer<LifetimeTracked<Int>, Never> { _ in
            guard !items.isEmpty else { return nil }
            return items.removeFirst()
          }
          deque.prepend(from: producer)

          let expected = tracker.instances(for: 0 ..< newCount)
            + tracker.instances(for: 1000 ..< 1000 + existingCount)
          expectUniqueDequeContents(deque, equalTo: expected)
        }
      }
    }
  }
#endif

  func test_growth() {
    let expectedCapacities = [
      0, 1, 2, 3, 5, 8, 12, 18, 27, 41, 62, 93, 140, 210, 315
    ]
    var actualCapacities: Set<Int> = []
    var deque = UniqueDeque<Int>()
    for i in 0 ..< 256 {
      actualCapacities.insert(deque.capacity)
      deque.append(i)
    }
    expectEqualElements(actualCapacities.sorted(), expectedCapacities)
  }

  func test_prepend() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        var data = tracker.uniqueDeque(with: layout)
        let extra = tracker.instance(for: layout.count)
        data.contents.insert(extra, at: 0)
        data.deque.prepend(extra)
        expectUniqueDequeContents(data.deque, equalTo: data.contents)
      }
    }
  }

  func test_append() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        var data = tracker.uniqueDeque(with: layout)
        let extra = tracker.instance(for: layout.count)
        data.contents.append(extra)
        data.deque.append(extra)
        expectUniqueDequeContents(data.deque, equalTo: data.contents)
      }
    }
  }

  func test_prepend_initializingWith_full() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)

          let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)

          data.contents.insert(contentsOf: extras, at: 0)

          var i = 0
          data.deque.prepend(addingCount: prependCount) { target in
            while !target.isFull {
              target.append(extras[i])
              i += 1
            }
          }

          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

  func test_append_initializingWith_full() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)

          let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)

          data.contents.append(contentsOf: extras)

          var i = 0
          data.deque.append(addingCount: prependCount) { target in
            while !target.isFull {
              target.append(extras[i])
              i += 1
            }
          }

          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

  func test_prepend_initializingWith_partial() {
    withEveryDeque("layout", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)

          let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)

          data.contents.insert(contentsOf: extras, at: 0)

          var i = 0
          data.deque.prepend(addingCount: layout.freeCapacity) { target in
            while !target.isFull, i < prependCount {
              target.append(extras[i])
              i += 1
            }
          }
          expectEqual(i, extras.count)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

  func test_append_initializingWith_partial() {
    withEveryDeque("layout", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)

          let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)

          data.contents.append(contentsOf: extras)

          var i = 0
          data.deque.append(addingCount: layout.freeCapacity) { target in
            while !target.isFull, i < prependCount {
              target.append(extras[i])
              i += 1
            }
          }
          expectEqual(i, extras.count)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

  func test_prepend_initializingWith_failing() {
    withEveryDeque("layout", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      if layout.freeCapacity == 0 { return }
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)

          let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)

          data.contents.insert(contentsOf: extras, at: 0)

          expectThrows { () throws(TestError) in
            var i = 0
            try data.deque.prepend(
              addingCount: layout.freeCapacity
            ) { target throws(TestError) in
              while !target.isFull, i < prependCount {
                target.append(extras[i])
                i += 1
              }
              if i == prependCount {
                throw TestError(42)
              }
            }
          }
          errorHandler: { error in
            expectEqual(error.value, 42)
          }
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }


  func test_append_initializingWith_failing() {
    withEveryDeque("layout", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      if layout.freeCapacity == 0 { return }
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)

          let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)

          data.contents.append(contentsOf: extras)

          expectThrows { () throws(TestError) in
            var i = 0
            try data.deque.append(
              addingCount: layout.freeCapacity
            ) { target throws(TestError) in
              while !target.isFull, i < prependCount {
                target.append(extras[i])
                i += 1
              }
              if i == prependCount {
                throw TestError(42)
              }
            }
          }
          errorHandler: { error in
            expectEqual(error.value, 42)
          }
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

#if compiler(>=6.4) && UnstableContainersPreview
  @available(SwiftStdlib 6.4, *)
  func test_prepend_Producer_full() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      withEvery("producerSize", in: 0 ..< 6) { producerSize in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)

          var extras = tracker.instances(for: 0 ..< producerSize)

          data.contents.insert(contentsOf: extras, at: 0)

          var producer = CustomProducer<LifetimeTracked<Int>, Never> { offset in
            guard !extras.isEmpty else { return nil }
            return extras.removeFirst()
          }

          data.deque.prepend(addingCount: extras.count, from: &producer)
          expectEqual(extras.count, 0)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
#endif

#if compiler(>=6.4) && UnstableContainersPreview
  @available(SwiftStdlib 6.4, *)
  func test_append_Producer_full() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      withEvery("producerSize", in: 0 ..< 6) { producerSize in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)

          var extras = tracker.instances(for: 0 ..< producerSize)

          data.contents.append(contentsOf: extras)

          var producer = CustomProducer<LifetimeTracked<Int>, Never> { offset in
            guard !extras.isEmpty else { return nil }
            return extras.removeFirst()
          }

          data.deque.append(addingCount: extras.count, from: &producer)
          expectEqual(extras.count, 0)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
#endif

#if compiler(>=6.4) && UnstableContainersPreview
  @available(SwiftStdlib 6.4, *)
  func test_prepend_Producer_failing() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      guard layout.freeCapacity > 0 else { return }
      withEvery("producerSize", in: 0 ..< 6) { producerSize in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)

          var extras = tracker.instances(for: 0 ..< producerSize)

          data.contents.insert(contentsOf: extras, at: 0)

          var producer = CustomProducer<LifetimeTracked<Int>, TestError> { offset throws(TestError) in
            guard !extras.isEmpty else { throw TestError(23) }
            return extras.removeFirst()
          }
          expectThrows { () throws(TestError) in
            try data.deque.prepend(addingCount: extras.count + 1, from: &producer)
          }
          errorHandler: { error in
            expectEqual(error.value, 23)
          }
          expectEqual(extras.count, 0)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
#endif

#if compiler(>=6.4) && UnstableContainersPreview
  @available(SwiftStdlib 6.4, *)
  func test_append_Producer_failing() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      guard layout.freeCapacity > 0 else { return }
      withEvery("producerSize", in: 0 ..< 6) { producerSize in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)

          var extras = tracker.instances(for: 0 ..< producerSize)

          data.contents.append(contentsOf: extras)

          var producer = CustomProducer<LifetimeTracked<Int>, TestError> { offset throws(TestError) in
            guard !extras.isEmpty else { throw TestError(23) }
            return extras.removeFirst()
          }

          expectThrows { () throws(TestError) in
            try data.deque.append(addingCount: extras.count + 1, from: &producer)
          }
          errorHandler: { error in
            expectEqual(error.value, 23)
          }
          expectEqual(extras.count, 0)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
#endif

  func test_prepend_MinimalSequence() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withEvery("underestimatedCount", in: [UnderestimatedCountBehavior.precise, .half, .value(min(1, c))]) { underestimatedCount in
          withLifetimeTracking { tracker in
            var data = tracker.uniqueDeque(with: layout)
            let extras = tracker.instances(for: layout.count ..< layout.count + c)
            let sequence = MinimalSequence(elements: extras, underestimatedCount: underestimatedCount)
            data.contents.insert(contentsOf: extras, at: 0)
            data.deque.prepend(copying: sequence)
            expectUniqueDequeContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }

  func test_append_MinimalSequence() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withEvery("underestimatedCount", in: [UnderestimatedCountBehavior.precise, .half, .value(min(1, c))]) { underestimatedCount in
          withLifetimeTracking { tracker in
            var data = tracker.uniqueDeque(with: layout)
            let extras = tracker.instances(for: layout.count ..< layout.count + c)
            let sequence = MinimalSequence(elements: extras, underestimatedCount: underestimatedCount)
            data.contents.append(contentsOf: extras)
            data.deque.append(copying: sequence)
            expectUniqueDequeContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }

  func test_prepend_MinimalCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)
          let extra = tracker.instances(for: layout.count ..< layout.count + c)
          let minimal = MinimalCollection(extra)
          data.contents.insert(contentsOf: extra, at: 0)
          data.deque.prepend(copying: minimal)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

  func test_append_MinimalCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)
          let extra = tracker.instances(for: layout.count ..< layout.count + c)
          let minimal = MinimalCollection(extra)
          data.contents.append(contentsOf: extra)
          data.deque.append(copying: minimal)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

  func test_prepend_ContiguousArray_asCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)
          let extraRange = layout.count ..< layout.count + c
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          data.contents.insert(contentsOf: extra, at: 0)
          data.deque.prepend(copying: extra)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

  func test_append_ContiguousArray_asCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)
          let extraRange = layout.count ..< layout.count + c
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          data.contents.append(contentsOf: extra)
          data.deque.append(copying: extra)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

  func test_prepend_ContiguousArray_asSequence() {
    // This calls the Sequence-based `Deque.prepend` overload, even if
    // `elements` happens to be of a Collection type.
    func prependSequence<S: Sequence>(
      contentsOf elements: S,
      to deque: inout UniqueDeque<S.Element>
    ) {
      deque.prepend(copying: elements)
    }

    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)
          let extraRange = layout.count ..< layout.count + c
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          data.contents.insert(contentsOf: extra, at: 0)
          prependSequence(contentsOf: extra, to: &data.deque)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

  func test_append_ContiguousArray_asSequence() {
    // This calls the Sequence-based `Deque.append` overload, even if
    // `elements` happens to be of a Collection type.
    func appendSequence<S: Sequence>(
      contentsOf elements: S,
      to deque: inout UniqueDeque<S.Element>
    ) {
      deque.append(copying: elements)
    }

    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.uniqueDeque(with: layout)
          let extraRange = layout.count ..< layout.count + c
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          data.contents.append(contentsOf: extra)
          appendSequence(contentsOf: extra, to: &data.deque)
          expectUniqueDequeContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }

#if compiler(>=6.4) && UnstableContainersPreview
  @available(SwiftStdlib 6.4, *)
  func test_prepend_copying_StaccatoContainer() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("count", in: 0 ... 15) { count in
        withEvery("spanCounts", in: [
          [1],
          [1, 2, 3],
          [3, 5, 7],
          [Int.max],
        ] as [[Int]]) { spanCounts in
          var expected = Array(layout.valueRange)
          expected.insert(contentsOf: layout.count ..< layout.count + count, at: 0)

          var actual = UniqueDeque(layout: layout)
          let additions = StaccatoContainer(count: count, spanCounts: spanCounts) {
            layout.count + $0
          }
          actual.prepend(copying: additions)

          expectUniqueDequeContents(actual, equalTo: expected)
        }
      }
    }
  }
#endif

#if compiler(>=6.4) && UnstableContainersPreview
  @available(SwiftStdlib 6.4, *)
  func test_append_copying_StaccatoContainer() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("count", in: 0 ... 15) { count in
        withEvery("spanCounts", in: [
          [1],
          [1, 2, 3],
          [3, 5, 7],
          [Int.max],
        ] as [[Int]]) { spanCounts in
          var expected = Array(layout.valueRange)
          expected.append(contentsOf: layout.count ..< layout.count + count)

          var actual = UniqueDeque(layout: layout)
          let additions = StaccatoContainer(count: count, spanCounts: spanCounts) {
            layout.count + $0
          }
          actual.append(copying: additions)

          expectUniqueDequeContents(actual, equalTo: expected)
        }
      }
    }
  }
#endif

}
