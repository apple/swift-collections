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
  public mutating func formIntersection(_ other: Self) {
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

  @inlinable
  public mutating func formIntersection<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Int {
    if S.self == Range<Int>.self {
      formIntersection(other as! Range<Int>)
      return
    }
    formIntersection(BitSet(_validMembersOf: other))
  }

  public mutating func formIntersection(_ other: Range<Int>) {
    let other = other._clampedToUInt()
    guard let last = other.last else {
      self = BitSet()
      return
    }
    let lastWord = _UnsafeHandle.Index(last).word
    if _storage.count - lastWord - 1 > 0 {
      _storage.removeLast(_storage.count - lastWord - 1)
    }
    _updateThenShrink { handle, shrink in
      handle.formIntersection(other)
    }
  }
}
