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

extension UInt {
  @inlinable @inline(__always)
  internal var _nonzeroBitCount: UInt {
    Self(truncatingIfNeeded: nonzeroBitCount)
  }

  internal var _reversed: UInt {
    // https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
    var shift: UInt = UInt(UInt.bitWidth)
    var mask: UInt = ~0;
    var result = self
    while true {
      shift &>>= 1
      guard shift > 0 else { break }
      mask ^= mask &<< shift
      result = ((result &>> shift) & mask) | ((result &<< shift) & ~mask)
    }
    return result
  }

  @inlinable @inline(__always)
  internal var _lastSetBit: UInt {
    UInt(truncatingIfNeeded: self.trailingZeroBitCount)
  }

  @inlinable @inline(__always)
  internal var _firstSetBit: UInt {
    UInt(truncatingIfNeeded: UInt.bitWidth &- 1 &- self.leadingZeroBitCount)
  }

  /// Returns the position of the `n`th set bit in `self`.
  ///
  /// - Parameter n: The  to retrieve. This value is
  ///    decremented by the number of items found in this `self` towards the
  ///    value we're looking for. (If the function returns non-nil, then `n`
  ///    is set to `0` on return.)
  /// - Returns: If this integer contains enough set bits to satisfy the
  ///    request, then this function returns the position of the bit found.
  ///    Otherwise it returns nil.
  internal func _nthSetBit(_ n: inout UInt) -> UInt? {
    // FIXME: Use bit deposit instruction when available (PDEP on Intel).
    assert(UInt.bitWidth == 64 || UInt.bitWidth == 32, "Unsupported UInt bitWidth")

    var shift: UInt = 0

    let c = self._nonzeroBitCount
    guard n < c else {
      n &-= c
      return nil
    }

    if UInt.bitWidth == 64 {
      let c32 = (self & 0xFFFFFFFF)._nonzeroBitCount
      if n >= c32 {
        shift &+= 32
        n &-= c32
      }
    }
    let c16 = ((self &>> shift) & 0xFFFF)._nonzeroBitCount
    if n >= c16 {
      shift &+= 16
      n &-= c16
    }
    let c8 = ((self &>> shift) & 0xFF)._nonzeroBitCount
    if n >= c8 {
      shift &+= 8
      n &-= c8
    }
    let c4 = ((self &>> shift) & 0xF)._nonzeroBitCount
    if n >= c4 {
      shift &+= 4
      n &-= c4
    }
    let c2 = ((self &>> shift) & 0x3)._nonzeroBitCount
    if n >= c2 {
      shift &+= 2
      n &-= c2
    }
    let c1 = (self &>> shift) & 0x1
    if n >= c1 {
      shift &+= 1
      n &-= c1
    }
    precondition(n == 0 && (self &>> shift) & 0x1 == 1)
    return shift
  }
}

