// -----------------------------------------------------------------------------
// This file includes the "dispatch" code so that a `Collection`-constrained
// generic parameter can be upgraded to its RAC conforming-implementation
// and a `Zip2Dispatch` type that uses that to conditionally conform to both
// Bidi and RAC. The ~magic~ happens in `Zip2Dispatch.distance(from:to:)`,
// which uses the RAC-optimized version of its base collections if they possible
// and otherwise falls back to a naive computation.
// -----------------------------------------------------------------------------

@usableFromInline
struct Dispatch<Model> {
  @inlinable
  func apply<A, R>(_ a: A, _ f: (Model) -> R) -> R {
    f(a as! Model)
  }
  
  @inlinable init() {}
}

@usableFromInline
protocol RandomAccessCollectionDispatch {
  func fastDistance<C: Collection>(_ c: C, from start: C.Index, to end: C.Index) -> Int
}

extension Dispatch: RandomAccessCollectionDispatch
  where Model: RandomAccessCollection
{
  @inlinable
  func fastDistance<C: Collection>(_ c: C, from start: C.Index, to end: C.Index) -> Int {
    apply(c) { c in
      c.distance(from: start as! Model.Index, to: end as! Model.Index)
    }
  }
}

extension Collection {
  @inlinable
  var randomAccessDispatch: RandomAccessCollectionDispatch? {
    Dispatch<Self>() as? RandomAccessCollectionDispatch
  }
}

// -----------------------------------------------------------------------------
// zipDynamic
// -----------------------------------------------------------------------------

@inlinable
public func zipDispatch<Base1: Collection, Base2: Collection>(
  _ base1: Base1, _ base2: Base2
) -> Zip2Dispatch<Base1, Base2> {
  return Zip2Dispatch(base1, base2)
}

@frozen
public struct Zip2Dispatch<Base1, Base2>
  where Base1: Collection, Base2: Collection
{
  @usableFromInline
  internal let _base1: Base1
  @usableFromInline
  internal let _base2: Base2

  /// Creates an instance that makes pairs of elements from `base1` and `base2`.
  @inlinable // generic-performance
  internal init(_ base1: Base1, _ base2: Base2) {
    (_base1, _base2) = (base1, base2)
  }
}

extension Zip2Dispatch: Collection {
  @frozen
  public struct _Index {
    /// The position in the first underlying collection.
    public let base1: Base1.Index
    
    /// The position in the second underlying collection.
    public let base2: Base2.Index
    
    @inlinable
    init(base1: Base1.Index, base2: Base2.Index) {
      self.base1 = base1
      self.base2 = base2
    }
  }
  
  // Ensures that `Self.Index == SubSequence.Index`.
  public typealias Index = SubSequence._Index
  public typealias SubSequence =
    Zip2Dispatch<Base1.SubSequence, Base2.SubSequence>
  
  @inlinable
  public var startIndex: Index {
    return isEmpty
      ? endIndex
      : Index(base1: _base1.startIndex, base2: _base2.startIndex)
  }
  
  @inlinable
  public var endIndex: Index {
    return Index(base1: _base1.endIndex, base2: _base2.endIndex)
  }
  
  /// Constructs an `Index` from its parts, returning `endIndex` if necessary.
  @inlinable
  internal func _pack(_ base1: Base1.Index, _ base2: Base2.Index) -> Index {
    return base1 == _base1.endIndex || base2 == _base2.endIndex
      ? endIndex
      : Index(base1: base1, base2: base2)
  }
  
  /// Destructs an `Index` into its parts.
  ///
  /// - Complexity: O(1)
  @inlinable
  internal func _unpack(_ index: Index) -> (Base1.Index, Base2.Index) {
    if index == endIndex {
      let count = self.count
      return (
        _base1.index(_base1.startIndex, offsetBy: count),
        _base2.index(_base2.startIndex, offsetBy: count))
    } else {
      return (index.base1, index.base2)
    }
  }
  
  @inlinable
  public func index(after i: Index) -> Index {
    return _pack(
      _base1.index(after: i.base1),
      _base2.index(after: i.base2))
  }
  
  @inlinable
  public subscript(position: Index) -> (Base1.Element, Base2.Element) {
    return (_base1[position.base1], _base2[position.base2])
  }
  
  @inlinable
  public subscript(bounds: Range<Index>) -> SubSequence {
    SubSequence(
      _base1[bounds.lowerBound.base1..<bounds.upperBound.base1],
      _base2[bounds.lowerBound.base2..<bounds.upperBound.base2])
  }
  
  @inlinable
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    let (base1, base2) = distance >= 0 ? (i.base1, i.base2) : _unpack(i)
    return _pack(
      _base1.index(base1, offsetBy: distance),
      _base2.index(base2, offsetBy: distance))
  }
  
  @inlinable
  public func index(
    _ i: Index,
    offsetBy distance: Int,
    limitedBy limit: Index
  ) -> Index? {
    let (base1, base2) = distance >= 0 ? (i.base1, i.base2) : _unpack(i)
    guard let newBase1 = _base1.index(
            base1,
            offsetBy: distance,
            limitedBy: limit.base1),
          let newBase2 = _base2.index(
            base2,
            offsetBy: distance,
            limitedBy: limit.base2)
    else { return nil }
    return _pack(newBase1, newBase2)
  }
  
  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    guard start <= end else { return -distance(from: end, to: start) }
    if let base1Dispatch = _base1.randomAccessDispatch,
       let base2Dispatch = _base2.randomAccessDispatch
    {
      return Swift.min(
        base1Dispatch.fastDistance(_base1, from: start.base1, to: end.base1),
        base2Dispatch.fastDistance(_base2, from: start.base2, to: end.base2)
      )
    } else {
      var result = 0
      var i = startIndex
      let end = endIndex
      while i != end {
        formIndex(after: &i)
        result += 1
      }
      return result
    }
  }
  
  @inlinable
  public var isEmpty: Bool {
    return _base1.isEmpty || _base2.isEmpty
  }
}

extension Zip2Dispatch: BidirectionalCollection where Base1: BidirectionalCollection, Base2: BidirectionalCollection {
  
  @inlinable
  public func index(before i: Index) -> Index {
    return _pack(
      _base1.index(after: i.base1),
      _base2.index(after: i.base2))
  }

}

extension Zip2Dispatch: RandomAccessCollection where Base1: RandomAccessCollection, Base2: RandomAccessCollection {}

extension Zip2Dispatch._Index: Comparable {
  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.base1 == rhs.base1
  }

  @inlinable
  public static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.base1 < rhs.base1
  }
}
