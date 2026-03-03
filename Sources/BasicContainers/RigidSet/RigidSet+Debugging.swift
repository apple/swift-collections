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

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  public func _describe(
    bitmap: Bool = false,
    chains: Bool = false,
    buckets: Bool = false,
  ) -> String {
    var s = _table.describe(bitmap: bitmap)
    if chains {
      s += "\n"
      s += _chainDescription
    }
    if buckets, !_table.isSmall, !_table.isEmpty {
      s += "\nBuckets:"
      var it = _table.makeBucketIterator()
      var c = 0
      while let next = it.nextOccupiedRegion() {
        var b = next.lowerBound
        while b != next.upperBound {
          if c.isMultiple(of: 8) { s += "\n  " }
          let hashValue = _hashValue(at: b)
          let idealBucket = _table.idealBucket(forHashValue: hashValue)
          let s1 = String(b.offset)._lpad(5)
          let s2 = String(idealBucket.offset)._rpad(5)
          s += "\(s1)→\(s2) "
          c += 1
          b._offset += 1
        }
      }
      s += "\n"
    }
    return s
  }

  public func _dump(
    bitmap: Bool = false,
    chains: Bool = false,
    buckets: Bool = false,
  ) {
    print(self._describe(bitmap: bitmap, chains: chains, buckets: buckets))
  }
  
  public func _probeLengthCounts() -> (successful: [Int], unsuccessful: [Int]) {
    var positiveLengths: [Int: Int] = [:]
    var negativeLengths: [Int: Int] = [:]
    var it = self._table.makeBucketIterator()
    var prev = self._table.startBucket
    while let next = it.nextOccupiedRegion() {
      negativeLengths[0, default: 0] += next.lowerBound.offset - prev.offset
      var b = next.lowerBound
      while b != next.upperBound {
        let hashValue = self._hashValue(at: b)
        let pl = _table.probeLength(forHashValue: hashValue, in: b)
        positiveLengths[pl, default: 0] += 1

        var nl = next.upperBound.offset - b.offset
#if !COLLECTIONS_NO_ROBIN_HOOD_HASHING
        nl = Swift.min(nl, _table._maxProbeLength)
#endif
        negativeLengths[nl, default: 0] += 1
        _table.formBucket(after: &b)
      }
      prev = next.upperBound
    }
    var successful = Array(repeating: 0, count: positiveLengths.keys.max() ?? 0)
    assert(positiveLengths[0] == nil)
    var totalChainLength = 0
    var totalCount = 0
    for (length, count) in positiveLengths {
      successful[length - 1] = count
      totalChainLength += length * count
      totalCount += count
    }
    //assert(totalCount == self.count)

    var unsuccessful = Array(
      repeating: 0,
      count: 1 + (negativeLengths.keys.max() ?? 0))
    for (length, count) in negativeLengths {
      unsuccessful[length] = count
    }
    return (successful, unsuccessful)
  }
  
  package var _chainDescription: String {
    let data = self._probeLengthCounts()
    var str = ""
    do {
      str += "Chain length distribution (for successful lookups):\n"
      let max = data.successful.max() ?? 1
      var sum = 0
      var histogram = ""
      for length in data.successful.indices {
        let count = data.successful[length]
        histogram += "\(String(length + 1)._lpad(6)): "
        let dotCount = (75 * count + max) / max
        histogram += String(repeating: "*", count: dotCount)
        histogram += " \(count)\n"
        sum += (length + 1) * count
      }
      let avg = Double((sum * 1000 + 500) / _table.count) / 1000.0
      str += "   AVG: \(avg)\n"
      str += histogram
    }
    do {
      str += "Chain length distribution (for unsuccessful lookups):\n"
      let max = data.unsuccessful.max() ?? 1
      var sum = 0
      var histogram = ""
      for length in data.unsuccessful.indices {
        let count = data.unsuccessful[length]
        histogram += "\(String(length)._lpad(6)): "
        let dotCount = (75 * count + max) / max
        histogram += String(repeating: "*", count: dotCount)
        histogram += " \(count)\n"
        sum += length * count
      }
      let avg = Double((sum * 1000 + 500) / _table.storageCapacity) / 1000.0
      str += "   AVG: \(avg)\n"
      str += histogram
    }
    return str
  }
}

#endif
