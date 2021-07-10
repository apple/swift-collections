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

import CollectionsTestSupport
@_spi(Testing) @testable import SortedCollections

final class NodeBalancingTests: CollectionTestCase {
  func test_collapseAtSlot() {
    let t = tree {
      tree {
        tree { 0; 1 }
        2
        tree { 3; 4 }
        5
        tree { 6; 7 }
      }
      8
      tree {
        tree { 9; 10 }
        11
        tree { 12; 13 }
        14
        tree { 15; 16 }
      }
      17
      tree {
        tree { 18; 19 }
        20
        tree { 21; 22 }
        23
        tree { 24; 25 }
      }
    }

    var btree = t.toBTree(ofCapacity: 2)
    print(btree.debugDescription)
    btree.removeAny(key: 0)
    btree.removeAny(key: 1)
    btree.removeAny(key: 2)
    btree.removeAny(key: 3)
    btree.removeAny(key: 4)
    btree.removeAny(key: 5)
    btree.removeAny(key: 6)
    btree.removeAny(key: 18)
    print(btree.debugDescription)
//    print(SortedDictionary<Int, Int>(_rootedAt: btree))
  }
  
  // MARK: Right Rotation
  func test_internalRightRotation() {
    let t = tree {
      tree {
        tree { 1; 2 }
        3
        tree { 4 ; 5 }
        6
        tree { 7; 8 }
      }
      9
      tree {
        tree { 10; 11 }
      }
    }
    
    var node = t.toNode(ofCapacity: 2)
    node.update { $0.rotateRight(at: 0) }
    
    expectTrue(
      tree {
        tree {
          tree { 1; 2 }
          3
          tree { 4; 5 }
        }
        6
        tree {
          tree { 7; 8 }
          9
          tree { 10; 11 }
        }
      }.matches(node)
    )
  }
  
  func test_leafRightRotation() {
    let t = tree {
      tree { 0; 1 }
      2
      tree { 3 }
    }
    
    var node = t.toNode(ofCapacity: 2)
    node.update { $0.rotateRight(at: 0) }
    
    expectTrue(
      tree {
        tree { 0 }
        1
        tree { 2; 3 }
      }.matches(node)
    )
  }
  
  // MARK: Left Rotation
  func test_internalLeftRotation() {
    let t = tree {
      tree {
        tree { 1; 2 }
      }
      3
      tree {
        tree { 4 ; 5 }
        6
        tree { 7; 8 }
        9
        tree { 10; 11 }
      }
    }
    
    var node = t.toNode(ofCapacity: 2)
    node.update { $0.rotateLeft(at: 0) }
    
    expectTrue(
      tree {
        tree {
          tree { 1; 2 }
          3
          tree { 4; 5 }
        }
        6
        tree {
          tree { 7; 8 }
          9
          tree { 10; 11 }
        }
      }.matches(node)
    )
  }
  
  func test_leafLeftRotation() {
    let t = tree {
      tree { 0 }
      1
      tree { 2; 3 }
    }
    
    var node = t.toNode(ofCapacity: 2)
    node.update { $0.rotateLeft(at: 0) }
    
    expectTrue(
      tree {
        tree { 0; 1 }
        2
        tree { 3 }
      }.matches(node)
    )
  }
  
  func test_emptyLeafLeftRotation() {
    let t = tree {
      tree { }
      1
      tree { 2; 3 }
    }
    
    var node = t.toNode(ofCapacity: 2)
    node.update { $0.rotateLeft(at: 0) }
    
    expectTrue(
      tree {
        tree { 1 }
        2
        tree { 3 }
      }.matches(node)
    )
  }
  
  // MARK: Collapse
  func test_internalCollapse() {
    let t = tree {
      tree {
        tree { 1; 2 }
      }
      3
      tree {
        tree { 4 }
        5
        tree { 6; 7 }
      }
    }
    
    var node = t.toNode(ofCapacity: 2)
    node.update { $0.collapse(at: 0) }
    
    expectTrue(
      tree {
        tree {
          tree { 1; 2 }
          3
          tree { 4 }
          5
          tree { 6; 7 }
        }
      }.matches(node)
    )
  }
  
  func test_leafCollapse() {
    let t = tree {
      tree { }
      2
      tree { 3 }
      4
      tree { 5; 6 }
    }

    var node = t.toNode(ofCapacity: 2)
    node.update { $0.collapse(at: 0) }
    
    expectTrue(
      tree {
        tree { 2; 3 }
        4
        tree { 5; 6 }
      }.matches(node)
    )
  }
}
