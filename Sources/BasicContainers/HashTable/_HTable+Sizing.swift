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
  /// The minimum hash table scale.
  @_alwaysEmitIntoClient
  package static var minimumScale: UInt8 {
    @_effects(readnone)
    @_transparent
    get {
      4
    }
  }
  
  /// The maximum hash table scale.
  @_alwaysEmitIntoClient
  package static var maximumScale: UInt8 {
    @_effects(readnone)
    @_transparent
    get {
      Swift.min(UInt8(truncatingIfNeeded: Int.bitWidth) &- 1, 56)
    }
  }
  
  /// The maximum number of items for which we do not create a hash table.
  @usableFromInline
  package static var maximumUnhashedCount: Int {
    @_effects(readnone)
    get {
      maximumCapacity(forScale: 0)
    }
  }
  
  @inlinable
  @inline(__always)
  package static func wordCount(forScale scale: UInt8) -> Int {
    guard scale > 0 else { return 0 }
    let shift = Swift.max(UInt(scale), Word.wordShift) - Word.wordShift
    return 1 &<< shift
  }

  // These specific parameters result in the following capacity ranges:
  //
  //    Scale   Capacity range
  //        4     2 ... 14
  //        5     4 ... 28
  //        6     8 ... 56
  //        7    16 ... 112
  //        8    32 ... 224
  //        9    64 ... 448
  //       10   128 ... 896
  //       11   256 ... 1792
  //       12   512 ... 3584
  //       etc.
  //
  // Note how neighboring intervals overlap significantly, as far as two steps
  // away. This provides hysteresis for storage capacities, preventing hash
  // tables from repeatedly shrinking/growing when only a handful of items are
  // added/removed in a loop.
  
  /// The numerator of the maximum hash table load factor.
  @_transparent
  internal static var _maxLFNum: UInt { 7 }
  
  /// The denominator of the maximum hash table load factor.
  @_transparent
  internal static var _maxLFDenom: UInt { 8 }
  
  /// The numerator of the minimum hash table load factor.
  @_transparent
  internal static var _minLFNum: UInt { 1 }
  
  /// The denominator of minimum hash table load factor.
  @_alwaysEmitIntoClient
  @_transparent
  internal static var _minLFDenom: UInt { 8 }
  
  /// The minimum number of items that can be held in a hash table of the given scale.
  @usableFromInline
  @_effects(readnone)
  package static func minimumCapacity(forScale scale: UInt8) -> Int {
    guard scale >= minimumScale else { return 0 }
    precondition(scale <= maximumScale)
    let bucketCount: UInt = 1 &<< scale
    return Int(bucketCount * _minLFNum / _minLFDenom)
  }
  
  /// The maximum number of items that can be held in a hash table of the given scale.
  @usableFromInline
  @_effects(readnone)
  package static func maximumCapacity(forScale scale: UInt8) -> Int {
    let scale = Swift.max(scale, minimumScale &- 1)
    let bucketCount: UInt = 1 &<< scale
    return Int(bucketCount * _maxLFNum / _maxLFDenom)
  }
  
  
  /// The minimum hash table scale that can hold the specified number of elements.
  @usableFromInline
  @_effects(readnone)
  package static func minimumScale(forCapacity capacity: Int) -> UInt8 {
    guard capacity > maximumUnhashedCount else { return 0 }
    let capacity = UInt(truncatingIfNeeded: Swift.max(capacity, 1))
    // Calculate the minimum number of entries we need to allocate to satisfy
    // the maximum load factor.
    let minimumEntries = Swift.max(
      (capacity * _maxLFDenom + _maxLFNum - 1) / _maxLFNum, // (capacity / maxLoadFactor).rounded(.up)
      capacity + 1)
    // The actual number of entries we need to allocate is the lowest power of
    // two greater than or equal to the minimum entry count. Calculate its
    // exponent.
    let scale = (Swift.max(minimumEntries, 2) - 1)._binaryLogarithm() + 1
    assert(scale >= minimumScale && scale <= maximumScale)
    // The scale is the exponent corresponding to the bucket count.
    assert(self.maximumCapacity(forScale: UInt8(scale)) >= capacity)
    return UInt8(truncatingIfNeeded: scale)
  }

  @usableFromInline
  @_effects(readnone)
  package static func dynamicStorageParameters(
    minimumCapacity: Int
  ) -> (scale: UInt8, capacity: Int) {
    let maximumUnhashedCount = self.maximumUnhashedCount
    if minimumCapacity <= maximumUnhashedCount {
      let c = Swift.min(
        minimumCapacity._roundUpToPowerOfTwo(),
        maximumUnhashedCount)
      return (0, c)
    }
    let scale = minimumScale(forCapacity: minimumCapacity)
    let capacity = maximumCapacity(forScale: scale)
    assert(capacity >= minimumCapacity)
    let storageCapacity: Int = 1 &<< scale
    assert(capacity < storageCapacity) // We need at least one empty bucket.
    return (scale, capacity)
  }
}
#endif
