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

extension SortedSet: SetAlgebra {
  
  // MARK: Testing for Membership
  
  /// Returns a Boolean value that indicates whether the given element exists in the set.
  /// - Complexity: O(`log n`) where `n` is the number of members in the
  ///   sorted set.
  @inlinable
  @inline(__always)
  public func contains(_ member: Element) -> Bool {
    self._root.contains(key: member)
  }
  
  
  // MARK: Adding Elements
  
  /// Inserts the given element in the set if it is not already present.
  ///
  /// - Parameter newMember:
  /// - Returns: `(true, newMember)` if `newMember` was not contained in the
  ///     set. If an element equal to `newMember` was already contained in the set, the
  ///     method returns `(false, oldMember)`, where `oldMember` is the element
  ///     that was equal to `newMember`. In some cases, `oldMember` may be
  ///     distinguishable from `newMember` by identity comparison or some other means.
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func insert(
    _ newMember: Element
  ) -> (inserted: Bool, memberAfterInsert: Element) {
    if let oldKey = self._root.updateAnyValue((), forKey: newMember, updatingKey: false)?.key {
      return (inserted: false, memberAfterInsert: oldKey)
    } else {
      return (inserted: true, memberAfterInsert: newMember)
    }
  }
  
  /// Inserts the given element into the set unconditionally.
  ///
  /// - Parameter newMember: An element to insert into the set.
  /// - Returns: An element equal to `newMember` if the set already contained such a
  ///     member; otherwise, `nil`. In some cases, the returned element may be distinguishable
  ///     from `newMember` by identity comparison or some other means.
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func update(with newMember: Element) -> Element? {
    return self._root.updateAnyValue((), forKey: newMember, updatingKey: true)?.key
  }
  
