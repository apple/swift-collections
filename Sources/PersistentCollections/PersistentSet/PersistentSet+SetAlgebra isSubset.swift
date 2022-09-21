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
  public func isSubset(of other: Self) -> Bool {
    self._root.isSubset(.top, of: other._root)
  }

  @inlinable
  public func isSubset<Value>(
    of other: PersistentDictionary<Element, Value>
  ) -> Bool {
    self._root.isSubset(.top, of: other._root)
  }
}
