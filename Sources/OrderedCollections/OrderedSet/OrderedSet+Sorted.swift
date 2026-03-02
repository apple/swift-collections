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

extension OrderedSet {
  /// Returns a new set sorted using the given predicate as the comparison
  /// between elements.
  ///
  /// When you want to sort a set of elements that don't conform to the
  /// `Comparable` protocol, pass a closure to this method that returns
  /// `true` when the first element should be ordered before the second.
  ///
  /// Alternatively, use this method to sort a set of elements that do conform
  /// to `Comparable` when you want the sort to be descending instead of
  /// ascending. Pass the greater-than operator (`>`) as the predicate.
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
  /// - Parameter areInIncreasingOrder: A predicate that returns `true` if its
  ///   first argument should be ordered before its second argument; otherwise,
  ///   `false`.
  ///
  /// - Returns: A new `OrderedSet` containing the elements of this set,
  ///   sorted by the given predicate.
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

extension OrderedSet where Element: Comparable {
  /// Returns a new set with its elements sorted in ascending order.
  ///
  /// You can sort a set of elements that conform to the `Comparable`
  /// protocol by calling this method. Elements are sorted in ascending order.
  ///
  /// Here's an example of sorting a set of students' names. Strings in Swift
  /// conform to the `Comparable` protocol, so the names are sorted in
  /// ascending order according to the less-than operator (`<`).
  ///
  ///     let students: OrderedSet = ["Kofi", "Abena", "Peter", "Kweku", "Akosua"]
  ///     let sorted = students.sorted()
  ///     print(sorted)
  ///     // Prints "["Abena", "Akosua", "Kofi", "Kweku", "Peter"]"
  ///     print(type(of: sorted))
  ///     // Prints "OrderedSet<String>"
  ///
  /// To sort the elements of your set in descending order, pass the
  /// greater-than operator (`>`) to the `sorted(by:)` method.
  ///
  ///     let descending = students.sorted(by: >)
  ///     print(descending)
  ///     // Prints "["Peter", "Kweku", "Kofi", "Akosua", "Abena"]"
  ///
  /// The sorting algorithm is guaranteed to be stable. A stable sort
  /// preserves the relative order of elements that compare as equal.
  ///
  /// - Returns: A new `OrderedSet` containing the elements of this set,
  ///   sorted in ascending order.
  ///
  /// - Complexity: O(*n* log *n*), where *n* is the length of the collection.
  @inlinable
  public func sorted() -> Self {
    var copy = self
    copy.sort()
    return copy
  }
}
