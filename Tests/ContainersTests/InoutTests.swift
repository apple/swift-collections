//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import ContainersPreview
#endif

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
final class InoutTests: XCTestCase {
  func test_basic() {
    var x = 0
    var y = Inout(&x)

    var v = y.value
    XCTAssertEqual(v, 0)

    y.value += 10

    v = y.value
    XCTAssertEqual(v, 10)
    XCTAssertEqual(x, 10)
  }
}
#endif
