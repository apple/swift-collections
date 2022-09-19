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

/// Identifies a particular level within the hash tree.
///
/// Hash trees have a maximum depth of ⎡`UInt.bitWidth / _Bucket.bitWidth`⎤, so
/// the level always fits in an `UInt8` value.
@usableFromInline
@frozen
internal struct _Level {
  /// The bit position within a hash value that begins the hash slice that is
  /// associated with this level. For collision nodes, this can be larger than
  /// `UInt.bitWidth`.
  @usableFromInline
  internal var _shift: UInt8

  @inlinable @inline(__always)
  init(_shift: UInt8) {
    self._shift = _shift
  }

  @inlinable @inline(__always)
  init(shift: UInt) {
    assert(shift <= UInt8.max)
    self._shift = UInt8(truncatingIfNeeded: shift)
  }
}

extension _Level {
  @inlinable @inline(__always)
  internal static var limit: Int {
    (_Hash.bitWidth + _Bitmap.bitWidth - 1) / _Bitmap.bitWidth
  }

  @inlinable @inline(__always)
  internal static var _step: UInt8 {
    UInt8(truncatingIfNeeded: _Bitmap.bitWidth)
  }

  @inlinable @inline(__always)
  internal static var top: _Level {
    _Level(shift: 0)
  }

  /// The bit position within a hash value that begins the hash slice that is
  /// associated with this level. For collision nodes, this can be larger than
  /// `UInt.bitWidth`.
  @inlinable @inline(__always)
  internal var shift: UInt { UInt(truncatingIfNeeded: _shift) }

  @inlinable @inline(__always)
  internal var isAtRoot: Bool { _shift == 0 }

  @inlinable @inline(__always)
  internal var isAtBottom: Bool { _shift >= UInt.bitWidth }

  @inlinable @inline(__always)
  internal func descend() -> _Level {
    // FIXME: Consider returning nil when we run out of bits
    _Level(_shift: _shift &+ Self._step)
  }

  @inlinable @inline(__always)
  internal func ascend() -> _Level {
    assert(!isAtRoot)
    return _Level(_shift: _shift &- Self._step)
  }
}

extension _Level: Equatable {
  @inlinable @inline(__always)
  internal static func ==(left: Self, right: Self) -> Bool {
    left._shift == right._shift
  }
}

extension _Level: Comparable {
  @inlinable @inline(__always)
  internal static func <(left: Self, right: Self) -> Bool {
    left._shift < right._shift
  }
}
