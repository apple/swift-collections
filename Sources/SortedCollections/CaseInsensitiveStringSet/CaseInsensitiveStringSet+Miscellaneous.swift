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
  public var count: Int { self.underestimatedCount }

  /// The least-ranked element of the set.
  public var first: Element? {
    self.inner._storage.rowHeads.first.map(\.head.value)
  }

  /// Removes all elements from the set.
  public mutating func removeAll() {
    self.inner._ensureUnique()
    self.inner._storage.rowHeads.removeAll(keepingCapacity: true)
  }

  /// Removes all the elements that satisfy the given predicate.
  public mutating func removeAll(
    where shouldBeRemoved: (Element) throws -> Bool
  ) rethrows {
    self.inner._ensureUnique()
    for killTarget in try self.filter(shouldBeRemoved) {  // must be non-lazy
      self.remove(killTarget)
    }
  }

  /// Removes and returns the least-ranked element of the set.
  @discardableResult
  public mutating func removeFirst() -> Element {
    defer { self.removeFirst(1) }

    return self.first!
  }

  /// Removes the specified number of the least-ranked elements from the set.
  public mutating func removeFirst(_ k: Int) {
    self.inner._ensureUnique()
    for _ in 0..<k {
      _ = self.inner._storage.popFirst()
    }
  }
}
