//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension BigString {
  public struct UnicodeScalarView {
    var _guts: _BString
    
    init(_guts: _BString) {
      self._guts = _guts
    }
  }
  
  public var unicodeScalars: UnicodeScalarView {
    get {
      UnicodeScalarView(_guts: _guts)
    }
    set {
      _guts = newValue._guts
    }
    _modify {
      var view = UnicodeScalarView(_guts: _guts)
      self._guts = .init()
      defer {
        self._guts = view._guts
      }
      yield &view
    }
  }
}

extension BigString {
  public init(_ content: UnicodeScalarView) {
    self._guts = content._guts
  }
}

extension BigString.UnicodeScalarView: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(_guts: _BString(value))
  }
}

extension BigString.UnicodeScalarView: CustomStringConvertible {
  public var description: String {
    String(_from: _guts)
  }
}

extension BigString.UnicodeScalarView: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    left._guts.utf8IsEqual(to: right._guts)
  }
}

extension BigString.UnicodeScalarView: Comparable {
  public static func <(left: Self, right: Self) -> Bool {
    left._guts.utf8IsLess(than: right._guts)
  }
}

extension BigString.UnicodeScalarView: Hashable {
  public func hash(into hasher: inout Hasher) {
    _guts.hashUTF8(into: &hasher)
  }
}

extension BigString.UnicodeScalarView: Sequence {
  public struct Iterator: IteratorProtocol {
    public typealias Element = Unicode.Scalar

    internal var _base: _BString.UnicodeScalarIterator

    internal init(_base: _BString.UnicodeScalarIterator) {
      self._base = _base
    }

    public mutating func next() -> Unicode.Scalar? {
      _base.next()
    }
  }

  public func makeIterator() -> Iterator {
    Iterator(_base: _guts.makeUnicodeScalarIterator())
  }
}

extension BigString.UnicodeScalarView: BidirectionalCollection {
  public typealias Element = Unicode.Scalar
  public typealias Index = BigString.Index

  public var count: Int {
    _guts.unicodeScalarCount
  }

  public var startIndex: Index {
    Index(_guts.startIndex)
  }

  public var endIndex: Index {
    Index(_guts.endIndex)
  }

  public func index(after i: Index) -> Index {
    Index(_guts.unicodeScalarIndex(after: i._value))
  }

  public func index(before i: Index) -> Index {
    Index(_guts.unicodeScalarIndex(after: i._value))
  }

  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    Index(_guts.unicodeScalarIndex(i._value, offsetBy: distance))
  }

  public func distance(from start: Index, to end: Index) -> Int {
    _guts.unicodeScalarDistance(from: start._value, to: end._value)
  }

  public subscript(index: Index) -> Unicode.Scalar {
    _guts[unicodeScalar: index._value]
  }
}

extension BigString.UnicodeScalarView: RangeReplaceableCollection {
  public mutating func replaceSubrange(
    _ subrange: Range<Index>,
    with newElements: __owned some Collection<Unicode.Scalar>
  ) {
    if let newElements = newElements as? Self {
      replaceSubrange(subrange, with: newElements)
    } else if let newElements = newElements as? String.UnicodeScalarView {
      replaceSubrange(subrange, with: newElements)
    } else if let newElements = newElements as? Substring.UnicodeScalarView {
      replaceSubrange(subrange, with: newElements)
    } else {
      _guts.replaceSubrange(subrange._base, with: _BString(newElements))
    }
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>,
    with newElements: __owned String.UnicodeScalarView
  ) {
    _guts.replaceSubrange(subrange._base, with: String(newElements))
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>,
    with newElements: __owned Substring.UnicodeScalarView
  ) {
    _guts.replaceSubrange(subrange._base, with: Substring(newElements))
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>,
    with newElements: __owned BigString.UnicodeScalarView
  ) {
    _guts.replaceSubrange(subrange._base, with: newElements._guts)
  }

  public mutating func reserveCapacity(_ n: Int) {}

  public init() {
    _guts = .init()
  }

