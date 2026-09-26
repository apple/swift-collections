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
import ContainersPreview
import BasicContainers
#endif

#if compiler(>=6.4) && UnstableContainersPreview

/// Copies the contents of a span into an array (spans aren't `Sequence`s).
@available(SwiftStdlib 5.0, *)
func materialize<T>(_ span: Span<T>) -> [T] {
  var result: [T] = []
  for i in span.indices { result.append(span[i]) }
  return result
}

/// A reference-typed element that counts live instances, so tests can catch
/// leaks (under-release) and double-frees (over-release) in `TemporaryArray`'s
/// stack/heap ownership handling.
@available(SwiftStdlib 5.0, *)
final class Tracker {
  nonisolated(unsafe) static var liveCount = 0
  let value: Int
  init(_ value: Int) {
    self.value = value
    Tracker.liveCount += 1
  }
  deinit { Tracker.liveCount -= 1 }
}

@available(SwiftStdlib 5.0, *)
final class TemporaryArrayTests: XCTestCase {
  func test_staysWithinReservedCapacity() {
    withTemporaryArray(of: Int.self, capacity: 8) { array in
      XCTAssertEqual(array.capacity, 8)
      for i in 0 ..< 8 { array.append(i) }
      XCTAssertEqual(array.count, 8)
      XCTAssertEqual(array.capacity, 8, "Should not reallocate within capacity")
      XCTAssertEqual(materialize(array.span), Array(0 ..< 8))
    }
  }

  func test_growsPastReservedCapacity() {
    withTemporaryArray(of: Int.self, capacity: 4) { array in
      for i in 0 ..< 4 { array.append(i) }
      XCTAssertEqual(array.capacity, 4)
      array.append(4) // overflow the initial buffer
      XCTAssertGreaterThanOrEqual(array.capacity, 5)
      XCTAssertEqual(materialize(array.span), Array(0 ..< 5))
    }
  }

  func test_zeroReservedCapacityGrowsOnAppend() {
    withTemporaryArray(of: Int.self, capacity: 0) { array in
      XCTAssertEqual(array.capacity, 0)
      array.append(42)
      XCTAssertGreaterThanOrEqual(array.capacity, 1)
      XCTAssertEqual(materialize(array.span), [42])
    }
  }

  func test_largeInitialCapacity() {
    withTemporaryArray(of: Int.self, capacity: 200) { array in
      XCTAssertGreaterThanOrEqual(array.capacity, 200)
      array.append(copying: 0 ..< 200)
      XCTAssertEqual(materialize(array.span), Array(0 ..< 200))
    }
  }

  func test_noLeakOrDoubleFree_withinCapacity() {
    Tracker.liveCount = 0
    withTemporaryArray(of: Tracker.self, capacity: 8) { array in
      for i in 0 ..< 5 { array.append(Tracker(i)) }
      XCTAssertEqual(Tracker.liveCount, 5)
    }
    XCTAssertEqual(Tracker.liveCount, 0, "Elements in the seed buffer must be released exactly once")
  }

  func test_noLeakOrDoubleFree_afterGrowth() {
    Tracker.liveCount = 0
    withTemporaryArray(of: Tracker.self, capacity: 2) { array in
      for i in 0 ..< 10 { array.append(Tracker(i)) } // forces growth/reallocation
      XCTAssertEqual(Tracker.liveCount, 10)
    }
    XCTAssertEqual(Tracker.liveCount, 0, "Elements must survive growth and be released exactly once")
  }

  func test_take_movesContentsIntoUniqueArray() {
    Tracker.liveCount = 0
    var escaped: UniqueArray<Tracker> = withTemporaryArray(
      of: Tracker.self, capacity: 4
    ) { array in
      for i in 0 ..< 6 { array.append(Tracker(i)) } // grows past capacity
      return array.take()
    }
    XCTAssertEqual(escaped.count, 6)
    XCTAssertEqual(Tracker.liveCount, 6)
    XCTAssertEqual(materialize(escaped.span).map { $0.value }, Array(0 ..< 6))
    escaped.removeAll()
    XCTAssertEqual(Tracker.liveCount, 0)
  }

  func test_take_withinReservedCapacity() {
    Tracker.liveCount = 0
    var escaped: UniqueArray<Tracker> = withTemporaryArray(
      of: Tracker.self, capacity: 8
    ) { array in
      for i in 0 ..< 3 { array.append(Tracker(i)) } // never grows
      return array.take()
    }
    XCTAssertEqual(materialize(escaped.span).map { $0.value }, [0, 1, 2])
    XCTAssertEqual(Tracker.liveCount, 3)
    escaped.removeAll()
    XCTAssertEqual(Tracker.liveCount, 0)
  }

