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

extension PersistentDictionary {
  /// Returns a new persistent dictionary containing the key-value pairs of this
  /// dictionary that satisfy the given predicate.
  ///
  /// - Parameter isIncluded: A closure that takes a key-value pair as its
  ///   argument and returns a Boolean value indicating whether it should be
  ///   included in the returned dictionary.
  ///
  /// - Returns: A dictionary of the key-value pairs that `isIncluded` allows.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Self {
    let result = try _root.filter(.top, isIncluded)
    guard let result = result else { return self }
    return PersistentDictionary(_new: result.finalize(.top))
  }
}
