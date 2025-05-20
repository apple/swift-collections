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
  public struct SubSequence {
    @usableFromInline
    internal typealias _TreeSubSequence = _Tree.SubSequence
    
    @usableFromInline
    internal let _subSequence: _TreeSubSequence
    
    @inlinable
    @inline(__always)
    internal init(_ _subSequence: _TreeSubSequence) {
      self._subSequence = _subSequence
    }
    
    /// The underlying collection of the subsequence.
    @inlinable
    @inline(__always)
    internal var base: SortedDictionary { SortedDictionary(_rootedAt: _subSequence.base) }
  }
}

extension SortedDictionary.SubSequence: @unchecked Sendable
where Key: Sendable, Value: Sendable {}

extension SortedDictionary.SubSequence: Sequence {
  public typealias Element = SortedDictionary.Element
  
  
  public struct Iterator: IteratorProtocol {
    @usableFromInline
    internal var _iterator: _TreeSubSequence.Iterator
    
    @inlinable
    @inline(__always)
    internal init(_ _iterator: _TreeSubSequence.Iterator) {
      self._iterator = _iterator
    }
    
    /// Advances to the next element and returns it, or nil if no next element exists.
    ///
    /// - Returns: The next element in the underlying sequence, if a next element exists;
    ///     otherwise, `nil`.
    /// - Complexity: O(1) amortized over the entire sequence.
    @inlinable
    @inline(__always)
    public mutating func next() -> Element? {
      _iterator.next()
    }
  }
  
  /// Returns an iterator over the elements of the subsequence.
  ///
  /// - Complexity: O(log(`self.count`))
  @inlinable
  @inline(__always)
  public __consuming func makeIterator() -> Iterator {
    Iterator(_subSequence.makeIterator())
  }
}

extension SortedDictionary.SubSequence.Iterator: @unchecked Sendable
where Key: Sendable, Value: Sendable {}

extension SortedDictionary.SubSequence: BidirectionalCollection {
  public typealias Index = SortedDictionary.Index
  public typealias SubSequence = Self
  
  /// The position of the first element in a nonempty subsequence.
  ///
  /// If the collection is empty, `startIndex` is equal to `endIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var startIndex: Index { Index(_subSequence.startIndex) }
  
  /// The subsequence's "past the end" position---that is, the position one
  /// greater than the last valid subscript argument.
  ///
  /// If the collection is empty, `endIndex` is equal to `startIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var endIndex: Index { Index(_subSequence.endIndex) }
  
  /// The number of elements in the subsequence.
  /// 
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var count: Int { _subSequence.count }
  
  /// Returns the distance between two indices.
  ///
  /// - Parameters:
  ///   - start: A valid index of the collection.
  ///   - end: Another valid index of the collection. If end is equal to start, the result is zero.
  /// - Returns: The distance between start and end. The result can be negative.
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public func distance(from start: Index, to end: Index) -> Int {
    start._index.ensureValid(forTree: _subSequence.base)
    end._index.ensureValid(forTree: _subSequence.base)
    return _subSequence.distance(from: start._index, to: end._index)
  }
  
  
  /// Returns the position immediately after the given index.
  ///
  /// - Parameter i: A valid index of the collection. `i` must be less than `endIndex`.
  /// - Returns: The index value immediately after `i`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  @inline(__always)
  public func index(after i: Index) -> Index {
    i._index.ensureValid(forTree: _subSequence.base)
    return Index(_subSequence.index(after: i._index))
  }
  
  /// Replaces the given index with its successor.
  ///
  /// - Parameter i: A valid index of the collection. `i` must be less than `endIndex`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  @inline(__always)
  public func formIndex(after i: inout Index) {
    i._index.ensureValid(forTree: _subSequence.base)
    return _subSequence.formIndex(after: &i._index)
  }
  
  
  /// Returns the position immediately before the given index.
  ///
  /// - Parameter i: A valid index of the collection. `i` must be greater
  ///     than `startIndex`.
  /// - Returns: The index value immediately before `i`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  @inline(__always)
  public func index(before i: Index) -> Index {
    i._index.ensureValid(forTree: _subSequence.base)
    return Index(_subSequence.index(before: i._index))
  }
  
