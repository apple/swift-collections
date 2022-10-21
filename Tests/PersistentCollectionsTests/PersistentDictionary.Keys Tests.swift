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

import XCTest
import _CollectionsTestSupport
import PersistentCollections

class PersistentDictionaryKeysTests: CollectionTestCase {
  func test_BidirectionalCollection_fixtures() {
    withEachFixture { fixture in
      withLifetimeTracking { tracker in
        let (d, ref) = tracker.persistentDictionary(for: fixture)
        checkBidirectionalCollection(
          d.keys,
          expectedContents: ref.map { $0.key },
          by: ==)
      }
    }
  }

  func test_descriptions() {
    let d: PersistentDictionary = [
      "a": 1,
      "b": 2
    ]

    if d.first!.key == "a" {
      expectEqual(d.keys.description, "[a, b]")
      expectEqual(
        d.keys.debugDescription,
        "PersistentDictionary<String, Int>.Keys([\"a\", \"b\"])")
    } else {
      expectEqual(d.keys.description, "[b, a]")
      expectEqual(
        d.keys.debugDescription,
        "PersistentDictionary<String, Int>.Keys([\"b\", \"a\"])")
    }
  }
}
