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

extension SparseSet: Equatable where Value: Equatable {
  /// Returns a Boolean value indicating whether two values are equal.
  ///
  /// Two sparse set are considered equal if they contain the same key-value
  /// pairs, in the same order.
  ///
  /// - Complexity: O(`min(left.count, right.count)`)
  @inlinable
  public static func ==(left: Self, right: Self) -> Bool {
    left._dense.keys == right._dense.keys && left._dense.values == right._dense.values
  }
}
