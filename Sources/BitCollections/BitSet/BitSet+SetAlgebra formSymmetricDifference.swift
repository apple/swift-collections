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
  ) where S.Element == Int {
    if S.self == Range<Int>.self {
      formSymmetricDifference(other as! Range<Int>)
      return
    }
    formSymmetricDifference(BitSet(other))
  }
}

extension BitSet {
  public mutating func formSymmetricDifference(_ other: Range<Int>) {
    guard let other = other._toUInt() else {
      preconditionFailure("Invalid range")
    }
    guard !other.isEmpty else { return }
    _ensureCapacity(limit: other.upperBound)
    _updateThenShrink { handle, shrink in
      handle.formSymmetricDifference(other)
    }
  }
}
