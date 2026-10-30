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
import SpanPreview
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview
/// Test that the removal and consumption operations of a `DrainableContainer`
/// edit it the way `removeSubrange(_:)` edits an `Array` holding the same
/// items:
///
/// - The drain returned by `consumeSubrange(_:)` hands out the items of the
///   subrange in order, in spans of at most `maxCount` items, and then only
///   empty spans. Its `count` is the number of items it has yet to hand out.
/// - Whether it is finalized or dropped, and however many items it has handed
///   out, the drain removes the whole subrange, discarding the items it did
///   not hand out and those left in its spans. `finalize()` returns the index
///   following the removed items.
/// - `consumeSubrange(_:consumingWith:)` passes the removed items to its
///   consumer, in order, and discards any the consumer leaves.
/// - `remove(at:)` and `removeFirst()` return the removed item.
/// - The returned indices, and the index passed to `remove(at:)` as inout,
///   address the position following the removed items.
/// - The `RangeExpression2` and `UnboundedRange` overloads remove the items
///   they express.
/// - No item is leaked or destroyed, other than the removed items that are not
///   handed out.
///
/// Every subrange of a container of `count` items is removed. `makeContainer`
/// must return a new container holding the given items in order.
@available(SwiftStdlib 6.4, *)
package func checkDrainableContainer<C: DrainableContainer & ~Copyable>(
  count: Int,
  file: StaticString = #filePath,
  line: UInt = #line,
  makeContainer: ([LifetimeTracked<Int>]) -> C
) where C.Element == LifetimeTracked<Int> {
  let entry = TestContext.current.push(
    "checkDrainableContainer", file: file, line: line)
  defer { TestContext.current.pop(entry) }
  checkDrainLaws(
    count: count, file: file, line: line, makeContainer: makeContainer)
}

/// Test the operations of a bidirectional `DrainableContainer` as above, along
/// with `consumeLast(_:)`, `removeLast()`, `removeLast(_:)` and `popLast()`,
/// which returns nil on an empty container.
@available(SwiftStdlib 6.4, *)
package func checkDrainableContainer<
  C: BidirectionalContainer & DrainableContainer & ~Copyable
>(
  count: Int,
  file: StaticString = #filePath,
  line: UInt = #line,
  makeContainer: ([LifetimeTracked<Int>]) -> C
) where C.Element == LifetimeTracked<Int> {
  let entry = TestContext.current.push(
    "checkDrainableContainer", file: file, line: line)
  defer { TestContext.current.pop(entry) }
  checkDrainLaws(
    count: count, file: file, line: line, makeContainer: makeContainer)

  func check(
    _ label: String,
    _ removed: Range<Int>,
    taking takenCount: Int = 0,
    _ remove: (inout C, inout [LifetimeTracked<Int>]) -> C.Index?
  ) {
    checkDrainLaw(
      label, count: count, removing: removed, taking: takenCount,
      file: file, line: line, makeContainer: makeContainer, remove)
  }

  withEvery("n", in: 0 ... count) { n in
    check("consumeLast(_:)", count - n ..< count, taking: n) {
      container, taken in
      drain(
        container.consumeLast(n), count: n, into: &taken,
        file: file, line: line)
    }
    check("removeLast(_:)", count - n ..< count) { container, _ in
      container.removeLast(n)
      return nil
    }
  }
  let last = count - min(count, 1) ..< count
  check("popLast()", last, taking: last.count) { container, taken in
    if let item = container.popLast() {
      taken.append(item)
    }
    return nil
  }
  if count > 0 {
    check("removeLast()", last, taking: 1) { container, taken in
      taken.append(container.removeLast())
      return nil
    }
  }
}

