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

import _CollectionsTestSupport
@testable import ARTreeModule

private class TestBox {
  var d: String

  init(_ d: String) {
    self.d = d
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class ARTreeRefCountTest: CollectionTestCase {
  func testRefCountBasic() throws {
    // TODO: Why is it 2?
    var x = TestBox("foo")
    expectEqual(_getRetainCount(x), 2)
    var t = ARTree<TestBox>()
    expectEqual(_getRetainCount(x), 2)
    t.insert(key: [10, 20, 30], value: x)
    expectEqual(_getRetainCount(x), 3)
    x = TestBox("bar")
    expectEqual(_getRetainCount(x), 2)
    x = t.getValue(key: [10, 20, 30])!
    expectEqual(_getRetainCount(x), 3)
    t.delete(key: [10, 20, 30])
    expectEqual(_getRetainCount(x), 2)
  }

  func testRefCountNode4() throws {
    typealias Tree = ARTree<Int>
    var t: _? = Tree()
    t!.insert(key: [1, 2, 3], value: 10)
    t!.insert(key: [2, 4, 4], value: 20)

    expectEqual(_getRetainCount(t!._root!.buf), 2)
    var n4 = t!._root
    expectEqual(_getRetainCount(n4!.buf), 3)
    t = nil
    expectEqual(_getRetainCount(n4!.buf), 2)
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

    expectEqual(_getRetainCount(t!._root!.buf), 2)
    var n4 = t!._root
    expectEqual(_getRetainCount(n4!.buf), 3)
    t = nil
    expectEqual(_getRetainCount(n4!.buf), 2)
    n4 = nil
  }

  func testRefCountStorage() throws {
    typealias Tree = ARTree<Int>
    let node = Node4<Tree.Spec>.allocate()
    let ref = node.ref
    let count0 = _getRetainCount(ref)

    let a = node.node
    let count1 = _getRetainCount(ref)
    expectEqual(count1, count0)

    let b = node.node
    let count2 = _getRetainCount(ref)
    expectEqual(count2, count1)

    let c = node.node.rawNode
    let count3 = _getRetainCount(ref)
    expectEqual(count3, count2 + 1)

    _ = (a, b, c) // FIXME: to suppress warning
  }

  func testRefCountReplace() throws {
    typealias Tree = ARTree<TestBox>
    var t = Tree()
    var v = TestBox("val1")
    expectTrue(isKnownUniquelyReferenced(&v))

    let count0 = _getRetainCount(v)
    t.insert(key: [1, 2, 3], value: v)
    expectFalse(isKnownUniquelyReferenced(&v))
    expectEqual(_getRetainCount(v), count0 + 1)

    t.insert(key: [1, 2, 3], value: TestBox("val2"))
    expectEqual(_getRetainCount(v), count0)
    expectTrue(isKnownUniquelyReferenced(&v))
  }

  func testRefCountNode4ChildAndClone() throws {
    typealias Tree = ARTree<Int>
    var node = Node4<Tree.Spec>.allocate()
    var newNode = Node4<Tree.Spec>.allocate()
    expectTrue(isKnownUniquelyReferenced(&newNode.ref))
    _ = node.addChild(forKey: 10, node: newNode)
    expectFalse(isKnownUniquelyReferenced(&newNode.ref))
    _ = node.deleteChild(at: 0)
    expectTrue(isKnownUniquelyReferenced(&newNode.ref))

    // Now do same after cloning.
    _ = node.addChild(forKey: 10, node: newNode)
    expectFalse(isKnownUniquelyReferenced(&newNode.ref))
    let cloneNode = node.clone()
    _ = node.deleteChild(at: 0)
    expectFalse(isKnownUniquelyReferenced(&newNode.ref),
                  "newNode can't be unique as it is should be referenced by clone as well")

    _ = (cloneNode) // FIXME: to suppress warning.
  }
}
