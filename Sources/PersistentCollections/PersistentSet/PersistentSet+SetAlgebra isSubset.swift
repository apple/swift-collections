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
  public func isSubset(of other: Self) -> Bool {
    self._root.isSubset(.top, of: other._root)
  }

  @inlinable
  public func isSubset<Value>(
    of other: PersistentDictionary<Element, Value>.Keys
  ) -> Bool {
    self._root.isSubset(.top, of: other._base._root)
  }

  @inlinable
  public func isSubset<S: _FastMembershipCheckable>(
    of other: S
  ) -> Bool
  where S.Element == Element {
    self.allSatisfy { other.contains($0) }
  }

  @inlinable
  public func isSubset<S: Sequence & _FastMembershipCheckable>(
    of other: S
  ) -> Bool
  where S.Element == Element {
    self.allSatisfy { other.contains($0) }
  }

  @inlinable
  public func isSubset<S: Sequence>(of other: S) -> Bool
  where S.Element == Element
  {
    // FIXME: Would making this a BitSet of seen positions be better?
    var seen: PersistentSet = []
    for item in other {
      if contains(item), seen._insert(item), seen.count == self.count {
        return true
      }
    }
    return false
  }
}
