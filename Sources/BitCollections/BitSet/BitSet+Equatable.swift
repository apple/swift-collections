//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BitSet: Equatable {
  /// Returns a Boolean value indicating whether two values are equal. Two
  /// bit sets are considered equal if they contain the same elements.
  ///
  /// - Complexity: O(*max*), where *max* is value of the largest member of either set.
  public static func ==(left: Self, right: Self) -> Bool {
    left._storage == right._storage
  }
}
