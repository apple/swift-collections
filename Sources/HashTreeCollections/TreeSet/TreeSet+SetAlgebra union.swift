//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

extension TreeSet {
  /// Returns a new set with the elements of both this and the given set.
  ///
  ///     var a: TreeSet = [1, 2, 3, 4]
  ///     let b: TreeSet = [0, 2, 4, 6]
  ///     let c = a.union(b)
  ///     // `c` is some permutation of `[0, 1, 2, 3, 4, 6]`
  ///
  /// For values that are members of both sets, the result set contains the
  /// instances that were originally in `self`. (This matters if equal members
  /// can be distinguished by comparing their identities, or by some other
  /// means.)
  ///
  /// - Parameter other: The set of elements to insert.
  ///
  /// - Complexity: Expected complexity is O(`self.count` + `other.count`) in
  ///     the worst case, if `Element` properly implements hashing.
  ///     However, the implementation is careful to make the best use of
  ///     hash tree structure to minimize work when possible, e.g. by linking
  ///     parts of the input trees directly into the result.
  @inlinable
  public func union(_ other: __owned Self) -> Self {
    let r = _root.union(.top, other._root)
    guard r.copied else { return self }
    r.node._fullInvariantCheck()
    return TreeSet(_new: r.node)
  }

  /// Returns a new set with the elements of both this set and the given
  /// keys view of a persistent dictionary.
  ///
  ///     var a: TreeSet = [1, 2, 3, 4]
  ///     let b: TreeDictionary = [0: "a", 2: "b", 4: "c", 6: "d"]
  ///     let c = a.union(b)
  ///     // `c` is some permutation of `[0, 1, 2, 3, 4, 6]`
  ///
  /// For values that are members of both inputs, the result set contains the
  /// instances that were originally in `self`. (This matters if equal members
  /// can be distinguished by comparing their identities, or by some other
  /// means.)
  ///
  /// - Parameter other: The keys view of a persistent dictionary.
  ///
  /// - Complexity: Expected complexity is O(`self.count` + `other.count`) in
  ///     the worst case, if `Element` properly implements hashing.
  ///     However, the implementation is careful to make the best use of
  ///     hash tree structure to minimize work when possible, e.g. by linking
  ///     parts of the input trees directly into the result.
  @inlinable
  public func union<Value>(
    _ other: __owned TreeDictionary<Element, Value>.Keys
  ) -> Self {
    let r = _root.union(.top, other._base._root)
    guard r.copied else { return self }
    r.node._fullInvariantCheck()
    return TreeSet(_new: r.node)
  }

  /// Returns a new set with the elements of both this set and the given
  /// sequence.
  ///
  ///     var a: TreeSet = [1, 2, 3, 4]
  ///     let b = [0, 2, 4, 6, 0, 2]
  ///     let c = a.union(b)
  ///     // `c` is some permutation of `[0, 1, 2, 3, 4, 6]`
  ///
  /// For values that are members of both inputs, the result set contains the
  /// instances that were originally in `self`. (This matters if equal members
  /// can be distinguished by comparing their identities, or by some other
  /// means.)
  ///
  /// If some of the values that are missing from `self` have multiple copies
  /// in `other`, then the result of this function always contains the first
  /// instances in the sequence -- the second and subsequent copies are ignored.
  ///
  /// - Parameter other: An arbitrary finite sequence of items,
  ///    possibly containing duplicate values.
  ///
  /// - Complexity: Expected complexity is O(*n*) in
  ///     the worst case, where *n* is the number of items in `other`,
  ///     as long as `Element` properly implements hashing.
  @inlinable
  public func union(_ other: __owned some Sequence<Element>) -> Self {
    if let other = _specialize(other, for: Self.self) {
      return union(other)
    }

    var root = self._root
    for item in other {
      let hash = _Hash(item)
      _ = root.insert(.top, (item, ()), hash)
    }
    return Self(_new: root)
  }
}
