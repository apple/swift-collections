//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

extension _HashTable {
  /// The minimum hash table scale.
  @usableFromInline
  @inline(__always)
  internal static var minimumScale: Int {
    @_effects(readnone)
    get {
      5
    }
  }

  /// The maximum hash table scale.
  @usableFromInline
  @inline(__always)
  internal static var maximumScale: Int {
    @_effects(readnone)
    get {
      Swift.min(Int.bitWidth, 56)
    }
  }

  /// The maximum number of items for which we do not create a hash table.
  @usableFromInline
  @inline(__always)
  internal static var maximumUnhashedCount: Int {
    @_effects(readnone)
    get {
      (1 &<< (minimumScale - 1)) - 1
    }
  }

  /// The maximum hash table load factor. This is a rational number
  /// represented by a (numerator, denominator) tuple.
  @_transparent
  internal static var maximumLoadFactor: (Int, Int) { (3, 4) }

  /// The minimum hash table load factor. This is a rational number
  /// represented by a (numerator, denominator) tuple.
  @_transparent
  internal static var minimumLoadFactor: (Int, Int) { (1, 4) }

  /// The minimum number of items that can be held in a hash table of the given scale.
  @usableFromInline
  @_effects(readnone)
  internal static func minimumCapacity(forScale scale: Int) -> Int {
    guard scale >= minimumScale else { return 0 }
    let bucketCount = 1 &<< scale
    return (bucketCount * minimumLoadFactor.0) / minimumLoadFactor.1
  }

  /// The maximum number of items that can be held in a hash table of the given scale.
  @usableFromInline
  @_effects(readnone)
  internal static func maximumCapacity(forScale scale: Int) -> Int {
    guard scale >= minimumScale else { return maximumUnhashedCount }
    let bucketCount = 1 &<< scale
    return (bucketCount * maximumLoadFactor.0) / maximumLoadFactor.1
  }

  /// The minimum hash table scale that can hold the specified number of elements.
  @usableFromInline
  @_effects(readnone)
  internal static func scale(forCapacity capacity: Int) -> Int {
    guard capacity > maximumUnhashedCount else { return 0 }
    let capacity = Swift.max(capacity, 1)
    // Calculate the minimum number of entries we need to allocate to satisfy
    // the maximum load factor. `capacity + 1` below ensures that we always
    // leave at least one hole.
    let minimumEntries = Swift.max(
        (capacity * maximumLoadFactor.1 + maximumLoadFactor.0 - 1) / maximumLoadFactor.0,
        capacity + 1)
    // The actual number of entries we need to allocate is the lowest power of
    // two greater than or equal to the minimum entry count. Calculate its
    // exponent.
    let scale = (Swift.max(minimumEntries, 2) - 1)._binaryLogarithm() + 1
    assert(scale >= minimumScale && scale < Int.bitWidth)
    // The scale is the exponent corresponding to the bucket count.
    assert(self.maximumCapacity(forScale: scale) >= capacity)
    return scale
  }

  /// The count of 64-bit words that a hash table of the specified scale
  /// will need to have in its storage.
  internal static func wordCount(forScale scale: Int) -> Int {
    ((scale &<< scale) + 63) / 64
  }
}