  public init(_ elements: some Sequence<Unicode.Scalar>) {
    if let elements = elements as? Self {
      self._guts = elements._guts
    } else if let elements = elements as? String.UnicodeScalarView {
      self._guts = _BString(elements)
    } else if let elements = elements as? Substring.UnicodeScalarView {
      self._guts = _BString(elements)
    } else {
      self._guts = _BString(elements)
    }
  }

  public init(_ elements: String.UnicodeScalarView) {
    self._guts = _BString(elements)
  }

  public init(_ elements: Substring.UnicodeScalarView) {
    self._guts = _BString(elements)
  }

  public init(_ elements: Self) {
    self._guts = elements._guts
  }

  public init(_ elements: Self.SubSequence) {
    let lower = elements.startIndex._value
    let upper = elements.endIndex._value
    self._guts = _BString(elements.base._guts, in: lower ..< upper)
  }

  public init(repeating scalar: Unicode.Scalar, count: Int) {
    self._guts = _BString(repeating: _BString(String(scalar)), count: count)
  }

  public mutating func append(_ newElement: __owned Element) {
    _guts.append(contentsOf: String(newElement))
  }

  public mutating func append(contentsOf newElements: __owned some Sequence<Unicode.Scalar>) {
    if let newElements = newElements as? Self {
      self.append(contentsOf: newElements)
    } else if let newElements = newElements as? String.UnicodeScalarView {
      self.append(contentsOf: newElements)
    } else if let newElements = newElements as? Substring.UnicodeScalarView {
      self.append(contentsOf: newElements)
    } else {
      _guts.append(contentsOf: _BString(newElements))
    }
  }

  public mutating func append(contentsOf newElements: __owned String.UnicodeScalarView) {
    _guts.append(contentsOf: String(newElements))
  }

  public mutating func append(contentsOf newElements: __owned Substring.UnicodeScalarView) {
    _guts.append(contentsOf: Substring(newElements))
  }

  public mutating func append(contentsOf newElements: __owned Self) {
    _guts.append(contentsOf: newElements._guts)
  }

  public mutating func append(contentsOf newElements: __owned Self.SubSequence) {
    let lower = newElements.startIndex._value
    let upper = newElements.endIndex._value
    _guts.append(contentsOf: newElements.base._guts, in: lower ..< upper)
  }

  public mutating func insert(_ newElement: __owned Unicode.Scalar, at i: Index) {
    _guts.insert(contentsOf: String(newElement), at: i._value)
  }

  public mutating func insert(contentsOf newElements: some Collection<Unicode.Scalar>, at i: Index) {
    if let newElements = newElements as? Self {
      self.insert(contentsOf: newElements, at: i)
    } else if let newElements = newElements as? String.UnicodeScalarView {
      self.insert(contentsOf: newElements, at: i)
    } else if let newElements = newElements as? Substring.UnicodeScalarView {
      self.insert(contentsOf: newElements, at: i)
    } else {
      _guts.insert(contentsOf: _BString(newElements), at: i._value)
    }
  }

  public mutating func insert(contentsOf newElements: String.UnicodeScalarView, at i: Index) {
    _guts.insert(contentsOf: String(newElements), at: i._value)
  }

  public mutating func insert(contentsOf newElements: Substring.UnicodeScalarView, at i: Index) {
    _guts.insert(contentsOf: Substring(newElements), at: i._value)
  }

  public mutating func insert(contentsOf newElements: Self, at i: Index) {
    _guts.insert(contentsOf: newElements._guts, at: i._value)
  }

  public mutating func insert(contentsOf newElements: __owned Self.SubSequence, at i: Index) {
    let lower = newElements.startIndex._value
    let upper = newElements.endIndex._value
    _guts.insert(contentsOf: newElements.base._guts, in: lower ..< upper, at: i._value)
  }

  @discardableResult
  public mutating func remove(at i: Index) -> Unicode.Scalar {
    _guts.removeUnicodeScalar(at: i._value)
  }

  public mutating func removeSubrange(_ bounds: Range<Index>) {
    _guts.removeSubrange(bounds._base)
  }

  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    _guts = _BString()
  }
}
