//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _CollectionsTestSupport
import PersistentCollections

class PersistentSetTests: CollectionTestCase {
  func test_init_empty() {
    let set = PersistentSet<Int>()
    expectEqual(set.count, 0)
    expectTrue(set.isEmpty)
    expectEqualElements(set, [])
  }

  func test_BidirectionalCollection() {
    withEachFixture { fixture in
      withLifetimeTracking { tracker in
        let (set, ref) = tracker.persistentSet(for: fixture)
        checkBidirectionalCollection(set, expectedContents: ref, by: ==)
      }
    }
  }


}
