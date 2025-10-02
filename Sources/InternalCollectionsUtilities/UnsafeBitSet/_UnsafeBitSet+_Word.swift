//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension _UnsafeBitSet {
  @frozen
  @usableFromInline
  package struct _Word {
    @usableFromInline
    package var value: UInt

    @inlinable
    @inline(__always)
    package init(_ value: UInt) {
      self.value = value
    }

    @inlinable
    @inline(__always)
    package init(upTo bit: UInt) {
      assert(bit <= _Word.capacity)
      self.init((1 << bit) &- 1)
    }

    @inlinable
    @inline(__always)
    package init(from start: UInt, to end: UInt) {
      assert(start <= end && end <= _Word.capacity)
      self = Self(upTo: end).symmetricDifference(Self(upTo: start))
    }
  }
}

extension _UnsafeBitSet._Word: CustomStringConvertible {
  @usableFromInline
  package var description: String {
    String(value, radix: 16)
  }
}

extension _UnsafeBitSet._Word {
  /// Returns the `n`th member in `self`.
  ///
  /// - Parameter n: The offset of the element to retrieve. This value is
  ///    decremented by the number of items found in this `self` towards the
  ///    value we're looking for. (If the function returns non-nil, then `n`
  ///    is set to `0` on return.)
  /// - Returns: If this word contains enough members to satisfy the request,
  ///    then this function returns the member found. Otherwise it returns nil.
  @inline(never)
  internal func nthElement(_ n: inout UInt) -> UInt? {
    let c = UInt(bitPattern: count)
    guard n < c else {
      n &-= c
      return nil
    }
    let m = Int(bitPattern: n)
    n = 0
    return value._bit(ranked: m)!
  }
  
  @inline(never)
  internal func nthElementFromEnd(_ n: inout UInt) -> UInt? {
    let c = UInt(bitPattern: count)
    guard n < c else {
      n &-= c
      return nil
    }
    let m = Int(bitPattern: c &- 1 &- n)
    n = 0
    return value._bit(ranked: m)!
  }
}

extension _UnsafeBitSet._Word {
  @inlinable
  @inline(__always)
  package static func wordCount(forBitCount count: UInt) -> Int {
    // Note: We perform on UInts to get faster unsigned math (shifts).
    let width = UInt(bitPattern: Self.capacity)
    return Int(bitPattern: (count + width - 1) / width)
  }
}

extension _UnsafeBitSet._Word {
  @inlinable
  @inline(__always)
  package static var capacity: Int {
    return UInt.bitWidth
  }

  @inlinable
  @inline(__always)
  package var count: Int {
    value.nonzeroBitCount
  }

  @inlinable
  @inline(__always)
  package var isEmpty: Bool {
    value == 0
  }

  @inlinable
  @inline(__always)
  package var isFull: Bool {
    value == UInt.max
  }

  @inlinable
  @inline(__always)
  package func contains(_ bit: UInt) -> Bool {
    assert(bit >= 0 && bit < UInt.bitWidth)
    return value & (1 &<< bit) != 0
  }

  @inlinable
  @inline(__always)
  package var firstMember: UInt? {
    value._lastSetBit
  }

  @inlinable
  @inline(__always)
  package var lastMember: UInt? {
    value._firstSetBit
  }

  @inlinable
  @inline(__always)
  @discardableResult
  package mutating func insert(_ bit: UInt) -> Bool {
    assert(bit < UInt.bitWidth)
    let mask: UInt = 1 &<< bit
    let inserted = value & mask == 0
    value |= mask
    return inserted
  }

  @inlinable
  @inline(__always)
  @discardableResult
  package mutating func remove(_ bit: UInt) -> Bool {
    assert(bit < UInt.bitWidth)
    let mask: UInt = 1 &<< bit
    let removed = (value & mask) != 0
    value &= ~mask
    return removed
  }

  @inlinable
  @inline(__always)
  package mutating func update(_ bit: UInt, to value: Bool) {
    assert(bit < UInt.bitWidth)
    let mask: UInt = 1 &<< bit
    if value {
      self.value |= mask
    } else {
      self.value &= ~mask
    }
  }
}

