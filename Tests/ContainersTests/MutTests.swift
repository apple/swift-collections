//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
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
final class MutTests: XCTestCase {
  func test_basic() {
    var x = 0
    var y = Mut(&x)

    var v = y[]
    XCTAssertEqual(v, 0)

    y[] += 10

    v = y[]
    XCTAssertEqual(v, 10)
    XCTAssertEqual(x, 10)
  }
}
#endif
