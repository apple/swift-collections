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
  /// Returns a new set containing the elements of this set that do not occur
  /// in the given other set.
  ///
  ///     var a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [0, 2, 4, 6]
  ///     let c = a.subtracting(b)
  ///     // `c` is some permutation of `[1, 3]`
  ///
  /// - Parameter other: An arbitrary set of elements.
  /// - Complexity: Expected complexity is O(`self.count` + `other.count`) in
  ///     the worst case, if `Element` properly implements hashing.
  ///     However, the implementation is careful to make the best use of
  ///     hash tree structure to minimize work when possible, e.g. by linking
  ///     parts of the input trees directly into the result.
  @inlinable
  public __consuming func subtracting(_ other: Self) -> Self {
    let builder = _root.subtracting(.top, .emptyPrefix, other._root)
    guard let builder = builder else { return self }
    let root = builder.finalize(.top)
    root._fullInvariantCheck(.top, .emptyPrefix)
    return Self(_new: root)
  }
}
