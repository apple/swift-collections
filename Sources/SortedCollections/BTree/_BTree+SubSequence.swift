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

extension _BTree {
  @usableFromInline
  internal struct SubSequence {
    @usableFromInline
    internal let _base: _BTree
    
    @usableFromInline
    internal var _startIndex: Index
    
    @usableFromInline
    internal var _endIndex: Index
    
    @inlinable
    @inline(__always)
    internal init(base: _BTree, bounds: Range<Index>) {
      self._base = base
      self._startIndex = bounds.lowerBound
      self._endIndex = bounds.upperBound
    }
    
    /// The underlying collection of the subsequence.
    @inlinable
    @inline(__always)
    internal var base: _BTree { _base }
  }
}

extension _BTree.SubSequence: Sequence {
  @usableFromInline
  internal typealias Element = _BTree.Element
  
  
  @usableFromInline
  internal struct Iterator: IteratorProtocol {
    @usableFromInline
    internal typealias Element = SubSequence.Element
    
    @usableFromInline
    internal var _iterator: _BTree.Iterator
    
    @usableFromInline
    internal var distanceRemaining: Int
    
    @inlinable
    @inline(__always)
    internal init(_iterator: _BTree.Iterator, distance: Int) {
      self._iterator = _iterator
      self.distanceRemaining = distance
    }
    
    @inlinable
    @inline(__always)
    internal mutating func next() -> Element? {
      if distanceRemaining == 0 {
        return nil
      } else {
        distanceRemaining -= 1
        return _iterator.next()
      }
    }
  }
  
  @inlinable
  @inline(__always)
  internal func makeIterator() -> Iterator {
    let it = _BTree.Iterator(forTree: _base, startingAt: _startIndex)
    let distance = _base.distance(from: _startIndex, to: _endIndex)
    return Iterator(_iterator: it, distance: distance)
  }
}

extension _BTree.SubSequence: BidirectionalCollection {
  @usableFromInline
  internal typealias Index = _BTree.Index
  
  @usableFromInline
  internal typealias SubSequence = Self
  
  
  @inlinable
  @inline(__always)
  internal var startIndex: Index { _startIndex }
  
  @inlinable
  @inline(__always)
  internal var endIndex: Index { _endIndex }
  
  @inlinable
  @inline(__always)
  internal var count: Int { _base.distance(from: _startIndex, to: _endIndex) }
  
  @inlinable
  @inline(__always)
  internal func distance(from start: Index, to end: Index) -> Int {
    _base.distance(from: start, to: end)
  }
  
  @inlinable
  @inline(__always)
  internal func index(before i: Index) -> Index {
    _base.index(before: i)
  }
  
  @inlinable
  @inline(__always)
  internal func formIndex(before i: inout Index) {
    _base.formIndex(before: &i)
  }
  
  
  @inlinable
  @inline(__always)
  internal func index(after i: Index) -> Index {
    _base.index(after: i)
  }
  
  @inlinable
  @inline(__always)
  internal func formIndex(after i: inout Index) {
    _base.formIndex(after: &i)
  }
  
  @inlinable
  @inline(__always)
  internal func index(_ i: Index, offsetBy distance: Int) -> Index {
    _base.index(i, offsetBy: distance)
  }
  
  @inlinable
  @inline(__always)
  internal func formIndex(_ i: inout Index, offsetBy distance: Int) {
    _base.formIndex(&i, offsetBy: distance)
  }
  
  @inlinable
  @inline(__always)
  internal func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    _base.index(i, offsetBy: distance, limitedBy: limit)
  }
  
  @inlinable
  @inline(__always)
  internal func formIndex(_ i: inout Index, offsetBy distance: Int, limitedBy limit: Self.Index) -> Bool {
    _base.formIndex(&i, offsetBy: distance, limitedBy: limit)
  }

  
  @inlinable
  @inline(__always)
  internal subscript(position: Index) -> Element {
    _failEarlyRangeCheck(position, bounds: startIndex..<endIndex)
    return _base[position]
  }
  
  @inlinable
  public subscript(bounds: Range<Index>) -> SubSequence {
    _failEarlyRangeCheck(bounds, bounds: startIndex..<endIndex)
    return _base[bounds]
  }
  
  // TODO: implement optimized `var indices`
  
  @inlinable
  @inline(__always)
  public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {
    _base._failEarlyRangeCheck(index, bounds: bounds)
  }

  @inlinable
  @inline(__always)
  public func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>) {
    _base._failEarlyRangeCheck(range, bounds: bounds)
  }
}

// TODO: implement partial RangeReplaceableCollection methods
