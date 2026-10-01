//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@usableFromInline
@frozen
@safe
package struct _HTable: ~Copyable {
  @usableFromInline
  package typealias Word = _UnsafeBitSet._Word

  @_alwaysEmitIntoClient
  @unsafe // FIXME: Only mutations are unsafe
  package var _count: Int

  @_alwaysEmitIntoClient
  @unsafe // FIXME: Only mutations are unsafe
  package var _capacity: Int

  @_alwaysEmitIntoClient
  @unsafe
  package let _bitmap: UnsafeMutablePointer<Word>?

  @_alwaysEmitIntoClient
  @safe
  package var _maxProbeLength: Int

  @_alwaysEmitIntoClient
  @safe
  package let scale: UInt8

  // FIXME: Add a reservedScale for UniqueSet/UniqueDictonary

  @inlinable
  @safe
  internal init(
    _capacity: Int,
    scale: UInt8
  ) {
    assert(
      _capacity >= Self.minimumCapacity(forScale: scale)
      && _capacity <= Self.maximumCapacity(forScale: scale))
    unsafe self._count = 0
    unsafe self._capacity = _capacity
    self._maxProbeLength = 0
    self.scale = scale
    if scale == 0 {
      unsafe self._bitmap = nil
    } else {
      assert(scale >= Self.minimumScale && scale <= Self.maximumScale)
      let wordCount = _HTable.wordCount(forScale: scale)
      let bitmap = UnsafeMutablePointer<Word>.allocate(capacity: wordCount)
      unsafe bitmap.initialize(repeating: .empty, count: wordCount)
      unsafe self._bitmap = bitmap
    }
  }

  @inlinable
  @safe
  internal init(capacity: Int) {
    assert(capacity >= 0)
    self.init(
      _capacity: capacity,
      scale: Self.minimumScale(forCapacity: capacity))
  }

  @inlinable
  @safe
  internal init(minimumCapacity: Int) {
    precondition(minimumCapacity >= 0, "Capacity must be nonnegative")
    let p = Self.dynamicStorageParameters(minimumCapacity: minimumCapacity)
    self.init(_capacity: p.capacity, scale: p.scale)
  }


  @_alwaysEmitIntoClient
  deinit {
    unsafe _bitmap?.deallocate()
  }
}

extension _HTable {
  @_alwaysEmitIntoClient
  @_transparent
  @safe
  package var isSmall: Bool {
    unsafe _bitmap == nil
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  package var count: Int {
    unsafe _assumeNonNegative(_count)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  package var capacity: Int {
    unsafe _assumeNonNegative(_capacity)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  package var isEmpty: Bool {
    count == 0
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  package var isFull: Bool {
    count == capacity
  }


  @_alwaysEmitIntoClient
  @_transparent
  @safe
  package var wordCount: Int {
    if isSmall { return 0 }
    return Word.wordCount(forBitCount: bucketCount)
  }
}

extension _HTable {
  @_alwaysEmitIntoClient
  @_transparent
  @safe
  package var startBucket: Bucket {
    Bucket(offset: 0)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  package var endBucket: Bucket {
    Bucket(offset: bucketCount)
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  package var storageCapacity: Int {
    if isSmall { return capacity }
    return 1 &<< scale
  }

  @_alwaysEmitIntoClient
  @_transparent
  @safe
  package var bucketCount: UInt {
    UInt(bitPattern: storageCapacity)
  }

  @_transparent
  @inlinable
  @safe
  package func isValid(_ bucket: Bucket) -> Bool {
    bucket._offset < bucketCount
  }

  @_transparent
  @inlinable
  @safe
  package func wrapBucket(after bucket: inout Bucket) {
    assert(isValid(bucket))
    bucket._offset &+= 1
    if bucket._offset == bucketCount {
      bucket._offset = 0
    }
  }

  @_transparent
  @inlinable
  @safe
  package func formBucket(after bucket: inout Bucket) {
    assert(isValid(bucket))
    bucket._offset &+= 1
  }

  @inlinable
  @safe
  package var bitmap: Bitmap {
    @_lifetime(borrow self)
    get {
      Bitmap(table: self)
    }
  }

  @_transparent
  @inlinable
  @safe
  package func isOccupied(_ bucket: Bucket) -> Bool {
    if isSmall { return bucket._offset < count }
    return bitmap.isOccupied(bucket)
  }
}

extension _HTable {
  @_transparent
  @safe
  internal func idealBucket(forHashValue hashValue: Int) -> Bucket {
    let hashValue = UInt(truncatingIfNeeded: hashValue)
    return Bucket(offset: hashValue & (bucketCount &- 1))
  }

  @_transparent
  @safe
  internal func probeLength(
    from start: Bucket,
    to end: Bucket
  ) -> Int {
    if start.offset <= end.offset {
      return Int(end._offset &- start._offset &+ 1)
    }
    return Int(bucketCount &- start._offset &+ end._offset &+ 1)
  }

  @_transparent
  @safe
  internal func probeLength(
    forHashValue hashValue: Int,
    in bucket: Bucket
  ) -> Int {
    let ideal = idealBucket(forHashValue: hashValue)
    return probeLength(from: ideal, to: bucket)
  }
}

extension _HTable {
  @usableFromInline
  @safe
  package mutating func clear() {
    unsafe self._count = 0
    self.bitmap.clearAll()
    self._maxProbeLength = 0
  }
}

extension _HTable {
  @usableFromInline
  @safe
  package func isTriviallyIdentical(to other: borrowing Self) -> Bool {
    unsafe self._count == other._count
    && self._capacity == other._capacity
    && self._bitmap == other._bitmap
    && self._maxProbeLength == other._maxProbeLength
    && self.scale == other.scale
  }
}
