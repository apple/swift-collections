//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/**
  This file defines `SkipListedSortedSet`,
  a set implementation based on a deterministic skip list structure designed for
  efficient ordered set operations such as insertion, deletion, and
  membership queries.
  The skip list provides expected logarithmic time complexity for
  these operations while maintaining elements in a sorted order according to
  a specified total ordering.
 */

/// An always-sorted set based on a skip list data structure.
///
/// This type maintains elements in a sorted order as defined by
/// the provided `TotalOrdering`.
/// It supports efficient insertion, deletion, and searches with
/// the expected logarithmic time complexity.
/// Deterministic balencing is used to maintain performance.
public struct SkipListedSortedSet<TotalOrdering: Orderable> {
  public init() {}

  /// The underlying skip list storage responsible for maintaining the
  /// set's ordered elements efficiently.
  var skipList = SkipList<TotalOrdering>()
}

// Operations inspired by `RangeReplaceableCollection`.
extension SkipListedSortedSet {
  /// The number of elements in the set.
  ///
  /// - Complexity: `O(1)`.
  public var count: Int { self.skipList.count }

  /// The first element of the set.
  ///
  /// If this set is empty, the value of this property is `nil`.
  public var first: Element? {
    var pointer = self.skipList._core.head
    while pointer !== self.skipList._core.bottom {
      pointer = pointer.below
    }
    if pointer.value == .maximum {
      pointer = pointer.forward
    }
    return if case .normal(let result) = pointer.value {
      result.sample
    } else {
      nil
    }
  }

  /// Removes and returns the first element of the set.
  ///
  /// - Returns: The first element of this set if the set is not empty;
  ///   otherwise, `nil`.
  ///
  /// - Complexity: `O(log n)`, where *n* is the length of this set.
  mutating func popFirst() -> Element? {
    return if let target = self.first {
      self.remove(target)
    } else {
      nil
    }
  }

  /// Removes and returns the lowest-ranked element of the set.
  ///
  /// The set must not be empty.
  ///
  /// - Returns: The removed element.
  ///
  /// - Complexity: `O(log n)`, where *n* is the length of this set.
  @discardableResult
  public mutating func removeFirst() -> Element {
    return self.popFirst()!
  }
  /// Removes the specified number of the lowest-ranked elements from the set.
  ///
  /// - Parameter k: The number of elements to remove from the set.
  ///   `k` must be greater than or equal to zero and must not exceed the
  ///   number of elements in the set.
  ///
  /// - Complexity: `O(k × log n)`, where *n* is the length of this set.
  public mutating func removeFirst(_ k: Int) {
    for _ in 0..<k {
      self.removeFirst()
    }
  }
  /// Removes all elements from the set.
  public mutating func removeAll() {
    self.skipList.deleteAll()
  }
}

extension SkipListedSortedSet: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.lexicographicallyPrecedes(rhs, by: TotalOrdering.areIncreasing)
  }
}

extension SkipListedSortedSet: Sequence {
  public struct Iterator: IteratorProtocol {
    var inner: SkipList<TotalOrdering>.Iterator

    mutating public func next() -> TotalOrdering.Element? {
      return inner.next()
    }
  }

  public func makeIterator() -> Iterator {
    return .init(inner: self.skipList.makeIterator())
  }

  public var underestimatedCount: Int { self.skipList.underestimatedCount }
}

extension SkipListedSortedSet: SetAlgebra {
  // Use default implmentation of `init(arrayLiteral:)`.

  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.elementsEqual(rhs, by: TotalOrdering.areEquivalent)
  }

  public func contains(_ member: Element) -> Bool {
    self.skipList.getRepresentative(for: member) != nil
  }

  public func union(_ other: __owned Self) -> Self {
    return .init(
      sortedMerge(
        between: self,
        and: other,
        retaining: .union,
        sortingBy: TotalOrdering.areIncreasing
      )
    )
  }

  public func intersection(_ other: Self) -> Self {
    return .init(
      sortedMerge(
        between: self,
        and: other,
        retaining: .intersection,
        sortingBy: TotalOrdering.areIncreasing
      )
    )
  }

  public func symmetricDifference(_ other: __owned Self) -> Self {
    return .init(
      sortedMerge(
        between: self,
        and: other,
        retaining: .symmetricDifference,
        sortingBy: TotalOrdering.areIncreasing
      )
    )
  }

  public mutating func insert(_ newMember: __owned Element) -> (
    inserted: Bool, memberAfterInsert: Element
  ) {
    return if let old = self.skipList.insert(newMember) {
      (inserted: false, memberAfterInsert: old)
    } else {
      (inserted: true, memberAfterInsert: newMember)
    }
  }

  public mutating func remove(_ member: Element) -> Element? {
    return self.skipList.delete(member)
  }

  public mutating func update(with newMember: __owned Element) -> Element? {
    return if let old = self.skipList.setRepresentative(for: newMember) {
      old
    } else {
      self.skipList.insert(newMember)
    }
  }

  public mutating func formUnion(_ other: __owned Self) {
    self = self.union(other)
  }

  public mutating func formIntersection(_ other: Self) {
    self = self.intersection(other)
  }

  public mutating func formSymmetricDifference(_ other: __owned Self) {
    self = self.symmetricDifference(other)
  }

  public func subtracting(_ other: Self) -> Self {
    return .init(
      sortedMerge(
        between: self,
        and: other,
        retaining: .exclusivesToFirst,
        sortingBy: TotalOrdering.areIncreasing
      )
    )
  }

  public func isSubset(of other: Self) -> Bool {
    return doesSortedMerger(
      of: self,
      and: other,
      haveExclusivesToFirst: .mustBeAbsent,
      haveExclusivesToSecond: .doNotCare,
      haveSharedElements: .doNotCare,
      sortingBy: TotalOrdering.areIncreasing
    )
  }

  public func isDisjoint(with other: Self) -> Bool {
    return doesSortedMerger(
      of: self,
      and: other,
      haveExclusivesToFirst: .doNotCare,
      haveExclusivesToSecond: .doNotCare,
      haveSharedElements: .mustBeAbsent,
      sortingBy: TotalOrdering.areIncreasing
    )
  }

  public func isSuperset(of other: Self) -> Bool {
    return doesSortedMerger(
      of: self,
      and: other,
      haveExclusivesToFirst: .doNotCare,
      haveExclusivesToSecond: .mustBeAbsent,
      haveSharedElements: .doNotCare,
      sortingBy: TotalOrdering.areIncreasing
    )
  }

  public var isEmpty: Bool { self.count == 0 }

  // Use default implementation of `init(_:)`.

  public mutating func subtract(_ other: Self) {
    self = self.subtracting(other)
  }
}
