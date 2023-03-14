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
extension BigSubstring {
  public struct UnicodeScalarView: Sendable {
    internal var _guts: _BSubstring.UnicodeScalarView

    internal init(_guts: _BSubstring.UnicodeScalarView) {
      self._guts = _guts
    }
  }

  public var unicodeScalars: UnicodeScalarView {
    UnicodeScalarView(_guts: _guts.unicodeScalars)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString {
  public init(_ unicodeScalars: BigSubstring.UnicodeScalarView) {
    self.init(_guts: _BString(unicodeScalars._guts))
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UnicodeScalarView {
  public var base: BigString.UnicodeScalarView {
    BigString.UnicodeScalarView(_guts: _guts.base)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UnicodeScalarView: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(_guts: _BSubstring.UnicodeScalarView(value.unicodeScalars))
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UnicodeScalarView: CustomStringConvertible {
  public var description: String {
    _guts.description
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UnicodeScalarView: CustomDebugStringConvertible {
  public var debugDescription: String {
    _guts.debugDescription
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UnicodeScalarView: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    left._guts == right._guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UnicodeScalarView: Hashable {
  public func hash(into hasher: inout Hasher) {
    _guts.hash(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UnicodeScalarView: Sequence {
  public typealias Element = UnicodeScalar

  public struct Iterator: IteratorProtocol {
    internal var _guts: _BSubstring.UnicodeScalarView.Iterator

    internal init(_guts: _BSubstring.UnicodeScalarView.Iterator) {
      self._guts = _guts
    }

    public mutating func next() -> UnicodeScalar? {
      _guts.next()
    }
  }

  public func makeIterator() -> Iterator {
    Iterator(_guts: _guts.makeIterator())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UnicodeScalarView: BidirectionalCollection {
  public typealias Index = BigString.Index
  public typealias SubSequence = Self

  public var startIndex: Index { Index(_guts.startIndex) }
  public var endIndex: Index { Index(_guts.endIndex) }
  public var count: Int { _guts.count }
  public func index(after i: Index) -> Index { Index(_guts.index(after: i._value)) }
  public func index(before i: Index) -> Index { Index(_guts.index(after: i._value)) }
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    Index(_guts.index(i._value, offsetBy: distance))
  }
  public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    _guts.index(i._value, offsetBy: distance, limitedBy: limit._value).map { Index($0) }
  }
  public func distance(from start: Index, to end: Index) -> Int {
    _guts.distance(from: start._value, to: end._value)
  }
  public subscript(position: Index) -> UnicodeScalar {
    _guts[position._value]
  }
  public subscript(bounds: Range<Index>) -> Self {
    BigSubstring.UnicodeScalarView(_guts: _guts[bounds._base])
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UnicodeScalarView {
  internal func index(roundingDown i: Index) -> Index {
    Index(_guts.index(roundingDown: i._value))
  }

  internal func index(roundingUp i: Index) -> Index {
    Index(_guts.index(roundingUp: i._value))
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UnicodeScalarView: RangeReplaceableCollection {
  public init() {
    self.init(_guts: _BSubstring.UnicodeScalarView())
  }

  public mutating func reserveCapacity(_ n: Int) {}

  public mutating func replaceSubrange<C: Sequence<UnicodeScalar>>( // Note: Sequence, not Collection
    _ subrange: Range<Index>,
    with newElements: __owned C
  ) {
    if C.self == BigString.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: BigString.UnicodeScalarView.self)
      _guts.replaceSubrange(subrange._base, with: newElements._guts)
    } else if C.self == BigSubstring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: BigSubstring.UnicodeScalarView.self)
      _guts.replaceSubrange(subrange._base, with: newElements._guts)
    } else {
      _guts.replaceSubrange(subrange._base, with: newElements)
    }
  }

  public init<S: Sequence<UnicodeScalar>>(_ elements: S) {
    if S.self == BigString.UnicodeScalarView.self {
      let newElements = _identityCast(elements, to: BigString.UnicodeScalarView.self)
      self.init(_guts: _BSubstring.UnicodeScalarView(newElements._guts))
    } else if S.self == BigSubstring.UnicodeScalarView.self {
      let newElements = _identityCast(elements, to: BigSubstring.UnicodeScalarView.self)
      let base = _BString.UnicodeScalarView(newElements._guts)
      self.init(_guts: _BSubstring.UnicodeScalarView(base))
    } else {
      self.init(_guts: _BSubstring.UnicodeScalarView(elements))
    }
  }

  public init(repeating repeatedValue: UnicodeScalar, count: Int) {
    self._guts = _BSubstring.UnicodeScalarView(repeating: repeatedValue, count: count)
  }

  public mutating func append(_ newElement: UnicodeScalar) {
    _guts.append(newElement)
  }

  public mutating func append<S: Sequence<UnicodeScalar>>(
    contentsOf newElements: __owned S
  ) {
    if S.self == BigString.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: BigString.UnicodeScalarView.self)
      _guts.append(contentsOf: newElements._guts)
    } else if S.self == BigSubstring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: BigSubstring.UnicodeScalarView.self)
      _guts.append(contentsOf: newElements._guts)
    } else {
      _guts.append(contentsOf: newElements)
    }
  }

  public mutating func insert(_ newElement: UnicodeScalar, at i: Index) {
    _guts.insert(newElement, at: i._value)
  }

  public mutating func insert<C: Sequence<UnicodeScalar>>( // Note: Sequence, not Collection
    contentsOf newElements: __owned C, at i: Index
  ) {
    if C.self == BigString.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: BigString.UnicodeScalarView.self)
      _guts.insert(contentsOf: newElements._guts, at: i._value)
    } else if C.self == BigSubstring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: BigSubstring.UnicodeScalarView.self)
      _guts.insert(contentsOf: newElements._guts, at: i._value)
    } else {
      _guts.insert(contentsOf: newElements, at: i._value)
    }
  }

  @discardableResult
  public mutating func remove(at i: Index) -> UnicodeScalar {
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
