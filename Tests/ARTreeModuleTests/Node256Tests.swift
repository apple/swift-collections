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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class ARTreeNode256Tests: XCTestCase {
  typealias Leaf = NodeLeaf<DefaultSpec<[UInt8]>>
  typealias N256 = Node256<DefaultSpec<[UInt8]>>

  func test256Basic() throws {
    var node = N256.allocate()
    _ = node.addChild(forKey: 10, node: Leaf.allocate(key: [10], value: [0]))
    _ = node.addChild(forKey: 20, node: Leaf.allocate(key: [20], value: [3]))
    XCTAssertEqual(
      node.print(),
      "○ Node256 {childs=2, partial=[]}\n" +
      "├──○ 10: 1[10] -> [0]\n" +
      "└──○ 20: 1[20] -> [3]")
  }

  func test48DeleteAtIndex() throws {
    var node = N256.allocate()
    _ = node.addChild(forKey: 10, node: Leaf.allocate(key: [10], value: [1]))
    _ = node.addChild(forKey: 15, node: Leaf.allocate(key: [15], value: [2]))
    _ = node.addChild(forKey: 20, node: Leaf.allocate(key: [20], value: [3]))
    XCTAssertEqual(
      node.print(),
      "○ Node256 {childs=3, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.deleteChild(at: 10)
    XCTAssertEqual(
      node.print(),
      "○ Node256 {childs=2, partial=[]}\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.deleteChild(at: 15)
    XCTAssertEqual(
      node.print(),
      "○ Node256 {childs=1, partial=[]}\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.deleteChild(at: 20)
    XCTAssertEqual(node.print(), "○ Node256 {childs=0, partial=[]}\n")
  }
}
