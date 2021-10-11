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

/// An unordered, counted multiset.
@frozen
public struct CountedSet<Element: Hashable> {
  @usableFromInline
  internal var _storage = [Element: Int]()

  /// Creates an empty counted set with preallocated space for at least the
  /// specified number of unique elements.
  ///
  /// - Parameter minimumCapacity: The minimum number of elements that the
  ///   newly created counted set should be able to store without reallocating
  ///   its storage buffer.
  @inlinable
  public init(minimumCapacity: Int) {
    self._storage = .init(minimumCapacity: minimumCapacity)
  }
}
