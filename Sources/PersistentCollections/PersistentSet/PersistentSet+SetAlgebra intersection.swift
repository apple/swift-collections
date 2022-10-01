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
  /// Returns a new set with the elements that are common to both this set and
  /// the provided other one.
  ///
  ///     var a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [0, 2, 4, 6]
  ///     let c = a.intersection(b)
  ///     // `c` is some permutation of `[2, 4]`
  ///
  /// The result will only contain instances that were originally in `self`.
  /// (This matters if equal members can be distinguished by comparing their
  /// identities, or by some other means.)
  ///
  /// - Parameter other: An arbitrary set of elements.
  /// - Complexity: Expected complexity is O(`self.count` + `other.count`) in
  ///     the worst case, if `Element` properly implements hashing.
  ///     However, the implementation is careful to make the best use of
  ///     hash tree structure to minimize work when possible, e.g. by linking
  ///     parts of the input trees directly into the result.
  @inlinable
  public func intersection(_ other: Self) -> Self {
    let builder = _root.intersection(.top, .emptyPrefix, other._root)
    guard let builder = builder else { return self }
    let root = builder.finalize(.top)
    root._fullInvariantCheck(.top, .emptyPrefix)
    return Self(_new: root)
  }
}
