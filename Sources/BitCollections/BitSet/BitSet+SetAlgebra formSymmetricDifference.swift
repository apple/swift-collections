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
  internal mutating func formSymmetricDifference(_ other: __owned Self) {
    _ensureCapacity(limit: other._capacity)
    _updateThenShrink { target, shrink in
      other._read { source in
        target.combineSharedPrefix(
          with: source, using: { $0.formSymmetricDifference($1) })
      }
    }
  }

  @usableFromInline
  internal mutating func formSymmetricDifference(_ other: Range<UInt>) {
    guard !other.isEmpty else { return }
    _ensureCapacity(limit: other.upperBound)
    _updateThenShrink { handle, shrink in
      handle.formSymmetricDifference(other)
    }
  }
}

extension BitSet {
  @inlinable
  public mutating func formSymmetricDifference(_ other: __owned Self) {
    _core.formSymmetricDifference(other._core)
  }

  @inlinable
  public mutating func formSymmetricDifference<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Element {
    if S.self == Range<S.Element>.self {
      formSymmetricDifference(other as! Range<S.Element>)
      return
    }
    _core.formSymmetricDifference(BitSet(other)._core)
  }
}

extension BitSet {
  @inlinable
  public mutating func formSymmetricDifference(
    _ other: Range<Element>
  ) {
    guard let other = other._toUInt() else {
      preconditionFailure("Invalid range")
    }
    _core.formSymmetricDifference(other)
  }
}
