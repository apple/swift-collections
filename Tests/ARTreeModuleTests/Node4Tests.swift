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

final class ARTreeNode4Tests: XCTestCase {
  func test4Basic() throws {
    var node = Node4.allocate()
    node.addChild(forKey: 10, node: NodeLeaf.allocate(key: [10], value: [11]))
    node.addChild(forKey: 20, node: NodeLeaf.allocate(key: [20], value: [22]))
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 10: 1[10] -> [11]\n" +
      "└──○ 20: 1[20] -> [22]")
  }

  func test4AddInMiddle() throws {
    var node = Node4.allocate()
    node.addChild(forKey: 10, node: NodeLeaf.allocate(key: [10], value: [1]))
    node.addChild(forKey: 20, node: NodeLeaf.allocate(key: [20], value: [2]))
    node.addChild(forKey: 30, node: NodeLeaf.allocate(key: [30], value: [3]))
    node.addChild(forKey: 15, node: NodeLeaf.allocate(key: [15], value: [4]))
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node4 {childs=4, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [4]\n" +
      "├──○ 20: 1[20] -> [2]\n" +
      "└──○ 30: 1[30] -> [3]")
  }

  func test4DeleteAtIndex() throws {
    var node = Node4.allocate()
    node.addChild(forKey: 10, node: NodeLeaf.allocate(key: [10], value: [1]))
    node.addChild(forKey: 15, node: NodeLeaf.allocate(key: [15], value: [2]))
    node.addChild(forKey: 20, node: NodeLeaf.allocate(key: [20], value: [3]))
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node4 {childs=3, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    node.deleteChild(at: 0)
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")

    var ptr: (any Node)? = node
    node.deleteChild(at: 1, ref: &ptr)
    XCTAssertNotNil(ptr)
    XCTAssertEqual(ptr?.type, .leaf)
  }

  func test4ExapandTo16() throws {
    var node = Node4.allocate()

    node.addChild(forKey: 1, node: NodeLeaf.allocate(key: [1], value: [1]))
    node.addChild(forKey: 2, node: NodeLeaf.allocate(key: [2], value: [2]))
    node.addChild(forKey: 3, node: NodeLeaf.allocate(key: [3], value: [3]))
    node.addChild(forKey: 4, node: NodeLeaf.allocate(key: [4], value: [4]))
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node4 {childs=4, partial=[]}\n" +
      "├──○ 1: 1[1] -> [1]\n" +
      "├──○ 2: 1[2] -> [2]\n" +
      "├──○ 3: 1[3] -> [3]\n" +
      "└──○ 4: 1[4] -> [4]")

    var addr: (any Node)? = node
    withUnsafeMutablePointer(to: &addr) {
      let ref: ChildSlotPtr? = $0
      node.addChild(forKey: 5, node: NodeLeaf.allocate(key: [5], value: [5]), ref: ref)
      XCTAssertEqual(
        ref!.pointee!.print(value: [UInt8].self),
        "○ Node16 {childs=5, partial=[]}\n" +
        "├──○ 1: 1[1] -> [1]\n" +
        "├──○ 2: 1[2] -> [2]\n" +
        "├──○ 3: 1[3] -> [3]\n" +
        "├──○ 4: 1[4] -> [4]\n" +
        "└──○ 5: 1[5] -> [5]")
    }
  }

  func test4DeleteKey() throws {
    var node = Node4.allocate()
    node.addChild(forKey: 10, node: NodeLeaf.allocate(key: [10], value: [1]))
    node.addChild(forKey: 15, node: NodeLeaf.allocate(key: [15], value: [2]))
    node.addChild(forKey: 20, node: NodeLeaf.allocate(key: [20], value: [3]))
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node4 {childs=3, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    node.deleteChild(forKey: 10)
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    node.deleteChild(forKey: 15)
    XCTAssertEqual(
      node.print(value: [UInt8].self),
      "○ Node4 {childs=1, partial=[]}\n" +
      "└──○ 20: 1[20] -> [3]")
    node.deleteChild(forKey: 20)
    XCTAssertEqual(node.print(value: [UInt8].self), "○ Node4 {childs=0, partial=[]}\n")
  }
}
