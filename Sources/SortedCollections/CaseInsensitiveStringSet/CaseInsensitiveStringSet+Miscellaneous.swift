//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

extension CaseInsensitiveStringSet {
  /// The number of elements in the set.
  ///
  /// - Complexity: `O(1)`.
  public var count: Int { self.inner.count }

  /// The first element of the set.
  ///
  /// If this set is empty, the value of this property is `nil`.
  public var first: Element? { self.inner.first }

  /// Removes and returns the first element of the set.
  ///
  /// - Returns: The first element of this set if the set is not empty;
  ///   otherwise, `nil`.
  ///
  /// - Complexity: `O(log n)`, where *n* is the length of this set.
  public mutating func popFirst() -> Element? {
    return self.inner.popFirst()
  }

  /// Removes all elements from the set.
  public mutating func removeAll() {
    self.inner.removeAll()
  }
  /// Removes and returns the least-ranked element of the set.
  ///
  /// The set must not be empty.
  ///
  /// - Returns: The removed element.
  ///
  /// - Complexity: `O(log n)`, where *n* is the length of this set.
  @discardableResult
  public mutating func removeFirst() -> Element {
    return self.inner.removeFirst()
  }
  /// Removes the specified number of the least-ranked elements from the set.
  ///
  /// - Parameter k: The number of elements to remove from the set.
  ///   `k` must be greater than or equal to zero and must not exceed the
  ///   number of elements in the set.
  ///
  /// - Complexity: `O(k × log n)`, where *n* is the length of this set.
  public mutating func removeFirst(_ k: Int) {
    self.inner.removeFirst(k)
  }
}
