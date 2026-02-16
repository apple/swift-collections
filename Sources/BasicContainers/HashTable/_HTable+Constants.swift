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
  @_transparent
  internal static var minimumScale: Int {
    @_effects(readnone)
    get {
      4
    }
  }
  
  /// The maximum hash table scale.
  @_alwaysEmitIntoClient
  @_transparent
  internal static var maximumScale: Int {
    @_effects(readnone)
    get {
      Swift.min(Int.bitWidth &- 1, 56)
    }
  }
  
  /// The maximum number of items for which we do not create a hash table.
  @_alwaysEmitIntoClient
  @_transparent
  internal static var maximumUnhashedCount: Int {
    @_effects(readnone)
    get {
      (1 &<< (minimumScale &- 1)) &- 1
    }
  }
  
  @inlinable
  @inline(__always)
  package static func wordCount(forScale scale: UInt8) -> Int {
    guard scale > 0 else { return 0 }
    let shift = Swift.max(UInt(scale), Word.wordShift) - Word.wordShift
    return 1 &<< shift
  }
  
  /// The numerator of the maximum hash table load factor.
  @_alwaysEmitIntoClient
  @_transparent
  internal static var _maxLFNum: UInt { 7 }
  
  /// The denominator of the maximum hash table load factor.
  @_alwaysEmitIntoClient
  @_transparent
  internal static var _maxLFDenom: UInt { 8 }
  
  /// The numerator of the minimum hash table load factor.
  @_alwaysEmitIntoClient
  @_transparent
  internal static var _minLFNum: UInt { 1 }
  
  /// The denominator of minimum hash table load factor.
  @_alwaysEmitIntoClient
  @_transparent
  internal static var _minLFDenom: UInt { 8 }
  
  /// The minimum number of items that can be held in a hash table of the given scale.
  @usableFromInline
  @_effects(readnone)
  internal static func minimumCapacity(forScale scale: UInt8) -> Int {
    guard scale >= minimumScale else { return 0 }
    precondition(scale <= maximumScale)
    let bucketCount: UInt = 1 &<< scale
    return Int(bucketCount * _minLFNum / _minLFDenom)
  }
  
  /// The maximum number of items that can be held in a hash table of the given scale.
  @usableFromInline
  @_effects(readnone)
  internal static func maximumCapacity(forScale scale: UInt8) -> Int {
    guard scale >= minimumScale else { return maximumUnhashedCount }
    let bucketCount: UInt = 1 &<< scale
    return Int(bucketCount * _maxLFNum / _maxLFDenom)
  }
  
  
  /// The minimum hash table scale that can hold the specified number of elements.
  @usableFromInline
  @_effects(readnone)
  internal static func minimumScale(forCapacity capacity: Int) -> UInt8 {
    guard capacity > maximumUnhashedCount else { return 0 }
    let capacity = UInt(truncatingIfNeeded: Swift.max(capacity, 1))
    // Calculate the minimum number of entries we need to allocate to satisfy
    // the maximum load factor. `capacity + 1` below ensures that we always
    // leave at least one hole.
    let minimumEntries = Swift.max(
      ((capacity + 1) * _maxLFDenom - 1) / _maxLFNum, // (capacity / maxLoadFactor).rounded(.up)
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
}
#endif
