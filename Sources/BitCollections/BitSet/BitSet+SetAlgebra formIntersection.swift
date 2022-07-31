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
  internal mutating func formIntersection(_ other: Self) {
    other._read { source in
      if source.wordCount < _storage.count {
        self._storage.removeLast(_storage.count - source.wordCount)
      }
      _updateThenShrink { target, shrink in
        target.combineSharedPrefix(
          with: source, using: { $0.formIntersection($1) })
      }
    }
  }

  @usableFromInline
  internal mutating func formIntersection(_ other: Range<UInt>) {
    guard let last = other.last else {
      self = _BitSet()
      return
    }
    let lastWord = UnsafeHandle.Index(last).word
    if _storage.count - lastWord - 1 > 0 {
      _storage.removeLast(_storage.count - lastWord - 1)
    }
    _updateThenShrink { handle, shrink in
      handle.formIntersection(other)
    }
  }
}

extension BitSet {
  @inlinable
  public mutating func formIntersection(_ other: Self) {
    _core.formIntersection(other._core)
  }

  @inlinable
  public mutating func formIntersection<I: FixedWidthInteger>(
    _ other: BitSet<I>
  ) {
    _core.formIntersection(other._core)
  }

  @inlinable
  public mutating func formIntersection<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Element {
    if S.self == Range<S.Element>.self {
      formIntersection(other as! Range<S.Element>)
      return
    }
    formIntersection(BitSet(_validMembersOf: other))
  }

  @inlinable
  public mutating func formIntersection(_ other: Range<Element>) {
    _core.formIntersection(other._clampedToUInt())
  }
}