  /// The motivating use case: map/compactMap over an arbitrary sequence using a
  /// stack-reserved scratch buffer sized from `underestimatedCount`.
  func test_useCase_compactMapOverSequence() {
    func compactMapped<S: Sequence>(
      _ source: S, _ transform: (S.Element) -> Int?
    ) -> UniqueArray<Int> {
      withTemporaryArray(
        of: Int.self, capacity: source.underestimatedCount
      ) { scratch in
        for x in source {
          if let y = transform(x) { scratch.append(y) }
        }
        return scratch.take()
      }
    }

    let result = compactMapped(0 ..< 100) { $0.isMultiple(of: 3) ? $0 * 2 : nil }
    XCTAssertEqual(
      materialize(result.span).map { $0 },
      (0 ..< 100).compactMap { $0.isMultiple(of: 3) ? $0 * 2 : nil })
  }

  func test_appendCopyingSequence_grows() {
    withTemporaryArray(of: Int.self, capacity: 2) { array in
      array.append(copying: 0 ..< 50)
      XCTAssertGreaterThanOrEqual(array.capacity, 50)
      XCTAssertEqual(materialize(array.span), Array(0 ..< 50))
    }
  }

  func test_removalsAndInsertions() {
    withTemporaryArray(of: Int.self, capacity: 16) { array in
      array.append(copying: 0 ..< 10)
      array.removeSubrange(2 ..< 5)            // remove 2,3,4
      XCTAssertEqual(materialize(array.span), [0, 1, 5, 6, 7, 8, 9])
      array.insert(99, at: 2)
      XCTAssertEqual(materialize(array.span), [0, 1, 99, 5, 6, 7, 8, 9])
      XCTAssertEqual(array.removeLast(), 9)
      XCTAssertEqual(array.popLast(), 8)
      XCTAssertEqual(materialize(array.span), [0, 1, 99, 5, 6, 7])
    }
  }

  func test_conformsToContainerProtocols() {
    // Exercise the read-side Container conformance via a generic function.
    func sum<C: Container<Int> & ~Copyable & ~Escapable>(
      _ c: borrowing C
    ) -> Int {
      var total = 0
      var i = c.startIndex
      while true {
        let span = c.nextSpan(after: &i)
        if span.isEmpty { break }
        for j in span.indices { total += span[j] }
      }
      return total
    }
    withTemporaryArray(of: Int.self, capacity: 4) { array in
      array.append(copying: 1 ... 10) // spills
      XCTAssertEqual(sum(array), 55)
    }
  }

  // MARK: - Newly mirrored SE-0527 API

  func test_heapBackedInitCapacity() {
    var array = TemporaryArray<Int>(capacity: 4)
    XCTAssertEqual(array.capacity, 4)
    array.append(copying: 0 ..< 4)
    XCTAssertEqual(materialize(array.span), Array(0 ..< 4))
  }

  func test_initCapacityInitializingWith() {
    let escaped: UniqueArray<Int> = {
      var array = TemporaryArray<Int>(capacity: 8) { target in
        for i in 0 ..< 5 { target.append(i * 10) }
      }
      XCTAssertEqual(materialize(array.span), [0, 10, 20, 30, 40])
      return array.take()
    }()
    XCTAssertEqual(materialize(escaped.span), [0, 10, 20, 30, 40])
  }

  func test_appendCopyingBuffer() {
    withTemporaryArray(of: Int.self, capacity: 2) { array in
      var source = [10, 20, 30, 40]
      source.withUnsafeBufferPointer { buffer in
        array.append(copying: buffer) // spills
      }
      XCTAssertEqual(materialize(array.span), [10, 20, 30, 40])
    }
  }

  func test_appendMovingOutputSpan() {
    withTemporaryArray(of: Int.self, capacity: 8) { array in
      array.append(0)
      withTemporaryArray(of: Int.self, capacity: 4) { other in
        other.append(copying: [1, 2, 3])
        other.edit { span in
          array.append(moving: &span)
          XCTAssertEqual(span.count, 0)
        }
      }
      XCTAssertEqual(materialize(array.span), [0, 1, 2, 3])
    }
  }

  func test_removeAtAndRemoveLastK() {
    withTemporaryArray(of: Int.self, capacity: 16) { array in
      array.append(copying: 0 ..< 8)
      XCTAssertEqual(array.remove(at: 3), 3)
      XCTAssertEqual(materialize(array.span), [0, 1, 2, 4, 5, 6, 7])
      array.removeLast(2)
      XCTAssertEqual(materialize(array.span), [0, 1, 2, 4, 5])
    }
  }

