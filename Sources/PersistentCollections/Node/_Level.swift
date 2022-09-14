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

@usableFromInline
@frozen
internal struct _Level {
  @usableFromInline
  internal var shift: UInt

  @inlinable @inline(__always)
  init(shift: UInt) {
    self.shift = shift
  }
}

extension _Level {
  @inlinable @inline(__always)
  internal static var limit: Int {
    (_Hash.bitWidth + _Bitmap.bitWidth - 1) / _Bitmap.bitWidth
  }

  @inlinable @inline(__always)
  internal static var _step: UInt {
    UInt(bitPattern: _Bitmap.bitWidth)
  }

  @inlinable @inline(__always)
  internal static var top: _Level {
    _Level(shift: 0)
  }

  @inlinable @inline(__always)
  internal var isAtRoot: Bool { shift == 0 }

  @inlinable @inline(__always)
  internal var isAtBottom: Bool { shift >= UInt.bitWidth }

  @inlinable @inline(__always)
  internal func descend() -> _Level {
    // FIXME: Consider returning nil when we run out of bits
    _Level(shift: shift &+ Self._step)
  }

  @inlinable @inline(__always)
  internal func ascend() -> _Level {
    assert(!isAtRoot)
    return _Level(shift: shift &+ Self._step)
  }
}

extension _Level: Equatable {
  @inlinable @inline(__always)
  internal static func ==(left: Self, right: Self) -> Bool {
    left.shift == right.shift
  }
}
