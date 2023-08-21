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
final class ARTreeNode16Tests: XCTestCase {
  func test16Basic() throws {
    typealias T = Tree<[UInt8]>
    var node = T.N16.allocate()
    _ = node.addChild(forKey: 10, node: T.Leaf.allocate(key: [10], value: [0]))
    _ = node.addChild(forKey: 20, node: T.Leaf.allocate(key: [20], value: [3]))
    XCTAssertEqual(
      node.print(),
      "○ Node16 {childs=2, partial=[]}\n" +
      "├──○ 10: 1[10] -> [0]\n" +
      "└──○ 20: 1[20] -> [3]")
  }

  func test4AddInMiddle() throws {
    typealias T = Tree<[UInt8]>
    var node = T.N16.allocate()
    _ = node.addChild(forKey: 10, node: T.Leaf.allocate(key: [10], value: [1]))
    _ = node.addChild(forKey: 20, node: T.Leaf.allocate(key: [20], value: [2]))
    _ = node.addChild(forKey: 30, node: T.Leaf.allocate(key: [30], value: [3]))
    _ = node.addChild(forKey: 15, node: T.Leaf.allocate(key: [15], value: [4]))
    XCTAssertEqual(
      node.print(),
      "○ Node16 {childs=4, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [4]\n" +
      "├──○ 20: 1[20] -> [2]\n" +
      "└──○ 30: 1[30] -> [3]")
  }

  func test16DeleteAtIndex() throws {
    typealias T = Tree<[UInt8]>
    var node = T.N16.allocate()
    _ = node.addChild(forKey: 10, node: T.Leaf.allocate(key: [10], value: [1]))
    _ = node.addChild(forKey: 15, node: T.Leaf.allocate(key: [15], value: [2]))
    _ = node.addChild(forKey: 20, node: T.Leaf.allocate(key: [20], value: [3]))
    XCTAssertEqual(
      node.print(),
      "○ Node16 {childs=3, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.deleteChild(at: 0)
    XCTAssertEqual(
      node.print(),
      "○ Node16 {childs=2, partial=[]}\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.deleteChild(at: 1)
    XCTAssertEqual(
      node.print(),
      "○ Node16 {childs=1, partial=[]}\n" +
      "└──○ 15: 1[15] -> [2]")
    _ = node.deleteChild(at: 0)
    XCTAssertEqual(node.print(), "○ Node16 {childs=0, partial=[]}\n")
  }

  func test16DeleteKey() throws {
    typealias T = Tree<[UInt8]>
    var node = T.N16.allocate()
    _ = node.addChild(forKey: 10, node: T.Leaf.allocate(key: [10], value: [1]))
    _ = node.addChild(forKey: 15, node: T.Leaf.allocate(key: [15], value: [2]))
    _ = node.addChild(forKey: 20, node: T.Leaf.allocate(key: [20], value: [3]))
    XCTAssertEqual(
      node.print(),
      "○ Node16 {childs=3, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.index(forKey: 10).flatMap { node.deleteChild(at: $0) }
    XCTAssertEqual(
      node.print(),
      "○ Node16 {childs=2, partial=[]}\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.index(forKey: 15).flatMap { node.deleteChild(at: $0) }
    XCTAssertEqual(
      node.print(),
      "○ Node16 {childs=1, partial=[]}\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.index(forKey: 20).flatMap { node.deleteChild(at: $0) }
    XCTAssertEqual(node.print(), "○ Node16 {childs=0, partial=[]}\n")
  }
}