  func test_removeSubrangeRangeExpression() {
    withTemporaryArray(of: Int.self, capacity: 16) { array in
      array.append(copying: 0 ..< 10)
      array.removeSubrange(7...)
      XCTAssertEqual(materialize(array.span), Array(0 ..< 7))
      array.removeSubrange(..<2)
      XCTAssertEqual(materialize(array.span), Array(2 ..< 7))
    }
  }

  func test_replaceSubrangeCopying() {
    withTemporaryArray(of: Int.self, capacity: 4) { array in
      array.append(copying: 0 ..< 5) // spills
      array.replaceSubrange(1 ..< 3, copying: [90, 91, 92, 93])
      XCTAssertEqual(materialize(array.span), [0, 90, 91, 92, 93, 3, 4])
    }
  }

  func test_insertCopyingCollection() {
    withTemporaryArray(of: Int.self, capacity: 8) { array in
      array.append(copying: [0, 1, 2])
      array.insert(copying: [97, 98, 99], at: 1)
      XCTAssertEqual(materialize(array.span), [0, 97, 98, 99, 1, 2])
    }
  }

  func test_isTriviallyIdentical() {
    withTemporaryArray(of: Int.self, capacity: 4) { a in
      a.append(copying: [1, 2, 3])
      XCTAssertTrue(a.isTriviallyIdentical(to: a))
      withTemporaryArray(of: Int.self, capacity: 4) { b in
        b.append(copying: [1, 2, 3])
        XCTAssertFalse(a.isTriviallyIdentical(to: b))
      }
    }
  }

  func test_appendRepeating() {
    withTemporaryArray(of: Int.self, capacity: 8) { array in
      array.append(3)
      array.append(repeating: 7, count: 4)
      array.append(repeating: 0, count: 0) // no-op
      XCTAssertEqual(materialize(array.span), [3, 7, 7, 7, 7])
    }
  }

  func test_appendRepeating_growsAndSpills() {
    withTemporaryArray(of: Int.self, capacity: 2) { array in
      array.append(repeating: 9, count: 50)
      XCTAssertGreaterThanOrEqual(array.capacity, 50)
      XCTAssertEqual(materialize(array.span), Array(repeating: 9, count: 50))
    }
  }

  func test_equatable() {
    withTemporaryArray(of: Int.self, capacity: 4) { a in
      a.append(copying: [1, 2, 3])
      withTemporaryArray(of: Int.self, capacity: 8) { b in
        b.append(copying: [1, 2, 3]) // equal contents, distinct storage
        XCTAssertTrue(a == b)
        b.append(4)
        XCTAssertTrue(a != b)
      }
    }
  }

  func test_hashable() {
    func hash(_ body: (inout TemporaryArray<Int>) -> Void) -> Int {
      withTemporaryArray(of: Int.self, capacity: 4) { array in
        body(&array)
        var hasher = Hasher()
        array.hash(into: &hasher)
        return hasher.finalize()
      }
    }
    XCTAssertEqual(
      hash { $0.append(copying: [1, 2, 3]) },
      hash { $0.append(copying: [1, 2, 3]) })
  }

  func test_description() {
    withTemporaryArray(of: Int.self, capacity: 4) { array in
      array.append(copying: [1, 2, 3])
      XCTAssertEqual(array.description, "<3 items>")
      XCTAssertEqual(array.debugDescription, "<3 items>")
    }
  }

  func test_clone_thenTake() {
    Tracker.liveCount = 0
    var escaped: UniqueArray<Tracker> = withTemporaryArray(
      of: Tracker.self, capacity: 8
    ) { array in
      for i in 0 ..< 3 { array.append(Tracker(i)) }
      // clone is only valid for Copyable elements at compile time; Tracker is a
      // class (Copyable reference), so this exercises the reference-copy path.
      var copy = array.clone()
      XCTAssertEqual(copy.count, 3)
      XCTAssertFalse(array.isTriviallyIdentical(to: copy))
      return copy.take()
    }
    XCTAssertEqual(materialize(escaped.span).map { $0.value }, [0, 1, 2])
    XCTAssertEqual(Tracker.liveCount, 3)
    escaped.removeAll()
    XCTAssertEqual(Tracker.liveCount, 0)
  }

  func test_cloneCapacity() {
    withTemporaryArray(of: Int.self, capacity: 4) { array in
      array.append(copying: [1, 2, 3])
      var big = array.clone(capacity: 16)
      XCTAssertEqual(big.capacity, 16)
      XCTAssertEqual(materialize(big.span), [1, 2, 3])
      big.append(4)
      XCTAssertEqual(materialize(big.span), [1, 2, 3, 4])
    }
  }
}

#endif
