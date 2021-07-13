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

extension SortedSet {
  /// Accesses the member at the specified position.
  ///
  /// - Parameter position: The position of the key-value pair to access.
  ///     `position` must be a valid index of the sorted set and not equal
  ///     to `endIndex`.
  /// - Returns: A member of the set.
  /// - Complexity: O(1)
  @inlinable
  public subscript(position: Index) -> Element {
    position._index.ensureValid(for: self._root)
    return self._root[position._index].key
  }
}
