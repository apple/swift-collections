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

#if compiler(>=6.2)
extension _HTable {
  @inlinable
  internal mutating func insertNew_Small(
    swapper: (Bucket) -> Void,
  ) -> Bucket {
    assert(isSmall)
    // FIXME: Scramble order by swapping things in some way
    let r = Bucket(offset: _count)
    _count &+= 1
    return r
  }
  
  
  @inlinable
  internal mutating func insertNew_Large(
    hashValue: Int,
    hashGenerator: (Bucket) -> Int,
    swapper: (Bucket) -> Void,
  ) -> Bucket {
    assert(!isSmall)
    assert(!isFull)
    
#if COLLECTIONS_NO_ROBIN_HOOD_HASHING
    let ideal = idealBucket(forHashValue: hashValue)
    let actual = _bitmap.firstUnoccupiedBucket(from: b)
    _totalProbeLength += probeLength(from: ideal, to: actual)
    _bitmap.setOccupied(actual)
    return actual
#else
    var b = idealBucket(forHashValue: hashValue)
    var probeLength = 0
    while bitmap.isOccupied(b) {
      probeLength &+= 1
      _totalProbeLength &+= 1
      let oldHashValue = hashGenerator(b)
      let oldProbeLength = self.probeLength(
        forHashValue: oldHashValue,
        in: b)
      if probeLength > oldProbeLength {
        swapper(b)
        probeLength = oldProbeLength
      }
      self.wrapBucket(after: &b)
    }
    _totalProbeLength &+= 1
    bitmap.setOccupied(b)
    _count &+= 1
    return b
#endif
  }
}
#endif
