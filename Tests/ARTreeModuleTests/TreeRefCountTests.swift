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

@inline(__always) func getRc(_ x: AnyObject) -> UInt {
  return _getRetainCount(x)
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class ARTreeRefCountTest: XCTestCase {
  func testRefCountBasic() throws {
    // TODO: Why is it 2?
    var x = TestBox("foo")
    XCTAssertEqual(getRc(x), 2)
    var t = ARTree<TestBox>()
    XCTAssertEqual(getRc(x), 2)
    t.insert(key: [10, 20, 30], value: x)
    XCTAssertEqual(getRc(x), 3)
    x = TestBox("bar")
    XCTAssertEqual(getRc(x), 2)
    x = t.getValue(key: [10, 20, 30])!
    XCTAssertEqual(getRc(x), 3)
    t.delete(key: [10, 20, 30])
    XCTAssertEqual(getRc(x), 2)
  }

  func testRefCountNode4() throws {
    typealias Tree = ARTree<Int>
    var t: _? = Tree()
    t!.insert(key: [1, 2, 3], value: 10)
    t!.insert(key: [2, 4, 4], value: 20)

    XCTAssertEqual(getRc(t!._root!.buf), 2)
    var n4 = t!._root
    XCTAssertEqual(getRc(n4!.buf), 3)
    t = nil
    XCTAssertEqual(getRc(n4!.buf), 2)
    n4 = nil
  }

  func testRefCountNode16() throws {
    typealias Tree = ARTree<Int>
    var t: _? = Tree()
    t!.insert(key: [1, 2, 3], value: 10)
    t!.insert(key: [2, 4, 4], value: 20)
    t!.insert(key: [3, 2, 3], value: 30)
    t!.insert(key: [4, 4, 4], value: 40)
    t!.insert(key: [5, 4, 4], value: 50)

    XCTAssertEqual(getRc(t!._root!.buf), 2)
    var n4 = t!._root
    XCTAssertEqual(getRc(n4!.buf), 3)
    t = nil
    XCTAssertEqual(getRc(n4!.buf), 2)
    n4 = nil
  }

  func testRefCountStorage() throws {
    typealias Tree = ARTree<Int>
    let node = Node4<Tree.Spec>.allocate()
    let count0 = getRc(node.rawNode.buf)

    let a = node.node
    let count1 = getRc(node.rawNode.buf)
    XCTAssertEqual(count1, count0)

    let b = node.node
    let count2 = getRc(node.rawNode.buf)
    XCTAssertEqual(count2, count1)

    let c = node.node.rawNode
    let count3 = getRc(node.rawNode.buf)
    XCTAssertEqual(count3, count2 + 1)
  }
}
