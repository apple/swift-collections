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

struct Tree<Value> {
  typealias Spec = DefaultSpec<Value>
  typealias Leaf = NodeLeaf<Spec>
  typealias N4 = Node4<Spec>
  typealias N16 = Node16<Spec>
  typealias N48 = Node16<Spec>
  typealias N256 = Node256<Spec>
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension NodeStorage where Mn: InternalNode {
  mutating func addChildReturn(forKey k: KeyPart,
                               node: NodeStorage<some ArtNode<Mn.Spec>>) -> RawNode? {

    switch addChild(forKey: k, node: node) {
    case .noop:
      return self.rawNode
    case .replaceWith(let newValue):
      return newValue
    }
  }

  mutating func deleteChildReturn(at idx: Index) -> RawNode? {
    switch deleteChild(at: idx) {
    case .noop:
      return self.rawNode
    case .replaceWith(let newValue):
      return newValue
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class ARTreeNode4Tests: XCTestCase {
  func test4Basic() throws {
    typealias T = Tree<[UInt8]>
    var node = T.N4.allocate()
    _ = node.addChild(forKey: 10, node: T.Leaf.allocate(key: [10], value: [11]))
    _ = node.addChild(forKey: 20, node: T.Leaf.allocate(key: [20], value: [22]))
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 10: 1[10] -> [11]\n" +
      "└──○ 20: 1[20] -> [22]")
  }

  func test4BasicInt() throws {
    typealias T = Tree<Int>
    var node = T.N4.allocate()
    _ = node.addChild(forKey: 10, node: T.Leaf.allocate(key: [10], value: 11))
    _ = node.addChild(forKey: 20, node: T.Leaf.allocate(key: [20], value: 22))
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 10: 1[10] -> 11\n" +
      "└──○ 20: 1[20] -> 22")
  }

  func test4AddInMiddle() throws {
    typealias T = Tree<[UInt8]>
    var node = T.N4.allocate()
    _ = node.addChild(forKey: 10, node: T.Leaf.allocate(key: [10], value: [1]))
    _ = node.addChild(forKey: 20, node: T.Leaf.allocate(key: [20], value: [2]))
    _ = node.addChild(forKey: 30, node: T.Leaf.allocate(key: [30], value: [3]))
    _ = node.addChild(forKey: 15, node: T.Leaf.allocate(key: [15], value: [4]))
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=4, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [4]\n" +
      "├──○ 20: 1[20] -> [2]\n" +
      "└──○ 30: 1[30] -> [3]")
  }

  func test4DeleteAtIndex() throws {
    typealias T = Tree<[UInt8]>
    var node = T.N4.allocate()
    _ = node.addChild(forKey: 10, node: T.Leaf.allocate(key: [10], value: [1]))
    _ = node.addChild(forKey: 15, node: T.Leaf.allocate(key: [15], value: [2]))
    _ = node.addChild(forKey: 20, node: T.Leaf.allocate(key: [20], value: [3]))
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=3, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.deleteChild(at: 0)
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")

    let newNode = node.deleteChildReturn(at: 1)
    XCTAssertEqual(newNode?.type, .leaf)
  }

  func test4DeleteFromFull() throws {
    typealias T = Tree<Int>
    var node = T.N4.allocate()
    _ = node.addChild(forKey: 1, node: T.Leaf.allocate(key: [1], value: 1))
    _ = node.addChild(forKey: 2, node: T.Leaf.allocate(key: [2], value: 2))
    _ = node.addChild(forKey: 3, node: T.Leaf.allocate(key: [3], value: 3))
    _ = node.addChild(forKey: 4, node: T.Leaf.allocate(key: [4], value: 4))
    XCTAssertEqual(node.type, .node4)
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=4, partial=[]}\n" +
      "├──○ 1: 1[1] -> 1\n" +
      "├──○ 2: 1[2] -> 2\n" +
      "├──○ 3: 1[3] -> 3\n" +
      "└──○ 4: 1[4] -> 4")
    _ = node.deleteChild(at: 1)
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=3, partial=[]}\n" +
      "├──○ 1: 1[1] -> 1\n" +
      "├──○ 3: 1[3] -> 3\n" +
      "└──○ 4: 1[4] -> 4")

    _ = node.deleteChild(at: 1)
    let newNode = node.deleteChildReturn(at: 1)
    XCTAssertEqual(newNode?.type, .leaf)
  }

  func test4ExapandTo16() throws {
    typealias T = Tree<[UInt8]>
    var node = T.N4.allocate()
    _ = node.addChild(forKey: 1, node: T.Leaf.allocate(key: [1], value: [1]))
    _ = node.addChild(forKey: 2, node: T.Leaf.allocate(key: [2], value: [2]))
    _ = node.addChild(forKey: 3, node: T.Leaf.allocate(key: [3], value: [3]))
    _ = node.addChild(forKey: 4, node: T.Leaf.allocate(key: [4], value: [4]))
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=4, partial=[]}\n" +
      "├──○ 1: 1[1] -> [1]\n" +
      "├──○ 2: 1[2] -> [2]\n" +
      "├──○ 3: 1[3] -> [3]\n" +
      "└──○ 4: 1[4] -> [4]")

    let newNode = node.addChildReturn(forKey: 5, node: T.Leaf.allocate(key: [5], value: [5]))
    XCTAssertEqual(
      newNode!.print(with: T.Spec.self),
      "○ Node16 {childs=5, partial=[]}\n" +
      "├──○ 1: 1[1] -> [1]\n" +
      "├──○ 2: 1[2] -> [2]\n" +
      "├──○ 3: 1[3] -> [3]\n" +
      "├──○ 4: 1[4] -> [4]\n" +
      "└──○ 5: 1[5] -> [5]")
  }

  func test4DeleteKey() throws {
    typealias T = Tree<[UInt8]>
    var node = T.N4.allocate()
    _ = node.addChild(forKey: 10, node: T.Leaf.allocate(key: [10], value: [1]))
    _ = node.addChild(forKey: 15, node: T.Leaf.allocate(key: [15], value: [2]))
    _ = node.addChild(forKey: 20, node: T.Leaf.allocate(key: [20], value: [3]))
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=3, partial=[]}\n" +
      "├──○ 10: 1[10] -> [1]\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.index(forKey: 10).flatMap { node.deleteChild(at: $0) }
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 15: 1[15] -> [2]\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.index(forKey: 15).flatMap { node.deleteChild(at: $0) }
    XCTAssertEqual(
      node.print(),
      "○ Node4 {childs=1, partial=[]}\n" +
      "└──○ 20: 1[20] -> [3]")
    _ = node.index(forKey: 20).flatMap { node.deleteChild(at: $0) }
    XCTAssertEqual(node.print(), "○ Node4 {childs=0, partial=[]}\n")
  }
}
