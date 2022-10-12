//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentSet {
  /// Adds the elements of the given set to this set.
  ///
  ///     var a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [0, 2, 4, 6]
  ///     a.formUnion(b)
  ///     // `a` is now some permutation of `[0, 1, 2, 3, 4, 6]`
  ///
  /// For values that are members of both sets, this operation preserves the
  /// instances that were originally in `self`. (This matters if equal members
  /// can be distinguished by comparing their identities, or by some other
  /// means.)
  ///
  /// - Parameter other: The set of elements to insert.
  /// - Complexity: Expected complexity is O(`self.count` + `other.count`) in
  ///     the worst case, if `Element` properly implements hashing.
  ///     However, the implementation is careful to make the best use of
  ///     hash tree structure to minimize work when possible, e.g. by linking
  ///     parts of the input trees directly into the result.
  @inlinable
  public mutating func formUnion(_ other: __owned Self) {
    self = union(other)
  }

  @inlinable
  public mutating func formUnion<S: Sequence>(_ other: __owned S)
  where S.Element == Element {
    self = union(other)
  }
}
