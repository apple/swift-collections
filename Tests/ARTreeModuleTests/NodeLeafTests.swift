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

final class ARTreeNodeLeafTests: XCTestCase {
  func testLeafBasic() throws {
    let leaf1 = NodeLeaf.allocate(key: [10, 20, 30, 40], value: [0])
    XCTAssertEqual(leaf1.print(value: [UInt8].self), "○ 4[10, 20, 30, 40] -> [0]")

    let leaf2 = NodeLeaf.allocate(key: [10, 20, 30, 40], value: [0, 1, 2])
    XCTAssertEqual(leaf2.print(value: [UInt8].self), "○ 4[10, 20, 30, 40] -> [0, 1, 2]")

    let leaf3 = NodeLeaf.allocate(key: [], value: [])
    XCTAssertEqual(leaf3.print(value: [UInt8].self), "○ 0[] -> []")
  }

  func testLeafKeyEquals() throws {
    let leaf1 = NodeLeaf.allocate(key: [10, 20, 30, 40], value: [0])
    XCTAssertFalse(leaf1.keyEquals(with: [10, 20, 30, 50]))
    XCTAssertFalse(leaf1.keyEquals(with: [10, 20, 30]))
    XCTAssertFalse(leaf1.keyEquals(with: [10, 20, 30, 40, 50]))
    XCTAssertTrue(leaf1.keyEquals(with: [10, 20, 30, 40]))
  }

  func testCasts() throws {
    let leaf = NodeLeaf.allocate(key: [10, 20, 30, 40], value: [0])
    XCTAssertEqual(leaf.key, [10, 20, 30, 40])
    XCTAssertEqual(leaf.value, [0])
  }

  func testLeafLcp() throws {
    let leaf1 = NodeLeaf.allocate(key: [10, 20, 30, 40], value: [0, 1, 2])
    XCTAssertEqual(
      leaf1.longestCommonPrefix(
        with: NodeLeaf.allocate(key: [0, 1, 2, 3], value: [0]),
        fromIndex: 0),
      0)
    XCTAssertEqual(
      leaf1.longestCommonPrefix(
        with: NodeLeaf.allocate(key: [0], value: [0]),
        fromIndex: 0),
      0)
    XCTAssertEqual(
      leaf1.longestCommonPrefix(
        with: NodeLeaf.allocate(key: [0, 1], value: [0]),
        fromIndex: 0),
      0)
    XCTAssertEqual(
      leaf1.longestCommonPrefix(
        with: NodeLeaf.allocate(key: [10, 1], value: [0]),
        fromIndex: 0),
      1)
    XCTAssertEqual(
      leaf1.longestCommonPrefix(
        with: NodeLeaf.allocate(key: [10, 20], value: [0]),
        fromIndex: 0),
      2)
    XCTAssertEqual(
      leaf1.longestCommonPrefix(
        with: NodeLeaf.allocate(key: [10, 20], value: [0]),
        fromIndex: 1),
      1)
    XCTAssertEqual(
      leaf1.longestCommonPrefix(
        with: NodeLeaf.allocate(key: [10, 20], value: [0]),
        fromIndex: 2),
      0)

    // Breaks the contract, so its OK that these fail.
    // XCTAssertEqual(
    //   leaf1.longestCommonPrefix(with: NodeLeaf.allocate(key: [], value: [0]),
    //                             fromIndex: 0),
    //   0)
    // XCTAssertEqual(
    //   leaf1.longestCommonPrefix(with: NodeLeaf.allocate(key: [10], value: [0]),
    //                             fromIndex: 2),
    //   0)
  }
}
