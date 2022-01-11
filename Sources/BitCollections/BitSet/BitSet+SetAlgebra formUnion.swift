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
  public mutating func formUnion(_ other: __owned Self) {
    _ensureCapacity(limit: other._capacity)
    _update { target in
      other._read { source in
        target.combineSharedPrefix(with: source) { $0.formUnion($1) }
      }
    }
  }

  @inlinable
  public mutating func formUnion<S: Sequence>(
    _ other: __owned S
  ) where S.Element: FixedWidthInteger {
    if S.self == BitSet.self {
      formUnion(other as! BitSet)
      return
    }
    if S.self == Range<S.Element>.self {
      formUnion(other as! Range<S.Element>)
      return
    }
    for value in other {
      self.insert(value)
    }
  }

  @inlinable
  public mutating func formUnion<I: FixedWidthInteger>(
    _ other: Range<I>
  ) {
    guard let other = other._toUInt() else {
      preconditionFailure("BitSet can only hold nonnegative integers")
    }
    _formUnion(other)
  }


  @usableFromInline
  internal mutating func _formUnion(_ other: Range<UInt>) {
    guard !other.isEmpty else { return }
    _ensureCapacity(limit: other.upperBound)
    _update { handle in
      handle.formUnion(other)
    }
  }
}
