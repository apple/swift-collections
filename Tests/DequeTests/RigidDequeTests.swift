//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
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
    message(), trapping: trapping, file: file, line: line)
}

/// Check if `left` and `right` contain equal elements in the same order.
@available(SwiftStdlib 5.0, *)
internal func expectIterableContents<
  E1,
  C2: Collection,
>(
  _ left: borrowing RigidDeque<E1>,
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
  struct TestError: Error, Equatable {
    let value: Int
    init(_ value: Int) { self.value = value }
  }
  
  func test_testingSPIs() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        let data = tracker.rigidDeque(with: layout)
        expectEqual(data.deque._startSlot, layout.startSlot)
        expectEqual(data.deque.capacity, layout.capacity)
        expectEqual(data.deque.count, layout.count)
        expectEqual(data.deque.freeCapacity, layout.capacity - layout.count)
        for i in 0 ..< layout.count {
          expectEqual(data.deque[i], data.contents[i])
        }
        expectIterableContents(data.deque, equalTo: data.contents)
      }
    }
  }
  
  func test_basicProperties() {
    var deque = RigidDeque<Int>(capacity: 10)
    
    // Empty deque
    expectEqual(deque.isEmpty, true)
    expectEqual(deque.isFull, false)
    expectEqual(deque.count, 0)
    expectEqual(deque.capacity, 10)
    expectEqual(deque.freeCapacity, 10)
    expectEqual(deque.startIndex, 0)
    expectEqual(deque.endIndex, 0)
    expectEqual(deque.indices, 0 ..< 0)
    
    // Add some elements
    deque.append(1)
    deque.append(2)
    deque.append(3)
    
    expectEqual(deque.isEmpty, false)
    expectEqual(deque.isFull, false)
    expectEqual(deque.count, 3)
    expectEqual(deque.capacity, 10)
    expectEqual(deque.freeCapacity, 7)
    expectEqual(deque.startIndex, 0)
    expectEqual(deque.endIndex, 3)
    expectEqual(deque.indices, 0 ..< 3)
    
    // Fill to capacity
    for i in 4...10 {
      deque.append(i)
    }
    
    expectEqual(deque.isEmpty, false)
    expectEqual(deque.isFull, true)
    expectEqual(deque.count, 10)
    expectEqual(deque.freeCapacity, 0)
    expectEqual(deque.indices, 0 ..< 10)
  }
  
  func test_subscriptBorrow() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        let data = tracker.rigidDeque(with: layout)
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
          var data = tracker.rigidDeque(with: layout)
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
            var data = tracker.rigidDeque(with: layout)
            data.deque.swapAt(i, j)
            data.contents.swapAt(i, j)
            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }
  
  func test_reallocate() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery(
        "newCapacity",
        in: [layout.capacity, layout.count, 2 * layout.capacity] as Set
      ) { newCapacity in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          data.deque.reallocate(capacity: newCapacity)
          
          expectEqual(data.deque.capacity, newCapacity)
          expectEqual(data.deque.count, layout.count)
          expectEqual(tracker.instances, layout.count)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_reserveCapacity() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery(
        "newCapacity",
        in: [layout.capacity, layout.count, 2 * layout.capacity] as Set
      ) { newCapacity in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          data.deque.reserveCapacity(newCapacity)
          
          expectEqual(data.deque.capacity, Swift.max(layout.capacity, newCapacity))
          expectEqual(data.deque.count, layout.count)
          expectEqual(tracker.instances, layout.count)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_initWithCapacity() {
    withEvery("capacity", in: [0, 1, 2, 3, 5, 10]) { capacity in
      let deque = RigidDeque<Int>(capacity: capacity)
      expectEqual(deque.capacity, capacity)
      expectEqual(deque.count, 0)
      expectEqual(deque.freeCapacity, capacity)
      if capacity == 0 {
        expectNil(deque._handle._buffer.baseAddress) // No allocations
      }
    }
  }
  
  func test_initEmpty() {
    let deque = RigidDeque<Int>()
    expectEqual(deque.capacity, 0)
    expectEqual(deque.count, 0)
    expectEqual(deque.freeCapacity, 0)
    expectNil(deque._handle._buffer.baseAddress) // No allocations
  }
  
  func test_initWithClosure_Full() {
    withEvery("capacity", in: 0 ..< 10) { capacity in
      withLifetimeTracking { tracker in
        let deque = RigidDeque(capacity: capacity) { span in
          for i in 0 ..< capacity {
            span.append(tracker.structInstance(for: i))
          }
        }
        expectEqual(deque.count, capacity)
        expectEqual(deque.capacity, capacity)
        withEvery("i", in: 0 ..< capacity) { i in
          expectEqual(deque[i].payload, i)
        }
        
        expectEqual(tracker.instances, capacity)
        _ = consume deque
        expectEqual(tracker.instances, 0)
      }
    }
  }
  
  func test_initWithClosure_Partial() {
    withEvery("capacity", in: 0 ..< 10) { capacity in
      withEvery("count", in: [0, capacity / 2, max(capacity - 1, 0)] as Set) { count in
        withLifetimeTracking { tracker in
          let deque = RigidDeque(capacity: capacity) { span in
            for i in 0 ..< count {
              span.append(tracker.structInstance(for: i))
            }
          }
          expectEqual(deque.count, count)
          expectEqual(deque.capacity, capacity)
          withEvery("i", in: 0 ..< count) { i in
            expectEqual(deque[i].payload, i)
          }
          
          expectEqual(tracker.instances, count)
          _ = consume deque
          expectEqual(tracker.instances, 0)
        }
      }
    }
  }
  
  func test_initWithClosure_Failing() {
    withEvery("capacity", in: 1 ..< 10 as Range<Int>) { capacity -> Void in
      withEvery("count", in: [0, capacity / 2, max(capacity - 1, 0)] as Set) { count -> Void in
        withLifetimeTracking { tracker -> Void in
          expectThrows { () throws(TestError) -> Void in
            let deque = try RigidDeque<LifetimeTrackedStruct<Int>>(
              capacity: capacity
            ) { span throws(TestError) -> Void in
              for i in 0 ..< count {
                span.append(tracker.structInstance(for: i))
              }
              expectEqual(tracker.instances, count)
              throw TestError(42)
            }
            expectEqual(deque.count, count)
          }
          errorHandler: { error in
            expectEqual(error.value, 42)
          }
        }
      }
    }
  }
  
  func test_init_consumingUniqueDeque() {
    withLifetimeTracking { tracker in
      let ud = UniqueDeque(copying: tracker.instances(for: 0 ..< 10))
      expectEqual(ud.count, 10)
      expectEqual(tracker.instances, 10)
      let buffer = ud._storage._handle._buffer
      expectNotNil(buffer.baseAddress)
      
      let rd = RigidDeque(consuming: ud)
      expectEqual(rd.count, 10)
      expectEqual(tracker.instances, 10)
      expectEqual(rd._handle._buffer.baseAddress, buffer.baseAddress)
      
      _ = consume rd
      expectEqual(tracker.instances, 0)
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_initFromProducer() {
    withEvery("count", in: 0 ..< 10) { count in
      withEvery("capacity", in: [count / 2, count, 2 * count] as Set) { capacity in
        withLifetimeTracking { tracker in
          var invocations = 0
          var producer = CustomProducer<LifetimeTrackedStruct<Int>, Never> {
            if invocations >= count {
              return nil
            }
            defer { invocations += 1 }
            return tracker.structInstance(for: invocations)
          }
          
          let c = min(count, capacity)
          let deque = RigidDeque(capacity: capacity, from: &producer)
          expectEqual(invocations, c)
          expectEqual(deque.count, c)
          expectEqual(tracker.instances, c)
          expectEqual(invocations, c)
          
          for i in 0 ..< c {
            expectEqual(deque[i].payload, i)
          }
        }
      }
    }
  }
  
  func test_initFromThrowingProducer() {
    withEvery("count", in: 0 ..< 10) { (count: Int) in
      withLifetimeTracking { tracker in
        var invocations = 0
        var producer = CustomProducer<LifetimeTrackedStruct<Int>, TestError>
        { () throws(TestError) in
          if invocations >= count {
            throw TestError(42)
          }
          defer { invocations += 1 }
          return tracker.structInstance(for: invocations)
        }
        
        expectThrows { () throws(TestError) in
          let _ = try RigidDeque(capacity: count + 10, from: &producer)
        }
        errorHandler: { error in
          expectEqual(error.value, 42)
        }
        expectEqual(invocations, count)
      }
    }
  }
#endif
  
  func test_initRepeatingValue() {
    withEvery("c", in: 0 ..< 10) { c in
      withLifetimeTracking { tracker in
        let deque = RigidDeque(repeating: LifetimeTracked(42, for: tracker), count: c)
        expectEqual(deque.count, c)
        expectEqual(deque.capacity, c)
        withEvery("i", in: 0 ..< c) { i in
          expectEqual(deque[i].payload, 42)
        }
        expectEqual(tracker.instances, c == 0 ? 0 : 1)
        _ = consume deque
        expectEqual(tracker.instances, 0)
      }
    }
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_initCopyingBorrowingSequence() {
    withEvery("c", in: 0 ..< 10) { c in
      withEvery("capacity", in: [c, c + 1]) { capacity in
        withLifetimeTracking { tracker in
          let values = RigidArray(copying: tracker.instances(for: 0 ..< c))
          let deque = RigidDeque(capacity: capacity, copying: values)
          
          expectEqual(deque.count, c)
          expectEqual(deque.capacity, capacity)
          expectIterablePayloads(deque, equalTo: 0 ..< c)
          
          expectEqual(tracker.instances, c)
          _ = consume values
          expectEqual(tracker.instances, c)
          _ = consume deque
          expectEqual(tracker.instances, 0)
        }
      }
    }
  }
#endif
  
  func test_initCopyingSequence() {
    withEvery("c", in: 0 ..< 10) { c in
      withEvery("capacity", in: [c, c + 1]) { capacity in
        withLifetimeTracking { tracker in
          let values = tracker.instances(for: 0 ..< c)
          let contents = MinimalSequence(
            elements: values,
            underestimatedCount: .value(0))
          
          let deque = RigidDeque(capacity: capacity, copying: contents)
          
          expectEqual(deque.count, c)
          expectEqual(deque.capacity, capacity)
          expectIterableContents(deque, equalTo: values)
          
          expectEqual(tracker.instances, c)
          _ = consume values
          _ = consume contents
          expectEqual(tracker.instances, c)
          _ = consume deque
          expectEqual(tracker.instances, 0)
        }
      }
    }
  }
  
  func test_initCopyingCollection() {
    withEvery("c", in: 0 ..< 10) { c in
      withEvery("capacity", in: [c, c + 1]) { capacity in
        withLifetimeTracking { tracker in
          let values = tracker.instances(for: 0 ..< c)
          let contents = MinimalCollection(values)
          
          let deque = RigidDeque(capacity: capacity, copying: contents)
          
          expectEqual(deque.count, c)
          expectEqual(deque.capacity, capacity)
          expectIterableContents(deque, equalTo: values)
          
          expectEqual(tracker.instances, c)
          _ = consume values
          _ = consume contents
          expectEqual(tracker.instances, c)
          _ = consume deque
          expectEqual(tracker.instances, 0)
        }
      }
    }
  }
  
  func test_initCopyingRange_classic() {
    // With a deployment target <6.2, this tests the Collection initializer
    withEvery("c", in: 0 ..< 10) { c in
      withEvery("capacity", in: [c, c + 1]) { capacity in
        let deque = RigidDeque(capacity: capacity, copying: 0 ..< c)
        
        expectEqual(deque.count, c)
        expectEqual(deque.capacity, capacity)
        expectIterableContents(deque, equalTo: 0 ..< c)
      }
    }
  }
  
  @available(SwiftStdlib 6.2, *)
  func test_initCopyingRange_modern() {
    // With a deployment target >=6.2, this tests the BorrowingSequence initializer
    withEvery("c", in: 0 ..< 10) { c in
      withEvery("capacity", in: [c, c + 1]) { capacity in
        let deque = RigidDeque(capacity: capacity, copying: 0 ..< c)
        
        expectEqual(deque.count, c)
        expectEqual(deque.capacity, capacity)
        expectIterableContents(deque, equalTo: 0 ..< c)
      }
    }
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
  
  func test_prepend() {
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
  
  func test_append() {
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
  
  func test_pushFirst() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        var data = tracker.rigidDeque(with: layout)
        let extra = tracker.instance(for: layout.count)
        
        let result = data.deque.pushFirst(extra)
        
        if layout.count == layout.capacity {
          expectEqual(result, extra)
          expectIterableContents(data.deque, equalTo: data.contents)
        } else {
          data.contents.insert(extra, at: 0)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_pushLast() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withLifetimeTracking { tracker in
        var data = tracker.rigidDeque(with: layout)
        let extra = tracker.instance(for: layout.count)
        
        let result = data.deque.pushLast(extra)
        
        if layout.count == layout.capacity {
          expectEqual(result, extra)
          expectIterableContents(data.deque, equalTo: data.contents)
        } else {
          data.contents.insert(extra, at: data.contents.count)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_prepend_initializingWith_full() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          
          let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)
          
          data.contents.insert(contentsOf: extras, at: 0)
          
          var i = 0
          data.deque.prepend(addingCount: prependCount) { target in
            while !target.isFull {
              target.append(extras[i])
              i += 1
            }
          }
          
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_append_initializingWith_full() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          
          let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)
          
          data.contents.append(contentsOf: extras)
          
          var i = 0
          data.deque.append(maximumCount: prependCount) { target in
            while !target.isFull {
              target.append(extras[i])
              i += 1
            }
          }
          
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_prepend_initializingWith_partial() {
    withEveryDeque("layout", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          
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
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_append_initializingWith_partial() {
    withEveryDeque("layout", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          
          let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)
          
          data.contents.append(contentsOf: extras)
          
          var i = 0
          data.deque.append(maximumCount: layout.freeCapacity) { target in
            while !target.isFull, i < prependCount {
              target.append(extras[i])
              i += 1
            }
          }
          expectEqual(i, extras.count)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_prepend_initializingWith_failing() {
    withEveryDeque("layout", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      if layout.freeCapacity == 0 { return }
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          
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
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  
  func test_append_initializingWith_failing() {
    withEveryDeque("layout", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      if layout.freeCapacity == 0 { return }
      withEvery("prependCount", in: 0 ..< layout.freeCapacity) { prependCount in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          
          let extras = tracker.instances(for: layout.count ..< layout.count + prependCount)
          
          data.contents.append(contentsOf: extras)
          
          expectThrows { () throws(TestError) in
            var i = 0
            try data.deque.append(
              maximumCount: layout.freeCapacity
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
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_prepend_Producer_full() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      withEvery("producerSize", in: 0 ..< 6) { producerSize in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          
          var extras = tracker.instances(for: 0 ..< producerSize)
          
          data.contents.insert(contentsOf: extras.prefix(layout.freeCapacity), at: 0)
          
          var producer = CustomProducer<LifetimeTracked<Int>, Never> {
            guard !extras.isEmpty else { return nil }
            return extras.removeFirst()
          }
          
          data.deque.prepend(from: &producer)
          expectEqual(extras.count, max(0, producerSize - layout.freeCapacity))
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
#endif
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_append_Producer() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      withEvery("producerSize", in: 0 ..< 6) { producerSize in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          
          var extras = tracker.instances(for: 0 ..< producerSize)
          
          data.contents.append(contentsOf: extras.prefix(layout.freeCapacity))
          
          var producer = CustomProducer<LifetimeTracked<Int>, Never> {
            guard !extras.isEmpty else { return nil }
            return extras.removeFirst()
          }
          
          data.deque.append(from: &producer)
          expectEqual(extras.count, max(0, producerSize - layout.freeCapacity))
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
#endif
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_prepend_Producer_failing() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      guard layout.freeCapacity > 0 else { return }
      withEvery("producerSize", in: 0 ..< layout.freeCapacity - 1) { producerSize in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          
          var extras = tracker.instances(for: 0 ..< producerSize)
          
          data.contents.insert(contentsOf: extras, at: 0)
          
          var producer = CustomProducer<LifetimeTracked<Int>, TestError> { () throws(TestError) in
            guard !extras.isEmpty else { throw TestError(23) }
            return extras.removeFirst()
          }
          
          expectThrows { () throws(TestError) in
            try data.deque.prepend(from: &producer)
          }
          errorHandler: { error in
            expectEqual(error.value, 23)
          }
          expectEqual(extras.count, 0)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
#endif
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_append_Producer_failing() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      guard layout.freeCapacity > 0 else { return }
      withEvery("producerSize", in: 0 ..< layout.freeCapacity - 1) { producerSize in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          
          var extras = tracker.instances(for: 0 ..< producerSize)
          
          data.contents.append(contentsOf: extras)
          
          var producer = CustomProducer<LifetimeTracked<Int>, TestError> { () throws(TestError) in
            guard !extras.isEmpty else { throw TestError(23) }
            return extras.removeFirst()
          }
          
          expectThrows { () throws(TestError) in
            try data.deque.append(from: &producer)
          }
          errorHandler: { error in
            expectEqual(error.value, 23)
          }
          expectEqual(extras.count, 0)
          expectIterableContents(data.deque, equalTo: data.contents)
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
            var data = tracker.rigidDeque(with: layout)
            let extras = tracker.instances(for: layout.count ..< layout.count + c)
            let sequence = MinimalSequence(elements: extras, underestimatedCount: underestimatedCount)
            data.contents.insert(contentsOf: extras, at: 0)
            data.deque.prepend(copying: sequence)
            expectIterableContents(data.deque, equalTo: data.contents)
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
            var data = tracker.rigidDeque(with: layout)
            let extras = tracker.instances(for: layout.count ..< layout.count + c)
            let sequence = MinimalSequence(elements: extras, underestimatedCount: underestimatedCount)
            data.contents.append(contentsOf: extras)
            data.deque.append(copying: sequence)
            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }
  
  func test_prepend_MinimalCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extra = tracker.instances(for: layout.count ..< layout.count + c)
          let minimal = MinimalCollection(extra)
          data.contents.insert(contentsOf: extra, at: 0)
          data.deque.prepend(copying: minimal)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_append_MinimalCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extra = tracker.instances(for: layout.count ..< layout.count + c)
          let minimal = MinimalCollection(extra)
          data.contents.append(contentsOf: extra)
          data.deque.append(copying: minimal)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_prepend_ContiguousArray_asCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extraRange = layout.count ..< layout.count + c
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          data.contents.insert(contentsOf: extra, at: 0)
          data.deque.prepend(copying: extra)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_append_ContiguousArray_asCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extraRange = layout.count ..< layout.count + c
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          data.contents.append(contentsOf: extra)
          data.deque.append(copying: extra)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_prepend_ContiguousArray_asSequence() {
    // This calls the Sequence-based `Deque.prepend` overload, even if
    // `elements` happens to be of a Collection type.
    func prependSequence<S: Sequence>(
      contentsOf elements: S,
      to deque: inout RigidDeque<S.Element>
    ) {
      deque.prepend(copying: elements)
    }
    
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extraRange = layout.count ..< layout.count + c
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          data.contents.insert(contentsOf: extra, at: 0)
          prependSequence(contentsOf: extra, to: &data.deque)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_append_ContiguousArray_asSequence() {
    // This calls the Sequence-based `Deque.append` overload, even if
    // `elements` happens to be of a Collection type.
    func appendSequence<S: Sequence>(
      contentsOf elements: S,
      to deque: inout RigidDeque<S.Element>
    ) {
      deque.append(copying: elements)
    }
    
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        withLifetimeTracking { tracker in
          var data = tracker.rigidDeque(with: layout)
          let extraRange = layout.count ..< layout.count + c
          let extra = ContiguousArray(tracker.instances(for: extraRange))
          data.contents.append(contentsOf: extra)
          appendSequence(contentsOf: extra, to: &data.deque)
          expectIterableContents(data.deque, equalTo: data.contents)
        }
      }
    }
  }
  
  func test_prepend_BridgedArray() {
    // https://github.com/apple/swift-collections/issues/27
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        var contents: [NSObject] = (0 ..< layout.count).map { _ in NSObject() }
        var deque = RigidDeque(layout: layout, contents: contents)
        guard c <= deque.freeCapacity else { return }
        let extra: [NSObject] = (0 ..< c)
          .map { _ in NSObject() }
          .withUnsafeBufferPointer { buffer in
            NSArray(objects: buffer.baseAddress, count: buffer.count) as! [NSObject]
          }
        contents.insert(contentsOf: extra, at: 0)
        deque.prepend(copying: extra)
        expectIterableContents(
          deque,
          equivalentTo: contents,
          by: ==,
          printer: { "\($0)" })
      }
    }
  }
  
  func test_append_BridgedArray() {
    // https://github.com/apple/swift-collections/issues/27
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("c", in: 0 ..< layout.freeCapacity) { c in
        var contents: [NSObject] = (0 ..< layout.count).map { _ in NSObject() }
        var deque = RigidDeque(layout: layout, contents: contents)
        guard c <= deque.freeCapacity else { return }
        let extra: [NSObject] = (0 ..< c)
          .map { _ in NSObject() }
          .withUnsafeBufferPointer { buffer in
            NSArray(objects: buffer.baseAddress, count: buffer.count) as! [NSObject]
          }
        contents.append(contentsOf: extra)
        deque.append(copying: extra)
        expectIterableContents(
          deque,
          equivalentTo: contents,
          by: ==,
          printer: { "\($0)" })
      }
    }
  }
  
  func test_insert() {
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

  func test_imsert_initializingWith_full() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("i", in: 0 ... layout.count) { i in
        withEvery("c", in: 0 ..< layout.freeCapacity) { c in
          withLifetimeTracking { tracker in
            var data = tracker.rigidDeque(with: layout)
            
            let extras = tracker.instances(for: layout.count ..< layout.count + c)
            
            data.contents.insert(contentsOf: extras, at: i)
            
            var j = 0
            data.deque.insert(addingCount: c, at: i) { target in
              expectLessThanOrEqual(target.count, extras.count - j)
              while !target.isFull {
                target.append(extras[j])
                j += 1
              }
            }
            expectEqual(j, extras.count)

            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }
  
  func test_insert_initializingWith_partial() {
    withEveryDeque("layout", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      guard layout.freeCapacity > 0 else { return }
      withEvery("i", in: 0 ... layout.count) { i in
        withEvery("c", in: 0 ..< layout.freeCapacity - 1) { c in
          withLifetimeTracking { tracker in
            var data = tracker.rigidDeque(with: layout)
            
            let extras = tracker.instances(for: layout.count ..< layout.count + c)
            
            data.contents.insert(contentsOf: extras, at: i)
            
            var j = 0
            data.deque.insert(addingCount: layout.freeCapacity, at: i) { target in
              while !target.isFull, j < c {
                target.append(extras[j])
                j += 1
              }
            }
            expectEqual(j, extras.count)
            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }
  
  func test_insert_initializingWith_failing() {
    withEveryDeque("layout", ofCapacities: [1, 2, 3, 5, 10]) { layout in
      if layout.freeCapacity == 0 { return }
      withEvery("i", in: 0 ... layout.count) { i in
        withEvery("c", in: 0 ..< layout.freeCapacity - 1) { c in
          withLifetimeTracking { tracker in
            var data = tracker.rigidDeque(with: layout)
            
            let extras = tracker.instances(for: layout.count ..< layout.count + c)
            
            data.contents.insert(contentsOf: extras, at: i)
            
            expectThrows { () throws(TestError) in
              var j = 0
              try data.deque.insert(
                addingCount: layout.freeCapacity,
                at: i
              ) { target throws(TestError) in
                while !target.isFull, j < c {
                  target.append(extras[j])
                  j += 1
                }
                if j == c {
                  throw TestError(42)
                }
              }
            }
            errorHandler: { error in
              expectEqual(error.value, 42)
            }
            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_insert_fromProducer() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      withEvery("i", in: 0 ... layout.count) { i in
        withEvery("c", in: 0 ..< 6) { c in
          withLifetimeTracking { tracker in
            var data = tracker.rigidDeque(with: layout)
            
            var extras = tracker.instances(for: 0 ..< c)
            
            data.contents.insert(
              contentsOf: extras.prefix(layout.freeCapacity),
              at: i)
            
            var producer = CustomProducer<LifetimeTracked<Int>, Never> {
              guard !extras.isEmpty else { return nil }
              return extras.removeFirst()
            }
            
            data.deque.insert(
              addingCount: layout.freeCapacity,
              from: &producer,
              at: i)
            expectEqual(extras.count, max(0, c - layout.freeCapacity))
            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }
#endif
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_insert_fromProducer_failing() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5]) { layout in
      guard layout.freeCapacity > 0 else { return }
      withEvery("i", in: 0 ... layout.count) { i in
        withEvery("c", in: 0 ..< layout.freeCapacity - 1) { c in
          withLifetimeTracking { tracker in
            var data = tracker.rigidDeque(with: layout)
            
            var extras = tracker.instances(for: 0 ..< c)
            
            data.contents.insert(contentsOf: extras, at: i)
            
            var producer = CustomProducer<LifetimeTracked<Int>, TestError> { () throws(TestError) in
              guard !extras.isEmpty else { throw TestError(23) }
              return extras.removeFirst()
            }
            
            expectThrows { () throws(TestError) in
              try data.deque.insert(
                addingCount: layout.freeCapacity,
                from: &producer,
                at: i)
            }
            errorHandler: { error in
              expectEqual(error.value, 23)
            }
            expectEqual(extras.count, 0)
            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }
#endif

  func test_insert_MinimalCollection() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("i", in: 0 ... layout.count) { i in
        withEvery("c", in: 0 ..< layout.freeCapacity) { c in
          withEvery("isContiguous", in: [false, true]) { isContiguous in
            withLifetimeTracking { tracker in
              var data = tracker.rigidDeque(with: layout)
              let extras = tracker.instances(
                for: layout.count ..< layout.count + c)
              let collection = MinimalCollection(
                extras,
                isContiguous: isContiguous)
              data.contents.insert(contentsOf: extras, at: i)
              data.deque.insert(copying: collection, at: i)
              expectIterableContents(data.deque, equalTo: data.contents)
            }
          }
        }
      }
    }
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  func test_insert_RigidArray() {
    withEveryDeque("layout", ofCapacities: [0, 1, 2, 3, 5, 10]) { layout in
      withEvery("i", in: 0 ... layout.count) { i in
        withEvery("c", in: 0 ..< layout.freeCapacity) { c in
          withLifetimeTracking { tracker in
            var data = tracker.rigidDeque(with: layout)
            let extras = tracker.instances(
              for: layout.count ..< layout.count + c)
            data.contents.insert(contentsOf: extras, at: i)

            let array = RigidArray(copying: extras)
            data.deque.insert(copying: array, at: i)
            expectIterableContents(data.deque, equalTo: data.contents)
          }
        }
      }
    }
  }
#endif

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
#endif
