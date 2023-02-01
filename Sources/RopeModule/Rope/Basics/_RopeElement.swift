//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// The element type of an augmented tree.
protocol _RopeElement {
  /// The commutative group that is used to augment the tree.
  associatedtype Summary: _RopeSummary
  associatedtype Index: Comparable

  /// Returns the summary of `self`.
  var summary: Summary { get }

  var isEmpty: Bool { get }
  var isUndersized: Bool { get }

  /// Check the consistency of `self`.
  func invariantCheck()

  mutating func rebalance(nextNeighbor right: inout Self) -> Bool
  mutating func rebalance(prevNeighbor left: inout Self) -> Bool
  mutating func split(at index: Index) -> Self
}

extension _RopeElement {
  mutating func rebalance(prevNeighbor left: inout Self) -> Bool {
    guard left.rebalance(nextNeighbor: &self) else { return false }
    swap(&self, &left)
    return true
  }
}

