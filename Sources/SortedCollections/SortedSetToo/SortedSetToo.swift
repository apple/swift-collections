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

/// A sorted set collection that uses a skip-list for its underlying storage.
///
/// `SortedSet` provides O(log n) expected time for membership tests,
/// insertions, and removals. It maintains elements in sorted order and
/// implements value semantics using copy-on-write optimization.
public struct SortedSet<TotalOrdering: Orderable> {
  public typealias Element = TotalOrdering.Element

  /// Ensures that the underlying storage is uniquely referenced by this set.
  mutating func _ensureUnique() {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = SkipList(cloning: _storage)
    }
  }

  /// Creates a new sorted set containing the given
  /// strictly increasing list of elements.
  init(strictlyIncreasing values: some Sequence<Element>) {
    self._storage = SkipList(strictlyIncreasing: values)
  }

  /// The underlying object storage for the skip list.
  var _storage: SkipList
}
