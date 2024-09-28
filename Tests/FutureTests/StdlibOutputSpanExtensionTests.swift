//===--- StdlibOutputSpanExtensionTests.swift -----------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import Foundation
import Future

final class OutputBufferUsageTests: XCTestCase {

  func testArrayInitializationExample() {
    var array: [UInt8]
    array = Array(capacity: 32, initializingWith: { output in
      for i in 0..<(output.capacity/2) {
        output.appendElement(UInt8(clamping: i))
      }
    })
    XCTAssertEqual(array.count, 16)
    XCTAssert(array.elementsEqual(0..<16))
    XCTAssertGreaterThanOrEqual(array.capacity, 32)
  }

  func testDataInitializationExample() {
    var data: Data
    data = Data(capacity: 32, initializingWith: { output in
      for i in 0..<(output.capacity/2) {
        output.appendElement(UInt8(clamping: i))
      }
    })
    XCTAssertEqual(data.count, 16)
    XCTAssert(data.elementsEqual(0..<16))
  }

  func testStringInitializationExample() {
    var string: String
    let c = UInt8(ascii: "A")
    string = String(utf8Capacity: 32, initializingWith: { output in
      for i in 0..<(output.capacity/2) {
        output.appendElement(c + UInt8(clamping: i))
      }
    })
    XCTAssertEqual(string.utf8.count, 16)
    XCTAssert(string.utf8.elementsEqual(c..<(c+16)))
  }
}
