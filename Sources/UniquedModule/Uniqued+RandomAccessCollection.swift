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

extension Uniqued: RandomAccessCollection {
  public typealias Index = Base.Index
  public typealias Indices = Base.Indices
  // For SubSequence, see Uniqued+SubSequence.swift.

  public var startIndex: Index { _elements.startIndex }
  public var endIndex: Index { _elements.endIndex }
  public var indices: Indices { _elements.indices }

  public func index(after i: Index) -> Index { _elements.index(after: i) }
  public func index(before i: Index) -> Index { _elements.index(before: i) }
  public func formIndex(after i: inout Index) { _elements.formIndex(after: &i) }
  public func formIndex(before i: inout Index) { _elements.formIndex(before: &i) }

  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    _elements.index(i, offsetBy: distance)
  }

  public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    _elements.index(i, offsetBy: distance, limitedBy: limit)
  }

  public func distance(from start: Index, to end: Index) -> Int {
    _elements.distance(from: start, to: end)
  }

  public subscript(position: Index) -> Element {
    _elements[position]
  }

  public subscript(bounds: Range<Index>) -> SubSequence {
    _failEarlyRangeCheck(bounds, bounds: startIndex ..< endIndex)
    return SubSequence(base: self, bounds: bounds)
  }

  public var isEmpty: Bool { _elements.isEmpty }
  public var count: Int { _elements.count }

  public func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    guard let storage = _storage else {
      return _elements._customIndexOfEquatableElement(element)
    }
    return storage.read { hashTable in
      let (o, _) = hashTable._find(element, in: _elements)
      guard let offset = o else { return .some(nil) }
      return _elements._index(at: offset)
    }
  }

  public func _customLastIndexOfEquatableElement(_ element: Element) -> Index?? {
    // Uniqued holds unique elements.
    _customIndexOfEquatableElement(element)
  }

  public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {
    _elements._failEarlyRangeCheck(index, bounds: bounds)
  }

  public func _failEarlyRangeCheck(_ index: Index, bounds: ClosedRange<Index>) {
    _elements._failEarlyRangeCheck(index, bounds: bounds)
  }

  public func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>) {
    _elements._failEarlyRangeCheck(range, bounds: bounds)
  }
}
