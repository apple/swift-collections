//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if DEBUG
import XCTest
@testable import _CollectionsTestSupport

final class UtilitiesTests: CollectionTestCase {
  func testIntegerSquareRoot() {
    withSome("i", in: 0 ..< Int.max, maxSamples: 100_000) { i in
      let s = i._squareRoot()
      expectLessThanOrEqual(s * s, i)
      expectGreaterThan((s + 1) * (s + 1), i)
    }
  }
}

#endif