extension _UnsafeBitSet._Word {
  @inlinable
  @inline(__always)
  internal mutating func insertAll(upTo bit: UInt) {
    assert(bit >= 0 && bit < Self.capacity)
    let mask: UInt = (1 as UInt &<< bit) &- 1
    value |= mask
  }

  @inlinable
  @inline(__always)
  internal mutating func removeAll(upTo bit: UInt) {
    assert(bit >= 0 && bit < Self.capacity)
    let mask = UInt.max &<< bit
    value &= mask
  }

  @inlinable
  @inline(__always)
  internal mutating func removeAll(through bit: UInt) {
    assert(bit >= 0 && bit < Self.capacity)
    var mask = UInt.max &<< bit
    mask &= mask &- 1       // Clear lowest nonzero bit.
    value &= mask
  }

  @inlinable
  @inline(__always)
  internal mutating func removeAll(from bit: UInt) {
    assert(bit >= 0 && bit < Self.capacity)
    let mask: UInt = (1 as UInt &<< bit) &- 1
    value &= mask
  }
}

extension _UnsafeBitSet._Word {
  @inlinable
  @inline(__always)
  package static var empty: Self {
    Self(0)
  }

  @inline(__always)
  package static var allBits: Self {
    Self(UInt.max)
  }
}

// _Word implements Sequence by using a copy of itself as its Iterator.
// Iteration with `next()` destroys the word's value; however, this won't cause
// problems in normal use, because `next()` is usually called on a separate
// iterator, not the original word.
extension _UnsafeBitSet._Word: Sequence, IteratorProtocol {
  @inlinable @inline(__always)
  package var underestimatedCount: Int {
    count
  }

  /// Return the index of the lowest set bit in this word,
  /// and also destructively clear it.
  @inlinable
  package mutating func next() -> UInt? {
    guard value != 0 else { return nil }
    let bit = UInt(truncatingIfNeeded: value.trailingZeroBitCount)
    value &= value &- 1       // Clear lowest nonzero bit.
    return bit
  }
}

extension _UnsafeBitSet._Word: Equatable {
  @inlinable
  package static func ==(left: Self, right: Self) -> Bool {
    left.value == right.value
  }
}

extension _UnsafeBitSet._Word: Hashable {
  @inlinable
  package func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
}

extension _UnsafeBitSet._Word {
  @inlinable @inline(__always)
  package func complement() -> Self {
    Self(~self.value)
  }

  @inlinable @inline(__always)
  package mutating func formComplement() {
    self.value = ~self.value
  }

  @inlinable @inline(__always)
  package func union(_ other: Self) -> Self {
    Self(self.value | other.value)
  }

  @inlinable @inline(__always)
  package mutating func formUnion(_ other: Self) {
    self.value |= other.value
  }

  @inlinable @inline(__always)
  package func intersection(_ other: Self) -> Self {
    Self(self.value & other.value)
  }

  @inlinable @inline(__always)
  package mutating func formIntersection(_ other: Self) {
    self.value &= other.value
  }

  @inlinable @inline(__always)
  package func symmetricDifference(_ other: Self) -> Self {
    Self(self.value ^ other.value)
  }

  @inlinable @inline(__always)
  package mutating func formSymmetricDifference(_ other: Self) {
    self.value ^= other.value
  }

  @inlinable @inline(__always)
  package func subtracting(_ other: Self) -> Self {
    Self(self.value & ~other.value)
  }

  @inlinable @inline(__always)
  package mutating func subtract(_ other: Self) {
    self.value &= ~other.value
  }
}

extension _UnsafeBitSet._Word {
  @inlinable
  @inline(__always)
  package func shiftedDown(by shift: UInt) -> Self {
    assert(shift >= 0 && shift < Self.capacity)
    return Self(self.value &>> shift)
  }

  @inlinable
  @inline(__always)
  package func shiftedUp(by shift: UInt) -> Self {
    assert(shift >= 0 && shift < Self.capacity)
    return Self(self.value &<< shift)
  }
}
