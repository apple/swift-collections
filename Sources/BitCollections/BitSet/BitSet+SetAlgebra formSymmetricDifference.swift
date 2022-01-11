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

extension BitSet {
  public mutating func formSymmetricDifference(_ other: __owned Self) {
    _ensureCapacity(limit: other._capacity)
    _updateThenShrink { target, shrink in
      other._read { source in
        target.combineSharedPrefix(
          with: source, using: { $0.formSymmetricDifference($1) })
      }
    }
  }

  @inlinable
  public mutating func formSymmetricDifference<S: Sequence>(
    _ other: __owned S
  ) where S.Element: FixedWidthInteger {
    if S.self == Range<S.Element>.self {
      formSymmetricDifference(other as! Range<S.Element>)
      return
    }
    formSymmetricDifference(BitSet(other))
  }

  @inlinable
  public mutating func formSymmetricDifference<I: FixedWidthInteger>(
    _ other: Range<I>
  ) {
    guard let other = other._toUInt() else {
      preconditionFailure("BitSet can only hold nonnegative integers")
    }
    _formSymmetricDifference(other)
  }

  @usableFromInline
  internal mutating func _formSymmetricDifference(_ other: Range<UInt>) {
    guard !other.isEmpty else { return }
    _ensureCapacity(limit: other.upperBound)
    _updateThenShrink { handle, shrink in
      handle.formSymmetricDifference(other)
    }
  }
}
