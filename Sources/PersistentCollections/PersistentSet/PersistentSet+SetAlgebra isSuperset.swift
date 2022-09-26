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
  @inlinable
  public func isSuperset(of other: Self) -> Bool {
    other._root.isSubset(.top, of: self._root)
  }

  @inlinable
  public func isSuperset<Value>(
    of other: PersistentDictionary<Element, Value>
  ) -> Bool {
    other._root.isSubset(.top, of: self._root)
  }

  @inlinable
  public func isSuperset<S: Sequence>(of other: S) -> Bool
  where S.Element == Element
  {
    guard self.count >= other.underestimatedCount else {
      return false
    }
    return other.allSatisfy { self.contains($0) }
  }
}
