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

// FIXME: These are non-standard extensions generalizing ==.
extension PersistentSet {
  /// Returns a Boolean value indicating whether persistent sets are equal. Two
  /// persistent sets are considered equal if they contain the same elements,
  /// but not necessarily in the same order.
  ///
  /// - Parameter other: Another set.
  ///
  /// - Returns: `true` if the set is equal to `other`; otherwise, `false`.
  ///
  /// - Complexity: Generally O(`count`), as long as`Element` properly
  ///    implements hashing. That said, the implementation is careful to take
  ///    every available shortcut to reduce complexity, e.g. by skipping
  ///    comparing elements in shared subtrees.
  @inlinable
  public func isEqual(to other: Self) -> Bool {
    _root.isEqual(to: other._root, by: { _, _ in true })
  }

  /// Returns a Boolean value indicating whether a persistent set compares equal
  /// to the given keys view of a persistent dictionary. The two input
  /// collections are considered equal if they contain the same elements,
  /// but not necessarily in the same order.
  ///
  /// - Parameter other: The keys view of a persistent dictionary.
  ///
  /// - Returns: `true` if the set contains exactly the same members as `other`;
  ///    otherwise, `false`.
  ///
  /// - Complexity: Generally O(`count`), as long as`Element` properly
  ///    implements hashing. That said, the implementation is careful to take
  ///    every available shortcut to reduce complexity, e.g. by skipping
  ///    comparing elements in shared subtrees.
  @inlinable
  public func isEqual<Value>(
    to other: PersistentDictionary<Element, Value>.Keys
  ) -> Bool {
    _root.isEqual(to: other._base._root, by: { _, _ in true })
  }

  /// Returns a Boolean value indicating whether this persistent set contains
  /// the same elements as the given `other` sequence, but not necessarily
  /// in the same order.
  ///
  /// Duplicate items in `other` do not prevent it from comparing equal to
  /// `self`.
  ///
  ///     let this: PersistentSet = [0, 1, 5, 6]
  ///     let that = [5, 5, 0, 1, 1, 6, 5, 0, 1, 6, 6, 5]
  ///
  ///     this.isEqual(to: that) // true
  ///
  /// - Parameter other: The keys view of a persistent dictionary.
  ///
  /// - Returns: `true` if the set contains exactly the same members as `other`;
  ///    otherwise, `false`. This function does not consider the order of
  ///    elements and it ignores duplicate items in `other`.
  ///
  /// - Complexity: Generally O(*n*), where *n* is the number of items in
  ///    `other`, as long as`Element` properly implements hashing.
  ///    That said, the implementation is careful to take
  ///    every available shortcut to reduce complexity, e.g. by skipping
  ///    comparing elements in shared subtrees.
  @inlinable
  public func isEqual<S: Sequence>(to other: S) -> Bool
  where S.Element == Element
  {
    if S.self == Self.self {
      return isEqual(to: other as! Self)
    }

    guard other.underestimatedCount <= self.count else { return false }
    // FIXME: Would making this a BitSet of seen positions be better?
    var seen: _Node = ._empty()
    for item in other {
      let hash = _Hash(item)
      guard self._root.containsKey(.top, item, hash) else { return false }
      guard seen.insert(.top, (item, ()), hash).inserted
      else { return false }
    }
    return seen.count == self.count
  }
}
