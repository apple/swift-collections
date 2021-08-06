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
  /// Iterates through all the levels in the heap, ensuring that items in min
  /// levels are smaller than all their descendants and items in max levels
  /// are larger than all their descendants.
  ///
  /// The min-max heap indices are structured like this:
  ///
  /// ```
  /// min               0
  /// max        1             2
  /// min      3   4         5     6
  /// max     7 8 9 10     11 12 13 14
  /// min    15...
  /// ...
  /// ```
  ///
  /// The iteration happens in depth-first order, so the descendants of the
  /// element at index 0 are checked to ensure they are >= that element. This is
  /// repeated for each child of the element at index 0 (inverting the
  /// comparison at each level).
  ///
  /// In the case of 7 elements total (spread across 3 levels), the checking
  /// happens in the following order:
  ///
  /// ```
  /// compare >= 0: 1, 3, 4, 2, 5, 6
  /// compare <= 1: 3, 4
  /// compare >= 3: (no children)
  /// compare >= 4: (no children)
  /// compare <= 2: 5, 6
  /// compare >= 5: (no children)
  /// compare >= 6: (no children)
  /// ```
  @inlinable
  @inline(never)
  internal func _checkInvariants() {
    guard count > 1 else { return }
    var indicesToVisit: [Int] = [0]

    while let elementIdx = indicesToVisit.popLast() {
      let element = _storage[elementIdx]

      let isMinLevel = _minMaxHeapIsMinLevel(elementIdx)

      var descendantIndicesToVisit = [Int]()

      // Add the children of this element to the outer loop (as we want to check
      // that they are >= or <= their descendants as well)
      if let rightIdx = _rightChildIndex(of: elementIdx) {
        descendantIndicesToVisit.append(rightIdx)
        indicesToVisit.append(rightIdx)
      }
      if let leftIdx = _leftChildIndex(of: elementIdx) {
        descendantIndicesToVisit.append(leftIdx)
        indicesToVisit.append(leftIdx)
      }

      // Compare the current element against its descendants
      while let idx = descendantIndicesToVisit.popLast() {
        if isMinLevel {
          precondition(element <= _storage[idx],
            "Element '\(_storage[idx])' at index \(idx) should be >= '\(element)'")
        } else {
          precondition(element >= _storage[idx],
            "Element '\(_storage[idx])' at index \(idx) should be <= '\(element)'")
        }

        if let rightIdx = _rightChildIndex(of: idx) {
          descendantIndicesToVisit.append(rightIdx)
        }
        if let leftIdx = _leftChildIndex(of: idx) {
          descendantIndicesToVisit.append(leftIdx)
        }
      }
    }
  }
  #else
  @inlinable
  @inline(__always)
  public func _checkInvariants() {}
  #endif  // COLLECTIONS_INTERNAL_CHECKS
}
