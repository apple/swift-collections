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
  public func isStrictSubset(of other: Self) -> Bool {
    guard self.count < other.count else { return false }
    return isSubset(of: other)
  }

  @inlinable
  public func isStrictSubset<Value>(
    of other: PersistentDictionary<Element, Value>
  ) -> Bool {
    guard self.count < other.count else { return false }
    return isSubset(of: other)
  }
}