  /// Replaces the given index with its predecessor.
  ///
  /// - Parameter i: A valid index of the collection. `i` must be greater
  ///     than `startIndex`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  @inline(__always)
  public func formIndex(before i: inout Index) {
    i._index.ensureValid(forTree: _subSequence.base)
    _subSequence.formIndex(before: &i._index)
  }
  
    
  /// Returns an index that is the specified distance from the given index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  /// - Returns: An index offset by `distance` from the index `i`. If `distance`
  ///     is positive, this is the same value as the result of `distance` calls to
  ///     `index(after:)`. If `distance` is negative, this is the same value as the
  ///     result of `abs(distance)` calls to `index(before:)`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  @inline(__always)
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    i._index.ensureValid(forTree: _subSequence.base)
    return Index(_subSequence.index(i._index, offsetBy: distance))
  }
  
  /// Offsets the given index by the specified distance.
  ///
  /// The value passed as distance must not offset i beyond the bounds of the collection.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  @inline(__always)
  internal func formIndex(_ i: inout Index, offsetBy distance: Int) {
    i._index.ensureValid(forTree: _subSequence.base)
    _subSequence.formIndex(&i._index, offsetBy: distance)
  }
  
  
  /// Returns an index that is the specified distance from the given index, unless that distance is beyond
  /// a given limiting index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  ///   - limit: A valid index of the collection to use as a limit. If `distance > 0`, a limit that is less
  ///       than `i` has no effect. Likewise, if `distance < 0`, a limit that is greater than `i` has
  ///       no effect.
  /// - Returns: An index offset by `distance` from the index `i`, unless that index would be
  ///     beyond `limit` in the direction of movement. In that case, the method returns `nil`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  @inline(__always)
  public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    i._index.ensureValid(forTree: _subSequence.base)
    limit._index.ensureValid(forTree: _subSequence.base)
    
    if let i = _subSequence.index(i._index, offsetBy: distance, limitedBy: limit._index) {
      return Index(i)
    } else {
      return nil
    }
  }
  
  /// Offsets the given index by the specified distance, or so that it equals the given limiting index.
  ///
  /// - Parameters:
  ///   - i: A valid index of the collection.
  ///   - distance: The distance to offset `i`.
  ///   - limit: A valid index of the collection to use as a limit. If `distance > 0`, a limit that is less
  ///       than `i` has no effect. Likewise, if `distance < 0`, a limit that is greater than `i` has
  ///       no effect.
  /// - Returns: `true` if `i` has been offset by exactly `distance` steps without going beyond
  ///     `limit`; otherwise, `false`. When the return value is `false`, the value of `i` is
  ///     equal to `limit`.
  /// - Complexity: O(log(`self.count`)) in the worst-case.
  @inlinable
  @inline(__always)
  internal func formIndex(_ i: inout Index, offsetBy distance: Int, limitedBy limit: Self.Index) -> Bool {
    i._index.ensureValid(forTree: _subSequence.base)
    limit._index.ensureValid(forTree: _subSequence.base)
    return _subSequence.formIndex(&i._index, offsetBy: distance, limitedBy: limit._index)
  }
  
  @inlinable
  @inline(__always)
  public subscript(position: Index) -> Element {
    position._index.ensureValid(forTree: _subSequence.base)
    return _subSequence[position._index]
  }
  
  @inlinable
  public subscript(bounds: Range<Index>) -> SubSequence {
    bounds.lowerBound._index.ensureValid(forTree: _subSequence.base)
    bounds.upperBound._index.ensureValid(forTree: _subSequence.base)
    
    let bound = bounds.lowerBound._index..<bounds.upperBound._index
    
    return SubSequence(_subSequence[bound])
  }
  
  @inlinable
  @inline(__always)
  public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {
    _subSequence._failEarlyRangeCheck(
      index._index,
      bounds: bounds.lowerBound._index..<bounds.upperBound._index
    )
  }

  @inlinable
  @inline(__always)
  public func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>) {
    _subSequence._failEarlyRangeCheck(
      range.lowerBound._index..<range.upperBound._index,
      bounds: bounds.lowerBound._index..<bounds.upperBound._index
    )
  }
}

extension SortedDictionary.SubSequence: Equatable where Value: Equatable {
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

extension SortedDictionary.SubSequence: Hashable where Key: Hashable, Value: Hashable {
  /// Hashes the essential components of this value by feeding them
  /// into the given hasher.
  /// - Parameter hasher: The hasher to use when combining
  ///     the components of this instance.
  /// - Complexity: O(`self.count`)
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.count)
    for (key, value) in self {
      hasher.combine(key)
      hasher.combine(value)
    }
  }
}
