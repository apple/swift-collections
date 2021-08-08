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
    guard count > 1 else { return }
    _checkInvariants(index: 0, min: nil, max: nil)
  }

  @inlinable
  internal func _checkInvariants(index: Int, min: Element?, max: Element?) {
    let value = _storage[index]
    if let min = min {
      precondition(value >= min,
                   "Element '\(value)' at index \(index) should be >= '\(min)'")
    }
    if let max = max {
      precondition(value <= max,
                   "Element '\(value)' at index \(index) should be <= '\(max)'")
    }
    if _minMaxHeapIsMinLevel(index) {
      if let left = _leftChildIndex(of: index) {
        _checkInvariants(index: left, min: value, max: max)
      }
      if let right = _rightChildIndex(of: index) {
        _checkInvariants(index: right, min: value, max: max)
      }
    } else {
      if let left = _leftChildIndex(of: index) {
        _checkInvariants(index: left, min: min, max: value)
      }
      if let right = _rightChildIndex(of: index) {
        _checkInvariants(index: right, min: min, max: value)
      }
    }
  }
  #else
  @inlinable
  @inline(__always)
  public func _checkInvariants() {}
  #endif  // COLLECTIONS_INTERNAL_CHECKS
}