  /// Removes the given element from the set.
  ///
  /// - Parameter member: The element of the set to remove.
  ///
  /// - Returns: The element equal to `member` if `member` is contained in the
  ///    set; otherwise, `nil`. In some cases, the returned element may be
  ///    distinguishable from `newMember` by identity comparison or some other
  ///    means.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func remove(_ member: Element) -> Element? {
    return self._root.removeAnyElement(forKey: member)?.key
  }
  
  // MARK: Combining Sets
  /// Returns a new set with the elements of both this and the given set.
  ///
  /// - Parameter other: A sorted set of the same type as the current set.
  /// - Returns: A new sorted set with the unique elements of this set and `other`.
  /// - Note: if this set and `other` contain elements that are equal but
  ///   distinguishable (e.g. via `===`), the element from the second set is inserted.
  /// - Complexity: O(`self.count` + `other.count`)
  @inlinable
  public func union(_ other: __owned Self) -> Self {
    var builder = _Tree.Builder(deduplicating: true)
     
    var it1 = self.makeIterator()
    var it2 = other.makeIterator()
    
    var e1 = it1.next()
    var e2 = it2.next()
    
    // While both sequences have a value, consume the smallest element.
    while let el1 = e1, let el2 = e2 {
      if el1 < el2 {
        builder.append(el1)
        e1 = it1.next()
      } else {
        builder.append(el2)
        e2 = it2.next()
      }
    }
    
    while let el1 = e1 {
      builder.append(el1)
      e1 = it1.next()
    }
    
    while let el2 = e2 {
      builder.append(el2)
      e2 = it2.next()
    }
    
    return SortedSet(_rootedAt: builder.finish())
  }
  
  /// Adds the elements of the given set to the set.
  ///
  /// - Parameter other: A set of the same type as the current set.
  /// - Note: if this set and `other` contain elements that are equal but
  ///   distinguishable (e.g. via `===`), the element from the second set is inserted.
  /// - Complexity: O(`self.count` + `other.count`)
  @inlinable
  public mutating func formUnion(_ other: __owned Self) {
    self = union(other)
  }
  
  /// Returns a new set with the elements that are common to both this set and
  /// the given set.
  ///
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: A new set.
  /// - Note: if this set and `other` contain elements that are equal but
  ///   distinguishable (e.g. via `===`), which of these elements is present
  ///   in the result is unspecified.
  /// - Complexity: O(`self.count` + `other.count`)
  @inlinable
  public func intersection(_ other: Self) -> Self {
    // We'll run this such that 'self' is the smallest array
    // TODO: might want to consider uniqueness to minimize CoW copies.
    var builder = _Tree.Builder(deduplicating: true)
    
    var it1 = self.makeIterator()
    var it2 = other.makeIterator()
    
    var e1 = it1.next()
    var e2 = it2.next()
    
    // While both sequences have a value, consume the smallest element.
    while let el1 = e1, let el2 = e2 {
      if el1 < el2 {
        e1 = it1.next()
      } else if el1 == el2 {
        builder.append(el2)
        e1 = it1.next()
        e2 = it2.next()
      } else {
        // el1 > el1
        e2 = it2.next()
      }
    }
    
    return SortedSet(_rootedAt: builder.finish())
  }
  
  /// Removes the elements of this set that aren't also in the given set.
  ///
  /// - Parameter other: A set of the same type as the current set.
  /// - Note: if this set and `other` contain elements that are equal but
  ///   distinguishable (e.g. via `===`), which of these elements is present
  ///   in the result is unspecified.
  /// - Complexity: O(`self.count` + `other.count`)
  @inlinable
  public mutating func formIntersection(_ other: Self) {
    self = intersection(other)
  }
  
  /// Returns a new set with the elements that are either in this set or in the
  /// given set, but not in both.
  ///
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: A new set.
  /// - Complexity: O(`self.count` + `other.count`)
  @inlinable
  public func symmetricDifference(_ other: Self) -> Self {
    var builder = _Tree.Builder(deduplicating: true)
    
    var it1 = self.makeIterator()
    var it2 = other.makeIterator()
    
    var e1 = it1.next()
    var e2 = it2.next()
    
    // While both sequences have a value, consume the smallest element.
    while let el1 = e1, let el2 = e2 {
      if el1 < el2 {
        builder.append(el1)
        e1 = it1.next()
      } else if el2 < el1 {
        builder.append(el2)
        e2 = it2.next()
      } else {
        // e1 == e2
        e1 = it1.next()
        e2 = it2.next()
      }
    }
    
    while let el1 = e1 {
      builder.append(el1)
      e1 = it1.next()
    }
    
    while let el2 = e2 {
      builder.append(el2)
      e2 = it2.next()
    }
    
    return SortedSet(_rootedAt: builder.finish())
  }
  
  /// Removes the elements of the set that are also in the given set and adds
  /// the members of the given set that are not already in the set.
  ///
  /// - Parameter other: A set of the same type.
  /// - Complexity: O(`self.count` + `other.count`)
  @inlinable
  public mutating func formSymmetricDifference(_ other: Self) {
    self = self.symmetricDifference(other)
  }
  
  /// Returns a new set containing the elements of this set that do not occur
  /// in the given set.
  ///
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: A new set.
  /// - Complexity: O(`self.count` + `other.count`)
  @inlinable
  public func subtracting(_ other: Self) -> Self {
    var builder = _Tree.Builder(deduplicating: true)
    
    var it1 = self.makeIterator()
    var it2 = other.makeIterator()
    
    var e1 = it1.next()
    var e2 = it2.next()
    
    // While both sequences have a value, consume the smallest element.
    while let el1 = e1, let el2 = e2 {
      if el1 < el2 {
        builder.append(el1)
        e1 = it1.next()
      } else if el2 < el1 {
        e2 = it2.next()
      } else {
        // e1 == e2
        e1 = it1.next()
        e2 = it2.next()
      }
    }
    
    while let el1 = e1 {
      builder.append(el1)
      e1 = it1.next()
    }
    
    return SortedSet(_rootedAt: builder.finish())
  }
  
  /// Removes the elements of the given set from this set.
  ///
  /// - Parameter other: A set of the same type as the current set.
  /// - Complexity: O(`self.count` + `other.count`)
  @inlinable
  public mutating func subtract(_ other: SortedSet<Element>) {
    self = self.subtracting(other)
  }
  
  // MARK: Comparing Sets
  /// Returns a Boolean value that indicates whether the set is a subset of another set.
  ///
  /// Set _A_ is a subset of another set _B_ if every member of _A_ is also a member of _B_.
  ///
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: `true` if the set is a subset of other; otherwise, `false`.
  /// - Complexity: O(max(`self.count`, `other.count`))
  @inlinable
  public func isSubset(of other: SortedSet<Element>) -> Bool {
    // TODO: could be worthwhile to evaluate recursive approach
    // TODO: in some cases, it could be faster to search from the root each time
    // Searching from the root is faster when:
    //    self.count < other.count / (log(other.count) - 1)
    // This means when `other` is significantly larger than `self`, it may be
    // faster to search from the root each time.
    if self.count > other.count { return false }
    
    var superIterator = other.makeIterator()
    
    for element in self {
      while true {
        // If we exhausted the superset without finding our element, then it
        // does not exist in the superset.
        guard let superElement = superIterator.next() else { return false }

        // If the superElement is greater than element, we won't find element
        // further on in the superset and therefore it doesn't exist in it. Here
        // we can return false
        if superElement > element { return false }
        
        // We did find the element
        if superElement == element { break }
      }
    }
    
    return true
  }
  
  /// Returns a Boolean value that indicates whether this set is a strict
  /// subset of the given set.
  ///
  /// Set *A* is a strict subset of another set *B* if every member of *A* is
  /// also a member of *B* and *B* contains at least one element that is not a
  /// member of *A*.
  ///
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: `true` if the set is a strict subset of `other`; otherwise,
  ///   `false`.
  /// - Complexity: O(`self.count` + `other.count`).
  @inlinable
  public func isStrictSubset(of other: SortedSet<Element>) -> Bool {
    if self.count >= other.count { return false }
    return self.isSubset(of: other)
  }
  
  /// Returns a Boolean value that indicates whether the set has no members in
  /// common with the given set.
  ///
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: `true` if the set has no elements in common with `other`;
  ///   otherwise, `false`.
  /// - Complexity: O(`self.count` + `other.count`).
  @inlinable
  public func isDisjoint(with other: SortedSet<Element>) -> Bool {
    var it1 = self.makeIterator()
    var it2 = other.makeIterator()
    
    var e1 = it1.next()
    var e2 = it2.next()
    
    // While both sequences have a value, consume the smallest element.
    while let el1 = e1, let el2 = e2 {
      if el1 < el2 {
        e1 = it1.next()
      } else if el1 == el2 {
        return false
      } else {
        // el1 > el2
        e2 = it2.next()
      }
    }
    
    return true
  }
}
