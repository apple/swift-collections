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
  public func isStrictSubset(of other: Self) -> Bool {
    guard self.count < other.count else { return false }
    return isSubset(of: other)
  }

  @inlinable
  public func isStrictSubset<Value>(
    of other: PersistentDictionary<Element, Value>.Keys
  ) -> Bool {
    guard self.count < other.count else { return false }
    return isSubset(of: other)
  }

  @inlinable
  public func isStrictSubset<S: Sequence & _FastMembershipCheckable>(
    of other: S
  ) -> Bool
  where S.Element == Element {
    guard self.isSubset(of: other) else { return false }
    return !other.allSatisfy { self.contains($0) }
  }


  @inlinable
  public func isStrictSubset<S: Sequence>(of other: S) -> Bool
  where S.Element == Element
  {
    if other.underestimatedCount > self.count {
      return isSubset(of: other)
    }
    // FIXME: Would making this a BitSet of seen positions be better?
    var seen: PersistentSet? = []
    var isStrict = false
    for item in other {
      if self.contains(item), seen?._insert(item) == true {
        if seen?.count == self.count {
          if isStrict { return true }
          // Stop collecting seen items -- we just need to decide
          // strictness now.
          seen = nil
        }
      } else {
        isStrict = true
        if seen == nil { return true }
      }
    }
    return false
  }
}
