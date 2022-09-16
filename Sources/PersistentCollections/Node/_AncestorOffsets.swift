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

/// A collection of slot values logically addressing a particular node in a
/// hash tree. The collection is (logically) extended with zero slots up to
/// the maximum depth of the tree -- to unambiguously address a single node,
/// this therefore needs to be augmented with a `_Level` value.
///
/// This construct can only be used to identify a particular node in the tree;
/// it does not necessarily have room to include an item offset in the addressed
/// node. (See `_Path` if you need to address a particular item.)
@usableFromInline
@frozen
struct _AncestorSlots {
  @usableFromInline
  internal var path: UInt

  @inlinable @inline(__always)
  internal init(_ path: UInt) {
    self.path = path
  }
}

extension _AncestorSlots: Equatable {
  @inlinable @inline(__always)
  internal static func ==(left: Self, right: Self) -> Bool {
    left.path == right.path
  }
}

extension _AncestorSlots {
  @inlinable @inline(__always)
  internal static var empty: Self { Self(0) }
}

extension _AncestorSlots {
  /// Return or set the slot value at the specified level.
  /// If this is used to mutate the collection, then the original value
  /// on the given level must be zero.
  @inlinable @inline(__always)
  internal subscript(_ level: _Level) -> _Slot {
    get {
      assert(level.shift < UInt.bitWidth)
      return _Slot((path &>> level.shift) & _Bucket.bitMask)
    }
    set {
      assert(newValue._value < UInt.bitWidth)
      assert(self[level] == .zero)
      path |= (UInt(truncatingIfNeeded: newValue._value) &<< level.shift)
    }
  }

  /// Clear the slot at the specified level, by setting it to zero.
  @inlinable
  internal mutating func clear(_ level: _Level) {
    guard level.shift < UInt.bitWidth else { return }
    path &= ~(_Bucket.bitMask &<< level.shift)
  }

  /// Truncate this path to the specified level.
  /// Slots at or beyond the specified level are cleared.
  @inlinable
  internal func truncating(to level: _Level) -> _AncestorSlots {
    assert(level.shift <= UInt.bitWidth)
    guard level.shift < UInt.bitWidth else { return self }
    return _AncestorSlots(path & ((1 &<< level.shift) &- 1))
  }

  /// Returns true if this path contains non-zero slots at or beyond the
  /// specified level, otherwise returns false.
  @inlinable
  internal func hasDataBelow(_ level: _Level) -> Bool {
    guard level.shift < UInt.bitWidth else { return false }
    return (path &>> level.shift) != 0
  }

  /// Compares this path to `other` up to but not including the specified level.
  /// Returns true if the path prefixes compare equal, otherwise returns false.
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

