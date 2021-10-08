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

import Swift
import Foundation

extension Heap {
  #if COLLECTIONS_INTERNAL_CHECKS
  /// Visits each item in the heap in depth-first order, verifying that the
  /// contents satisfy the min-max heap property.
  @inlinable
  @inline(never)
  internal func _checkInvariants() {
    if let (value, node, boundary) = _someHeapViolation() {
      switch boundary {
      case .lessThan(let min):
        preconditionFailure(
          "Element \(value) at \(node) is less than min \(min)"
        )
      case .greaterThan(let max):
        preconditionFailure(
          "Element \(value) at \(node) is greater than max \(max)"
        )
      }
    }
  }
  #else
  @inlinable
  @inline(__always)
  public func _checkInvariants() {}
  #endif  // COLLECTIONS_INTERNAL_CHECKS

  /// Returns any violation of the min-max heap property.
  @inlinable
  internal func _someHeapViolation()
  -> (value: Element, node: _Node, kind: _BoundaryViolation)? {
    guard !_storage.isEmpty else { return nil }

    /// Returns any violation of the min-max heap property within the sub-heap
    /// whose root is at the given node for the given value bounds.
    func _someSubHeapViolation(node: _Node, min: Element?, max: Element?)
    -> (value: Element, node: _Node, kind: _BoundaryViolation)? {
      // Check the sub-heap's root's bounds.
      let value = _storage[node.offset]
      if let min = min, value < min {
        return (value, node, .lessThan(min: min))
      }
      if let max = max, value > max {
        return (value, node, .greaterThan(max: max))
      }

      // Check the child sub-heaps.
      var nextMin = min, nextMax = max
      if node.isMinLevel {
        nextMin = value
      } else {
        nextMax = value
      }

      if case let leftNode = node.leftChild(),
         leftNode.offset < count,
         let result = _someSubHeapViolation(node: leftNode, min: nextMin,
                                            max: nextMax) {
        return result
      }
      if case let rightNode = node.rightChild(),
         rightNode.offset < count,
         let result = _someSubHeapViolation(node: rightNode, min: nextMin,
                                            max: nextMax) {
        return result
      }
      return nil
    }

    return _someSubHeapViolation(node: .root, min: nil, max: nil)
  }

  /// The manner the min-max heap property is violated.
  @usableFromInline
  internal enum _BoundaryViolation {
    /// An element had a value less than the supplied lower bound.
    case lessThan(min: Element)
    /// An element had a value greater than the supplied upper bound.
    case greaterThan(max: Element)
  }
}
