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

extension SortedSet: SetAlgebra {
  public func contains(_ member: Element) -> Bool {
    return switch self._storage.exchange(.confirm(value: member)) {
    case .added, .removed:
      preconditionFailure("This should not be reachable")
    case .existed:
      true
    case .notPresent:
      false
    }
  }

  public mutating func formIntersection(_ other: Self) {
    self = self.intersection(other)
  }

  public mutating func formSymmetricDifference(_ other: __owned Self) {
    self = self.symmetricDifference(other)
  }

  public mutating func formUnion(_ other: __owned Self) {
    self = self.union(other)
  }

  public init() {
    self.init(EmptyCollection())
  }

  public init(_ sequence: __owned some Sequence<Element>) {
    let sorted = sequence.sorted(by: TotalOrdering.areIncreasing)
    let deduplicated =
      sorted.isEmpty
      ? []
      : sorted.dropFirst().reduce(into: [sorted[0]]) {
        partialResult,
        nextElement in
        if !TotalOrdering.areEquivalent(partialResult.last!, nextElement) {
          partialResult.append(nextElement)
        }
      }
    self.init(strictlyIncreasing: deduplicated)
  }

  public mutating func insert(_ newMember: __owned Element) -> (
    inserted: Bool, memberAfterInsert: Element
  ) {
    return
      switch self._storage.exchange(.add(value: newMember, replace: false))
    {
    case .added:
      (true, newMember)
    case .existed(let old, replaced: false):
      (false, old)
    case .existed(_, replaced: true), .notPresent, .removed:
      preconditionFailure("This should not be reachable")
    }
  }

  public func intersection(_ other: Self) -> Self {
    return .init(
      strictlyIncreasing:
        SortedSetMergingSequence(
          firstBase: self,
          secondBase: other,
          operation: .intersection,
          areInIncreasingOrder: TotalOrdering.areIncreasing
        )
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

  public var isEmpty: Bool { self._storage.rowHeads.isEmpty }

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

  public mutating func remove(_ member: Element) -> Element? {
    switch self._storage.exchange(.remove(value: member)) {
    case .added, .existed:
      preconditionFailure("This should not be reachable")
    case .notPresent:
      nil
    case .removed(let old):
      old
    }
  }

  public mutating func subtract(_ other: Self) {
    self = self.subtracting(other)
  }

  public func subtracting(_ other: Self) -> Self {
    return .init(
      strictlyIncreasing:
        SortedSetMergingSequence(
          firstBase: self,
          secondBase: other,
          operation: .exclusivesToFirst,
          areInIncreasingOrder: TotalOrdering.areIncreasing
        )
    )
  }

  public func symmetricDifference(_ other: __owned Self) -> Self {
    return .init(
      strictlyIncreasing:
        SortedSetMergingSequence(
          firstBase: self,
          secondBase: other,
          operation: .symmetricDifference,
          areInIncreasingOrder: TotalOrdering.areIncreasing
        )
    )
  }

  public func union(_ other: __owned Self) -> Self {
    return .init(
      strictlyIncreasing:
        SortedSetMergingSequence(
          firstBase: self,
          secondBase: other,
          operation: .union,
          areInIncreasingOrder: TotalOrdering.areIncreasing
        )
    )
  }

  public mutating func update(with newMember: __owned Element) -> Element? {
    return
      switch self._storage.exchange(.add(value: newMember, replace: true))
    {
    case .added:
      nil
    case .existed(let old, replaced: true):
      old
    case .existed(_, replaced: false), .notPresent, .removed:
      preconditionFailure("This should not be reachable")
    }
  }
}
