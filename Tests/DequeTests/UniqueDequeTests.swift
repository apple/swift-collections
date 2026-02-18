//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
#if COLLECTIONS_SINGLE_MODULE
@_spi(Testing) import Collections
#else
import _CollectionsTestSupport
import DequeModule
import BasicContainers
import ContainersPreview
#endif

#if compiler(>=6.2)
#if !COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
internal func expectIterableContents<
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
  expectIterableContents(
    left,
    equivalentTo: right,
    by: ==,
    message(), trapping: trapping, file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
internal func expectIterableContents<
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
  expectIterableContents(
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
internal func expectIterableContents<
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

#endif

final class UniqueDequeTests: CollectionTestCase {
  struct TestError: Error, Equatable {
    let value: Int
    init(_ value: Int) { self.value = value }
  }
  
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
          expectIterableContents(data.deque, equalTo: data.contents)
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
            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }

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
}

#endif
