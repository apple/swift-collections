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
  @usableFromInline
  internal mutating func formUnion(_ other: Range<UInt>) {
  }
}

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
  ) where S.Element == Int {
    if S.self == BitSet.self {
      formUnion(other as! BitSet)
      return
    }
    if S.self == Range<Int>.self {
      formUnion(other as! Range<Int>)
      return
    }
    for value in other {
      self.insert(value)
    }
  }

  public mutating func formUnion(_ other: Range<Int>) {
    guard let other = other._toUInt() else {
      preconditionFailure("Invalid range")
    }
    guard !other.isEmpty else { return }
    _ensureCapacity(limit: other.upperBound)
    _update { handle in
      handle.formUnion(other)
    }
  }
}

