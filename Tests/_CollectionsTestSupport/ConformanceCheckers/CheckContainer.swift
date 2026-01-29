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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
import XCTest
import ContainersPreview

@available(SwiftStdlib 5.0, *)
@inlinable
public func checkIterable<
  S: BorrowingSequence & ~Copyable & ~Escapable,
  Expected: Sequence<S.Element>
>(
  _ iterable: borrowing S,
  expectedContents: Expected,
  file: StaticString = #filePath,
  line: UInt = #line
) where S.Element: Equatable {
  checkIterable(
    iterable,
    expectedContents: expectedContents,
    by: ==,
    file: file, line: line)
}

@available(SwiftStdlib 5.0, *)
@inlinable
public func checkIterable<
  S: BorrowingSequence & ~Copyable & ~Escapable,
  Expected: Sequence<S.Element>
>(
  _ iterable: borrowing S,
  expectedContents: Expected,
  by areEquivalent: (S.Element, S.Element) -> Bool,
  file: StaticString = #filePath,
  line: UInt = #line
) where S.Element: Equatable {
  let entry = TestContext.current.push("checkIterable", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  let expectedContents = Array(expectedContents)

  expectEqual(iterable.isEmpty, expectedContents.isEmpty)

  let estimatedCount = iterable.estimatedCount
  switch estimatedCount {
  case .exactly(let c):
    expectEqual(c, expectedContents.count)
  case .infinite:
    expectFailure()
  case .unknown:
    break
  }

  // Check that the spans seem plausibly sized and that the indices are monotonic.
  let spanShapes: [Range<Int>] = {
    var r: [Range<Int>] = []
    var pos = 0
    var it = iterable.makeBorrowingIterator()
    while true {
      let origPos = pos
      let span = it.nextSpan()
      pos += span.count
      if span.isEmpty {
        break
      }
      r.append(origPos ..< pos)
    }
    return r
  }()
  expectEqual(
    spanShapes.reduce(into: 0, { $0 += $1.count }), expectedContents.count,
    "Container's count does not match the sum of its spans")

  // Check that the spans have stable sizes and the expected contents.
  do {
    var pos = 0
    var it = iterable.makeBorrowingIterator()
    var spanIndex = 0
    while true {
      let span = it.nextSpan()
      if span.isEmpty { break }
      expectEqual(
        span.count, spanShapes[spanIndex].count,
        "Container has nondeterministic span sizes")
      for i in 0 ..< span.count {
        expectEqual(span[i], expectedContents[pos])
        pos += 1
      }
      spanIndex += 1
    }
    expectEqual(spanIndex, spanShapes.endIndex)
    expectEqual(pos, expectedContents.count)
  }
  
  // Check that we can iterate one by one.
  do {
    var pos = 0
    var it = iterable.makeBorrowingIterator()
    while true {
      let span = it.nextSpan(maximumCount: 1)
      if span.isEmpty { break }
      expectEqual(span.count, 1)
      for i in 0 ..< span.count {
        expectEqual(span[i], expectedContents[pos])
        pos += 1
      }
    }
    expectEqual(pos, expectedContents.count)
  }

  // Check that we can iterate with huge maximum counts
  do {
    var pos = 0
    var it = iterable.makeBorrowingIterator()
    var spanIndex = 0
    while true {
      let span = it.nextSpan(maximumCount: Int.max)
      if span.isEmpty { break }
      expectEqual(
        span.count, spanShapes[spanIndex].count,
        "Container has inconsistent/nondeterministic span sizes")
      for i in 0 ..< span.count {
        expectEqual(span[i], expectedContents[pos])
        pos += 1
      }
      spanIndex += 1
    }
    expectEqual(spanIndex, spanShapes.endIndex)
    expectEqual(pos, expectedContents.count)
  }

}
#endif
