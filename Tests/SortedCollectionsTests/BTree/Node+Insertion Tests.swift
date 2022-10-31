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

func expectInsertionInTree(
  capacity: Int,
  tree: NodeTemplate,
  inserting key: Int,
  toEqual refTree: NodeTemplate) {
  var btree = tree.toBTree(ofCapacity: capacity)
  
  btree.updateAnyValue(key * 2, forKey: key)
  
  let refMatches = refTree.matches(btree)
  if !refMatches {
    print("Expected: ")
    print(refTree.toBTree(ofCapacity: capacity))
    print("Instead got: ")
    print(btree)
  }
  expectTrue(refMatches)
}

final class NodeInsertionTests: CollectionTestCase {
  // MARK: Median Leaf Node Insertion
  func test_medianLeafInsertion() {
    expectInsertionInTree(
      capacity: 2,
      tree: tree { 0; 2 },
      inserting: 1,
      toEqual: tree {
        tree { 0 }
        1
        tree { 2 }
      }
    )
    
    expectInsertionInTree(
      capacity: 4,
      tree: tree { 0; 1; 3; 4 },
      inserting: 2,
      toEqual: tree {
        tree { 0; 1 }
        2
        tree { 3; 4 }
      }
    )
    
    expectInsertionInTree(
      capacity: 5,
      tree: tree { 0; 1; 3; 4; 5 },
      inserting: 2,
      toEqual: tree {
        tree { 0; 1 }
        2
        tree { 3; 4; 5 }
      }
    )
  }
  
  // MARK: Median Internal Node Insertion
  func test_medianInternalInsertion() {
    expectInsertionInTree(
      capacity: 2,
      tree: tree {
        tree { 0; 1 }
        2
        tree { 3; 5 }
        6
        tree { 7; 8 }
      },
      inserting: 4,
      toEqual: tree {
        tree {
          tree { 0; 1 }
          2
          tree { 3 }
        }
        4
        tree {
          tree { 5 }
          6
          tree { 7; 8 }
        }
      }
    )
    
    expectInsertionInTree(
      capacity: 3,
      tree: tree {
        tree { 0; 1; 2 }
        3
        tree { 4; 6; 7 }
        8
        tree { 9; 10; 11 }
        12
        tree { 13; 14; 15 }
      },
      inserting: 5,
      toEqual: tree {
        tree {
          tree { 0; 1; 2 }
          3
          tree { 4 }
        }
        5
        tree {
          tree { 6; 7 }
          8
          tree { 9; 10; 11 }
          12
          tree { 13; 14; 15 }
        }
      }
    )
    
    expectInsertionInTree(
      capacity: 4,
      tree: tree {
        tree { 0; 1; 2; 4 }
        5
        tree { 6; 7; 8; 9 }
        10
        tree { 11; 12; 14; 15 }
        16
        tree { 17; 18; 19; 20 }
        21
        tree { 22; 23; 24; 25 }
      },
      inserting: 13,
      toEqual: tree {
        tree {
          tree { 0; 1; 2; 4 }
          5
          tree { 6; 7; 8; 9 }
          10
          tree { 11; 12 }
        }
        13
        tree {
          tree { 14; 15 }
          16
          tree { 17; 18; 19; 20 }
          21
          tree { 22; 23; 24; 25 }
        }
      }
    )
    
    expectInsertionInTree(
      capacity: 5,
      tree: tree {
        tree { 0; 1; 2; 4; 5 }
        6
        tree { 7; 8; 9; 10; 11 }
        12
        tree { 13; 14; 16; 17; 18 }
        19
        tree { 20; 21; 22; 23; 24 }
        25
        tree { 26; 27; 28; 29; 30 }
        31
        tree { 32; 33; 34; 35; 36 }
      },
      inserting: 15,
      toEqual: tree {
        tree {
          tree { 0; 1; 2; 4; 5 }
          6
          tree { 7; 8; 9; 10; 11 }
          12
          tree { 13; 14 }
        }
        15
        tree {
          tree { 16; 17; 18 }
          19
          tree { 20; 21; 22; 23; 24 }
          25
          tree { 26; 27; 28; 29; 30 }
          31
          tree { 32; 33; 34; 35; 36 }
        }
      }
    )
  }
  
