//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.2)
extension _HTable {
  @usableFromInline
  internal func find_Small(
    tester: (Bucket) -> Bool,
  ) -> Bucket? {
    assert(isSmall)
    // Linear search
    var bucket = Bucket(offset: 0)
    while bucket.offset < count {
      if tester(bucket) { return bucket }
      bucket._offset &+= 1
    }
    return nil
  }

  @usableFromInline
  internal func find_Large(
    hashValue: Int,
    tester: (Bucket) -> Bool,
  ) -> Bucket? {
    assert(!isSmall)
#if COLLECTIONS_NO_ROBIN_HOOD_HASHING
    // Naive find
    let start = idealBucket(forHashValue: hashValue)
    var it = makeBucketIterator(from: start)
    while it.isOccupied {
      if tester(it.currentBucket) {
        return it.currentBucket
      }
      it.wrapToNextBit()
    }
    return nil
#else
    let start = idealBucket(forHashValue: hashValue)
    var it = makeBucketIterator(from: start)
    var i = 0
    while it.isOccupied, i <= _maxProbeLength {
      if tester(it.currentBucket) {
        return it.currentBucket
      }
      it.wrapToNextBit()
      i &+= 1
    }
    return nil
#endif
  }
}
#endif
