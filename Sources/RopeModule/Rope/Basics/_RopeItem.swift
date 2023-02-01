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

/// An internal protocol describing a summarizable entity that isn't a full `_RopeElement`.
///
/// Used as an implementation detail to increase code reuse across internal nodes and leaf nodes.
/// (Ideally `_Rope.Node` would just conform to the full `_RopeElement` protocol on its own, but
/// while that's an obvious refactoring idea, it hasn't happened yet.)
internal protocol _RopeItem<Summary> {
  associatedtype Summary: _RopeSummary

  var summary: Summary { get }
}

extension Sequence where Element: _RopeItem {
  func _sum() -> Element.Summary {
    self.reduce(into: .zero) { $0.add($1.summary) }
  }
}

extension _Rope: _RopeItem {
  typealias Summary = Element.Summary
  var summary: Summary {
    guard _root != nil else { return .zero }
    return root.summary
  }
}

extension _Rope {
  /// A trivial wrapper around a rope's Element type, giving it `_RopeItem` conformance without
  /// having to make the protocol public.
  internal struct Item {
    var value: Element
    init(_ value: Element) { self.value = value }
  }
}

extension _Rope.Item: _RopeItem {
  typealias Summary = _Rope.Summary
  var summary: Summary { value.summary }
}

extension _Rope.Item: CustomStringConvertible {
  var description: String {
    "\(value)"
  }
}

extension _Rope.Item {
  var isEmpty: Bool { value.isEmpty }
  var isUndersized: Bool { value.isUndersized }
  mutating func rebalance(nextNeighbor right: inout Self) -> Bool {
    value.rebalance(nextNeighbor: &right.value)
  }
  mutating func rebalance(prevNeighbor left: inout Self) -> Bool {
    value.rebalance(prevNeighbor: &left.value)
  }

  typealias Index = Element.Index
  mutating func split(at index: Index) -> Self {
    Self(self.value.split(at: index))
  }
}
