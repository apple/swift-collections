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

final class ARTreeNodeBasicTests: XCTestCase {
  func testNodeSizes() throws {
    let header = MemoryLayout<NodeHeader>.stride
    XCTAssertEqual(header, 14)

    let childSlotSize = MemoryLayout<NodePtr?>.stride
    let ptrSize = MemoryLayout<Int>.stride
    let size4 = Node4.size
    let size16 = Node16.size
    let size48 = Node48.size
    let size256 = Node256.size

    print("sizeOf(Int) = \(ptrSize)")
    print("sizeOf(childSlot) = \(childSlotSize)")
    print("sizeOf(Header) = \(header)")
    print("sizeOf(.node4) = \(size4)")
    print("sizeOf(.node16) = \(size16)")
    print("sizeOf(.node48) = \(size48)")
    print("sizeOf(.node256) = \(size256)")

    XCTAssertEqual(size4, header + 4 + 4 * ptrSize)
    XCTAssertEqual(size16, header + 16 + 16 * ptrSize)
    XCTAssertEqual(size48, header + 256 + 48 * ptrSize)
    XCTAssertEqual(size256, header + 256 * ptrSize)
  }
}
