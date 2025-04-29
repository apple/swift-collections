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
import _CollectionsTestSupport
import Future

class StaccatoContainerTests: CollectionTestCase {
  func checkStriding<C: Container & ~Copyable & ~Escapable>(
    _ container: borrowing C,
    spanCounts: [Int],
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let entry = context.push("checkStriding", file: file, line: line)
    defer { context.pop(entry) }

    var i = container.startIndex
    var j = 0
    var seen = 0
    while true {
      let span = container.nextSpan(after: &i)
      if i == container.endIndex {
        expectLessThanOrEqual(span.count, spanCounts[j])
        expectEqual(span.count, container.count - seen)
        break
      }
      expectEqual(span.count, spanCounts[j])
      seen += span.count
      j += 1
      if j == spanCounts.count { j = 0 }
    }
  }

  func test_Basic1() {
    let items = StaccatoContainer(
      contents: RigidArray(copying: 0 ..< 10),
      spanCounts: [1])
    checkContainer(items, expectedContents: 0 ..< 10)
  }

  func test_Basic2() {
    let items = StaccatoContainer(
      contents: RigidArray(copying: 0 ..< 10),
      spanCounts: [3])
    checkContainer(items, expectedContents: 0 ..< 10)
  }

  func test_Basic3() {
    let items = StaccatoContainer(
      contents: RigidArray(copying: 0 ..< 13),
      spanCounts: [1, 2])
    checkContainer(items, expectedContents: 0 ..< 13)
  }

  func test_SingleSpec() {
    withEvery("c", in: [0, 10, 20]) { c in
      withEvery("spanCount", in: 1 ... 20) { spanCount in
        let items = StaccatoContainer(
          contents: RigidArray(copying: 0 ..< c),
          spanCounts: [spanCount])

        checkStriding(items, spanCounts: [spanCount])
        checkContainer(items, expectedContents: 0 ..< c)
      }
    }
  }

  func test_DoubleSpec() {
    withEvery("c", in: [0, 10, 20]) { c in
      withEvery("spanCount1", in: 1 ... 10) { spanCount1 in
        withEvery("spanCount2", in: 1 ... 10) { spanCount2 in
          let spanCounts = [spanCount1, spanCount2]
          let items = StaccatoContainer(
            contents: RigidArray(copying: 0 ..< c),
            spanCounts: spanCounts)

          checkStriding(items, spanCounts: spanCounts)
          checkContainer(items, expectedContents: 0 ..< c)
        }
      }
    }
  }

  func test_TripleSpec() {
    withEvery("c", in: [0, 10, 20]) { c in
      withEvery("spanCount1", in: 1 ... 5) { spanCount1 in
        withEvery("spanCount2", in: 1 ... 5) { spanCount2 in
          withEvery("spanCount3", in: 1 ... 5) { spanCount3 in
            let spanCounts = [spanCount1, spanCount2, spanCount3]
            let items = StaccatoContainer(
              contents: RigidArray(copying: 0 ..< c),
              spanCounts: spanCounts)

            checkStriding(items, spanCounts: spanCounts)
            checkContainer(items, expectedContents: 0 ..< c)
          }
        }
      }
    }
  }
}
