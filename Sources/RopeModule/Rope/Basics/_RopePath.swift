//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct _RopePath<Summary: _RopeSummary> {
  // ┌──────────────────────────────────┬────────┐
  // │ b63:b8                           │ b7:b0  │
  // ├──────────────────────────────────┼────────┤
  // │ path                             │ height │
  // └──────────────────────────────────┴────────┘
  var _value: UInt64

  @inline(__always)
  static var _pathBitWidth: Int { 56 }

  init(_value: UInt64) {
    self._value = _value
  }

  init(height: UInt8) {
    self._value = UInt64(truncatingIfNeeded: height)
    assert((Int(height) + 1) * Summary.nodeSizeBitWidth <= Self._pathBitWidth)
  }
}

extension _Rope {
  typealias Path = _RopePath<Summary>
}

extension _RopePath: Equatable {
  static func ==(left: Self, right: Self) -> Bool {
    left._value == right._value
  }
}
extension _RopePath: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(_value)
  }
}

extension _RopePath: Comparable {
  static func <(left: Self, right: Self) -> Bool {
    left._value < right._value
  }
}

extension _RopePath: CustomStringConvertible {
  var description: String {
    var r = "<"
    for h in stride(from: height, through: 0, by: -1) {
      r += "\(self[h])"
      if h > 0 { r += ", " }
    }
    r += ">"
    return r
  }
}

extension _RopePath {
  var height: UInt8 {
    UInt8(truncatingIfNeeded: _value)
  }

  subscript(height: UInt8) -> Int {
    get {
      assert(height <= self.height)
      let shift = 8 + Int(height) * Summary.nodeSizeBitWidth
      let mask: UInt64 = (1 &<< Summary.nodeSizeBitWidth) &- 1
      return numericCast((_value &>> shift) & mask)
    }
    set {
      assert(height <= self.height)
      assert(newValue >= 0 && newValue <= Summary.maxNodeSize)
      let shift = 8 + Int(height) * Summary.nodeSizeBitWidth
      let mask: UInt64 = (1 &<< Summary.nodeSizeBitWidth) &- 1
      _value &= ~(mask &<< shift)
      _value |= numericCast(newValue) &<< shift
    }
  }

  func isEmpty(below height: UInt8) -> Bool {
    let shift = Int(height) * Summary.nodeSizeBitWidth
    assert(shift + Summary.nodeSizeBitWidth <= Self._pathBitWidth)
    let mask: UInt64 = ((1 &<< shift) - 1) &<< 8
    return (_value & mask) == 0
  }

  mutating func clear(below height: UInt8) {
    let shift = Int(height) * Summary.nodeSizeBitWidth
    assert(shift + Summary.nodeSizeBitWidth <= Self._pathBitWidth)
    let mask: UInt64 = ((1 &<< shift) - 1) &<< 8
    _value &= ~mask
  }
}

