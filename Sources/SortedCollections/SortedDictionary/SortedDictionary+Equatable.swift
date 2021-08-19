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

extension SortedDictionary: Equatable where Value: Equatable {
  /// Returns a Boolean value indicating whether two values are equal.
  ///
  /// Equality is the inverse of inequality. For any values `a` and `b`,
  /// `a == b` implies that `a != b` is false.
  ///
  /// - Parameters:
  ///   - lhs: A value to compare.
  ///   - rhs: Another value to compare.
  /// - Complexity: O(`self.count`)
  @inlinable
  public static func ==(lhs: SortedDictionary<Key, Value>, rhs: SortedDictionary<Key, Value>) -> Bool {
    // TODO: optimize/benchmarking by comparing node identity/shared subtrees.
    if lhs.count != rhs.count { return false }
    for ((k1, v1), (k2, v2)) in zip(lhs, rhs) {
      if k1 != k2 || v1 != v2 {
        return false
      }
    }
    return true
  }
}
