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

extension Uniqued {
  public struct SubSequence {
    internal var _startIndex: Base.Index
    internal var _endIndex: Base.Index
    internal var _base: Uniqued

    public init(base: Uniqued, bounds: Range<Index>) {
      self._base = base
      self._startIndex = bounds.lowerBound
      self._endIndex = bounds.upperBound
    }
  }
}

extension Uniqued.SubSequence {
  internal var _slice: Base.SubSequence {
    _base._elements[_startIndex ..< _endIndex]
  }

  internal func _index(of element: Element) -> Index? {
    guard let index = _base._find(element).index else { return nil }
    guard _startIndex <= index && index < _endIndex else { return nil }
    return index
  }
}

extension Uniqued.SubSequence: Sequence {
  public typealias Element = Base.Element
  public typealias Iterator = Base.SubSequence.Iterator

  public func makeIterator() -> Iterator {
    _slice.makeIterator()
  }

  public func _customContainsEquatableElement(_ element: Element) -> Bool? {
    _index(of: element) != nil
  }

  public __consuming func _copyToContiguousArray() -> ContiguousArray<Element> {
    _slice._copyToContiguousArray()
  }

  public __consuming func _copyContents(
    initializing ptr: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator, UnsafeMutableBufferPointer<Element>.Index) {
    _slice._copyContents(initializing: ptr)
  }

  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    try _slice.withContiguousStorageIfAvailable(body)
  }
}

extension Uniqued.SubSequence: RandomAccessCollection {
  public typealias Index = Base.Index
  public typealias Indices = Base.SubSequence.Indices
  public typealias SubSequence = Self

  public var startIndex: Index { _startIndex }
  public var endIndex: Index { _endIndex }
  public var indices: Indices { _slice.indices }

  public func index(after i: Index) -> Index { _slice.index(after: i) }
  public func index(before i: Index) -> Index { _slice.index(before: i) }
  public func formIndex(after i: inout Index) { _slice.formIndex(after: &i) }
  public func formIndex(before i: inout Index) { _slice.formIndex(before: &i) }

  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    _slice.index(i, offsetBy: distance)
  }

  public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    _slice.index(i, offsetBy: distance, limitedBy: limit)
  }

  public func distance(from start: Index, to end: Index) -> Int {
    _slice.distance(from: start, to: end)
  }

  public subscript(position: Index) -> Element {
    _slice[position]
  }

  public subscript(bounds: Range<Index>) -> SubSequence {
    _failEarlyRangeCheck(bounds, bounds: startIndex ..< endIndex)
    return SubSequence(base: _base, bounds: bounds)
  }

  public var isEmpty: Bool { _startIndex == _endIndex }
  public var count: Int { distance(from: _startIndex, to: _endIndex) }

  public func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    .some(_index(of: element))
  }

  public func _customLastIndexOfEquatableElement(_ element: Element) -> Index?? {
    .some(_index(of: element))
  }

  public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {
    _slice._failEarlyRangeCheck(index, bounds: bounds)
  }

  public func _failEarlyRangeCheck(_ index: Index, bounds: ClosedRange<Index>) {
    _slice._failEarlyRangeCheck(index, bounds: bounds)
  }

  public func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>) {
    _slice._failEarlyRangeCheck(range, bounds: bounds)
  }
}
