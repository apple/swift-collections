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
  /// Removes the elements of the given bit set from this set.
  ///
  ///     var set: BitSet = [1, 2, 3, 4]
  ///     let other: BitSet = [0, 2, 4, 6]
  ///     set.subtract(other)
  ///     // set is now [1, 3]
  ///
  /// - Parameter other: Another bit set.
  ///
  /// - Complexity: O(*max*), where *max* is the largest item in either input.
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

  /// Removes the elements of the given bit set from this set.
  ///
  ///     var set: BitSet = [1, 2, 3, 4]
  ///     let other: BitSet.Counted = [0, 2, 4, 6]
  ///     set.subtract(other)
  ///     // set is now [1, 3]
  ///
  /// - Parameter other: Another bit set.
  ///
  /// - Complexity: O(*max*), where *max* is the largest item in either input.
  public mutating func subtract(_ other: BitSet.Counted) {
    subtract(other._bits)
  }

  /// Removes the elements of the given range of integers from this set.
  ///
  ///     var set: BitSet = [1, 2, 3, 4]
  ///     set.subtract(-10 ..< 3)
  ///     // set is now [3, 4]
  ///
  /// - Parameter other: A range of arbitrary integers.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: O(*max*), where *max* is the largest item in self.
  public mutating func subtract(_ other: Range<Int>) {
    _subtract(other._clampedToUInt())
  }

  @usableFromInline
  internal mutating func _subtract(_ other: Range<UInt>) {
    guard !other.isEmpty else { return }
    _updateThenShrink { handle, shrink in
      handle.subtract(other)
    }
  }

  /// Removes the elements of the given sequence of integers from this set.
  ///
  ///     var set: BitSet = [1, 2, 3, 4]
  ///     let other = [6, 4, 2, 0, -2, -4]
  ///     set.subtract(other)
  ///     // set is now [1, 3]
  ///
  /// - Parameter other: A sequence of arbitrary integers.
  ///
  /// - Complexity: O(*max*) + *k*, where *max* is the largest item in `self`,
  ///    and *k* is the complexity of iterating over all elements in `other`.
  @inlinable
  public mutating func subtract<S: Sequence>(
    _ other: S
  ) where S.Element == Int {
    if S.self == BitSet.self {
      self.subtract(other as! BitSet)
      return
    }
    if S.self == BitSet.Counted.self {
      self.subtract(other as! BitSet.Counted)
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
  internal mutating func _subtract(_ next: () -> UInt?) {
    _updateThenShrink { handle, shrink in
      while let value = next() {
        handle.remove(value)
      }
    }
  }
}
