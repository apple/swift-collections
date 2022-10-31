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
}
#endif