  // MARK: Right Leaf Insertion
  func test_rightLeafInsertion() {
    expectInsertionInTree(
      capacity: 2,
      tree: tree { 1; 2 },
      inserting: 3,
      toEqual: tree {
        tree { 1 }
        2
        tree { 3 }
      }
    )
    
    expectInsertionInTree(
      capacity: 3,
      tree: tree { 1; 2; 4 },
      inserting: 3,
      toEqual: tree {
        tree { 1 }
        2
        tree { 3; 4 }
      }
    )
    
    expectInsertionInTree(
      capacity: 4,
      tree: tree { 0; 1; 2; 4 },
      inserting: 3,
      toEqual: tree {
        tree { 0; 1 }
        2
        tree { 3; 4 }
      }
    )
    
    expectInsertionInTree(
      capacity: 5,
      tree: tree { 0; 1; 2; 3; 5 },
      inserting: 4,
      toEqual: tree {
        tree { 0; 1 }
        2
        tree { 3; 4; 5 }
      }
    )
  }
  
  // MARK: Right Internal Node Insertion
  func test_rightInternalNodeInsertion() {
    expectInsertionInTree(
      capacity: 2,
      tree: tree {
        tree { 0; 1 }
        2
        tree { 3; 4 }
        5
        tree { 6; 7 }
      },
      inserting: 8,
      toEqual: tree {
        tree {
          tree { 0; 1 }
          2
          tree { 3; 4 }
        }
        5
        tree {
          tree { 6 }
          7
          tree { 8 }
        }
      }
    )
    
    expectInsertionInTree(
      capacity: 3,
      tree: tree {
        tree { 0; 1; 2 }
        3
        tree { 4; 5; 6 }
        7
        tree { 8; 9; 10 }
        11
        tree { 12; 13; 15 }
      },
      inserting: 14,
      toEqual: tree {
        tree {
          tree { 0; 1; 2 }
          3
          tree { 4; 5; 6 }
        }
        7
        tree {
          tree { 8; 9; 10 }
          11
          tree { 12 }
          13
          tree { 14; 15 }
        }
      }
    )

    expectInsertionInTree(
      capacity: 4,
      tree: tree {
        tree { 0; 1; 2; 4 }
        5
        tree { 6; 7; 8; 9 }
        10
        tree { 11; 12; 13; 14 }
        15
        tree { 16; 17; 18; 19 }
        20
        tree { 21; 22; 23; 25 }
      },
      inserting: 24,
      toEqual: tree {
        tree {
          tree { 0; 1; 2; 4 }
          5
          tree { 6; 7; 8; 9 }
          10
          tree { 11; 12; 13; 14 }
        }
        15
        tree {
          tree { 16; 17; 18; 19 }
          20
          tree { 21; 22 }
          23
          tree { 24; 25 }
        }
      }
    )

    expectInsertionInTree(
      capacity: 5,
      tree: tree {
        tree { 0; 1; 2; 4; 5 }
        6
        tree { 7; 8; 9; 10; 11 }
        12
        tree { 13; 14; 15; 16; 17 }
        18
        tree { 19; 20; 21; 22; 23 }
        24
        tree { 25; 26; 27; 28; 29 }
        30
        tree { 31; 32; 33; 34; 36 }
      },
      inserting: 35,
      toEqual: tree {
        tree {
          tree { 0; 1; 2; 4; 5 }
          6
          tree { 7; 8; 9; 10; 11 }
          12
          tree { 13; 14; 15; 16; 17 }
        }
        18
        tree {
          tree { 19; 20; 21; 22; 23 }
          24
          tree { 25; 26; 27; 28; 29 }
          30
          tree { 31; 32 }
          33
          tree { 34; 35; 36 }
        }
      }
    )
  }
  
