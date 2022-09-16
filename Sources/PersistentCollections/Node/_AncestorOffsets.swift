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
struct _AncestorOffsets {
  @usableFromInline
  internal var path: UInt

  @inlinable @inline(__always)
  internal init(_ path: UInt) {
    self.path = path
  }
}

extension _AncestorOffsets: Equatable {
  @inlinable @inline(__always)
  internal static func ==(left: Self, right: Self) -> Bool {
    left.path == right.path
  }
}

extension _AncestorOffsets {
  @inlinable @inline(__always)
  internal static var empty: Self { Self(0) }
}

extension _AncestorOffsets {
  @inlinable @inline(__always)
  internal subscript(_ level: _Level) -> Int {
    get {
      assert(level.shift < UInt.bitWidth)
      return Int(bitPattern: (path &>> level.shift) & _Bucket.bitMask)
    }
    set {
      assert(newValue < UInt.bitWidth)
      assert(self[level] == 0)
      path |= (UInt(bitPattern: newValue) &<< level.shift)
    }
  }

  @inlinable
  internal func truncating(to level: _Level) -> _AncestorOffsets {
    assert(level.shift <= UInt.bitWidth)
    guard level.shift < UInt.bitWidth else { return self }
    return _AncestorOffsets(path & ((1 &<< level.shift) &- 1))
  }

  @inlinable
  internal mutating func clear(_ level: _Level) {
    guard level.shift < UInt.bitWidth else { return }
    path &= ~(_Bucket.bitMask &<< level.shift)
  }

  @inlinable
  internal func hasDataBelow(_ level: _Level) -> Bool {
    guard level.shift < UInt.bitWidth else { return false }
    return (path &>> level.shift) != 0
  }

  @inlinable
  internal func isEqual(to other: Self, upTo level: _Level) -> Bool {
    if level.isAtRoot { return true }
    if level.isAtBottom { return self == other }
    let s = UInt(UInt.bitWidth) - level.shift
    let v1 = self.path &<< s
    let v2 = other.path &<< s
    return v1 == v2
  }
}

