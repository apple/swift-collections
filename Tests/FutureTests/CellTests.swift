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

final class FutureCellTests: XCTestCase {
  struct IntOnStack: ~Copyable {
    var value = Cell<Int>(0)
  }

  func test_basic() {
    var myInt = IntOnStack()

    XCTAssertEqual(myInt.value[], 0)

    myInt.value[] = 123

    XCTAssertEqual(myInt.value[], 123)

    let inoutToIntOnStack = myInt.value.asInout()

    inoutToIntOnStack[] = 321

    XCTAssertEqual(myInt.value[], 321)

    XCTAssertEqual(myInt.value.copy(), 321)
  }
}
