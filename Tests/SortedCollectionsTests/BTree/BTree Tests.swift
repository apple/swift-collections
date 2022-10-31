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

func btreeOfSize(
  _ size: Int,
  _ body: (inout _BTree<Int, Int>, [(key: Int, value: Int)]) throws -> Void
) rethrows {
  var tree = _BTree<Int, Int>(capacity: 2)
  var keyValues = [(key: Int, value: Int)]()
  for i in 0..<size {
    tree.updateAnyValue(i * 2, forKey: i)
    keyValues.append((key: i, value: i * 2))
  }
  try withExtendedLifetime(tree) {
    try body(&tree, keyValues)
  }
}

final class BTreeTests: CollectionTestCase {
  func test_iterator() {
    btreeOfSize(100) { tree, kvs in
      for (treeElem, kv) in zip(tree, kvs) {
        expectEqual(treeElem.key, kv.key)
        expectEqual(treeElem.value, kv.value)
      }
    }
  }
  
  func test_indexAtOffset() {
    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64]) { count in
      btreeOfSize(count) { btree, kvs in
        for i in 0..<count {
          let index = btree.index(atOffset: i)
          expectEqual(btree[index].key, i)
        }
      }
    }
  }
  
  func test_startIndex() {
    withEvery("count", in: [0, 1, 2, 4, 8, 16, 32, 64]) { count in
      btreeOfSize(count) { btree, kvs in
        if count == 0 {
          expectEqual(btree.startIndex, btree.endIndex)
        } else {
          expectEqual(btree[btree.startIndex].key, 0)
        }
      }
    }
  }
  
  func test_indexAfter() {
    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64]) { count in
      btreeOfSize(count) { btree, kvs in
        var index = btree.startIndex
        
        for i in 0..<count {
          expectEqual(btree[index].key, i)
          btree.formIndex(after: &index)
        }
        
        expectEqual(index, btree.endIndex)
      }
    }
  }
  
  func test_indexBefore() {
    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64]) { count in
      btreeOfSize(count) { btree, kvs in
        var index = btree.endIndex
        
        for i in (0..<count).reversed() {
          btree.formIndex(before: &index)
          expectEqual(btree[index].key, i)
        }
      }
    }
  }
  
  func test_indexOffsetByForward() {
    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64]) { count in
      btreeOfSize(count) { btree, kvs in
        withEvery("baseIndex", in: 0...count) { baseIndex in
          withEvery("distance", in: 0...(count - baseIndex)) { distance in
            var index = btree.index(atOffset: baseIndex)
            btree.formIndex(&index, offsetBy: distance)
            
            let expectedIndex = btree.index(atOffset: baseIndex + distance)
            
            expectEqual(index, expectedIndex)
          }
        }
      }
    }
  }
  
  func test_indexOffsetByBackward() {
    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64]) { count in
      btreeOfSize(count) { btree, kvs in
        withEvery("baseIndex", in: 0...count) { baseIndex in
          withEvery("distance", in: 0...baseIndex) { distance in
            var index = btree.index(atOffset: baseIndex)
            btree.formIndex(&index, offsetBy: -distance)
            
            let expectedIndex = btree.index(atOffset: baseIndex - distance)
            
            expectEqual(index, expectedIndex)
          }
        }
      }
    }
  }
  
  func test_bidirectionalCollection() {
    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64]) { count in
      btreeOfSize(count) { btree, kvs in
        checkBidirectionalCollection(
          btree,
          expectedContents: kvs,
          by: { $0.key == $1.key && $0.value == $1.value }
        )
      }
    }
  }
  
  func test_randomInsertionOrder() {
    let kvs = [
      (key: 71, value: 142),
      (key: 0, value: 0),
      (key: 53, value: 106),
      (key: 72, value: 144),
      (key: 74, value: 148),
      (key: 29, value: 58),
      (key: 24, value: 48),
      (key: 58, value: 116),
      (key: 17, value: 34),
      (key: 46, value: 92),
      (key: 62, value: 124),
      (key: 51, value: 102),
      (key: 70, value: 140),
      (key: 9, value: 18),
      (key: 75, value: 150),
      (key: 26, value: 52),
      (key: 69, value: 138),
      (key: 8, value: 16),
      (key: 30, value: 60),
      (key: 1, value: 2),
      (key: 12, value: 24),
      (key: 63, value: 126),
      (key: 49, value: 98),
      (key: 14, value: 28),
      (key: 43, value: 86),
      (key: 78, value: 156),
      (key: 100, value: 152),
    ]

    var tree = _BTree<Int, Int>()
    for (key, value) in kvs {
      tree.updateAnyValue(value, forKey: key)
    }
  }
}
#endif
