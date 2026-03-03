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
  @usableFromInline
  internal mutating func insertNew_Small(
    swapper: (Bucket) -> Void,
  ) -> Bucket {
    assert(isSmall)
    // FIXME: Scramble order by swapping things in some way
    let r = Bucket(offset: _count)
    _count &+= 1
    _maxProbeLength = _count
    return r
  }
  
  
  @usableFromInline
  internal mutating func insertNew_Large(
    hashValue: Int,
    hashGenerator: (Bucket) -> Int,
    swapper: (Bucket) -> Void,
  ) -> Bucket {
    assert(!isSmall)
    assert(!isFull)
    
#if COLLECTIONS_NO_ROBIN_HOOD_HASHING
    let ideal = idealBucket(forHashValue: hashValue)
    let bitmap = self.bitmap
    let actual = bitmap.nextUnoccupiedBucket(wrappingFrom: ideal)
    bitmap.setOccupied(actual)
    let probeLength = self.probeLength(from: ideal, to: actual)
    _maxProbeLength = Swift.max(_maxProbeLength, probeLength)
    _count &+= 1
    return actual
#else
    var b = idealBucket(forHashValue: hashValue)
    var probeLength = 0
    while bitmap.isOccupied(b) {
      probeLength &+= 1
      let oldHashValue = hashGenerator(b)
      let oldProbeLength = self.probeLength(
        forHashValue: oldHashValue,
        in: b)
      if probeLength > oldProbeLength {
        swapper(b)
        if probeLength > _maxProbeLength {
          _maxProbeLength = probeLength
        }
        probeLength = oldProbeLength
      }
      self.wrapBucket(after: &b)
    }
    bitmap.setOccupied(b)
    _count &+= 1
    if probeLength > _maxProbeLength {
      _maxProbeLength = probeLength
    }
    return b
#endif
  }
}
#endif
