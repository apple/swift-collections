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
  internal mutating func formUnion(_ other: __owned Self) {
    _ensureCapacity(limit: other._capacity)
    _update { target in
      other._read { source in
        target.combineSharedPrefix(with: source) { $0.formUnion($1) }
      }
    }
  }

  @usableFromInline
  internal mutating func formUnion(_ other: Range<UInt>) {
    guard !other.isEmpty else { return }
    _ensureCapacity(limit: other.upperBound)
    _update { handle in
      handle.formUnion(other)
    }
  }
}

extension BitSet {
  @inlinable
  public mutating func formUnion(_ other: __owned Self) {
    _core.formUnion(other._core)
  }

  @inlinable
  public mutating func formUnion<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Element {
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
  public mutating func formUnion(_ other: Range<Element>) {
    guard let other = other._toUInt() else {
      preconditionFailure("Invalid range")
    }
    _core.formUnion(other)
  }
}

