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
import Future

@available(SwiftCompatibilitySpan 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  internal func _indicesByIndexAfter() -> [Index] {
    var result: [Index] = []
    var i = startIndex
    while i != endIndex {
      result.append(i)
      i = index(after: i)
    }
    return result
  }

  @inlinable
  internal func _indicesByFormIndexAfter() -> [Index] {
    var result: [Index] = []
    var i = startIndex
    while i != endIndex {
      result.append(i)
      formIndex(after: &i)
    }
    return result
  }
}

@available(SwiftCompatibilitySpan 5.0, *)
public func checkContainer<
  C: Container & ~Copyable & ~Escapable,
  Expected: Sequence<C.Element>
>(
  _ container: borrowing C,
  expectedContents: Expected,
  file: StaticString = #file,
  line: UInt = #line
) where C.Element: Equatable {
  checkContainer(
    container,
    expectedContents: expectedContents,
    by: ==,
    file: file, line: line)
}

@available(SwiftCompatibilitySpan 5.0, *)
public func checkContainer<
  C: Container & ~Copyable & ~Escapable,
  Expected: Sequence<C.Element>
>(
  _ container: borrowing C,
  expectedContents: Expected,
  by areEquivalent: (C.Element, C.Element) -> Bool,
  file: StaticString = #file,
  line: UInt = #line
) where C.Element: Equatable {
  let entry = TestContext.current.push("checkContainer", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  let expectedContents = Array(expectedContents)
  expectEqual(container.isEmpty, expectedContents.isEmpty)
  let actualCount = container.count
  expectEqual(actualCount, expectedContents.count)

  let validIndices = container._indicesByIndexAfter()

  expectEqual(
    container._indicesByIndexAfter(), validIndices,
    "Container does not have stable indices")

  // Check that `index(after:)` produces the same results as `formIndex(after:)`
  do {
    let indicesByFormIndexAfter = container._indicesByFormIndexAfter()
    expectEqual(indicesByFormIndexAfter, validIndices)
  }

  expectEqual(container.index(container.startIndex, offsetBy: container.count), container.endIndex)

  // Check contents using indexing.
  let actualContents = validIndices.map { container[$0] }
  expectEquivalentElements(actualContents, expectedContents, by: areEquivalent)

  let allIndices = validIndices + [container.endIndex]
  do {
    var last: C.Index? = nil
    for index in allIndices {
      if let last {
        // The indices must be monotonically increasing.
        expectGreaterThan(
          index, last,
          "Index \(index) is not greater than immediately preceding index \(last)")

        // Aligning a valid index must not change it.
        let nearestDown = container.index(alignedDown: index)
        expectEqual(nearestDown, index, "Aligning a valid index down must not change its position")
        let nearestUp = container.index(alignedUp: index)
        expectEqual(nearestUp, index, "Aligning a valid index up must not change its position")
      }
      last = index
    }
  }

  // Check the `Comparable` conformance of the Index type.
  if C.Index.self != Int.self {
    checkComparable(allIndices, oracle: { .comparing($0, $1) })
  }

  withEveryRange("range", in: 0 ..< allIndices.count - 1) { range in
    let i = range.lowerBound
    let j = range.upperBound

    // Check `index(_,offsetBy:)`
    let e = container.index(allIndices[i], offsetBy: j - i)
    expectEqual(e, allIndices[j])
    if j < expectedContents.count {
      expectEquivalent(container[e], expectedContents[j], by: areEquivalent)
    }

    // Check `distance(from:to:)`
    let d = container.distance(from: allIndices[i], to: allIndices[j])
    expectEqual(d, j - i)
  }

  // Check `formIndex(_,offsetBy:limitedBy:)`
  let limits =
  Set([0, allIndices.count - 1, allIndices.count / 2])
    .sorted()
  withEvery("limit", in: limits) { limit in
    withEvery("i", in: 0 ..< allIndices.count) { i in
      let max = allIndices.count - i + (limit >= i ? 2 : 0)
      withEvery("delta", in: 0 ..< max) { delta in
        let target = i + delta
        var index = allIndices[i]
        var d = delta
        container.formIndex(&index, offsetBy: &d, limitedBy: allIndices[limit])
        if i > limit {
          expectEqual(d, 0, "Nonzero remainder after jump opposite limit")
          expectEqual(index, allIndices[target], "Jump opposite limit landed in wrong position")
        } else if target <= limit {
          expectEqual(d, 0, "Nonzero remainder after jump within limit")
          expectEqual(index, allIndices[target], "Jump within limit landed in wrong position")
        } else {
          expectEqual(d, target - limit, "Unexpected remainder after jump beyond limit")
          expectEqual(index, allIndices[limit], "Jump beyond limit landed in unexpected position")
        }
      }
    }
  }

  // Check that the spans seem plausibly sized and that the indices are monotonic.
  let spanShapes: [(offsetRange: Range<Int>, indexRange: Range<C.Index>)] = {
    var r: [(offsetRange: Range<Int>, indexRange: Range<C.Index>)] = []
    var pos = 0
    var index = container.startIndex
    while true {
      let origIndex = index
      let origPos = pos
      let span = container.nextSpan(after: &index)
      pos += span.count
      if span.isEmpty {
        expectEqual(origIndex, container.endIndex)
        expectEqual(index, origIndex, "nextCount is not expected to move the end index")
        break
      }
      expectGreaterThan(
        index, origIndex, "nextCount does not monotonically increase the index")
      expectEqual(
        index, allIndices[pos], "nextCount does not increase the index by the size of the span")
      r.append((origPos ..< pos, origIndex ..< index))
    }
    return r
  }()
  expectEqual(
    spanShapes.reduce(into: 0, { $0 += $1.offsetRange.count }), actualCount,
    "Container's count does not match the sum of its spans")


  // Check that the spans have stable sizes and the expected contents.
  do {
    var pos = 0
    var index = container.startIndex
    var spanIndex = 0
    while true {
      let span = container.nextSpan(after: &index)
      if span.isEmpty { break }
      expectEqual(
        span.count, spanShapes[spanIndex].offsetRange.count,
        "Container has nondeterministic span sizes")
      expectEqual(
        index, spanShapes[spanIndex].indexRange.upperBound,
        "Container has nondeterministic span boundaries")
      for i in 0 ..< span.count {
        expectEqual(span[i], expectedContents[pos])
        pos += 1
      }
      spanIndex += 1
    }
    expectEqual(spanIndex, spanShapes.endIndex)
    expectEqual(pos, expectedContents.count)
  }

  // Check that we can get a span beginning at every index, and that it extends as much as possible.
  do {
    for spanIndex in spanShapes.indices {
      let (offsetRange, indexRange) = spanShapes[spanIndex]
      for pos in offsetRange {
        let start = validIndices[pos]
        var i = start
        let span = container.nextSpan(after: &i)

        expectEqual(span.count, offsetRange.upperBound - pos,
                    "Unexpected span size at offset \(pos), index \(start)")
        expectEqual(i, indexRange.upperBound,
                    "Unexpected span upper bound at offset \(pos), index \(start)")
      }
    }
  }
}
