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
  public mutating func subtract(_ other: Self) {
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
  internal mutating func _subtract(_ next: () -> UInt?) {
    _updateThenShrink { handle, shrink in
      while let value = next() {
        handle.remove(value)
      }
    }
  }

  @inlinable
  public mutating func subtract<S: Sequence>(
    _ other: __owned S
  ) where S.Element == Int {
    if S.self == BitSet.self {
      self.subtract(other as! BitSet)
      return
    }
    if S.self == Range<Int>.self {
      self.subtract(other as! Range<Int>)
      return
    }
    var it = other.makeIterator()
    _subtract {
      while let value = it.next() {
        if let value = UInt(exactly: value) {
          return value
        }
      }
      return nil
    }
  }

  @usableFromInline
  internal mutating func _subtract(_ other: Range<UInt>) {
    guard !other.isEmpty else { return }
    _updateThenShrink { handle, shrink in
      handle.subtract(other)
    }
  }

  public mutating func subtract(_ other: Range<Int>) {
    _subtract(other._clampedToUInt())
  }
}