  // MARK: Left Leaf Insertion
  func test_leftLeafInsertion() {
    expectInsertionInTree(
      capacity: 2,
      tree: tree { 1; 2 },
      inserting: 0,
      toEqual: tree {
        tree { 0 }
        1
        tree { 2 }
      }
    )
    
    expectInsertionInTree(
      capacity: 3,
      tree: tree { 1; 2; 3 },
      inserting: 0,
      toEqual: tree {
        tree { 0; 1 }
        2
        tree { 3 }
      }
    )
    
    expectInsertionInTree(
      capacity: 4,
      tree: tree { 0; 2; 3; 4 },
      inserting: 1,
      toEqual: tree {
        tree { 0; 1 }
        2
        tree { 3; 4 }
      }
    )
    
    expectInsertionInTree(
      capacity: 5,
      tree: tree { 0; 2; 3; 4; 5 },
      inserting: 1,
      toEqual: tree {
        tree { 0; 1; 2 }
        3
        tree { 4; 5 }
      }
    )
  }
  
  // MARK: Left Internal Node Insertion
  func test_leftInternalNodeInsertion() {
    expectInsertionInTree(
      capacity: 2,
      tree: tree {
        tree { 1; 2 }
        3
        tree { 4; 5 }
        6
        tree { 7; 8 }
      },
      inserting: 0,
      toEqual: tree {
        tree {
          tree { 0 }
          1
          tree { 2 }
        }
        3
        tree {
          tree { 4; 5 }
          6
          tree { 7; 8 }
        }
      }
    )
    
    expectInsertionInTree(
      capacity: 3,
      tree: tree {
        tree { 1; 2; 3 }
        4
        tree { 5; 6; 7 }
        8
        tree { 9; 10; 11 }
        12
        tree { 13; 14; 15 }
      },
      inserting: 0,
      toEqual: tree {
        tree {
          tree { 0; 1 }
          2
          tree { 3 }
          4
          tree { 5; 6; 7 }
        }
        8
        tree {
          tree { 9; 10; 11 }
          12
          tree { 13; 14; 15 }
        }
      }
    )

    expectInsertionInTree(
      capacity: 4,
      tree: tree {
        tree { 0; 2; 3; 4 }
        5
        tree { 6; 7; 8; 9 }
        10
        tree { 11; 12; 13; 14 }
        15
        tree { 16; 17; 18; 19 }
        20
        tree { 21; 22; 23; 24 }
      },
      inserting: 1,
      toEqual: tree {
        tree {
          tree { 0; 1 }
          2
          tree { 3; 4 }
          5
          tree { 6; 7; 8; 9 }
        }
        10
        tree {
          tree { 11; 12; 13; 14 }
          15
          tree { 16; 17; 18; 19 }
          20
          tree { 21; 22; 23; 24 }
        }
      }
    )

    expectInsertionInTree(
      capacity: 5,
      tree: tree {
        tree { 0; 2; 3; 4; 5 }
        6
        tree { 7; 8; 9; 10; 11 }
        12
        tree { 13; 14; 15; 16; 17 }
        18
        tree { 19; 20; 21; 22; 23 }
        24
        tree { 25; 26; 27; 28; 29 }
        30
        tree { 31; 32; 33; 34; 35 }
      },
      inserting: 1,
      toEqual: tree {
        tree {
          tree { 0; 1; 2 }
          3
          tree { 4; 5 }
          6
          tree { 7; 8; 9; 10; 11 }
          12
          tree { 13; 14; 15; 16; 17 }
        }
        18
        tree {
          tree { 19; 20; 21; 22; 23 }
          24
          tree { 25; 26; 27; 28; 29 }
          30
          tree { 31; 32; 33; 34; 35 }
        }
      }
    )
  }
}
#endif
