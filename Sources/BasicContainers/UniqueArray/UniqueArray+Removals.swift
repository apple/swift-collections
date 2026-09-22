//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Removes all elements from the array, preserving its
  /// allocated capacity.
  ///
  /// - Complexity: O(*n*), where *n* is the original count of the array.
  @inlinable
  @inline(__always)
  public mutating func removeAll() {
    _storage.removeAll()
  }

  /// Removes and returns the element at the specified position.
  ///
  /// All the elements following the specified position are moved to close the
  /// gap.
  ///
  /// - Parameter index: The position of the element to remove. `index` must be
  ///   a valid index of the array that is not equal to the end index.
  ///   On return, `index` is updated to address the position following the
  ///   removed element.
  /// - Returns: The removed element.
  ///
  /// - Complexity: O(`self.count`)
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func remove(at index: inout Int) -> Element {
    _storage.remove(at: &index)
  }

  /// Removes and returns the element at the specified position.
  ///
  /// All the elements following the specified position are moved to close the
  /// gap.
  ///
  /// - Parameter index: The position of the element to remove. `index` must be
  ///   a valid index of the array that is not equal to the end index.
  /// - Returns: The removed element.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    _storage.remove(at: index)
  }


  /// Removes and returns the last element of the array.
  ///
  /// The array must not be empty.
  ///
  /// - Returns: The last element of the original array.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func removeLast() -> Element {
    _storage.removeLast()
  }

  /// Removes and discards the specified number of elements from the end of the
  /// array.
  ///
  /// Attempting to remove more elements than exist in the array triggers a
  /// runtime error.
  ///
  /// - Parameter k: The number of elements to remove from the array.
  ///   `k` must be greater than or equal to zero and must not exceed
  ///    the count of the array.
  ///
  /// - Complexity: O(`k`)
  @inlinable
  public mutating func removeLast(_ k: Int) {
    _storage.removeLast(k)
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// All the elements following the specified subrange are moved to close the
  /// resulting gap.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds
  ///   of the range must be valid indices of the array.
  ///
  /// - Complexity: O(`self.count`)
  @inlinable
  @discardableResult
  public mutating func removeSubrange(_  bounds: Range<Int>) -> Int {
    _storage.removeSubrange(bounds)
  }

  /// Removes the specified subrange of elements from the array.
  ///
  /// - Parameter bounds: The subrange of the array to remove. The bounds
  ///   of the range must be valid indices of the array.
  ///
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func removeSubrange(
    _  bounds: some RangeExpression<Int>
  ) -> Int {
    // FIXME: Remove this in favor of the DrainableContainer algorithm.
    removeSubrange(bounds.relative(to: indices))
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Removes and returns the last element of the array, if there is one.
  ///
  /// - Returns: The last element of the array if the array is not empty;
  ///    otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func popLast() -> Element? {
    // FIXME: Remove this in favor of the DrainableContainer algorithm.
    if isEmpty { return nil }
    return removeLast()
  }
}
