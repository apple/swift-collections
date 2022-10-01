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
  @inlinable @inline(__always)
  public func intersection(_ other: Self) -> Self {
    _intersection(other._root)
  }

  @inlinable @inline(__always)
  public func intersection<Value>(
    _ other: PersistentDictionary<Element, Value>.Keys
  ) -> Self {
    _intersection(other._base._root)
  }

  @inlinable
  internal func _intersection<V>(
    _ other: PersistentCollections._Node<Element, V>
  ) -> Self {
    let builder = _root.intersection(.top, other)
    guard let builder = builder else { return self }
    let root = builder.finalize(.top)
    root._fullInvariantCheck()
    return Self(_new: root)
  }

  /// Returns a new set with the elements that are common to both this set and
  /// the provided sequence.
  ///
  ///     var a: PersistentSet = [1, 2, 3, 4]
  ///     let b = [0, 2, 4, 6]
  ///     let c = a.intersection(b)
  ///     // `c` is some permutation of `[2, 4]`
  ///
  /// The result will only contain instances that were originally in `self`.
  /// (This matters if equal members can be distinguished by comparing their
  /// identities, or by some other means.)
  ///
  /// - Parameter other: An arbitrary sequence of items, possibly containing
  ///    duplicate values.
  @inlinable
  public func intersection<S: Sequence>(
    _ other: S
  ) -> Self
  where S.Element == Element {
    if S.self == Self.self {
      return intersection(other as! Self)
    }

    guard let first = self.first else { return Self() }
    if other._customContainsEquatableElement(first) != nil {
      // Fast path: the sequence has fast containment checks.
      return self.filter { other.contains($0) }
    }

    var result: _Node = ._emptyNode()
    for item in other {
      let hash = _Hash(item)
      if let r = self._root.lookup(.top, item, hash) {
        let itemInSelf = _UnsafeHandle.read(r.node) { $0[item: r.slot] }
        _ = result.updateValue(.top, forKey: itemInSelf.key, hash) {
          $0.initialize(to: itemInSelf)
        }
      }
    }
    return Self(_new: result)
  }
}
