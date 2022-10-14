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
  /// Returns a new set with the elements that are either in this set or in
  /// `other`, but not in both.
  ///
  ///     var a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [0, 2, 4, 6]
  ///     let c = a.symmetricDifference(b)
  ///     // `c` is some permutation of `[0, 1, 3, 6]`
  ///
  /// - Parameter other: An arbitrary set of elements.
  /// - Complexity: Expected complexity is O(`self.count` + `other.count`) in
  ///     the worst case, if `Element` properly implements hashing.
  ///     However, the implementation is careful to make the best use of
  ///     hash tree structure to minimize work when possible, e.g. by linking
  ///     parts of the input trees directly into the result.
  @inlinable
  public func symmetricDifference(_ other: __owned Self) -> Self {
    let branch = _root.symmetricDifference(.top, other._root)
    guard let branch = branch else { return self }
    let root = branch.finalize(.top)
    root._fullInvariantCheck()
    return PersistentSet(_new: root)
  }

  @inlinable
  public func symmetricDifference<S: Sequence>(_ other: __owned S) -> Self
  where S.Element == Element {
    if S.self == Self.self {
      return symmetricDifference(other as! Self)
    }

    var root = self._root
    for item in other {
      let hash = _Hash(item)
      var state = root.prepareValueUpdate(item, hash)
      if state.found {
        state.value = nil
      } else {
        state.value = ()
      }
      root.finalizeValueUpdate(state)
    }
    return Self(_new: root)
  }
}
