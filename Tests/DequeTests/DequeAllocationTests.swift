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
@_spi(Testing) import Collections
#else
import _CollectionsTestSupport
@_spi(Testing) import DequeModule
#endif

/// Clear box tests for `Deque`'s storage allocation behavior, observed through
/// the `_capacity` testing SPI.
final class DequeAllocationTests: CollectionTestCase {
  enum SingleInsertion: CaseIterable {
    case append
    case prepend
    case insertInMiddle

    func apply(_ item: Int, to deque: inout Deque<Int>, model: inout [Int]) {
      switch self {
      case .append:
        deque.append(item)
        model.append(item)
      case .prepend:
        deque.prepend(item)
        model.insert(item, at: 0)
      case .insertInMiddle:
        deque.insert(item, at: deque.count / 2)
        model.insert(item, at: model.count / 2)
      }
    }
  }

  enum BulkInsertion: CaseIterable {
    case appendContiguousArray
    case appendCollection
    case appendSequence
    case appendSequenceWithoutUnderestimatedCount
    case prependContiguousArray
    case prependCollection
    case prependSequence
    case insertCollectionInMiddle
    case replaceEmptySubrangeInMiddle

    func apply(_ items: [Int], to deque: inout Deque<Int>, model: inout [Int]) {
      switch self {
      case .appendContiguousArray:
        deque.append(contentsOf: ContiguousArray(items))
        model.append(contentsOf: items)
      case .appendCollection:
        deque.append(contentsOf: MinimalCollection(items))
        model.append(contentsOf: items)
      case .appendSequence:
        deque.append(
          contentsOf: MinimalSequence(elements: items, underestimatedCount: .precise))
        model.append(contentsOf: items)
      case .appendSequenceWithoutUnderestimatedCount:
        deque.append(contentsOf: MinimalSequence(elements: items))
        model.append(contentsOf: items)
      case .prependContiguousArray:
        deque.prepend(contentsOf: ContiguousArray(items))
        model.insert(contentsOf: items, at: 0)
      case .prependCollection:
        deque.prepend(contentsOf: MinimalCollection(items))
        model.insert(contentsOf: items, at: 0)
      case .prependSequence:
        deque.prepend(
          contentsOf: MinimalSequence(elements: items, underestimatedCount: .precise))
        model.insert(contentsOf: items, at: 0)
      case .insertCollectionInMiddle:
        deque.insert(contentsOf: MinimalCollection(items), at: deque.count / 2)
        model.insert(contentsOf: items, at: model.count / 2)
      case .replaceEmptySubrangeInMiddle:
        let i = deque.count / 2
        deque.replaceSubrange(i ..< i, with: MinimalCollection(items))
        model.replaceSubrange(i ..< i, with: items)
      }
    }
  }

  func test_initializers_allocateExactCapacity() {
    withEvery("count", in: [0, 1, 2, 10, 100]) { count in
      expectEqual(Deque<Int>(minimumCapacity: count)._capacity, count)
      expectEqual(Deque(0 ..< count)._capacity, count)
      expectEqual(Deque(MinimalCollection(0 ..< count))._capacity, count)
      expectEqual(
        Deque(MinimalSequence(elements: 0 ..< count, underestimatedCount: .precise))._capacity,
        count)
      expectEqual(Deque(repeating: 42, count: count)._capacity, count)
    }
  }

  func test_singleInsertions_growExponentially() {
    let expectedCapacities = [
      0, 1, 2, 3, 5, 8, 12, 18, 27, 41, 62, 93, 140, 210, 315
    ]
    withEvery("operation", in: SingleInsertion.allCases) { operation in
      var deque = Deque<Int>()
      var contents: [Int] = []
      var capacities = [deque._capacity]
      for i in 0 ..< 256 {
        operation.apply(i, to: &deque, model: &contents)
        if deque._capacity != capacities.last {
          capacities.append(deque._capacity)
        }
      }
      expectEqualElements(capacities, expectedCapacities)
      expectEqualElements(deque, contents)
    }
  }

  func test_bulkInsertions_growExponentially() {
    // https://github.com/apple/swift-collections/pull/113
    // Inserting many small batches must not grow storage linearly, reallocating
    // on nearly every call.
    withEvery("operation", in: BulkInsertion.allCases) { operation in
      withEvery("batchSize", in: [1, 2, 3, 7]) { batchSize in
        var deque = Deque<Int>()
        var contents: [Int] = []
        var reallocationCount = 0
        for round in 0 ..< 100 {
          let batch = Array(round * batchSize ..< (round + 1) * batchSize)
          let oldCapacity = deque._capacity
          operation.apply(batch, to: &deque, model: &contents)
          let newCapacity = deque._capacity
          guard newCapacity != oldCapacity else { continue }
          reallocationCount += 1
          expectGreaterThanOrEqual(newCapacity, oldCapacity + oldCapacity / 2)
        }
        // Linear growth would reallocate in every round.
        expectLessThan(reallocationCount, 20)
        expectEqualElements(deque, contents)
      }
    }
  }

  func test_reservedCapacity_isUsedWithoutReallocating() {
    let reservedCapacity = 100
    withEvery("initialCount", in: [0, 1, 5]) { initialCount in
      withEvery("operation", in: SingleInsertion.allCases) { operation in
        var deque = Deque(0 ..< initialCount)
        var contents = Array(0 ..< initialCount)
        deque.reserveCapacity(reservedCapacity)
        while deque.count < reservedCapacity {
          operation.apply(deque.count, to: &deque, model: &contents)
          expectEqual(deque._capacity, reservedCapacity)
        }
        expectEqualElements(deque, contents)
      }

      withEvery("operation", in: BulkInsertion.allCases) { operation in
        var deque = Deque(0 ..< initialCount)
        var contents = Array(0 ..< initialCount)
        deque.reserveCapacity(reservedCapacity)
        while deque.count + 3 <= reservedCapacity {
          let batch = Array(deque.count ..< deque.count + 3)
          operation.apply(batch, to: &deque, model: &contents)
          expectEqual(deque._capacity, reservedCapacity)
        }
        expectEqualElements(deque, contents)
      }
    }
  }

  func test_insertingIntoSharedStorage() {
    withEveryDeque("deque", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        var (deque, contents) = tracker.deque(with: layout)
        let copy = deque
        let extra = tracker.instance(for: layout.count)
        deque.append(extra)
        contents.append(extra)
        expectEqualElements(deque, contents)
        if layout.count < layout.capacity {
          // Making a unique copy preserves capacity when there is enough room.
          expectEqual(deque._capacity, layout.capacity)
        } else {
          // Otherwise the copy grows by the same factor as unique storage.
          expectGreaterThanOrEqual(
            deque._capacity, layout.capacity + layout.capacity / 2)
        }
        // The original storage is left untouched.
        expectEqual(copy._capacity, layout.capacity)
        expectEqual(copy._startSlot, layout.startSlot)
        expectEqual(copy.count, layout.count)
      }
    }
  }
}
