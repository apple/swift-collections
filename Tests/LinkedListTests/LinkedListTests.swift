//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
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
import LinkedListModule
#endif
import ContainersPreview

#if compiler(>=6.4)

extension LifetimeTracker {
  @available(SwiftStdlib 6.4, *)
  func linkedList<Element>(
    count: Int,
    using generator: (Int) -> Element
  ) -> LinkedList<LifetimeTrackedStruct<Element>> {
    var list = LinkedList<LifetimeTrackedStruct<Element>>()
    for offset in 0 ..< count {
      list.append(self.structInstance(for: generator(offset)))
    }
    return list
  }

  @available(SwiftStdlib 6.4, *)
  func linkedList(count: Int) -> LinkedList<LifetimeTrackedStruct<Int>> {
    linkedList(count: count, using: { $0 })
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable {
  @inlinable
  @inline(never)
  internal func checkInvariants() {
    if count > 0 {
      expectNotEqual(_version._bits, 0)
    }
    var tortoise = unsafe _first
    var hare = unsafe _first
    var last = unsafe _first
    var c = 0
    while let current = unsafe hare {
      c += 1
      if c.isMultiple(of: 2) {
        unsafe tortoise = tortoise?.pointee.next
      }
      unsafe last = current
      unsafe hare = current.pointee.next
      guard unsafe hare != tortoise else {
        expectFailure("Cycle detected")
        return
      }
    }
    expectEqual(c, _count, "Invalid count")
    unsafe expectEqual(last, _last, "Invalid last node")
  }

#if !UnstableContainersPreview
  internal func _index(atOffset offset: Int) -> Index {
    self.index(self.startIndex, offsetBy: offset)
  }
#endif
}


@available(SwiftStdlib 6.4, *)
class LinkedListTests: CollectionTestCase {
  func test_empty() {
    withLifetimeTracking { tracker in
      let list = LinkedList<LifetimeTrackedStruct<Int>>()
      list.checkInvariants()
      expectTrue(list.isEmpty)
      expectEqual(list.count, 0)
      expectEqual(list.underestimatedCount, 0)
      expectEqual(list.startIndex, list.endIndex)
      expectEqual(list.distance(from: list.startIndex, to: list.endIndex), 0)

      do {
        var i = list.startIndex
        expectEqual(list.nextSpan(after: &i).count, 0)
        expectEqual(i, list.startIndex)
      }

      do {
        var it = list.makeBorrowingIterator()
        expectEqual(list.currentIndex(of: &it), list.startIndex)
        do {
          let span = it.nextSpan()
          expectEqual(span.count, 0)
        }
        expectEqual(list.currentIndex(of: &it), list.endIndex)
      }

    }
  }

  func test_singleElement() {
    withLifetimeTracking { tracker in
      var list = LinkedList<LifetimeTrackedStruct<Int>>()
      list.append(tracker.structInstance(for: 42))
      list.checkInvariants()
      expectFalse(list.isEmpty)
      expectEqual(list.count, 1)
      expectEqual(list.underestimatedCount, 1)
      expectLessThan(list.startIndex, list.endIndex)
      expectEqual(list.distance(from: list.startIndex, to: list.endIndex), 1)
      expectEqual(list.index(after: list.startIndex), list.endIndex)
      expectEqual(list[list.startIndex].payload, 42)

      do {
        var i = list.startIndex
        let span = list.nextSpan(after: &i)
        expectEqual(span.count, 1)
        expectEqual(span[0].payload, 42)
        expectEqual(i, list.endIndex)
      }

      do {
        var it = list.makeBorrowingIterator()
        expectEqual(list.currentIndex(of: &it), list.startIndex)
        do {
          let span = it.nextSpan()
          expectEqual(span.count, 1)
          expectEqual(span[0].payload, 42)
        }
        expectEqual(list.currentIndex(of: &it), list.endIndex)
        expectEqual(it.nextSpan().count, 0)
      }

      let i = list.startIndex
      list[i] = tracker.structInstance(for: 23)
      expectEqual(list[i].payload, 23)

      list.swapAt(i, i)
      expectEqual(list[i].payload, 23)
    }
  }

  #if UnstableContainersPreview
  func test_Container() {
    withEvery("count", in: 0 ..< 10) { count in
      withLifetimeTracking { tracker in
        var list = LinkedList<LifetimeTrackedStruct<Int>>()
        withEvery("value", in: 0 ..< count) { value in
          list.append(tracker.structInstance(for: value))
          list.checkInvariants()
          checkContainer(
            list,
            expectedContents: 0 ... value,
            by: { $0.payload == $1 },
            printer: { "\($0.payload)" })
        }
      }
    }
  }
  #endif

  func test_append() {
    withEvery("count", in: 0 ..< 10) { count in
      withLifetimeTracking { tracker in
        var list = LinkedList<LifetimeTrackedStruct<Int>>()
        withEvery("value", in: 0 ..< count) { value in
          let i = list.append(tracker.structInstance(for: value))
          list.checkInvariants()
          expectEqual(list.count, value + 1)
          expectEqual(i, list._index(atOffset: value))
          expectEqual(list[i].payload, value)
          expectIterablePayloads(list, equalTo: 0 ... value)
        }
      }
    }
  }

  func test_append_consuming_LinkedList() {
    withEvery("c1", in: 0 ..< 3) { c1 in
      withEvery("c2", in: 0 ..< 3) { c2 in
        withLifetimeTracking { tracker in
          var list = tracker.linkedList(count: c1)
          let tail = tracker.linkedList(count: c2, using: { c1 + $0 })

          let range = list.append(consuming: tail)

          list.checkInvariants()
          expectIterablePayloads(list, equalTo: 0 ..< (c1 + c2))

          expectEqual(range.lowerBound, list._index(atOffset: c1))
          expectEqual(range.upperBound, list.endIndex)
        }
      }
    }
  }

  func test_prepend() {
    withEvery("count", in: 0 ..< 10) { count in
      withLifetimeTracking { tracker in
        var list = LinkedList<LifetimeTrackedStruct<Int>>()
        withEvery("value", in: 0 ..< count) { value in
          let i = list.prepend(tracker.structInstance(for: value))
          list.checkInvariants()
          expectEqual(list.count, value + 1)
          expectEqual(i, list.startIndex)
          expectEqual(list[i].payload, value)
          expectIterablePayloads(list, equalTo: (0 ... value).reversed())
        }
      }
    }
  }

  func test_prepend_consuming_LinkedList() {
    withEvery("c1", in: 0 ..< 3) { c1 in
      withEvery("c2", in: 0 ..< 3) { c2 in
        withLifetimeTracking { tracker in
          var list = tracker.linkedList(count: c1, using: { c2 + $0 })
          let tail = tracker.linkedList(count: c2)

          let range = list.prepend(consuming: tail)

          list.checkInvariants()
          expectIterablePayloads(list, equalTo: 0 ..< (c1 + c2))

          expectEqual(range.lowerBound, list.startIndex)
          expectEqual(range.upperBound, list._index(atOffset: c2))
        }
      }
    }
  }

  func test_insert_at() {
    withEvery("count", in: 0 ..< 10) { count in
      withEvery("offset", in: 0 ... count) { offset in
        withLifetimeTracking { tracker in
          var list = LinkedList<LifetimeTrackedStruct<Int>>()
          withEvery("value", in: 0 ..< count) { value in
            list.append(tracker.structInstance(for: value))
          }
          var expected = Array(0 ..< count)
          expected.insert(-1, at: offset)

          let index = list.index(list.startIndex, offsetBy: offset)
          let result = list.insert(tracker.structInstance(for: -1), at: index)

          list.checkInvariants()
          expectEqual(list.count, count + 1)
          expectEqual(result, list._index(atOffset: offset))
          expectEqual(list[result].payload, -1)
          expectIterablePayloads(list, equalTo: expected)
        }
      }
    }
  }

  func test_insert_consuming_LinkedList_at() {
    withEvery("c1", in: 0 ..< 3) { c1 in
      withEvery("c2", in: 0 ..< 3) { c2 in
        withEvery("offset", in: 0 ... c1) { offset in
          withLifetimeTracking { tracker in
            var list = tracker.linkedList(count: c1)
            let tail = tracker.linkedList(count: c2, using: { c1 + $0 })

            let i = list._index(atOffset: offset)
            let range = list.insert(consuming: tail, at: i)

            list.checkInvariants()

            var expected = Array(0 ..< c1)
            expected.insert(contentsOf: c1 ..< (c1 + c2), at: offset)
            expectIterablePayloads(list, equalTo: expected)

            expectEqual(range.lowerBound, list._index(atOffset: offset))
            expectEqual(range.upperBound, list._index(atOffset: offset + c2))
          }
        }
      }
    }
  }

  func test_remove_at() {
    withEvery("count", in: 1 ..< 10) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withLifetimeTracking { tracker in
          var list = tracker.linkedList(count: count)
          var index = list._index(atOffset: offset)

          let removed = list.remove(at: &index)

          list.checkInvariants()
          expectEqual(removed.payload, offset)
          expectEqual(list.count, count - 1)

          var expected = Array(0 ..< count)
          expected.remove(at: offset)
          expectIterablePayloads(list, equalTo: expected)

          expectEqual(index, list._index(atOffset: offset))
          if offset == count - 1 {
            expectEqual(index, list.endIndex)
          } else {
            expectEqual(list[index].payload, offset + 1)
          }
        }
      }
    }
  }

