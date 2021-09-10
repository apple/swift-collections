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

#if DEBUG // These unit tests need access to OrderedSet internals
import XCTest
import _CollectionsTestSupport
@_spi(Testing) @testable import OrderedCollections

class BitsetTests: CollectionTestCase {
  typealias Word = _UnsafeBitset.Word

  func test_empty() {
    withEvery("capacity", in: 0 ..< 500) { capacity in
      _UnsafeBitset.withTemporaryBitset(capacity: capacity) { bitset in
        expectGreaterThanOrEqual(bitset.capacity, capacity)
        expectEqual(bitset.count, 0)
        expectEqual(bitset._actualCount, 0)
        withEvery("i", in: 0 ..< capacity) { i in
          expectFalse(bitset.contains(i))
        }
      }
    }
  }

  func test_insert() {
    withEvery("capacity", in: [16, 64, 100, 128, 1000, 1024]) { capacity in
      withEvery("seed", in: 0 ..< 3) { seed in
        var rng = RepeatableRandomNumberGenerator(seed: seed)
        let items = (0 ..< capacity).shuffled(using: &rng)
        _UnsafeBitset.withTemporaryBitset(capacity: capacity) { bitset in
          var c = 0
          withEvery("item", in: items) { item in
            expectFalse(bitset.contains(item))
            expectTrue(bitset.insert(item))

            expectTrue(bitset.contains(item))
            expectFalse(bitset.insert(item))

            c += 1
            expectEqual(bitset.count, c)
          }
        }
      }
    }
  }

  func withRandomBitsets(
    capacity: Int,
    loadFactor: Double,
    body: (inout _UnsafeBitset, inout Set<Int>) throws -> Void
  ) rethrows {
    precondition(loadFactor >= 0 && loadFactor <= 1)
    try withEvery("seed", in: 0 ..< 10) { seed in
      var rng = RepeatableRandomNumberGenerator(seed: seed)
      var items = (0 ..< capacity).shuffled(using: &rng)
      items.removeLast(Int((1 - loadFactor) * Double(capacity)))
      try _UnsafeBitset.withTemporaryBitset(capacity: capacity) { bitset in
        for item in items {
          bitset.insert(item)
        }
        var set = Set(items)
        try body(&bitset, &set)
      }
    }
  }

  func test_remove() {
    withEvery("capacity", in: [16, 64, 100, 128, 1000, 1024]) { capacity in
      withRandomBitsets(capacity: capacity, loadFactor: 0.5) { bitset, contents in
        var c = contents.count
        withEvery("item", in: 0 ..< capacity) { item in
          if contents.contains(item) {
            expectTrue(bitset.remove(item))
            expectFalse(bitset.contains(item))
            c -= 1
            expectEqual(bitset.count, c)
          } else {
            expectFalse(bitset.remove(item))
            expectEqual(bitset.count, c)
          }
        }
        expectEqual(bitset.count, 0)
        withEvery("item", in: 0 ..< capacity) { item in
          expectFalse(bitset.contains(item))
        }
      }
    }
  }

  func test_clear() {
    withEvery("capacity", in: [16, 64, 100, 128, 1000, 1024]) { capacity in
      withRandomBitsets(capacity: capacity, loadFactor: 0.5) { bitset, contents in
        bitset.clear()
        expectEqual(bitset.count, 0)
        withEvery("item", in: 0 ..< capacity) { item in
          expectFalse(bitset.contains(item))
        }
      }
    }
  }

  func test_insertAll_upTo() {
    withEvery("capacity", in: [16, 64, 100, 128, 1000, 1024]) { capacity in
      withRandomBitsets(capacity: capacity, loadFactor: 0.5) { bitset, contents in

        let cutoff = capacity / 2
        bitset.insertAll(upTo: cutoff)
        expectEqual(
          bitset.count,
          capacity / 2 + contents.lazy.filter { $0 >= cutoff }.count)
        withEvery("item", in: 0 ..< capacity) { item in
          if item < cutoff {
            expectTrue(bitset.contains(item))
          } else {
            expectEqual(bitset.contains(item), contents.contains(item))
          }
        }

        bitset.insertAll(upTo: capacity)
        expectEqual(bitset.count, capacity)
        withEvery("item", in: 0 ..< capacity) { item in
          expectTrue(bitset.contains(item))
        }
      }
    }
  }

  func test_removeAll_upTo() {
    withEvery("capacity", in: [16, 64, 100, 128, 1000, 1024]) { capacity in
      withRandomBitsets(capacity: capacity, loadFactor: 0.5) { bitset, contents in

        let cutoff = capacity / 2
        bitset.removeAll(upTo: cutoff)
        expectEqual(
          bitset.count,
          contents.lazy.filter { $0 >= cutoff }.count)
        withEvery("item", in: 0 ..< capacity) { item in
          if item < cutoff {
            expectFalse(bitset.contains(item))
          } else {
            expectEqual(bitset.contains(item), contents.contains(item))
          }
        }

        bitset.removeAll(upTo: capacity)
        expectEqual(bitset.count, 0)
        withEvery("item", in: 0 ..< capacity) { item in
          expectFalse(bitset.contains(item))
        }
      }
    }
  }

  func test_Sequence() {
    withEvery("capacity", in: [16, 64, 100, 128, 1000, 1024]) { capacity in
      withRandomBitsets(capacity: capacity, loadFactor: 0.5) { bitset, contents in
        expectEqual(bitset.underestimatedCount, contents.count)
        let expected = contents.sorted()
        var actual: [Int] = []
        actual.reserveCapacity(bitset.count)
        for item in bitset {
          actual.append(item)
        }
        expectEqual(actual, expected)
      }
    }
  }

  func test_max() {
    withEvery("capacity", in: [16, 64, 100, 128, 1000, 1024]) { capacity in
      withRandomBitsets(capacity: capacity, loadFactor: 0.5) { bitset, contents in
        let max = bitset.max()
        expectEqual(max, contents.max())
      }
    }
  }

}
#endif // DEBUG
