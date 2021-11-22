//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest

open class CollectionTestCase: XCTestCase {
  internal var _context: TestContext?

  public var context: TestContext { _context! }

  public override func setUp() {
    super.setUp()
    _context = TestContext.pushNew()
  }

  public override func tearDown() {
    TestContext.pop(context)
    _context = nil
    super.tearDown()
  }
}
