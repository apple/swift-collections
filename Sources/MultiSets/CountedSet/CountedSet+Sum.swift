//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension CountedSet {
  /// Combines the elements two sets, adding multiplicities together.
  @inlinable
  public static func + (lhs: Self, rhs: __owned Self) -> Self {
    var result = lhs
    result += rhs
    return result
  }

  /// Adds the elements of a set to another set, adding multiplicities
  /// together.
  @inlinable
  public static func += (lhs: inout Self, rhs: __owned Self) {
    lhs._storage.merge(rhs.rawValue, uniquingKeysWith: +)
  }
}
