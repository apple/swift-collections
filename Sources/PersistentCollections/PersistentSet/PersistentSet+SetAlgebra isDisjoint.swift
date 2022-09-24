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
  public func isDisjoint(with other: Self) -> Bool {
    self._root.isDisjoint(.top, with: other._root)
  }

  @inlinable
  public func isDisjoint<Value>(
    with other: PersistentDictionary<Element, Value>.Keys
  ) -> Bool {
    self._root.isDisjoint(.top, with: other._base._root)
  }

  @inlinable
  public func isDisjoint<S: Sequence>(with other: S) -> Bool
  where S.Element == Element
  {
    other.allSatisfy { !self.contains($0) }
  }
}
