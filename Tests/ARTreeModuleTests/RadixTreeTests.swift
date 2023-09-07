//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _CollectionsTestSupport
@testable import ARTreeModule

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class RadixTreeCollectionTests: CollectionTestCase {
  func testDictionaryLiteral() throws {
    let d: RadixTree<String, Int> = [
      "a": 0,
      "b": 1,
      "c": 2
    ]

    var items: [(String, Int)] = []
    for (key, value) in d {
      items.append((key, value))
    }

    var count = 0
    for (lhs, rhs) in zip([("a", 0), ("b", 1), ("c", 2)], items) {
      count += 1
      expectEqual(lhs, rhs)
    }

    expectEqual(count, 3)
  }

  func testSubscript() throws {
    var d: RadixTree<String, Int> = [:]
    d["a"] = 0
    d["b"] = 1
    d["c"] = 2

    var items: [(String, Int)] = []
    for (key, value) in d {
      items.append((key, value))
    }

    var count = 0
    for (lhs, rhs) in zip([("a", 0), ("b", 1), ("c", 2)], items) {
      count += 1
      expectEqual(lhs, rhs)
    }

    expectEqual(count, 3)
  }

  func testEmptyIteration() throws {
    var d: RadixTree<String, Int> = [:]
    var count = 0
    for (k, v) in d {
      count += 1
    }
    expectEqual(count, 0)

    d["a"] = 0
    for _ in d {
      count += 1
    }
    expectEqual(count, 1)

    d["a"] = nil
    count = 0
    for _ in d {
      count += 1
    }
    expectEqual(count, 0)
  }
}
