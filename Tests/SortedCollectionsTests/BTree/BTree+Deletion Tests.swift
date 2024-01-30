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

final class NodeDeletionTests: CollectionTestCase {
  func test_singleDeletion() {
    withEvery("size", in: [1, 2, 4, 8, 16, 32, 64, 128]) { size in
      withEvery("key", in: 0..<size) { key in
        btreeOfSize(size) { tree, kvs in
          tree.removeAnyElement(forKey: key)
          
          var comparisonKeys = Array(0..<size)
          comparisonKeys.remove(at: key)
          
          expectEqual(tree.count, size - 1)
          expectEqualElements(tree.map { $0.key }, comparisonKeys)
        }
      }
    }
  }

  func test_removeAllWithRemoveFirst() {
    withEvery("size", in: [1, 2, 4, 8, 16, 32, 64, 128, 512]) { size in
      btreeOfSize(size) { tree, _ in
        expectEqual(tree.count, size)

        tree.removeFirst(size)

        expectEqual(tree.count, 0)
      }
    }
  }

  func test_removeAllWithRemoveLast() {
    withEvery("size", in: [1, 2, 4, 8, 16, 32, 64, 128, 512]) { size in
      btreeOfSize(size) { tree, _ in
        expectEqual(tree.count, size)

        tree.removeLast(size)

        expectEqual(tree.count, 0)
      }
    }
  }
}
#endif
