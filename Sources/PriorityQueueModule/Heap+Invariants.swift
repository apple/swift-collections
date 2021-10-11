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

extension Heap {
  #if COLLECTIONS_INTERNAL_CHECKS
  /// Visits each item in the heap in depth-first order, verifying that the
  /// contents satisfy the min-max heap property.
  @inlinable
  @inline(never)
  internal func _checkInvariants() {
    guard count > 1 else { return }
    _checkInvariants(node: .root, min: nil, max: nil)
  }

  @inlinable
  internal func _checkInvariants(node: _Node, min: Element?, max: Element?) {
    let value = _storage[node.offset]
    if let min = min {
      precondition(value >= min,
                   "Element \(value) at \(node) is less than min \(min)")
    }
    if let max = max {
      precondition(value <= max,
                   "Element \(value) at \(node) is greater than max \(max)")
    }
    let left = node.leftChild()
    let right = node.rightChild()
    if node.isMinLevel {
      if left.offset < count {
        _checkInvariants(node: left, min: value, max: max)
      }
      if right.offset < count {
        _checkInvariants(node: right, min: value, max: max)
      }
    } else {
      if left.offset < count {
        _checkInvariants(node: left, min: min, max: value)
      }
      if right.offset < count {
        _checkInvariants(node: right, min: min, max: value)
      }
    }
  }
  #else
  @inlinable
  @inline(__always)
  public func _checkInvariants() {}
  #endif  // COLLECTIONS_INTERNAL_CHECKS
}
