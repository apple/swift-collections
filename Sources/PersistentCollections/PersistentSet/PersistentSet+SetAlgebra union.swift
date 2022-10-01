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

/// Returns a new set with the elements of both this and the given set.
///
///     var a: PersistentSet = [1, 2, 3, 4]
///     let b: PersistentSet = [0, 2, 4, 6]
///     let c = a.union(b)
///     // `c` is some permutation of `[0, 1, 2, 3, 4, 6]`
///
/// For values that are members of both sets, the result set contains the
/// instances that were originally in `self`. (This matters if equal members
/// can be distinguished by comparing their identities, or by some other means.)
///
/// - Parameter other: The set of elements to insert.
/// - Complexity: Expected complexity is O(`self.count` + `other.count`) in
///     the worst case, if `Element` properly implements hashing.
///     However, the implementation is careful to make the best use of
///     hash tree structure to minimize work when possible, e.g. by linking
///     parts of the input trees directly into the result.
extension PersistentSet {
  @inlinable
  public func union(_ other: __owned Self) -> Self {
    let r = _root.union(.top, .emptyPrefix, other._root)
    guard r.copied else { return self }
    r.node._fullInvariantCheck(.top, .emptyPrefix)
    return PersistentSet(_new: r.node)
  }
}
