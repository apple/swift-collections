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

#if compiler(>=6.2)
final class BoxTests: XCTestCase {
  func test_basic() {
    var intOnHeap = Box<Int>(0)

    XCTAssertEqual(intOnHeap[], 0)

    intOnHeap[] = 123

    XCTAssertEqual(intOnHeap[], 123)

    XCTAssertEqual(intOnHeap.copy(), 123)

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
    var inoutToIntOnHeap = intOnHeap.leak()

    XCTAssertEqual(inoutToIntOnHeap[], 123)

    inoutToIntOnHeap[] = 321

    XCTAssertEqual(inoutToIntOnHeap[], 321)
#endif
  }
}
#endif
