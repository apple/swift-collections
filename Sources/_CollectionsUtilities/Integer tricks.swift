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

extension FixedWidthInteger {
  /// Round up `self` to the nearest power of two, assuming it's representable.
  /// Returns 0 if `self` isn't positive.
  @inlinable
  public func _roundUpToPowerOfTwo() -> Self {
    guard self > 0 else { return 0 }
    let l = Self.bitWidth - (self &- 1).leadingZeroBitCount
    return 1 << l
  }
}

extension UInt32 {
  @inlinable @inline(__always)
  internal var _nonzeroBitCount: Self {
    Self(truncatingIfNeeded: nonzeroBitCount)
  }

  @inlinable @inline(__always)
  public func _rank(ofBit bit: UInt) -> Int {
    assert(bit < Self.bitWidth)
    let mask: Self = (1 &<< bit) &- 1
    return (self & mask).nonzeroBitCount
  }

  // Returns the position of the `n`th set bit in `self`, i.e., the bit with
  // rank `n`.
  @_effects(releasenone)
  public func _bit(ranked n: Int) -> UInt? {
    assert(n >= 0 && n < Self.bitWidth)
    var shift: Self = 0
    var n: Self = UInt32(truncatingIfNeeded: n)
    let c16 = (self & 0xFFFF)._nonzeroBitCount
    if n >= c16 {
      shift = 16
      n -= c16
    }
    let c8 = ((self &>> shift) & 0xFF)._nonzeroBitCount
    if n >= c8 {
      shift &+= 8
      n -= c8
    }
    let c4 = ((self &>> shift) & 0xF)._nonzeroBitCount
    if n >= c4 {
      shift &+= 4
      n -= c4
    }
    let c2 = ((self &>> shift) & 0x3)._nonzeroBitCount
    if n >= c2 {
      shift &+= 2
      n -= c2
    }
    let c1 = (self &>> shift) & 0x1
    if n >= c1 {
      shift &+= 1
      n -= c1
    }
    guard n == 0, (self &>> shift) & 0x1 == 1 else { return nil }
    return UInt(truncatingIfNeeded: shift)
  }
}

extension UInt16 {
  @inlinable @inline(__always)
  internal var _nonzeroBitCount: Self {
    Self(truncatingIfNeeded: nonzeroBitCount)
  }

  @inlinable @inline(__always)
  public func _rank(ofBit bit: UInt) -> Int {
    assert(bit < Self.bitWidth)
    let mask: Self = (1 &<< bit) &- 1
    return (self & mask).nonzeroBitCount
  }

  // Returns the position of the `n`th set bit in `self`, i.e., the bit with
  // rank `n`.
  @_effects(releasenone)
  public func _bit(ranked n: Int) -> UInt? {
    assert(n >= 0 && n < Self.bitWidth)
    var shift: Self = 0
    var n: Self = UInt16(truncatingIfNeeded: n)
    let c8 = ((self &>> shift) & 0xFF)._nonzeroBitCount
    if n >= c8 {
      shift &+= 8
      n -= c8
    }
    let c4 = ((self &>> shift) & 0xF)._nonzeroBitCount
    if n >= c4 {
      shift &+= 4
      n -= c4
    }
    let c2 = ((self &>> shift) & 0x3)._nonzeroBitCount
    if n >= c2 {
      shift &+= 2
      n -= c2
    }
    let c1 = (self &>> shift) & 0x1
    if n >= c1 {
      shift &+= 1
      n -= c1
    }
    guard n == 0, (self &>> shift) & 0x1 == 1 else { return nil }
    return UInt(truncatingIfNeeded: shift)
  }
}
