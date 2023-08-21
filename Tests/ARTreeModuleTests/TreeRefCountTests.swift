//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest

@testable import ARTreeModule

private class TestBox {
  var d: String

  init(_ d: String) {
    self.d = d
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class ARTreeRefCountTest: XCTestCase {
  func testRefCountBasic() throws {
    // TODO: Why is it 2?
    var x = TestBox("foo")
    XCTAssertEqual(CFGetRetainCount(x), 2)
    var t = ARTree<TestBox>()
    XCTAssertEqual(CFGetRetainCount(x), 2)
    t.insert(key: [10, 20, 30], value: x)
    XCTAssertEqual(CFGetRetainCount(x), 3)
    x = TestBox("bar")
    XCTAssertEqual(CFGetRetainCount(x), 2)
    x = t.getValue(key: [10, 20, 30])!
    XCTAssertEqual(CFGetRetainCount(x), 3)
    t.delete(key: [10, 20, 30])
    XCTAssertEqual(CFGetRetainCount(x), 2)
  }
}
