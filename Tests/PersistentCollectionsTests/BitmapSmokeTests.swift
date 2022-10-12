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
import XCTest
@testable import PersistentCollections

#if false
final class BitmapSmokeTests: CollectionTestCase {
  func test_BitPartitionSize_isValid() {
    expectTrue(_bitPartitionSize > 0)
    expectTrue((2 << (_bitPartitionSize - 1)) != 0)
    expectTrue((2 << (_bitPartitionSize - 1)) <= Bitmap.bitWidth)
  }

  func test_Bitmap_nonzeroBits() {
    let bitmap: Bitmap = 0b0100_0000_0000_1011

    expectEqual(Array(bitmap._nonzeroBits()), [0, 1, 3, 14])
    expectEqual(
      Array(bitmap._zeroBits()),
      (0 ..< Bitmap.bitWidth).filter { ![0, 1, 3, 14].contains($0) })
  }

  func test_Bitmap_nonzeroBitsToArray() {
    let bitmap: Bitmap = 0b0100_0000_0000_1011

    let counts = bitmap._nonzeroBits().reduce(
      into: Array(repeating: 0, count: Bitmap.bitWidth)
    ) { counts, index in
      counts[index] = 1
    }

    expectEqual(counts.count, Bitmap.bitWidth)
    expectEqual(counts.reduce(0, +), bitmap.nonzeroBitCount)
    expectEqual(counts.reduce(0, +), 4)
    expectEqual(counts[0], 1)
    expectEqual(counts[1], 1)
    expectEqual(counts[3], 1)
    expectEqual(counts[14], 1)
  }

  func test_Bitmap_enumerateCompactedArray() {
    let bitmap: Bitmap = 0b0100_0000_0000_1011
    let elements: [String] = ["zero", "one", "three", "fourteen"]

    var zipIterator = zip(bitmap._nonzeroBits(), elements).makeIterator()

    expectEqual(zipIterator.next()!, (0, "zero"))
    expectEqual(zipIterator.next()!, (1, "one"))
    expectEqual(zipIterator.next()!, (3, "three"))
    expectEqual(zipIterator.next()!, (14, "fourteen"))
    expectNil(zipIterator.next())
  }
}
#endif
