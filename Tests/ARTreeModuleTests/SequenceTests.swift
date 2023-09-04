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
final class ARTreeSequenceTests: CollectionTestCase {
  func testSequenceEmpty() throws {
    let t = ARTree<[UInt8]>()
    var total = 0
    for (_, _) in t {
      total += 1
    }
    expectEqual(total, 0)
  }

  func testSequenceBasic() throws {
    let sizes = [3, 12, 30, 70]
    for size in sizes {
      print("With \(size) nodes")
      var t = ARTree<[UInt8]>()
      var pairs: [(Key, [UInt8])] = []
      for i in 0...size {
        let s = UInt8(i)
        pairs.append(([s, s + 1, s + 2, s + 3], [s]))
      }

      for (k, v) in pairs {
        t.insert(key: k, value: v)
      }

      var newPairs: [(Key, [UInt8])] = []
      for (k, v) in t {
        newPairs.append((k, v))
      }

      expectEqual(pairs.count, newPairs.count)
      for ((k1, v1), (k2, v2)) in zip(pairs, newPairs) {
        expectEqual(k1, k2)
        expectEqual(v1, v2)
      }
    }
  }
}
