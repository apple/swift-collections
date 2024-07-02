//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import Future

final class FutureBoxTests: XCTestCase {
  func test_basic() {
    let intOnHeap = Box<Int>(0)

    XCTAssertEqual(intOnHeap[], 0)

    intOnHeap[] = 123

    XCTAssertEqual(intOnHeap[], 123)

    let inoutToIntOnHeap = intOnHeap.leak()

    XCTAssertEqual(inoutToIntOnHeap[], 123)

    inoutToIntOnHeap[] = 321

    XCTAssertEqual(inoutToIntOnHeap[], 321)

    let intOnHeapAgain = Box<Int>(inoutToIntOnHeap)

    XCTAssertEqual(intOnHeapAgain[], 321)

    XCTAssertEqual(intOnHeapAgain.copy(), 321)

    let intInRegister = intOnHeapAgain.consume()

    XCTAssertEqual(intInRegister, 321)
  }
}