@available(SwiftStdlib 6.4, *)
private func checkDrainLaws<C: DrainableContainer & ~Copyable>(
  count: Int,
  file: StaticString,
  line: UInt,
  makeContainer: ([LifetimeTracked<Int>]) -> C
) where C.Element == LifetimeTracked<Int> {
  func check(
    _ label: String,
    _ removed: Range<Int>,
    taking takenCount: Int = 0,
    _ remove: (inout C, inout [LifetimeTracked<Int>]) -> C.Index?
  ) {
    checkDrainLaw(
      label, count: count, removing: removed, taking: takenCount,
      file: file, line: line, makeContainer: makeContainer, remove)
  }

  func index(_ offset: Int, in container: borrowing C) -> C.Index {
    container.index(container.startIndex, offsetBy: offset)
  }

  func bounds(
    _ subrange: Range<Int>, in container: borrowing C
  ) -> Range<C.Index> {
    index(subrange.lowerBound, in: container)
      ..< index(subrange.upperBound, in: container)
  }

  func checkExpression<R: RangeExpression2<C.Index>>(
    _ name: String,
    _ subrange: Range<Int>,
    _ expression: (borrowing C) -> R
  ) {
    check("consumeSubrange(_: \(name))", subrange, taking: subrange.count) {
      container, taken in
      drain(
        container.consumeSubrange(expression(container)),
        count: subrange.count, into: &taken, file: file, line: line)
    }
    check(
      "consumeSubrange(_: \(name), consumingWith:)", subrange,
      taking: subrange.count
    ) { container, taken in
      container.consumeSubrange(expression(container)) { span in
        while !span.isEmpty {
          taken.append(span.removeFirst())
        }
      }
    }
    check("removeSubrange(_: \(name))", subrange) { container, _ in
      container.removeSubrange(expression(container))
    }
  }

  withEveryRange("subrange", in: 0 ..< count) { subrange in
    let takenCounts = Set([0, subrange.count / 2, subrange.count]).sorted()
    withEvery("maxCount", in: [1, 2, Int.max]) { maxCount in
      check("consumeSubrange(_:)", subrange, taking: subrange.count) {
        container, taken in
        drain(
          container.consumeSubrange(bounds(subrange, in: container)),
          count: subrange.count, maxCount: maxCount, into: &taken,
          file: file, line: line)
      }
      withEvery("takenCount", in: takenCounts) { takenCount in
        withEvery("finalized", in: [false, true]) { finalized in
          check("consumeSubrange(_:)", subrange, taking: takenCount) {
            container, taken in
            drain(
              container.consumeSubrange(bounds(subrange, in: container)),
              count: subrange.count, maxCount: maxCount, taking: takenCount,
              finalizing: finalized, into: &taken, file: file, line: line)
          }
        }
      }
    }
    withEvery("takenCount", in: takenCounts) { takenCount in
      check(
        "consumeSubrange(_:consumingWith:)", subrange, taking: takenCount
      ) { container, taken in
        var offered: [Int] = []
        let index = container.consumeSubrange(
          bounds(subrange, in: container)
        ) { span in
          for position in span.indices {
            offered.append(span[position].payload)
          }
          while taken.count < takenCount, !span.isEmpty {
            taken.append(span.removeFirst())
          }
        }
        expectEqual(offered, Array(subrange),
                    "consumer was not passed the removed items",
                    file: file, line: line)
        return index
      }
    }
    check("removeSubrange(_:)", subrange) { container, _ in
      container.removeSubrange(bounds(subrange, in: container))
    }
    checkExpression("Range", subrange) { bounds(subrange, in: $0) }
    if !subrange.isEmpty {
      checkExpression("ClosedRange", subrange) {
        index(subrange.lowerBound, in: $0)
          ... index(subrange.upperBound - 1, in: $0)
      }
    }
    if subrange.upperBound == count {
      checkExpression("PartialRangeFrom", subrange) {
        index(subrange.lowerBound, in: $0)...
      }
    }
    if subrange.lowerBound == 0 {
      checkExpression("PartialRangeUpTo", subrange) {
        ..<index(subrange.upperBound, in: $0)
      }
      if !subrange.isEmpty {
        checkExpression("PartialRangeThrough", subrange) {
          ...index(subrange.upperBound - 1, in: $0)
        }
      }
    }
  }

  withEvery("offset", in: 0 ..< count) { offset in
    check("remove(at:)", offset ..< offset + 1, taking: 1) {
      container, taken in
      taken.append(container.remove(at: index(offset, in: container)))
      return nil
    }
    check("remove(at: inout Index)", offset ..< offset + 1, taking: 1) {
      container, taken in
      var position = index(offset, in: container)
      taken.append(container.remove(at: &position))
      return position
    }
  }

  withEvery("n", in: 0 ... count) { n in
    check("consumeFirst(_:)", 0 ..< n, taking: n) { container, taken in
      drain(
        container.consumeFirst(n), count: n, into: &taken,
        file: file, line: line)
    }
    check("removeFirst(_:)", 0 ..< n) { container, _ in
      container.removeFirst(n)
      return nil
    }
  }
  if count > 0 {
    check("removeFirst()", 0 ..< 1, taking: 1) { container, taken in
      taken.append(container.removeFirst())
      return nil
    }
  }

  check("consumeAll()", 0 ..< count, taking: count) { container, taken in
    drain(
      container.consumeAll(), count: count, into: &taken,
      file: file, line: line)
  }
  check("consumeAll(consumingWith:)", 0 ..< count, taking: count) {
    container, taken in
    container.consumeAll { span in
      while !span.isEmpty {
        taken.append(span.removeFirst())
      }
    }
    return nil
  }
  check("consumeSubrange(_: UnboundedRange)", 0 ..< count, taking: count) {
    container, taken in
    drain(
      container.consumeSubrange(...), count: count, into: &taken,
      file: file, line: line)
  }
  check(
    "consumeSubrange(_: UnboundedRange, consumingWith:)", 0 ..< count,
    taking: count
  ) { container, taken in
    container.consumeSubrange(...) { span in
      while !span.isEmpty {
        taken.append(span.removeFirst())
      }
    }
  }
  check("removeSubrange(_: UnboundedRange)", 0 ..< count) { container, _ in
    container.removeSubrange(...)
  }
  check("removeAll()", 0 ..< count) { container, _ in
    container.removeAll()
    return nil
  }
}

