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

#if swift(>=5.8)

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString {
  public init(_ content: UnicodeScalarView) {
    self._guts = content._guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(_guts: _BString(value))
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: CustomStringConvertible {
  public var description: String {
    String(_from: _guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    _BString.utf8IsEqual(left._guts, to: right._guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: Comparable {
  public static func <(left: Self, right: Self) -> Bool {
    left._guts.utf8IsLess(than: right._guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: Hashable {
  public func hash(into hasher: inout Hasher) {
    _guts.hashUTF8(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: RangeReplaceableCollection {
  public mutating func replaceSubrange<C: Collection>(
    _ subrange: Range<Index>,
    with newElements: __owned C
  ) where C.Element == Unicode.Scalar {
    if C.self == BigString.UnicodeScalarView.self {
      let replacement = _identityCast(newElements, to: BigString.UnicodeScalarView.self)
      _guts.replaceSubrange(subrange._base, with: replacement._guts)
      return
    }
    if C.self == String.UnicodeScalarView.self {
      let replacement = _identityCast(newElements, to: String.UnicodeScalarView.self)
      _guts.replaceSubrange(subrange._base, with: String(replacement))
      return
    }
    if C.self == Substring.UnicodeScalarView.self {
      let replacement = _identityCast(newElements, to: Substring.UnicodeScalarView.self)
      _guts.replaceSubrange(subrange._base, with: Substring(replacement))
      return
    }
    _guts.replaceSubrange(subrange._base, with: _BString(_from: newElements))
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

  public init<S: Sequence>(_ elements: S) where S.Element == UnicodeScalar {
    if S.self == BigString.UnicodeScalarView.self {
      let elements = _identityCast(elements, to: BigString.UnicodeScalarView.self)
      self._guts = elements._guts
      return
    }
    if S.self == String.UnicodeScalarView.self {
      let elements = _identityCast(elements, to: String.UnicodeScalarView.self)
      self._guts = _BString(_from: String(elements))
      return
    }
    if S.self == Substring.UnicodeScalarView.self {
      let elements = _identityCast(elements, to: Substring.UnicodeScalarView.self)
      self._guts = _BString(_from: Substring(elements))
      return
    }
    self._guts = _BString(_from: elements)
  }

  public init(_ elements: String.UnicodeScalarView) {
    self._guts = _BString(_from: String(elements))
  }

  public init(_ elements: Substring.UnicodeScalarView) {
    self._guts = _BString(_from: Substring(elements))
  }

  public init(_ elements: Self) {
    self._guts = elements._guts
  }

  public init(_ elements: Self.SubSequence) {
    let lower = elements.startIndex._value
    let upper = elements.endIndex._value
    self._guts = _BString(_from: elements.base._guts, in: lower ..< upper)
  }

  public init(repeating scalar: Unicode.Scalar, count: Int) {
    self._guts = _BString(repeating: _BString(String(scalar)), count: count)
  }

  public mutating func append(_ newElement: __owned Element) {
    _guts.append(contentsOf: String(newElement))
  }

  public mutating func append<S: Sequence>(
    contentsOf newElements: __owned S
  ) where S.Element == UnicodeScalar {
    if S.self == BigString.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: BigString.UnicodeScalarView.self)
      _guts.append(contentsOf: newElements._guts)
      return
    }
    if S.self == BigString.UnicodeScalarView.SubSequence.self {
      let newElements = _identityCast(newElements, to: BigString.UnicodeScalarView.SubSequence.self)
      _guts._append(
        contentsOf: newElements.base._guts,
        in: newElements.startIndex._value ..< newElements.endIndex._value)
      return
    }
    if S.self == String.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: String.UnicodeScalarView.self)
      _guts.append(contentsOf: String(newElements))
      return
    }
    if S.self == Substring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: Substring.UnicodeScalarView.self)
      _guts.append(contentsOf: Substring(newElements))
      return
    }
    _guts.append(contentsOf: _BString(_from: newElements))
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
    _guts._append(contentsOf: newElements.base._guts, in: lower ..< upper)
  }

  public mutating func insert(_ newElement: __owned Unicode.Scalar, at i: Index) {
    _guts.insert(contentsOf: String(newElement), at: i._value)
  }

  public mutating func insert<C: Collection<Unicode.Scalar>>(
    contentsOf newElements: C, at i: Index
  ) {
    if C.self == BigString.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: BigString.UnicodeScalarView.self)
      self._guts.insert(contentsOf: newElements._guts, at: i._value)
      return
    }
    if C.self == BigString.UnicodeScalarView.SubSequence.self {
      let newElements = _identityCast(newElements, to: BigString.UnicodeScalarView.SubSequence.self)
      self._guts._insert(
        contentsOf: newElements.base._guts,
        in: newElements.startIndex._value ..< newElements.endIndex._value,
        at: i._value)
      return
    }
    if C.self == String.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: String.UnicodeScalarView.self)
      self._guts.insert(contentsOf: String(newElements), at: i._value)
      return
    }
    if C.self == Substring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: Substring.UnicodeScalarView.self)
      self._guts.insert(contentsOf: Substring(newElements), at: i._value)
      return
    }
    _guts.insert(contentsOf: _BString(_from: newElements), at: i._value)
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
    _guts._insert(contentsOf: newElements.base._guts, in: lower ..< upper, at: i._value)
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

#endif
