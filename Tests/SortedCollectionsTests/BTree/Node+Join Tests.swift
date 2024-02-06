//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if DEBUG
import _CollectionsTestSupport
@_spi(Testing) @testable import SortedCollections

func expectNodeJoin(
  capacity: Int,
  tree1: NodeTemplate,
  separator: Int,
  tree2: NodeTemplate,
  toEqual refTree: NodeTemplate
) {
  var tree1 = tree1.toNode(ofCapacity: capacity)
  var tree2 = tree2.toNode(ofCapacity: capacity)
  
  let newTree = _Node.join(
    &tree1,
    with: &tree2,
    separatedBy: (separator, -separator),
    capacity: capacity
  )
  
  expectTrue(refTree.matches(newTree))
  _BTree(rootedAt: newTree, internalCapacity: capacity).checkInvariants()
}


final class NodeJoinTests: CollectionTestCase {
  func test_joinSimple() {
    expectNodeJoin(
      capacity: 5,
      tree1: tree {
        0
      },
      separator: 1,
      tree2: tree {
        2; 3; 4
      },
      toEqual: tree { 0; 1; 2; 3; 4 }
    )
    
    expectNodeJoin(
      capacity: 5,
      tree1: tree {
        0
      },
      separator: 1,
      tree2: tree {
        2; 3; 4; 5
      },
      toEqual: tree {
        tree { 0; 1; 2 }
        3
        tree { 4; 5 }
      }
    )
  }
  
  func test_joinMedian() {
    expectNodeJoin(
      capacity: 2,
      tree1: tree {
        tree { 0 }
        1
        tree { 2 }
        2
        tree { 3 }
      },
      separator: 4,
      tree2: tree {
        tree { 5 }
        6
        tree { 7 }
        8
        tree { 9 }
      },
      toEqual: tree {
        tree {
          tree { 0 }
          1
          tree { 2 }
          2
          tree { 3 }
        }
        4
        tree {
          tree { 5 }
          6
          tree { 7 }
          8
          tree { 9 }
        }
      }
    )
  }
}
#endif
