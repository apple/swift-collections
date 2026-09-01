//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
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
import ContainersPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
@inlinable
public func checkContainer<
  C: Container & ~Copyable & ~Escapable,
  Expected: Sequence<C.Element>
>(
  _ container: borrowing C,
  expectedContents: Expected,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(C.Failure)
where C.Element: Equatable {
  checkContainer(
    container,
    expectedContents: expectedContents,
    by: ==,
    file: file, line: line)
}

@available(SwiftStdlib 6.4, *)
@inlinable
public func checkContainer<
  C: Container & ~Copyable & ~Escapable,
  Expected: Sequence
>(
  _ container: borrowing C,
  expectedContents: Expected,
  by areEquivalent: (borrowing C.Element, Expected.Element) -> Bool,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(C.Failure) where C.Element: Copyable {
  checkContainer(
    container,
    expectedContents: expectedContents,
    by: areEquivalent,
    printer: { "\($0)" },
    file: file,
    line: line)
}

@available(SwiftStdlib 6.4, *)
@inlinable
public func checkContainer<
  C: Container & ~Copyable & ~Escapable,
  Expected: Sequence
>(
  _ container: borrowing C,
  expectedContents: Expected,
  by areEquivalent: (borrowing C.Element, Expected.Element) -> Bool,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(C.Failure) where C.Element: TestPrintable & ~Copyable {
  checkContainer(
    container,
    expectedContents: expectedContents,
    by: areEquivalent,
    printer: { $0.testDescription },
    file: file,
    line: line)
}

public struct ValidationError: Error {
  public let message: String
  public let file: StaticString
  public let line: UInt

  public init(
    _ message: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    self.message = message
    self.file = file
    self.line = line
  }

  public init(
    _ message: String,
    _ values: KeyValuePairs<String, Any>,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    var message = "\(message)\n"
    for (key, value) in values {
      message += "  \(key): \(value)\n"
    }
    self.message = message
    self.file = file
    self.line = line
  }
}

@available(SwiftStdlib 6.4, *)
@inlinable
public func checkContainer<
  C: Container & ~Copyable & ~Escapable,
  Expected: Sequence
>(
  _ container: borrowing C,
  expectedContents: Expected,
  by areEquivalent: (borrowing C.Element, Expected.Element) -> Bool,
  printer: (borrowing C.Element) -> String,
  file: StaticString = #filePath,
  line: UInt = #line
) where C.Element: ~Copyable {
  let entry = TestContext.current.push("checkContainer", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  do {
    try validateContainer(
      container,
      expectedContents: expectedContents,
      by: areEquivalent,
      printer: printer)
  } catch {
    expectFailure(error.message, file: file, line: line)
  }
}


@available(SwiftStdlib 6.4, *)
@inlinable
public func validateContainer<
  C: Container & ~Copyable & ~Escapable,
  Expected: Sequence
>(
  _ container: borrowing C,
  expectedContents: Expected,
  by areEquivalent: (borrowing C.Element, Expected.Element) -> Bool,
  printer: (borrowing C.Element) -> String,
  file: StaticString = #filePath,
  line: UInt = #line
) throws(ValidationError) where C.Element: ~Copyable {
  let expectedContents = Array(expectedContents)

  // *** isEmpty, count, underestimatedCount
  let underestimatedCount = container.underestimatedCount
  let count = container.count
  let isEmpty = container.isEmpty
  guard count >= 0 else {
    throw ValidationError(
      "`count` must be nonnegative",
      ["count": count])
  }
  guard underestimatedCount >= 0 else {
    throw ValidationError(
      "`underestimatedCount` must be nonnegative",
      ["underestimatedCount": underestimatedCount])
  }
  guard underestimatedCount <= count else {
    throw ValidationError(
      "`underestimatedCount` must be less than or equal to `count`",
      ["underestimatedCount": underestimatedCount,
       "count": count])
  }
  guard isEmpty == (count == 0) else {
    throw ValidationError(
      "`isEmpty` must be consistent with `count`",
      ["isEmpty": isEmpty,
       "count": count])
  }

  // *** startIndex, endIndex
  let startIndex = container.startIndex
  let endIndex = container.endIndex
  guard isEmpty == (startIndex == endIndex) else {
    throw ValidationError(
      "`isEmpty` must be consistent with `startIndex`/`endIndex` equality",
      ["isEmpty": isEmpty,
       "startIndex": startIndex,
       "endIndex": endIndex])
  }

  // *** index(after:), formIndex(after:)
  var indices: [C.Index] = []
  do {
    var i = startIndex
    for offset in 0 ..< count {
      indices.append(i)
      let j = container.index(after: i)
      var k = i
      container.formIndex(after: &k)
      guard j == k else {
        throw ValidationError(
          "`index(after:)` must be consistent with `formIndex(after:)`",
          ["offset": offset,
           "index": i,
           "index(after:) result": j,
           "formIndex(after:) result": k])
      }
      guard (offset == count - 1) == (j == endIndex) else {
        throw ValidationError(
          "`index(after:)` must reach `endIndex` after precisely `count` steps",
          ["offset": offset,
           "index": i,
           "index(after:) result": j,
           "endIndex": endIndex])
      }
      i = j
    }
  }
  guard indices.count == count else {
    throw ValidationError(
      "index(after:) exposes the wrong number of indices",
      ["indexCount": indices.count,
       "count": count])
  }
  for offset in indices.indices {
    let i = indices[offset]
    guard areEquivalent(container[i], expectedContents[offset]) else {
      throw ValidationError(
        "`subscript(Index)` must expose the expected contents",
        ["offset": offset,
         "index": i,
         "expected": expectedContents[offset],
         "actual": printer(container[i])
        ])
    }
  }
  let allIndices = indices + [endIndex]

  // FIXME: Add throwing versions of checkEquatable/checkHashable/checkComparable
  //checkHashable(allIndices, equalityOracle: ==)

  // *** nextSpan(after:)

  let chunks = container._chunks()
  do {
    // Check that the spans seem plausibly sized and that the indices are monotonic.
    let sum = chunks.reduce(into: 0, { $0 += $1.count })
    guard sum == count else {
      throw ValidationError(
        "`nextSpan(after:)` must expose `count` elements",
        ["count": count,
         "sum of span counts": sum])
    }
    var j = 0
    for i in chunks.indices {
      let chunk = chunks[i]
      precondition(allIndices[j] == chunk.start)
      guard j + chunk.count < allIndices.count else {
        throw ValidationError(
          "`nextSpan(after:)` must expose monotonically increasing span boundaries consistent with `index(after:)`",
          ["chunk start": chunk.start,
           "chunk end": chunk.end,
           "chunk count": chunk.count])
      }
      guard
        j + chunk.count < allIndices.count,
        allIndices[j + chunk.count] == chunk.end
      else {
        throw ValidationError(
          "`nextSpan(after:)` must expose monotonically increasing span boundaries consistent with `index(after:)`",
          ["chunk start": chunk.start,
           "chunk end": chunk.end,
           "chunk count": chunk.count,
           "expected chunk end": allIndices[j + chunk.count]])
      }
      j += chunk.count
    }
  }

  do {
    // Check that contents match expectations.
    var i = container.startIndex
    var offset = 0
    var chunkIndex = 0
    while true {
      let start = i
      let span = container.nextSpan(after: &i)
      guard !span.isEmpty else { break }
      let expected = chunks[chunkIndex]
      guard
        span.count == expected.count,
        start == expected.start,
        i == expected.end
      else {
        throw ValidationError(
          "`nextSpan(after:)` must expose stable chunk boundaries across repeated iterations",
          ["offset": offset,
           "actual start": start,
           "actual end": i,
           "actual count": span.count,
           "expected start": expected.start,
           "expected end": expected.end,
           "expected count": expected.count])
      }
      for k in span.indices {
        guard areEquivalent(span[k], expectedContents[offset]) else {
          throw ValidationError(
            "`nextSpan(after:)` must expose the expected contents",
            ["offset": offset,
             "chunk start": i,
             "chunk offset": k,
             "actual content": printer(span[k]),
             "expected content": expectedContents[offset]])
        }
        offset += 1
      }
      chunkIndex += 1
    }
    guard i == container.endIndex else {
      throw ValidationError(
        "`nextSpan(after:)` must stop at the container's `endIndex`",
        ["endIndex": container.endIndex,
         "end": i])
    }
  }

  // *** nextSpan(after:maxCount:limitedBy:)
  func checkNextSpan(maxCount: Int) throws(ValidationError) {
    var offset = 0
    var i = startIndex
    while true {
      let start = i
      let span = container.nextSpan(after: &i, maxCount: maxCount)
      if span.isEmpty { break }
      guard span.count <= maxCount else {
        throw ValidationError(
          "`nextSpan(after:maxCount:limitedBy:)` must observe `maxCount`",
          ["container offset": offset,
           "index": start,
           "maxCount": maxCount,
           "returned span count": span.count])
      }
      for i in 0 ..< span.count {
        guard areEquivalent(span[i], expectedContents[offset]) else {
          throw ValidationError(
            "`nextSpan(after:maxCount:limitedBy:)` must expose the expected contents",
            ["index": start,
             "maxCount": maxCount,
             "offset within span": i,
             "actual content": printer(span[i]),
             "expected content": expectedContents[offset]])
        }
        offset += 1
      }
    }
    guard offset == count else {
      throw ValidationError(
        "`nextSpan(after:maxCount:limitedBy:)` must expose `count` elements",
        ["maxCount": maxCount,
         "count": count,
         "sum of span counts": offset])
    }
  }
  try checkNextSpan(maxCount: 1)
  try checkNextSpan(maxCount: 2)
  try checkNextSpan(maxCount: Int.max)
  try checkNextSpan(maxCount: Int.max - 1)

  // *** `BorrowingIterator`

  do {
    // Check that the iterator exposes consistent chunks.
    let iteratorChunks = container.makeBorrowingIterator()._spanCounts()
    let sum = iteratorChunks.reduce(into: 0, { $0 += $1 })
    guard sum == count else {
      throw ValidationError(
        "`BorrowingIterator` must expose `count` elements",
        ["count": count,
         "sum of span counts": sum])
    }
    guard iteratorChunks == chunks.map({ $0.count }) else {
      throw ValidationError(
        "`BorrowingIterator` and `nextSpan` must expose consistent span boundaries",
        ["nextSpan chunk sizes": chunks.map({ $0.count }),
         "iterator chunk sizes": iteratorChunks])
    }
  }

  func checkIterator(maxCount: Int) throws(ValidationError) {
    var offset = 0
    var it = container.makeBorrowingIterator()
    while true {
      let i = allIndices[offset]
      let j = container.currentIndex(of: &it)
      guard j == i else {
        throw ValidationError(
          "`currentIndex(of:)` must return the iterator's current position",
          ["actual": j,
           "expected": i])
      }
      let span = it.nextSpan(maxCount: maxCount)
      if span.isEmpty { break }
      guard span.count <= maxCount else {
        throw ValidationError(
          "`BorrowingIterator.nextSpan(maxCount:)` must observe `maxCount`",
          ["container offset": offset,
           "maxCount": maxCount,
           "returned span count": span.count])
      }
      for i in 0 ..< span.count {
        guard areEquivalent(span[i], expectedContents[offset]) else {
          throw ValidationError(
            "`BorrowingIterator.nextSpan(maxCount:)` must expose the expected contents",
            ["container offset": offset,
             "maxCount": maxCount,
             "offset within span": i,
             "actual content": printer(span[i]),
             "expected content": expectedContents[offset]])
        }
        offset += 1
      }
    }
    guard offset == count else {
      throw ValidationError(
        "`BorrowingIterator.nextSpan(maxCount:)` must expose `count` elements",
        ["maxCount": maxCount,
         "expected count": count,
         "actual count": offset])
    }
    let i = container.currentIndex(of: &it)
    guard i == endIndex else {
      throw ValidationError(
        "`currentIndex(of:)` must return `endIndex` at the end of iteration",
        ["actual": i,
         "expected": endIndex])
    }
  }
  try checkIterator(maxCount: 1)
  try checkIterator(maxCount: 2)
  try checkIterator(maxCount: Int.max)
  try checkIterator(maxCount: Int.max - 1)

  // *** formIndex(_:offsetBy:limitedBy:)`
  do {
    let limits = Set([0, allIndices.count - 1, allIndices.count / 2]).sorted()
    for l in limits {
      for i in 0 ..< count {
        let max = (l >= i ? l - i + 2 : count - i)
        let deltas = (
          [0, 1, 2, 10, 20, max / 2, max - 2, max - 1, max] as Set
        ).filter { $0 < max && $0 >= 0 }.sorted()
        for delta in deltas {
          var index = allIndices[i]
          var n = delta
          let limit = allIndices[l]
          container.formIndex(&index, offsetBy: &n, limitedBy: limit)
          let j = i + delta
          if i > l || j <= l {
            guard index == allIndices[j], n == 0 else {
              throw ValidationError(
                "`formIndex(_:offsetBy:limitedBy:)` must run to completion when the limit doesn't apply",
                ["input index": allIndices[i],
                 "input delta": delta,
                 "expected index": allIndices[j],
                 "expected delta": 0,
                 "actual index": index,
                 "actual delta": n])
            }
          } else {
            guard index == limit, n == delta - l + i else {
              throw ValidationError(
                "`formIndex(_:offsetBy:limitedBy:)` must report partial succcess when the limit applies",
                ["input index": allIndices[i],
                 "input delta": delta,
                 "expected index": limit,
                 "expected delta": delta - l + i,
                 "actual index": index,
                 "actual delta": n])
            }
          }
        }
      }
    }
  }
}

@available(SwiftStdlib 6.4, *)
extension BorrowingIteratorProtocol
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @inlinable
  internal consuming func _spanCounts() throws(Failure) -> [Int] {
    var result: [Int] = []
    var it = consume self
    while true {
      let c = try it.nextSpan().count
      guard c > 0 else { break }
      result.append(c)
    }
    return result
  }
}

@available(SwiftStdlib 6.4, *)
extension Container where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @inlinable
  internal borrowing func _chunks(
    maxCount: Int? = nil
  ) -> [(start: Index, end: Index, count: Int)] {
    var result: [(start: Index, end: Index, count: Int)] = []
    var i = self.startIndex
    while i != self.endIndex {
      let start = i
      let span: Span<Element>
      if let maxCount {
        span = self.nextSpan(after: &i, maxCount: maxCount)
      } else {
        span = self.nextSpan(after: &i)
      }
      guard !span.isEmpty else { break }
      result.append((start, i, span.count))
    }
    return result
  }
}
#endif
