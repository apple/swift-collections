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

final class FutureInoutTests: XCTestCase {
  func test_basic() {
    var x = 0
    let y = Inout(&x)

    XCTAssertEqual(y[], 0)

    y[] += 10

    XCTAssertEqual(y[], 10)
    XCTAssertEqual(x, 10)
  }
}
