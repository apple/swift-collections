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
  /// Returns a new bit set with the elements that are either in this set or in
  /// `other`, but not in both.
  ///
  ///     let set: BitSet = [1, 2, 3, 4]
  ///     let other: BitSet = [6, 4, 2, 0]
  ///     set.symmetricDifference(other) // [0, 1, 3, 6]
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: O(*max*), where *max* is the largest item in either set.
  public __consuming func symmetricDifference(_ other: __owned Self) -> Self {
    self._read { first in
      other._read { second in
        Self(
          _combining: (first, second),
          includingTail: true,
          using: { $0.symmetricDifference($1) })
      }
    }
  }

  /// Returns a new bit set with the elements that are either in this set or in
  /// `other`, but not in both.
  ///
  ///     let set: BitSet = [1, 2, 3, 4]
  ///     let other = [6, 4, 2, 0, 2, 0]
  ///     set.formSymmetricDifference(other) // [0, 1, 3, 6]
  ///
  /// - Parameter other: A sequence of nonnegative integers.
  ///
  /// - Complexity: O(*max*) + *k*, where *max* is the largest item in either
  ///    input, and *k* is the complexity of iterating over all elements in
  ///    `other`.
  @inlinable
  public __consuming func symmetricDifference<S: Sequence>(
    _ other: __owned S
  ) -> Self
  where S.Element == Int
  {
    if S.self == Range<Int>.self {
      return symmetricDifference(other as! Range<Int>)
    }
    return symmetricDifference(BitSet(other))
  }

  /// Returns a new bit set with the elements that are either in this set or in
  /// `other`, but not in both.
  ///
  ///     let set: BitSet = [1, 2, 3, 4]
  ///     set.formSymmetricDifference(3 ..< 7) // [1, 2, 5, 6]
  ///
  /// - Parameter other: A range of nonnegative integers.
  ///
  /// - Returns: A new set.
  ///
  /// - Complexity: O(*max*), where *max* is the largest item in either input.
  public __consuming func symmetricDifference(_ other: Range<Int>) -> Self {
    var result = self
    result.formSymmetricDifference(other)
    return result
  }
}
