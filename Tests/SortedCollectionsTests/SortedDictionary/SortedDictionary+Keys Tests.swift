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

class SortedDictionaryKeysTests: CollectionTestCase {
  func test_keys() {
    let d: SortedDictionary = [
      1: "one",
      2: "two",
      3: "three",
      4: "four",
    ]
    expectEqualElements(d.keys, [1, 2, 3, 4])
  }
}
