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
    XCTAssertEqual(_getRetainCount(x), 2)
    var t = ARTree<TestBox>()
    XCTAssertEqual(_getRetainCount(x), 2)
    t.insert(key: [10, 20, 30], value: x)
    XCTAssertEqual(_getRetainCount(x), 3)
    x = TestBox("bar")
    XCTAssertEqual(_getRetainCount(x), 2)
    x = t.getValue(key: [10, 20, 30])!
    XCTAssertEqual(_getRetainCount(x), 3)
    t.delete(key: [10, 20, 30])
    XCTAssertEqual(_getRetainCount(x), 2)
  }

  func testRefCountNode4() throws {
    typealias Tree = ARTree<Int>
    var t: _? = Tree()
    t!.insert(key: [1, 2, 3], value: 10)
    t!.insert(key: [2, 4, 4], value: 20)

    XCTAssertEqual(_getRetainCount(t!._root!.buf), 2)
    var n4 = t!._root
    XCTAssertEqual(_getRetainCount(n4!.buf), 3)
    t = nil
    XCTAssertEqual(_getRetainCount(n4!.buf), 2)
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

    XCTAssertEqual(_getRetainCount(t!._root!.buf), 2)
    var n4 = t!._root
    XCTAssertEqual(_getRetainCount(n4!.buf), 3)
    t = nil
    XCTAssertEqual(_getRetainCount(n4!.buf), 2)
    n4 = nil
  }

  func testRefCountStorage() throws {
    typealias Tree = ARTree<Int>
    let node = Node4<Tree.Spec>.allocate()
    let ref = node.ref
    let count0 = _getRetainCount(ref)

    let a = node.node
    let count1 = _getRetainCount(ref)
    XCTAssertEqual(count1, count0)

    let b = node.node
    let count2 = _getRetainCount(ref)
    XCTAssertEqual(count2, count1)

    let c = node.node.rawNode
    let count3 = _getRetainCount(ref)
    XCTAssertEqual(count3, count2 + 1)

    _ = (a, b, c) // FIXME: to suppress warning
  }

  func testRefCountReplace() throws {
    typealias Tree = ARTree<TestBox>
    var t = Tree()
    var v = TestBox("val1")
    XCTAssertTrue(isKnownUniquelyReferenced(&v))

    let count0 = _getRetainCount(v)
    t.insert(key: [1, 2, 3], value: v)
    XCTAssertFalse(isKnownUniquelyReferenced(&v))
    XCTAssertEqual(_getRetainCount(v), count0 + 1)

    t.insert(key: [1, 2, 3], value: TestBox("val2"))
    XCTAssertEqual(_getRetainCount(v), count0)
    XCTAssertTrue(isKnownUniquelyReferenced(&v))
  }

  func testRefCountNode4ChildAndClone() throws {
    typealias Tree = ARTree<Int>
    var node = Node4<Tree.Spec>.allocate()
    var newNode = Node4<Tree.Spec>.allocate()
    XCTAssertTrue(isKnownUniquelyReferenced(&newNode.ref))
    _ = node.addChild(forKey: 10, node: newNode)
    XCTAssertFalse(isKnownUniquelyReferenced(&newNode.ref))
    _ = node.deleteChild(at: 0)
    XCTAssertTrue(isKnownUniquelyReferenced(&newNode.ref))

    // Now do same after cloning.
    _ = node.addChild(forKey: 10, node: newNode)
    XCTAssertFalse(isKnownUniquelyReferenced(&newNode.ref))
    let cloneNode = node.clone()
    _ = node.deleteChild(at: 0)
    XCTAssertFalse(isKnownUniquelyReferenced(&newNode.ref),
                  "newNode can't be unique as it is should be referenced by clone as well")

    _ = (cloneNode) // FIXME: to suppress warning.
  }
}
