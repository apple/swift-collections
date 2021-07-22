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
  /// - Complexity: O(`log n`) where `n` is the number of members in the
  ///   sorted set.
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
  /// - Complexity: O(`log n`) where `n` is the number of members in the
  ///   sorted set.
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func remove(_ member: Element) -> Element? {
    return self._root.removeAnyElement(forKey: member)?.key
  }
  
  // MARK: Combining Sets
  // TODO: add optimized implementations
  @inlinable
  public func union(_ other: __owned Self) -> Self {
    var newSet = self
    newSet.formUnion(other)
    return newSet
  }
  
  @inlinable
  public mutating func formUnion(_ other: __owned Self) {
    for element in other {
      self.insert(element)
    }
  }
  
  @inlinable
  public func intersection(_ other: Self) -> Self {
    var newSet = SortedSet<Element>()
    for element in self {
      if other.contains(element) {
        newSet.insert(element)
      }
    }
    return newSet
  }
  
  @inlinable
  public mutating func formIntersection(_ other: Self) {
    for element in self {
      if !other.contains(element) {
        self.remove(element)
      }
    }
  }
  
  @inlinable
  public func symmetricDifference(_ other: Self) -> Self {
    var newSet = self.union(other)
    newSet.subtract(self.intersection(other))
    return newSet
  }
  
  @inlinable
  public mutating func formSymmetricDifference(_ other: Self) {
    self.formUnion(other)
    self.subtract(self.intersection(other))
  }
  
  // MARK: Comparing Sets
  /// Returns a Boolean value that indicates whether the set is a subset of another set.
  ///
  /// Set _A_ is a subset of another set _B_ if every member of _A_ is also a member of _B_.
  ///
  /// - Parameter other: A set of the same type as the current set.
  /// - Returns: `true` if the set is a subset of other; otherwise, `false`.
  @inlinable
  public func isSubset(of other: SortedSet<Element>) -> Bool {
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
}