@available(SwiftStdlib 6.4, *)
private func checkDrainLaw<C: DrainableContainer & ~Copyable>(
  _ label: String,
  count: Int,
  removing removed: Range<Int>,
  taking takenCount: Int,
  file: StaticString,
  line: UInt,
  makeContainer: ([LifetimeTracked<Int>]) -> C,
  _ remove: (inout C, inout [LifetimeTracked<Int>]) -> C.Index?
) where C.Element == LifetimeTracked<Int> {
  let entry = TestContext.current.push(label, file: file, line: line)
  defer { TestContext.current.pop(entry) }
  var expected = Array(0 ..< count)
  expected.removeSubrange(removed)
  withLifetimeTracking(file: file, line: line) { tracker in
    var container = makeContainer(tracker.instances(for: 0 ..< count))
    var taken: [LifetimeTracked<Int>] = []
    let index = remove(&container, &taken)
    expectEqual(
      taken.map { $0.payload }, Array(removed.prefix(takenCount)),
      "\(label) did not hand out the removed items in order",
      file: file, line: line)
    if let index {
      expectEqual(
        container.distance(from: container.startIndex, to: index),
        removed.lowerBound,
        "\(label) returned an index that does not follow the removed items",
        file: file, line: line)
    }
    expectEqual(tracker.instances, expected.count + taken.count,
                "\(label) leaked or destroyed items",
                file: file, line: line)
    var actual: [Int] = []
    var position = container.startIndex
    while position != container.endIndex {
      actual.append(container[position].payload)
      container.formIndex(after: &position)
    }
    expectEqual(actual, expected, "\(label) left the wrong contents",
                file: file, line: line)
  }
}

@available(SwiftStdlib 6.4, *)
private func drain<
  D: ContainerDrain<LifetimeTracked<Int>> & ~Copyable & ~Escapable
>(
  _ consumer: consuming D,
  count: Int,
  maxCount: Int = .max,
  taking takenCount: Int = .max,
  finalizing: Bool = true,
  into taken: inout [LifetimeTracked<Int>],
  file: StaticString,
  line: UInt
) -> D.Index? {
  var handedOut = 0
  while taken.count < takenCount, handedOut <= count {
    expectEqual(consumer.count, count - handedOut,
                "drain miscounted the items it has left",
                file: file, line: line)
    var span = consumer.drainNext(maxCount: maxCount)
    if span.isEmpty { break }
    expectLessThanOrEqual(span.count, maxCount,
                          "drainNext(maxCount:) returned too many items",
                          file: file, line: line)
    handedOut += span.count
    while taken.count < takenCount, !span.isEmpty {
      taken.append(span.removeFirst())
    }
  }
  if taken.count < takenCount {
    expectTrue(consumer.drainNext(maxCount: maxCount).isEmpty,
               "drainNext(maxCount:) returned items after an empty span",
               file: file, line: line)
  }
  guard finalizing else { return nil }
  return consumer.finalize()
}
#endif
