//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@usableFromInline
@frozen
internal struct _Word {
  @usableFromInline
  internal var value: UInt

  @inlinable
  @inline(__always)
  internal init(_ value: UInt) {
    self.value = value
  }

  @inline(__always)
  internal init(upTo bit: UInt) {
    assert(bit <= _Word.capacity)
    self.init((1 << bit) &- 1)
  }

  @inline(__always)
  internal init(from start: UInt, to end: UInt) {
    assert(start <= end && end <= _Word.capacity)
    self = Self(upTo: end).symmetricDifference(Self(upTo: start))
  }
}

extension _Word: CustomStringConvertible {
  @usableFromInline
  internal var description: String {
    String(value, radix: 16)
  }
}

extension _Word {
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
    value._nthSetBit(&n)
  }
  
  @inline(never)
  internal func nthElementFromEnd(_ n: inout UInt) -> UInt? {
    guard let i = value._reversed._nthSetBit(&n) else { return nil }
    return UInt(UInt.bitWidth) &- 1 &- i
  }
}

extension _Word {
  @inline(__always)
  internal static func wordCount(forBitCount count: UInt) -> Int {
    return _BitPosition(count + UInt(_Word.capacity) - 1).word
  }
}
extension _Word {
  @inlinable
  @inline(__always)
  internal static var capacity: Int {
    return UInt.bitWidth
  }

  @inlinable
  @inline(__always)
  internal var count: Int {
    value.nonzeroBitCount
  }

  @inlinable
  @inline(__always)
  internal var isEmpty: Bool {
    value == 0
  }

  @inlinable
  @inline(__always)
  internal var isFull: Bool {
    value == UInt.max
  }

  @inlinable
  @inline(__always)
  internal func contains(_ bit: UInt) -> Bool {
    assert(bit >= 0 && bit < UInt.bitWidth)
    return value & (1 &<< bit) != 0
  }

  @inlinable
  @inline(__always)
  internal var firstMember: UInt {
    value._lastSetBit
  }

  @inlinable
  @inline(__always)
  internal var lastMember: UInt {
    value._firstSetBit
  }

  @inlinable
  @inline(__always)
  @discardableResult
  internal mutating func insert(_ bit: UInt) -> Bool {
    assert(bit < UInt.bitWidth)
    let mask: UInt = 1 &<< bit
    let inserted = value & mask == 0
    value |= mask
    return inserted
  }

  @inlinable
  @inline(__always)
  @discardableResult
  internal mutating func remove(_ bit: UInt) -> Bool {
    assert(bit < UInt.bitWidth)
    let mask: UInt = 1 &<< bit
    let removed = (value & mask) != 0
    value &= ~mask
    return removed
  }

  @inlinable
  @inline(__always)
  internal mutating func update(_ bit: UInt, to value: Bool) {
    assert(bit < UInt.bitWidth)
    let mask: UInt = 1 &<< bit
    if value {
      self.value |= mask
    } else {
      self.value &= ~mask
    }
  }
}

extension _Word {
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

extension _Word {
  @inlinable
  @inline(__always)
  internal static var empty: Self {
    Self(0)
  }

  @inline(__always)
  internal static var allBits: Self {
    Self(UInt.max)
  }
}

// Word implements Sequence by using a copy of itself as its Iterator.
// Iteration with `next()` destroys the word's value; however, this won't cause
// problems in normal use, because `next()` is usually called on a separate
// iterator, not the original word.
extension _Word: Sequence, IteratorProtocol {
  @inlinable
  internal var underestimatedCount: Int {
    count
  }

  /// Return the index of the lowest set bit in this word,
  /// and also destructively clear it.
  @inlinable
  internal mutating func next() -> UInt? {
    guard value != 0 else { return nil }
    let bit = UInt(truncatingIfNeeded: value.trailingZeroBitCount)
    value &= value &- 1       // Clear lowest nonzero bit.
    return bit
  }
}

extension _Word: Equatable {
  @inlinable
  internal static func ==(left: Self, right: Self) -> Bool {
    left.value == right.value
  }
}

extension _Word: Hashable {
  @inlinable
  internal func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
}

extension _Word {
  @inline(__always)
  internal func complement() -> Self {
    _Word(~self.value)
  }

  @inline(__always)
  internal mutating func formComplement() {
    self.value = ~self.value
  }

  @inline(__always)
  internal func union(_ other: Self) -> Self {
    _Word(self.value | other.value)
  }

  @inline(__always)
  internal mutating func formUnion(_ other: Self) {
    self.value |= other.value
  }

  @inline(__always)
  internal func intersection(_ other: Self) -> Self {
    _Word(self.value & other.value)
  }

  @inline(__always)
  internal mutating func formIntersection(_ other: Self) {
    self.value &= other.value
  }

  @inline(__always)
  internal func symmetricDifference(_ other: Self) -> Self {
    _Word(self.value ^ other.value)
  }

  @inline(__always)
  internal mutating func formSymmetricDifference(_ other: Self) {
    self.value ^= other.value
  }

  @inline(__always)
  internal func subtracting(_ other: Self) -> Self {
    _Word(self.value & ~other.value)
  }

  @inline(__always)
  internal mutating func subtract(_ other: Self) {
    self.value &= ~other.value
  }
}

extension _Word {
  @inline(__always)
  internal func shiftedDown(by shift: UInt) -> Self {
    assert(shift >= 0 && shift < Self.capacity)
    return _Word(self.value &>> shift)
  }

  @inline(__always)
  internal func shiftedUp(by shift: UInt) -> Self {
    assert(shift >= 0 && shift < Self.capacity)
    return _Word(self.value &<< shift)
  }
}

extension Array where Element == _Word {
  internal func _encodeAsUInt64(
    to container: inout UnkeyedEncodingContainer
  ) throws {
    if _Word.capacity == 64 {
      for word in self {
        try container.encode(UInt64(truncatingIfNeeded: word.value))
      }
      return
    }
    assert(_Word.capacity == 32, "Unsupported platform")
    var first = true
    var w: UInt64 = 0
    for word in self {
      if first {
        w = UInt64(truncatingIfNeeded: word.value)
        first = false
      } else {
        w |= UInt64(truncatingIfNeeded: word.value) &<< 32
        try container.encode(w)
        first = true
      }
    }
    if !first {
      try container.encode(w)
    }
  }

  internal init(
    _fromUInt64 container: inout UnkeyedDecodingContainer,
    reservingCount count: Int? = nil
  ) throws {
    self = []
    if _Word.capacity == 64 {
      if let c = count {
        self.reserveCapacity(c)
      }
      while !container.isAtEnd {
        let v = try container.decode(UInt64.self)
        self.append(_Word(UInt(truncatingIfNeeded: v)))
      }
      return
    }
    assert(_Word.capacity == 32, "Unsupported platform")
    if let c = count {
      self.reserveCapacity(2 * c)
    }
    while !container.isAtEnd {
      let v = try container.decode(UInt.self)
      self.append(_Word(UInt(truncatingIfNeeded: v)))
      self.append(_Word(UInt(truncatingIfNeeded: v &>> 32)))
    }
  }
}
