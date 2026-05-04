//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_UNSTABLE_SORTED_COLLECTIONS

#if DEBUG
import _CollectionsTestSupport
@_spi(Testing) @testable import SortedCollections

final class BTreeBuilderTests: CollectionTestCase {
  func test_append() {
    withEvery("size", in: 0..<1000) { size in
      var builder = _BTree<Int, Int>.Builder(capacity: 4)

      for i in 0..<size {
        builder.append((i, -i))
      }

      let tree = builder.finish()
      tree.checkInvariants()
      expectEqualElements(tree, (0..<size).map { (key: $0, value: -$0) })
    }
  }

  func test_join_nonLeafSimpleMerge() {
    // Two depth-1 internal nodes whose combined element count plus the
    // separator fits in a single internal node of capacity 4.  This
    // exercises the simple-merge branch of
    // `_Node.UnsafeHandle.concatenateWith` on non-leaf nodes, which must
    // move children via `moveInitializeChildren` rather than
    // `moveInitializeElements`.
    let capacity = 4

    var leftNode = tree {
      tree { 0; 1; 2 }
      3
      tree { 4; 5 }
    }.toNode(ofCapacity: capacity)

    var rightNode = tree {
      tree { 7; 8 }
      9
      tree { 10; 11; 12 }
    }.toNode(ofCapacity: capacity)

    let merged = _Node.join(
      &leftNode,
      with: &rightNode,
      separatedBy: (key: 6, value: 12),
      capacity: capacity
    )

    let btree = _BTree(rootedAt: merged, internalCapacity: capacity)
    btree.checkInvariants()
    expectEqualElements(btree, (0...12).map { (key: $0, value: $0 * 2) })
  }
}
#endif

#endif
