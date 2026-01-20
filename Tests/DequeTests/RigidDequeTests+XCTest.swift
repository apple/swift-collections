//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
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
@_spi(Testing) import DequeModule
#endif

#if !COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
internal func expectIterableContents<
  Element: Equatable,
  C2: Collection<Element>,
>(
  _ left: borrowing RigidDeque<Element>,
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
    printer: { "\($0)" },
    message(), trapping: trapping, file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
internal func expectIterableContents<
  E1: ~Copyable,
  C2: Collection,
>(
  _ left: borrowing RigidDeque<E1>,
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

final class RigidDequeTests: CollectionTestCase {
  func test_testingSPIs() {
    // TODO
  }
  
  struct TestError: Error, Equatable {
    let value: Int
    init(_ value: Int) { self.value = value }
  }
  
  func test_popFirst() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        var data = tracker.rigidDeque(with: layout)
        let expected = data.contents[...].popFirst()
        let actual = data.deque.popFirst()
        expectEqual(actual, expected)
        expectIterableContents(data.deque, equalTo: data.contents)
      }
    }
  }
  
  func test_popLast() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        var data = tracker.rigidDeque(with: layout)
        let expected = data.contents[...].popLast()
        let actual = data.deque.popLast()
        expectEqual(actual, expected)
        expectIterableContents(data.deque, equalTo: data.contents)
      }
    }
  }
  
  func test_prependOne() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        var data = tracker.rigidDeque(with: layout)
        let extra = tracker.instance(for: layout.count)
        guard !data.deque.isFull else { return }
        data.contents.insert(extra, at: 0)
        data.deque.prepend(extra)
        expectIterableContents(data.deque, equalTo: data.contents)
      }
    }
  }
  
  func test_appendOne() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        var data = tracker.rigidDeque(with: layout)
        let extra = tracker.instance(for: layout.count)
        guard !data.deque.isFull else { return }
        data.contents.insert(extra, at: data.contents.count)
        data.deque.append(extra)
        expectIterableContents(data.deque, equalTo: data.contents)
      }
    }
  }
  
  func test_prependManyFromMinimalSequence() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< 10) { prependCount in
        withEvery("underestimatedCount", in: [UnderestimatedCountBehavior.precise, .half, .value(min(1, prependCount))]) { underestimatedCount in
          withLifetimeTracking { tracker in
            var data = tracker.rigidDeque(with: layout)
            let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)
            let sequence = MinimalSequence(elements: extras, underestimatedCount: underestimatedCount)
            data.contents.insert(contentsOf: extras, at: 0)
            guard extras.count <= data.deque.freeCapacity else { return }
            data.deque.prepend(copying: sequence)
            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }
  
  func test_prependManyFromMinimalCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< 10) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extra = tracker.instances(for: layout.count ..< layout.count + prependCount)
          guard extra.count <= data.deque.freeCapacity else { return }
          let minimal = MinimalCollection(extra)
          data.contents.insert(contentsOf: extra, at: 0)
          data.deque.prepend(copying: minimal)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_prependManyFromContiguousArray_asCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< 10) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extraRange = layout.count ..< layout.count + prependCount
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          guard extra.count <= data.deque.freeCapacity else { return }
          data.contents.insert(contentsOf: extra, at: 0)
          data.deque.prepend(copying: extra)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_prependManyFromContiguousArray_asSequence() {
    // This calls the Sequence-based `Deque.prepend` overload, even if
    // `elements` happens to be of a Collection type.
    func prependSequence<S: Sequence>(
      contentsOf elements: S,
      to deque: inout RigidDeque<S.Element>
    ) {
      deque.prepend(copying: elements)
    }
    
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< 10) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extraRange = layout.count ..< layout.count + prependCount
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          guard extra.count <= data.deque.freeCapacity else { return }
          data.contents.insert(contentsOf: extra, at: 0)
          prependSequence(contentsOf: extra, to: &data.deque)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_prependManyFromBridgedArray() {
    // https://github.com/apple/swift-collections/issues/27
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("appendCount", in: 0 ..< 10) { appendCount in
        var contents: [NSObject] = (0 ..< layout.count).map { _ in NSObject() }
        var deque = RigidDeque(layout: layout, contents: contents)
        guard appendCount <= deque.freeCapacity else { return }
        let extra: [NSObject] = (0 ..< appendCount)
          .map { _ in NSObject() }
          .withUnsafeBufferPointer { buffer in
            NSArray(objects: buffer.baseAddress, count: buffer.count) as! [NSObject]
          }
        guard extra.count <= deque.freeCapacity else { return }
        contents.insert(contentsOf: extra, at: 0)
        deque.prepend(copying: extra)
        expectIterableContents(deque, equivalentTo: contents, by: ==)
      }
    }
  }
  
  func test_appendManyFromMinimalSequence() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("appendCount", in: 0 ..< 10) { appendCount in
        withEvery("underestimatedCount", in: [UnderestimatedCountBehavior.precise, .half, .value(min(1, appendCount))]) { underestimatedCount in
          withLifetimeTracking { tracker in
            var data = tracker.rigidDeque(with: layout)
            let extras = tracker.instances(for: layout.count ..< layout.count + appendCount)
            let sequence = MinimalSequence(elements: extras, underestimatedCount: underestimatedCount)
            data.contents.append(contentsOf: extras)
            guard extras.count <= data.deque.freeCapacity else { return }
            data.deque.append(copying: sequence)
            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }
  
  func test_appendManyFromMinimalCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("appendCount", in: 0 ..< 10) { appendCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extra = tracker.instances(for: layout.count ..< layout.count + appendCount)
          guard extra.count <= data.deque.freeCapacity else { return }
          let minimal = MinimalCollection(extra)
          data.contents.append(contentsOf: extra)
          data.deque.append(copying: minimal)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_appendManyFromContiguousArray_asCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("appendCount", in: 0 ..< 10) { appendCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extraRange = layout.count ..< layout.count + appendCount
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          guard extra.count <= data.deque.freeCapacity else { return }
          data.contents.append(contentsOf: extra)
          data.deque.append(copying: extra)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_appendManyFromContiguousArray_asSequence() {
    // This calls the Sequence-based `Deque.append` overload, even if
    // `elements` happens to be of a Collection type.
    func appendSequence<S: Sequence>(
      contentsOf elements: S,
      to deque: inout RigidDeque<S.Element>
    ) {
      deque.append(copying: elements)
    }
    
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("appendCount", in: 0 ..< 10) { appendCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extraRange = layout.count ..< layout.count + appendCount
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          guard extra.count <= data.deque.freeCapacity else { return }
          data.contents.append(contentsOf: extra)
          appendSequence(contentsOf: extra, to: &data.deque)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_appendManyFromBridgedArray() {
    // https://github.com/apple/swift-collections/issues/27
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("appendCount", in: 0 ..< 10) { appendCount in
        var contents: [NSObject] = (0 ..< layout.count).map { _ in NSObject() }
        var deque = RigidDeque(layout: layout, contents: contents)
        guard appendCount <= deque.freeCapacity else { return }
        let extra: [NSObject] = (0 ..< appendCount)
          .map { _ in NSObject() }
          .withUnsafeBufferPointer { buffer in
            NSArray(objects: buffer.baseAddress, count: buffer.count) as! [NSObject]
          }
        guard extra.count <= deque.freeCapacity else { return }
        contents.append(contentsOf: extra)
        deque.append(copying: extra)
        expectIterableContents(deque, equivalentTo: contents, by: ==)
      }
    }
  }
  
  func test_insertOneElement() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("offset", in: 0 ... layout.count) { offset in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extra = tracker.instance(for: layout.count)
          guard !data.deque.isFull else { return }
          data.contents.insert(extra, at: offset)
          data.deque.insert(extra, at: offset)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
//  func test_insertFromMinimalCollection() {
//    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
//      withEvery("offset", in: 0 ... layout.count) { offset in
//        withEvery("insertCount", in: 0 ..< 10) { insertCount in
//          withLifetimeTracking { tracker in
//            var data = tracker.rigidDeque(with: layout)
//            let extras = tracker.instances(for: layout.count ..< layout.count + insertCount)
//            let minimal = MinimalCollection(extras)
//            data.contents.insert(contentsOf: extras, at: offset)
//            data.deque.insert(contentsOf: minimal, at: offset)
//            expectIterableContents(data.deque, equalTo: data.contents)
//          }
//        }
//      }
//    }
//  }
//  
//  func test_insertFromArray() {
//    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
//      withEvery("offset", in: 0 ... layout.count) { offset in
//        withEvery("insertCount", in: 0 ..< 10) { insertCount in
//          withLifetimeTracking { tracker in
//            var data = tracker.rigidDeque(with: layout)
//            let extras = tracker.instances(for: layout.count ..< layout.count + insertCount)
//            data.contents.insert(contentsOf: extras, at: offset)
//            data.deque.insert(contentsOf: extras, at: offset)
//            expectIterableContents(data.deque, equalTo: data.contents)
//          }
//        }
//      }
//    }
//  }
  
  func test_removeOne() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("offset", in: 0 ..< layout.count) { offset in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let expected = data.contents.remove(at: offset)
          let actual = data.deque.remove(at: offset)
          expectEqual(actual, expected)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_removeSubrange() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEveryRange("range", in: 0 ..< layout.count) { range in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          data.contents.removeSubrange(range)
          data.deque.removeSubrange(range)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_removeLast() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      guard layout.count > 0 else { return }
      withLifetimeTracking { tracker in
        var data = tracker.rigidDeque(with: layout)
        let expected = data.contents.removeLast()
        let actual = data.deque.removeLast()
        expectEqual(actual, expected)
        expectIterableContents(data.deque, equalTo: data.contents)
      }
    }
  }
  
  func test_removeLast_many() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      guard layout.count > 0 else { return }
      withEvery("n", in: 0 ... layout.count) { n in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          data.contents.removeLast(n)
          data.deque.removeLast(n)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_removeFirst_one() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      guard layout.count > 0 else { return }
      withLifetimeTracking { tracker in
        var data = tracker.rigidDeque(with: layout)
        let expected = data.contents.removeFirst()
        let actual = data.deque.removeFirst()
        expectEqual(actual, expected)
        expectIterableContents(data.deque, equalTo: data.contents)
      }
    }
  }
  
  func test_removeFirst_many() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      guard layout.count > 0 else { return }
      withEvery("n", in: 0 ... layout.count) { n in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          data.contents.removeFirst(n)
          data.deque.removeFirst(n)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_removeAll_keepingCapacity() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("isShared", in: [false, true]) { isShared in
        guard layout.count > 0 else { return }
        var data: RigidTestData<LifetimeTracked<Int>> = .init(.init(capacity: 0), [])
        withLifetimeTracking { tracker in
          data = tracker.rigidDeque(with: layout)
          data.contents.removeAll(keepingCapacity: true)
          data.deque.removeAll()
          expectEqual(data.deque.count, 0)
          expectEqual(data.deque.capacity, layout.capacity)
        } // All elements must be deinitialized at this point.
        withExtendedLifetime(data.deque) {}
      }
    }
  }
}
