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
public func checkMutableContainer<
  C: BidirectionalContainer & MutableContainer & ~Copyable & ~Escapable,
  Expected: Sequence<C.Element>
>(
  _ container: inout C,
  expectedContents: Expected,
  file: StaticString = #filePath,
  line: UInt = #line
) where C.Element: Equatable {
  let entry = TestContext.current.push(
    "checkMutableContainer", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  do {
    try validateMutableContainer(&container, expectedContents: expectedContents)
  } catch {
    expectFailure(error.message, file: file, line: line)
  }
}

@available(SwiftStdlib 6.4, *)
@inlinable
public func validateMutableContainer<
  C: BidirectionalContainer & MutableContainer & ~Copyable & ~Escapable,
  Expected: Sequence<C.Element>
>(
  _ container: inout C,
  expectedContents: Expected
) throws(ValidationError) where C.Element: Equatable {
  let expectedContents = Array(expectedContents)
  try validateBidirectionalContainer(
    container,
    expectedContents: expectedContents,
    by: ==,
    printer: { "\($0)" })

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

  func checkSpan(
    _ api: String,
    _ span: borrowing MutableSpan<C.Element>,
    index: C.Index,
    at offset: Int,
    maxCount: Int,
    limit: Int,
    expected range: Range<Int>,
    expectedIndex: Int
  ) throws(ValidationError) {
    guard span.count == range.count, index == allIndices[expectedIndex] else {
      throw ValidationError(
        "`\(api)` must return the span within its limits, and update the index",
        ["index": allIndices[offset],
         "maxCount": maxCount,
         "limit": allIndices[limit],
         "expected index": allIndices[expectedIndex],
         "expected count": range.count,
         "actual index": index,
         "actual count": span.count])
    }
    for k in span.indices {
      guard span[k] == expectedContents[range.lowerBound + k] else {
        throw ValidationError(
          "`\(api)` must expose the expected contents",
          ["index": allIndices[offset],
           "offset within span": k,
           "actual content": span[k],
           "expected content": expectedContents[range.lowerBound + k]])
      }
    }
  }

  // *** nextMutableSpan(after:), nextMutableSpan(after:maxCount:limitedBy:)
  for offset in 0 ... count {
    let end = boundaries.first(where: { $0 > offset }) ?? count
    var i = allIndices[offset]
    let span = container.nextMutableSpan(after: &i)
    try checkSpan(
      "nextMutableSpan(after:)", span,
      index: i, at: offset, maxCount: Int.max, limit: count,
      expected: offset ..< end, expectedIndex: end)
    for maxCount in [1, 2, Int.max - 1, Int.max] {
      for limit in limits {
        let upper = Swift.min(
          limit >= offset ? Swift.min(limit, end) : end,
          offset + Swift.min(maxCount, count - offset))
        var j = allIndices[offset]
        let next = container.nextMutableSpan(
          after: &j, maxCount: maxCount, limitedBy: allIndices[limit])
        try checkSpan(
          "nextMutableSpan(after:maxCount:limitedBy:)", next,
          index: j, at: offset, maxCount: maxCount, limit: limit,
          expected: offset ..< upper, expectedIndex: upper)
      }
    }
  }

  // *** previousMutableSpan(before:),
  // *** previousMutableSpan(before:maxCount:limitedBy:)
  for offset in 0 ... count {
    let start = boundaries.last(where: { $0 < offset }) ?? 0
    var i = allIndices[offset]
    let span = container.previousMutableSpan(before: &i)
    try checkSpan(
      "previousMutableSpan(before:)", span,
      index: i, at: offset, maxCount: Int.max, limit: 0,
      expected: start ..< offset, expectedIndex: start)
    for maxCount in [1, 2, Int.max - 1, Int.max] {
      for limit in limits {
        let lower = Swift.max(
          limit <= offset ? Swift.max(limit, start) : start,
          offset - Swift.min(maxCount, offset))
        var j = allIndices[offset]
        let previous = container.previousMutableSpan(
          before: &j, maxCount: maxCount, limitedBy: allIndices[limit])
        try checkSpan(
          "previousMutableSpan(before:maxCount:limitedBy:)", previous,
          index: j, at: offset, maxCount: maxCount, limit: limit,
          expected: lower ..< offset, expectedIndex: lower)
      }
    }
  }

  // *** Writes through nextMutableSpan(after:), previousMutableSpan(before:)
  func checkContents(
    _ api: String, _ contents: [C.Element]
  ) throws(ValidationError) {
    for offset in 0 ..< count {
      guard container[allIndices[offset]] == contents[offset] else {
        throw ValidationError(
          "Writes through `\(api)` must update the corresponding elements",
          ["offset": offset,
           "expected": contents[offset],
           "actual": container[allIndices[offset]]])
      }
    }
  }

  let rotated = (0 ..< count).map { expectedContents[($0 + count - 1) % count] }
  for start in boundaries.dropLast() {
    var i = allIndices[start]
    var span = container.nextMutableSpan(after: &i)
    for k in span.indices {
      span[k] = rotated[start + k]
    }
  }
  try checkContents("nextMutableSpan(after:)", rotated)
  for end in boundaries.dropFirst().reversed() {
    var i = allIndices[end]
    var span = container.previousMutableSpan(before: &i)
    for k in span.indices {
      span[k] = expectedContents[end - span.count + k]
    }
  }
  try checkContents("previousMutableSpan(before:)", expectedContents)
}
#endif