  func test_extract() {
    withEvery("count", in: [0, 1, 2, 5]) { count in
      withEveryRange("range", in: 0 ..< count) { range in
        withLifetimeTracking { tracker in
          var list = LinkedList<LifetimeTrackedStruct<Int>>()
          for i in 0 ..< count {
            list.append(tracker.structInstance(for: i))
          }
          list.checkInvariants()
          let lower = list.index(list.startIndex, offsetBy: range.lowerBound)
          let upper = list.index(lower, offsetBy: range.count)
          var indexRange = lower ..< upper
          let extract = list.extract(&indexRange)
          list.checkInvariants()
          extract.checkInvariants()

          expectIterablePayloads(extract, equalTo: range)

          let expected = Array(0 ..< range.lowerBound) + Array(range.upperBound ..< count)
          expectIterablePayloads(list, equalTo: expected)

          expectEqual(indexRange.lowerBound, indexRange.upperBound)
          expectEqual(
            indexRange.lowerBound,
            list._index(atOffset: range.lowerBound))
          expectEqual(
            list.distance(from: list.startIndex, to: indexRange.lowerBound),
            range.lowerBound)
          if range.upperBound == count {
            expectEqual(indexRange.lowerBound, list.endIndex)
          } else {
            expectEqual(list[indexRange.lowerBound].payload, range.upperBound)
          }
        }
      }
    }
  }
}
#endif
