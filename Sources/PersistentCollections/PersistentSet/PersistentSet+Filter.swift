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
  /// Returns a new persistent set containing the values pairs of the ordered
  /// set that satisfy the given predicate.
  ///
  /// - Parameter isIncluded: A closure that takes a value as its
  ///   argument and returns a Boolean value indicating whether the value
  ///   should be included in the returned set.
  ///
  /// - Returns: A set of the values that `isIncluded` allows.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Self {
    let result = try _root.filter(.top, .emptyPrefix) {
      try isIncluded($0.key)
    }
    guard let result = result else { return self }
    return PersistentSet(_new: result.finalize(.top))
  }
}
