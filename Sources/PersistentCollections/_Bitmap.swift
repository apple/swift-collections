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

/// A set of `_Bucket` values, represented by a 32-bit wide bitset.
@usableFromInline
@frozen
internal struct _Bitmap {
  @usableFromInline
  internal typealias Value = UInt32

  @usableFromInline
  internal var _value: Value

  @inlinable @inline(__always)
  init(_value: Value) {
    self._value = _value
  }

  @inlinable @inline(__always)
  init(bitPattern: Int) {
    self._value = Value(bitPattern)
  }

  @inline(__always)
  internal init() {
    _value = 0
  }

  @inlinable @inline(__always)
  internal init(_ bucket: _Bucket) {
    assert(bucket.value < Self.capacity)
    _value = (1 &<< bucket.value)
  }

  @inlinable @inline(__always)
  internal init(_ bucket1: _Bucket, _ bucket2: _Bucket) {
    assert(bucket1.value < Self.capacity && bucket2.value < Self.capacity)
    assert(bucket1 != bucket2)
    _value = (1 &<< bucket1.value) | (1 &<< bucket2.value)
  }

  @inlinable
  internal init(upTo bucket: _Bucket) {
    assert(bucket.value < Self.capacity)
    _value = (1 &<< bucket.value) &- 1
  }
}

extension _Bitmap: Equatable {
  @inlinable @inline(__always)
  internal static func ==(left: Self, right: Self) -> Bool {
    left._value == right._value
  }
}

extension _Bitmap {
  internal static var empty: Self { .init() }
  @inlinable @inline(__always)

  @inlinable @inline(__always)
  internal static var capacity: Int { Value.bitWidth }

  @inlinable @inline(__always)
  internal var count: Int { _value.nonzeroBitCount }

  @inlinable @inline(__always)
  internal var capacity: Int { Value.bitWidth }

  @inlinable @inline(__always)
  internal var isEmpty: Bool { _value == 0 }
}

extension _Bitmap {
  @inlinable @inline(__always)
  internal func contains(_ bucket: _Bucket) -> Bool {
    assert(bucket.value < capacity)
    return _value & (1 &<< bucket.value) != 0
  }

  @inlinable @inline(__always)
  internal mutating func insert(_ bucket: _Bucket) {
    assert(bucket.value < capacity)
    _value |= (1 &<< bucket.value)
  }

  @inlinable @inline(__always)
  internal mutating func remove(_ bucket: _Bucket) {
    assert(bucket.value < capacity)
    _value &= ~(1 &<< bucket.value)
  }

  @inlinable @inline(__always)
  internal func offset(of bucket: _Bucket) -> Int {
    _value._rank(ofBit: bucket.value)
  }

  @inlinable @inline(__always)
  internal func bucket(at offset: Int) -> _Bucket {
    _Bucket(_value._bit(ranked: offset)!)
  }
}

extension _Bitmap {
  @inlinable @inline(__always)
  internal func isDisjoint(with other: Self) -> Bool {
    _value & other._value != 0
  }

  @inlinable @inline(__always)
  internal func union(_ other: Self) -> Self {
    Self(_value: _value | other._value)
  }

  @inlinable @inline(__always)
  internal func intersection(_ other: Self) -> Self {
    Self(_value: _value & other._value)
  }

  @inlinable @inline(__always)
  internal func symmetricDifference(_ other: Self) -> Self {
    Self(_value: _value & other._value)
  }

  @inlinable @inline(__always)
  internal func subtracting(_ other: Self) -> Self {
    Self(_value: _value & ~other._value)
  }
}

extension _Bitmap: Sequence, IteratorProtocol {
  @usableFromInline
  internal typealias Element = _Bucket

  @inlinable
  internal var underestimatedCount: Int { count }

  @inlinable
  internal func makeIterator() -> _Bitmap { self }

  /// Return the index of the lowest set bit in this word,
  /// and also destructively clear it.
  @inlinable
  internal mutating func next() -> _Bucket? {
    guard _value != 0 else { return nil }
    let bucket = _Bucket(UInt(bitPattern: _value.trailingZeroBitCount))
    _value &= _value &- 1 // Clear lowest nonzero bit.
    return bucket
  }
}
