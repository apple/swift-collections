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
import BasicContainers
#endif
@testable import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
final class Container_SpanwiseZip_Tests: CollectionTestCase {
  func test_earlyExitWithinSpan() {
    let array = RigidArray(capacity: 10, copying: 0 ..< 10)
    let chunks = StaccatoContainer(count: 10, spanCounts: [3]) { $0 }

    var calls = 0
    let (arrayEnd, chunksEnd) = array._spanwiseZip(with: chunks) { a, b in
      expectEqual(a.count, 3)
      expectEqual(b.count, 3)
      calls += 1
      return calls < 2
    }
    expectEqual(calls, 2)
    expectEqual(arrayEnd, 6)
    expectEqual(chunks.distance(from: chunks.startIndex, to: chunksEnd), 6)

    calls = 0
    let (chunksEnd2, arrayEnd2) = chunks._spanwiseZip(with: array) { a, b in
      expectEqual(a.count, 3)
      expectEqual(b.count, 3)
      calls += 1
      return calls < 2
    }
    expectEqual(calls, 2)
    expectEqual(chunks.distance(from: chunks.startIndex, to: chunksEnd2), 6)
    expectEqual(arrayEnd2, 6)
  }

  func test_spanLayouts() {
    withEvery("leftCount", in: [0, 1, 7, 10]) { leftCount in
      withEvery("rightCount", in: [0, 1, 7, 10]) { rightCount in
        withEvery("leftSpans", in: [[3], [10], [2, 5]]) { leftSpans in
          withEvery("rightSpans", in: [[3], [10], [2, 5]]) { rightSpans in
            withEvery("stopAfter", in: [1, 2, 3, Int.max]) { stopAfter in
              let left = StaccatoContainer(
                count: leftCount,
                spanCounts: leftSpans
              ) { $0 }
              let right = StaccatoContainer(
                count: rightCount,
                spanCounts: rightSpans
              ) { $0 }
              var processed = 0
              var calls = 0
              let (leftEnd, rightEnd) = left._spanwiseZip(with: right) { a, b in
                expectEqual(a.count, b.count)
                for i in 0 ..< a.count {
                  expectEqual(a[i], processed + i)
                  expectEqual(b[i], processed + i)
                }
                processed += a.count
                calls += 1
                return calls < stopAfter
              }

              expectTrue(calls <= stopAfter)
              expectEqual(
                left.distance(from: left.startIndex, to: leftEnd),
                processed
              )
              expectEqual(
                right.distance(from: right.startIndex, to: rightEnd),
                processed
              )
              if calls < stopAfter {
                expectEqual(processed, min(leftCount, rightCount))
              }
            }
          }
        }
      }
    }
  }
}

#endif
