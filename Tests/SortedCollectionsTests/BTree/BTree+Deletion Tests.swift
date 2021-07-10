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

final class NodeDeletionTests: CollectionTestCase {
  func test_singleDeletion() {
    withEvery("size", in: [1, 2, 4, 8, 16, 32, 64, 128, 2000]) { size in
      withEvery("key", in: 0..<size) { key in
        btreeOfSize(size) { tree, kvs in
          tree.removeAny(key: key)
          
          var comparisonKeys = Array(0..<size)
          comparisonKeys.remove(at: key)
          
          expectEqual(tree.count, size - 1)
          expectEqualElements(tree.map { $0.key }, comparisonKeys)
        }
      }
    }
  }
}
