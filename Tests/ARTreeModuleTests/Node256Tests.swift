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

final class ARTreeNode256Tests: XCTestCase {
  func test256Basic() throws {
    var node = Node256.allocate()
    node.addChild(forKey: 10, node: NodeLeaf.allocate(key: [10], value: [0], of: [UInt8].self))
    node.addChild(forKey: 20, node: NodeLeaf.allocate(key: [20], value: [3], of: [UInt8].self))
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node256 {childs=2, partial=[]}\n" +
      "├──○ 10: 1[10] -> [0]\n" +
      "└──○ 20: 1[20] -> [3]")
  }

  func test48DeleteAtIndex() throws {
    var node = Node256.allocate()
    node.addChild(forKey: 10, node: NodeLeaf.allocate(key: [10], value: [1], of: [UInt8].self))
    node.addChild(forKey: 15, node: NodeLeaf.allocate(key: [15], value: [2], of: [UInt8].self))
    node.addChild(forKey: 20, node: NodeLeaf.allocate(key: [20], value: [3], of: [UInt8].self))
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node256 {childs=3, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    node.deleteChild(at: 10)
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node256 {childs=2, partial=[]}\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    node.deleteChild(at: 15)
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node256 {childs=1, partial=[]}\n" +
      "└──○ 20: 1[20] -> [3]")
    node.deleteChild(at: 20)
    XCTAssertEqual(node.print(value: [UInt8].self), "○ Node256 {childs=0, partial=[]}\n")
  }
}
