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

/// A utility protocol for marking container types (not necessarily
/// conforming to `Sequence` or `Collection`) that provide a
/// fast `contains` operation.
public protocol _FastMembershipCheckable {
  // FIXME: Add as primary associated type on >=5.7
  associatedtype Element: Equatable

  /// Returns a Boolean value that indicates whether the given element exists in `self`.
  ///
  /// - Performance: O(log(*n*)) or better, where *n* is the size
  ///    of `self` (for some definition of "size").
  func contains(_ item: Element) -> Bool
}

extension Set: _FastMembershipCheckable {}
extension Dictionary.Keys: _FastMembershipCheckable {}
