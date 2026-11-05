//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import XCTest

#if !COLLECTIONS_SINGLE_MODULE && DEBUG
import _CollectionsTestSupport
#endif

#if COLLECTIONS_SINGLE_MODULE || DEBUG
final class UtilitiesTests: CollectionTestCase {
  func testIntegerSquareRoot() {
    withSome("i", in: 0 ..< Int.max, maxSamples: 100_000) { i in
      let s = i._squareRoot()
      expectLessThanOrEqual(s * s, i)
      let next = (s + 1).multipliedReportingOverflow(by: s + 1)
      if !next.overflow {
        expectGreaterThan(next.partialValue, i)
      }
    }
  }

  func testCheckEquatable_sampledPairsOutOfOrder() {
    // With `maxSamples`, pairs can arrive in an order that used to trip a
    // precondition in the transitivity check, even for a valid oracle.
    for _ in 0 ..< 200 {
      checkEquatable([0, 0, 0], oracle: { _, _ in true }, maxSamples: 5)
    }
  }
}
#endif
