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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class ARTreeNodeLeafTests: CollectionTestCase {
  func testLeafBasic() throws {
    typealias L = NodeLeaf<DefaultSpec<[UInt8]>>
    let leaf1 = L.allocate(key: [10, 20, 30, 40], value: [0])
    expectEqual(leaf1.print(), "○ 4[10, 20, 30, 40] -> [0]")

    let leaf2 = L.allocate(key: [10, 20, 30, 40], value: [0, 1, 2])
    expectEqual(leaf2.print(), "○ 4[10, 20, 30, 40] -> [0, 1, 2]")

    let leaf3 = L.allocate(key: [], value: [])
    expectEqual(leaf3.print(), "○ 0[] -> []")
  }

  func testLeafKeyEquals() throws {
    typealias L = NodeLeaf<DefaultSpec<[Int]>>
    let leaf1 = L.allocate(key: [10, 20, 30, 40], value: [0])
    expectFalse(leaf1.node.keyEquals(with: [10, 20, 30, 50]))
    expectFalse(leaf1.node.keyEquals(with: [10, 20, 30]))
    expectFalse(leaf1.node.keyEquals(with: [10, 20, 30, 40, 50]))
    expectTrue(leaf1.node.keyEquals(with: [10, 20, 30, 40]))
  }

  func testCasts() throws {
    typealias L = NodeLeaf<DefaultSpec<[Int]>>
    let leaf = L.allocate(key: [10, 20, 30, 40], value: [0])
    expectEqual(leaf.node.key, [10, 20, 30, 40])
    expectEqual(leaf.node.value, [0])
  }

  func testLeafLcp() throws {
    typealias L = NodeLeaf<DefaultSpec<[Int]>>
    var leaf1 = L.allocate(key: [10, 20, 30, 40], value: [0, 1, 2])
    L.allocate(key: [0, 1, 2, 3], value: [0]).read { other in
      expectEqual(
        leaf1.node.longestCommonPrefix(
          with: other,
          fromIndex: 0),
        0)
    }

    L.allocate(key: [0], value: [0]).read { other in
      expectEqual(
        leaf1.node.longestCommonPrefix(
          with:other,
          fromIndex: 0),
        0)
    }
    L.allocate(key: [0, 1], value: [0]).read { other in
      expectEqual(
        leaf1.node.longestCommonPrefix(with: other, fromIndex: 0),
        0)
    }
    L.allocate(key: [10, 1], value: [0]).read { other in
      expectEqual(leaf1.node.longestCommonPrefix(with: other, fromIndex: 0),
                     1)
    }
    L.allocate(key: [10, 20], value: [0]).read { other in
      expectEqual(leaf1.node.longestCommonPrefix(with: other, fromIndex: 0),
                     2)
    }
    L.allocate(key: [10, 20], value: [0]).read { other in
      expectEqual(leaf1.node.longestCommonPrefix(with: other, fromIndex: 1),
                     1)
    }
    L.allocate(key: [10, 20], value: [0]).read { other in
      expectEqual(leaf1.node.longestCommonPrefix(with: other, fromIndex: 2),
                     0)
    }

    leaf1 = L.allocate(key: [1, 2, 3, 4], value: [0])
    L.allocate(key: [1, 2, 3, 4, 5, 6], value: [0]).read { other in
      expectEqual(leaf1.node.longestCommonPrefix(with: other, fromIndex: 0),
                     4)
    }
    L.allocate(key: [1, 2, 3, 5, 5, 6], value: [0]).read { other in
      expectEqual(leaf1.node.longestCommonPrefix(with: other, fromIndex: 0),
                     3)
    }
    L.allocate(key: [1, 2, 3, 4], value: [0]).read { other in
      expectEqual(leaf1.node.longestCommonPrefix(with: other, fromIndex: 0),
                     4)
    }

  //   // Breaks the contract, so its OK that these fail.
  //   // expectEqual(
  //   //   leaf1.node.longestCommonPrefix(with: L.allocate(key: [], value: [0]),
  //   //                             fromIndex: 0),
  //   //   0)
  //   // expectEqual(
  //   //   leaf1.node.longestCommonPrefix(with: L.allocate(key: [10], value: [0]),
  //   //                             fromIndex: 2),
  //   //   0)
  }
}
