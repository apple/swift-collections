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

import _CollectionsUtilities

extension PersistentSet {
  @inlinable
  public func isStrictSuperset(of other: Self) -> Bool {
    guard self.count > other.count else { return false }
    return other._root.isSubset(.top, of: self._root)
  }

  @inlinable
  public func isStrictSuperset<Value>(
    of other: PersistentDictionary<Element, Value>.Keys
  ) -> Bool {
    guard self.count > other.count else { return false }
    return other._base._root.isSubset(.top, of: self._root)
  }

  @inlinable
  public func isStrictSuperset<S: Sequence & _FastMembershipCheckable>(
    of other: S
  ) -> Bool
  where S.Element == Element
  {
    if self.count < other.underestimatedCount { return false }
    if !other.allSatisfy({ self.contains($0) }) { return false }
    return !self.allSatisfy { other.contains($0) }
  }

  @inlinable
  public func isStrictSuperset<S: Sequence>(of other: S) -> Bool
  where S.Element == Element
  {
    guard self.count >= other.underestimatedCount else {
      return false
    }
    // FIXME: Would making this a BitSet of seen positions be better?
    var seen: PersistentSet = []
    for item in other {
      guard self.contains(item) else { return false }
      if seen._insert(item), seen.count == self.count {
        return false
      }
    }
    assert(seen.count < self.count)
    return true
  }
}
