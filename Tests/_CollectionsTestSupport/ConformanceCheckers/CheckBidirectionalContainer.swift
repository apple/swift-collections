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
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
@inlinable
public func checkBidirectionalContainer<
  C: BidirectionalContainer & ~Copyable & ~Escapable,
  Expected: Sequence<C.Element>
>(
  _ container: borrowing C,
  expectedContents: Expected,
  file: StaticString = #filePath,
  line: UInt = #line
) where C.Element: Equatable {
  let entry = TestContext.current.push(
    "checkBidirectionalContainer", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  do {
    try validateBidirectionalContainer(
      container,
      expectedContents: expectedContents,
      by: ==,
      printer: { "\($0)" })
  } catch {
    expectFailure(error.message, file: file, line: line)
  }
}

@available(SwiftStdlib 6.4, *)
@inlinable
public func validateBidirectionalContainer<
  C: BidirectionalContainer & ~Copyable & ~Escapable,
  Expected: Sequence
>(
  _ container: borrowing C,
  expectedContents: Expected,
  by areEquivalent: (borrowing C.Element, Expected.Element) -> Bool,
  printer: (borrowing C.Element) -> String
) throws(ValidationError) where C.Element: ~Copyable {
  let expectedContents = Array(expectedContents)
  try validateContainer(
    container,
    expectedContents: expectedContents,
    by: areEquivalent,
    printer: printer)

  let count = container.count
  var allIndices = [container.startIndex]
  for offset in 0 ..< count {
    allIndices.append(container.index(after: allIndices[offset]))
  }
  var boundaries = [0]
  for chunk in container._chunks() {
    boundaries.append(boundaries[boundaries.count - 1] + chunk.count)
  }
  let limits = Set([0, count, count / 2]).sorted()

  // *** index(before:), formIndex(before:)
  for offset in 0 ..< count {
    let i = allIndices[offset + 1]
    let j = container.index(before: i)
    var k = i
    container.formIndex(before: &k)
    guard j == allIndices[offset], k == j else {
      throw ValidationError(
        "`index(before:)` and `formIndex(before:)` must undo `index(after:)`",
        ["index": i,
         "expected": allIndices[offset],
         "index(before:) result": j,
         "formIndex(before:) result": k])
    }
  }

  // *** spanBoundary(before:), spanBoundary(before:maxDistance:limitedBy:)
  func expectedStart(before i: Int, maxCount: Int, limit: Int?) -> Int {
    let start = boundaries.last(where: { $0 < i }) ?? 0
    let bound = Swift.max(start, i - Swift.min(maxCount, i))
    guard let limit, limit <= i else { return bound }
    return Swift.max(bound, limit)
  }

  func checkSpanBoundary(
    before i: Int, maxDistance: Int?, limit: Int?
  ) throws(ValidationError) {
    let api: String
    let r: (index: C.Index, distance: Int)
    if let maxDistance, let limit {
      api = "spanBoundary(before:maxDistance:limitedBy:)"
      r = container.spanBoundary(
        before: allIndices[i],
        maxDistance: maxDistance,
        limitedBy: allIndices[limit])
    } else if let maxDistance {
      api = "spanBoundary(before:maxDistance:)"
      r = container.spanBoundary(
        before: allIndices[i], maxDistance: maxDistance)
    } else {
      api = "spanBoundary(before:)"
      r = container.spanBoundary(before: allIndices[i])
    }
    let j = expectedStart(
      before: i, maxCount: maxDistance ?? Int.max, limit: limit)
    guard r.index == allIndices[j], r.distance == i - j else {
      throw ValidationError(
        "`\(api)` must return the nearest span boundary within its limits",
        ["index": allIndices[i],
         "maxDistance": maxDistance ?? Int.max,
         "limit": limit.map { allIndices[$0] } ?? container.startIndex,
         "expected index": allIndices[j],
         "expected distance": i - j,
         "actual index": r.index,
         "actual distance": r.distance])
    }
  }

  for i in 0 ... count {
    try checkSpanBoundary(before: i, maxDistance: nil, limit: nil)
    for maxDistance in [1, 2, Int.max - 1, Int.max] {
      try checkSpanBoundary(before: i, maxDistance: maxDistance, limit: nil)
      for limit in limits {
        try checkSpanBoundary(before: i, maxDistance: maxDistance, limit: limit)
      }
    }
  }

  // *** previousSpan(before:), previousSpan(before:maxCount:limitedBy:)
  func checkPreviousSpan(
    before i: Int, maxCount: Int?, limit: Int?
  ) throws(ValidationError) {
    let api: String
    var index = allIndices[i]
    let span: Span<C.Element>
    if let maxCount, let limit {
      api = "previousSpan(before:maxCount:limitedBy:)"
      span = container.previousSpan(
        before: &index, maxCount: maxCount, limitedBy: allIndices[limit])
    } else if let maxCount {
      api = "previousSpan(before:maxCount:)"
      span = container.previousSpan(before: &index, maxCount: maxCount)
    } else {
      api = "previousSpan(before:)"
      span = container.previousSpan(before: &index)
    }
    let j = expectedStart(
      before: i, maxCount: maxCount ?? Int.max, limit: limit)
    guard span.count == i - j, index == allIndices[j] else {
      throw ValidationError(
        "`\(api)` must return the span ending at the index and move before it",
        ["index": allIndices[i],
         "maxCount": maxCount ?? Int.max,
         "limit": limit.map { allIndices[$0] } ?? container.startIndex,
         "expected index": allIndices[j],
         "expected count": i - j,
         "actual index": index,
         "actual count": span.count])
    }
    for k in 0 ..< span.count {
      guard areEquivalent(span[k], expectedContents[j + k]) else {
        throw ValidationError(
          "`\(api)` must expose the expected contents",
          ["index": allIndices[i],
           "offset within span": k,
           "actual content": printer(span[k]),
           "expected content": expectedContents[j + k]])
      }
    }
  }

  for i in 0 ... count {
    try checkPreviousSpan(before: i, maxCount: nil, limit: nil)
    for maxCount in [1, 2, Int.max - 1, Int.max] {
      try checkPreviousSpan(before: i, maxCount: maxCount, limit: nil)
      for limit in limits {
        try checkPreviousSpan(before: i, maxCount: maxCount, limit: limit)
      }
    }
  }

  // *** index(_:offsetBy:), distance(from:to:)
  for i in 0 ... count {
    for j in 0 ... count {
      let index = container.index(allIndices[i], offsetBy: j - i)
      guard index == allIndices[j] else {
        throw ValidationError(
          "`index(_:offsetBy:)` must be consistent with `index(after:)`",
          ["index": allIndices[i],
           "offset": j - i,
           "expected": allIndices[j],
           "actual": index])
      }
      let distance = container.distance(from: allIndices[i], to: allIndices[j])
      guard distance == j - i else {
        throw ValidationError(
          "`distance(from:to:)` must be consistent with `index(after:)`",
          ["start": allIndices[i],
           "end": allIndices[j],
           "expected": j - i,
           "actual": distance])
      }
    }
  }

  // *** formIndex(_:offsetBy:limitedBy:)
  for limit in limits {
    for i in 0 ... count {
      for j in -2 ... count + 2 {
        let delta = j - i
        let stops = (i <= limit && limit < j) || (j < limit && limit <= i)
        guard stops || (0 ... count).contains(j) else { continue }
        let expected = stops ? limit : j
        var index = allIndices[i]
        var n = delta
        container.formIndex(&index, offsetBy: &n, limitedBy: allIndices[limit])
        guard index == allIndices[expected], n == delta - expected + i else {
          throw ValidationError(
            "`formIndex(_:offsetBy:limitedBy:)` must observe `limit`",
            ["input index": allIndices[i],
             "input delta": delta,
             "limit": allIndices[limit],
             "expected index": allIndices[expected],
             "expected delta": delta - expected + i,
             "actual index": index,
             "actual delta": n])
        }
      }
    }
  }
}
#endif
