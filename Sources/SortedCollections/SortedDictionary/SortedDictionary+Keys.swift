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

extension SortedDictionary {
  /// A view of an sorted dictionary's Keys as a standalone collection.
  public struct Keys {
    @usableFromInline
    internal var _base: SortedDictionary
    
    @inlinable
    @inline(__always)
    internal init(_base: SortedDictionary) {
      self._base = _base
    }
  }
}

extension SortedDictionary.Keys: Sendable
where Key: Sendable, Value: Sendable {}

extension SortedDictionary.Keys: Sequence {
  /// The element type of the collection.
  public typealias Element = Key

  /// The type that allows iteration over the collection's elements.
  public struct Iterator: IteratorProtocol {
    @usableFromInline
    internal var _iterator: SortedDictionary.Iterator
    
    @inlinable
    @inline(__always)
    internal init(_ _iterator: SortedDictionary.Iterator) {
      self._iterator = _iterator
    }
    
    @inlinable
    @inline(__always)
    public mutating func next() -> Element? {
      _iterator.next()?.key
    }
  }
  
  @inlinable
  @inline(__always)
  public __consuming func makeIterator() -> Iterator {
    Iterator(_base.makeIterator())
  }
}

extension SortedDictionary.Keys.Iterator: Sendable
where Key: Sendable, Value: Sendable {}

extension SortedDictionary.Keys: BidirectionalCollection {
  /// The index type for a dictionary's keys view.
  public typealias Index = SortedDictionary.Index
  
  /// The number of elements in the collection.
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var count: Int { self._base.count }
  
  /// A Boolean value that indicates whether the collection is empty.
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var isEmpty: Bool { self._base.isEmpty }
  
  /// The position of the first element in a nonempty collection.
  ///
  /// If the collection is empty, `startIndex` is equal to `endIndex`.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  public var startIndex: Index { self._base.startIndex }
  
  /// The collection's "past the end" position---that is, the position one
  /// greater than the last valid subscript argument.
  ///
  /// If the collection is empty, `endIndex` is equal to `startIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var endIndex: Index { self._base.endIndex }
  
  /// Returns the distance between two indices.
  ///
  /// - Parameters:
  ///   - start: A valid index of the collection.
  ///   - end: Another valid index of the collection. If `end` is equal to
  ///     `start`, the result is zero.
  ///
  /// - Returns: The distance between `start` and `end`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func distance(from start: Index, to end: Index) -> Int {
    self._base.distance(from: start, to: end)
  }
  
  /// Replaces the given index with its successor.
  ///
  /// The specified index must be a valid index less than `endIndex`, or the
  /// returned value won't be a valid index in the collection.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  public func formIndex(after index: inout Index) {
    self._base.formIndex(after: &index)
  }
  
  /// Returns the position immediately after the given index.
  ///
  /// The specified index must be a valid index less than `endIndex`, or the
  /// returned value won't be a valid index in the collection.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Returns: The index immediately after `i`.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  public func index(after index: Index) -> Index {
    self._base.index(after: index)
  }
  
  /// Replaces the given index with its successor.
  ///
  /// The specified index must be a valid index less than `endIndex`, or the
  /// returned value won't be a valid index in the collection.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  public func formIndex(before index: inout Index) {
    self._base.formIndex(before: &index)
  }
  
  /// Returns the position immediately before the given index.
  ///
  /// The specified index must be a valid index greater than `startIndex`, or
  /// the returned value won't be a valid index in the collection.
  ///
  /// - Parameter i: A valid index of the collection.
  ///
  /// - Returns: The index immediately before `i`.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  public func index(before index: Index) -> Index {
    self._base.index(before: index)
  }
  
  /// Offsets the given index by the specified distance.
  ///
  /// The value passed as `distance` must not offset `i` beyond the bounds of
  /// the collection.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  public func formIndex(_ i: inout Index, offsetBy distance: Int) {
    self._base.formIndex(&i, offsetBy: distance)
  }
  
  /// Returns an index that is the specified distance from the given index.
  ///
  /// The value passed as `distance` must not offset `i` beyond the bounds of
  /// the collection, or the returned value will not be a valid index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  ///
  /// - Returns: An index offset by `distance` from the index `i`. If `distance`
  ///   is positive, this is the same value as the result of `distance` calls to
  ///   `index(after:)`. If `distance` is negative, this is the same value as
  ///   the result of `abs(distance)` calls to `index(before:)`.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    self._base.index(i, offsetBy: distance)
  }
}

extension SortedDictionary.Keys {
  /// Accesses the element at the specified position.
  ///
  /// - Parameter index: The position of the element to access. `index` must be
  ///   greater than or equal to `startIndex` and less than `endIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public subscript(position: Index) -> Key {
    self._base[position].key
  }
}

extension SortedDictionary.Keys: Equatable {
  /// Returns a Boolean value indicating whether two values are equal.
  ///
  /// Equality is the inverse of inequality. For any values `a` and `b`,
  /// `a == b` implies that `a != b` is false.
  ///
  /// - Parameters:
  ///   - lhs: A value to compare.
  ///   - rhs: Another value to compare.
  /// - Complexity: O(`self.count`)
  @inlinable
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    if lhs.count != rhs.count { return false }
    for (e1, e2) in zip(lhs, rhs) {
      if e1 == e2 {
        return false
      }
    }
    return true
  }
}

extension SortedDictionary.Keys: Hashable where Key: Hashable {
  /// Hashes the essential components of this value by feeding them
  /// into the given hasher.
  /// - Parameter hasher: The hasher to use when combining
  ///     the components of this instance.
  /// - Complexity: O(`self.count`)
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.count)
    for key in self {
      hasher.combine(key)
    }
  }
}
