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

/// An abstract representation of a hash value.
@usableFromInline
@frozen
internal struct _HashValue {
  @usableFromInline
  internal var value: UInt

  @inlinable
  internal init<Key: Hashable>(_ key: Key) {
    let hashValue = key._rawHashValue(seed: 0)
    self.value = UInt(bitPattern: hashValue)
  }
}

extension _HashValue: Equatable {
  @inlinable @inline(__always)
  internal static func ==(left: Self, right: Self) -> Bool {
    left.value == right.value
  }
}

extension _HashValue {
  @inlinable
  internal subscript(_ level: _Level) -> _Bucket {
    assert(!level.isAtBottom)
    return _Bucket((value &>> level.shift) & _Bucket.bitMask)
  }
}

@usableFromInline
@frozen
internal struct _Level {
  @usableFromInline
  internal var shift: UInt

  @inlinable
  init(shift: UInt) {
    self.shift = shift
  }
}

extension _Level {
  @inlinable
  internal static var top: _Level {
    _Level(shift: 0)
  }

  @inlinable
  internal var isAtRoot: Bool { shift == 0 }

  @inlinable
  internal var isAtBottom: Bool { shift >= UInt.bitWidth }

  @inlinable
  internal func descend() -> _Level {
    // FIXME: Consider returning nil when we run out of bits
    _Level(shift: shift &+ UInt(bitPattern: _Bucket.bitWidth))
  }

  @inlinable
  internal func ascend() -> _Level {
    assert(!isAtRoot)
    return _Level(shift: shift &+ UInt(bitPattern: _Bucket.bitWidth))
  }
}

extension _Level: Equatable {
  @inlinable
  internal static func ==(left: Self, right: Self) -> Bool {
    left.shift == right.shift
  }
}
