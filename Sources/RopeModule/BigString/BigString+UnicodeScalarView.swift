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
    var _guts: _BString.UnicodeScalarView

    init(_guts: _BString.UnicodeScalarView) {
      self._guts = _guts
    }
  }
  
  public var unicodeScalars: UnicodeScalarView {
    get {
      UnicodeScalarView(_guts: _guts.unicodeScalars)
    }
    set {
      _guts = newValue._guts._base
    }
    _modify {
      var view = UnicodeScalarView(_guts: _guts.unicodeScalars)
      self._guts = .init()
      defer {
        self._guts = view._guts._base
      }
      yield &view
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString {
  public init(_ content: UnicodeScalarView) {
    self._guts = _BString(content._guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(_guts: _BString(value).unicodeScalars)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: CustomStringConvertible {
  public var description: String {
    String(_from: _guts._base)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    left._guts == right._guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: Hashable {
  public func hash(into hasher: inout Hasher) {
    _guts.hash(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: Sequence {
  public typealias Element = Unicode.Scalar

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
    Iterator(_base: _guts.makeIterator())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UnicodeScalarView: BidirectionalCollection {
  public typealias Index = BigString.Index
  public typealias SubSequence = BigSubstring.UnicodeScalarView

  public var count: Int {
    _guts.count
  }

  public var startIndex: Index {
    Index(_guts.startIndex)
  }

  public var endIndex: Index {
    Index(_guts.endIndex)
  }

  public func index(after i: Index) -> Index {
    Index(_guts.index(after: i._value))
  }

  public func index(before i: Index) -> Index {
    Index(_guts.index(after: i._value))
  }

  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    Index(_guts.index(i._value, offsetBy: distance))
  }

  public func distance(from start: Index, to end: Index) -> Int {
    _guts.distance(from: start._value, to: end._value)
  }

  public subscript(index: Index) -> Unicode.Scalar {
    _guts[index._value]
  }

  public subscript(bounds: Range<Index>) -> BigSubstring.UnicodeScalarView {
    BigSubstring.UnicodeScalarView(_guts: _guts[bounds._base])
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
    _guts.replaceSubrange(subrange._base, with: newElements)
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
    self._guts = _BString.UnicodeScalarView(elements)
  }

  public init(repeating scalar: UnicodeScalar, count: Int) {
    self._guts = _BString.UnicodeScalarView(repeating: scalar, count: count)
  }

  public mutating func append(_ newElement: __owned UnicodeScalar) {
    _guts.append(newElement)
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
      let range = newElements.startIndex ..< newElements.endIndex
      _guts.append(contentsOf: newElements.base._guts[range._base])
      return
    }
    _guts.append(contentsOf: newElements)
  }

  public mutating func insert(_ newElement: __owned Unicode.Scalar, at i: Index) {
    _guts.insert(newElement, at: i._value)
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
      let range = newElements.startIndex ..< newElements.endIndex
      self._guts.insert(contentsOf: newElements.base._guts[range._base], at: i._value)
      return
    }
    _guts.insert(contentsOf: newElements, at: i._value)
  }

  @discardableResult
  public mutating func remove(at i: Index) -> Unicode.Scalar {
    _guts.remove(at: i._value)
  }

  public mutating func removeSubrange(_ bounds: Range<Index>) {
    _guts.removeSubrange(bounds._base)
  }

  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    _guts.removeAll(keepingCapacity: keepCapacity)
  }
}

#endif
