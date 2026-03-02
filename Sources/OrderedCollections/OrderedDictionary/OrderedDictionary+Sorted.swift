//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

extension OrderedDictionary {
  /// Returns a new dictionary sorted using the given predicate as the
  /// comparison between elements.
  ///
  /// When you want to sort a dictionary's key-value pairs and you want the
  /// result to remain an `OrderedDictionary`, pass a closure to this method
  /// that returns `true` when the first key-value pair should be ordered
  /// before the second.
  ///
  /// `areInIncreasingOrder` must be a *strict weak ordering* over the
  /// elements. That is, for any elements `a`, `b`, and `c`, the following
  /// conditions must hold:
  ///
  /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
  /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
  ///   both `true`, then `areInIncreasingOrder(a, c)` is also `true`.
  ///   (Transitive comparability)
  /// - Two elements are *incomparable* if neither is ordered before the other
  ///   according to the predicate. If `a` and `b` are incomparable, and `b`
  ///   and `c` are incomparable, then `a` and `c` are also incomparable.
  ///   (Transitive incomparability)
  ///
  /// The sorting algorithm is guaranteed to be stable. A stable sort
  /// preserves the relative order of elements for which
  /// `areInIncreasingOrder` does not establish an order.
  ///
  /// Note: This method shadows the `Sequence.sorted(by:)` implementation,
  /// which returns an `Array`. If you need an array result, use
  /// `Array(self).sorted(by:)` or `self.elements.sorted(by:)` instead.
  ///
  /// - Parameter areInIncreasingOrder: A predicate that returns `true` if its
  ///   first argument should be ordered before its second argument; otherwise,
  ///   `false`. The predicate receives key-value pairs as its arguments.
  ///
  /// - Returns: A new `OrderedDictionary` containing the same key-value pairs
  ///   as this dictionary, sorted by the given predicate.
  ///
  /// - Complexity: O(*n* log *n*), where *n* is the length of the collection.
  @inlinable
  public func sorted(
    by areInIncreasingOrder: (Element, Element) throws -> Bool
  ) rethrows -> Self {
    var copy = self
    try copy.sort(by: areInIncreasingOrder)
    return copy
  }
}

extension OrderedDictionary where Key: Comparable {
  /// Returns a new dictionary with its key-value pairs sorted in ascending
  /// order by key.
  ///
  /// You can sort a dictionary whose keys conform to the `Comparable`
  /// protocol by calling this method. Key-value pairs are sorted in ascending
  /// key order.
  ///
  ///     let dict: OrderedDictionary = [3: "three", 1: "one", 2: "two"]
  ///     let sorted = dict.sorted()
  ///     print(sorted)
  ///     // Prints "[1: "one", 2: "two", 3: "three"]"
  ///     print(type(of: sorted))
  ///     // Prints "OrderedDictionary<Int, String>"
  ///
  /// Note: This method shadows the `Sequence.sorted()` implementation, which
  /// would produce a compile error for `OrderedDictionary` because its
  /// `Element` (a key-value tuple) does not conform to `Comparable`. If you
  /// need an array result, use `Array(self).sorted { $0.key < $1.key }` or
  /// `self.elements.sorted { $0.key < $1.key }` instead.
  ///
  /// The sorting algorithm is guaranteed to be stable. A stable sort
  /// preserves the relative order of elements that compare as equal.
  ///
  /// - Returns: A new `OrderedDictionary` containing the same key-value pairs
  ///   as this dictionary, sorted in ascending key order.
  ///
  /// - Complexity: O(*n* log *n*), where *n* is the length of the collection.
  @inlinable
  public func sorted() -> Self {
    var copy = self
    copy.sort()
    return copy
  }
}
