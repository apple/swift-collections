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

extension _BitSet {
  @usableFromInline
  internal mutating func subtract(_ other: Self) {
    _updateThenShrink { target, shrink in
      other._read { source in
        target.combineSharedPrefix(
          with: source,
          using: { $0.subtract($1) }
        )
      }
    }
  }

  @usableFromInline
  internal mutating func subtract(_ next: () -> UInt?) {
    _updateThenShrink { handle, shrink in
      while let value = next() {
        handle.remove(value)
      }
    }
  }

  @usableFromInline
  internal mutating func subtract(_ other: Range<UInt>) {
    guard !other.isEmpty else { return }
    _updateThenShrink { handle, shrink in
      handle.subtract(other)
    }
  }
}

extension BitSet {
  @inlinable
  public mutating func subtract(_ other: Self) {
    _core.subtract(other._core)
  }

  @inlinable
  public mutating func subtract<I: FixedWidthInteger>(
    _ other: BitSet<I>
  ) {
    _core.subtract(other._core)
  }

  @inlinable
  public mutating func subtract<S: Sequence>(
    _ other: __owned S
  ) where S.Element: FixedWidthInteger {
    if S.self == BitSet.self {
      self.subtract(other as! BitSet)
      return
    }
    if S.self == Range<Element>.self {
      self.subtract(other as! Range<Element>)
      return
    }
    var it = other.makeIterator()
    _core.subtract {
      while let value = it.next() {
        if let value = UInt(exactly: value) {
          return value
        }
      }
      return nil
    }
  }

  @inlinable
  public mutating func subtract(_ other: Range<Element>) {
    _core.subtract(other._clampedToUInt())
  }

  @inlinable
  public mutating func subtract<I: FixedWidthInteger>(
    _ other: Range<I>
  ) {
    _core.subtract(other._clampedToUInt())
  }
}
