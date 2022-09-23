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
    with other: PersistentDictionary<Element, Value>
  ) -> Bool {
    self._root.isDisjoint(.top, with: other._root)
  }
}
