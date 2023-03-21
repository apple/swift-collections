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
public struct BigSubstring: Sendable {
  internal var _guts: _BSubstring

  internal init(_guts: _BSubstring) {
    self._guts = _guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring {
  public var base: BigString { BigString(_guts: _guts._base) }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring: CustomStringConvertible {
  public var description: String { _guts.description }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring: CustomDebugStringConvertible {
  public var debugDescription: String { _guts.debugDescription }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(_guts: _BSubstring(stringLiteral: value))
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring: LosslessStringConvertible {
  // init?(_: String) is implemented by RangeReplaceableCollection.init(_:)
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    left._guts == right._guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring: Hashable {
  public func hash(into hasher: inout Hasher) {
    _guts.hash(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring: Comparable {
  public static func < (left: Self, right: Self) -> Bool {
    left._guts < right._guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring: Sequence {
  public typealias Element = Character
  public typealias Iterator = _BSubstring.Iterator

  public func makeIterator() -> Iterator {
    _guts.makeIterator()
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring: BidirectionalCollection {
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
  public subscript(position: Index) -> Character {
    _guts[position._value]
  }
  public subscript(bounds: Range<Index>) -> Self {
    BigSubstring(_guts: _guts[bounds._base])
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring {
  public func index(roundingDown i: Index) -> Index {
    Index(_guts.index(roundingDown: i._value))
  }
  public func index(roundingUp i: Index) -> Index {
    Index(_guts.index(roundingUp: i._value))
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring: RangeReplaceableCollection {
  public init() {
    self.init(_guts: _BSubstring())
  }
  
  public mutating func reserveCapacity(_ n: Int) {}
  
  public mutating func replaceSubrange<C: Sequence<Character>>( // Note: Sequence, not Collection
    _ subrange: Range<Index>,
    with newElements: __owned C
  ) {
    if C.self == BigString.self {
      let newElements = _identityCast(newElements, to: BigString.self)
      _guts.replaceSubrange(subrange._base, with: newElements._guts)
    } else if C.self == BigSubstring.self {
      let newElements = _identityCast(newElements, to: BigSubstring.self)
      _guts.replaceSubrange(subrange._base, with: newElements._guts)
    } else {
      _guts.replaceSubrange(subrange._base, with: newElements)
    }
  }

  public init<S: Sequence<Character>>(_ elements: S) {
    if S.self == BigString.self {
      let newElements = _identityCast(elements, to: BigString.self)
      self.init(_guts: _BSubstring(newElements._guts))
    } else if S.self == BigSubstring.self {
      let newElements = _identityCast(elements, to: BigSubstring.self)
      self.init(_guts: _BSubstring(_BString(newElements._guts)))
    } else {
      self.init(_guts: _BSubstring(elements))
    }
  }

  public init(repeating repeatedValue: Character, count: Int) {
    self._guts = _BSubstring(repeating: repeatedValue, count: count)
  }

  public init(repeating repeatedValue: some StringProtocol, count: Int) {
    self._guts = _BSubstring(repeating: repeatedValue, count: count)
  }

  public init(repeating repeatedValue: BigString, count: Int) {
    self._guts = _BSubstring(repeating: repeatedValue._guts, count: count)
  }

  public init(repeating repeatedValue: BigSubstring, count: Int) {
    self._guts = _BSubstring(repeating: repeatedValue._guts, count: count)
  }

  public mutating func append(_ newElement: Character) {
    _guts.append(newElement)
  }

  public mutating func append<S: Sequence<Character>>(contentsOf newElements: __owned S) {
    if S.self == BigString.self {
      let newElements = _identityCast(newElements, to: BigString.self)
      _guts.append(contentsOf: newElements._guts)
    } else if S.self == BigSubstring.self {
      let newElements = _identityCast(newElements, to: BigSubstring.self)
      _guts.append(contentsOf: newElements._guts)
    } else {
      _guts.append(contentsOf: newElements)
    }
  }

  public mutating func insert(_ newElement: Character, at i: Index) {
    _guts.insert(newElement, at: i._value)
  }

  public mutating func insert<C: Sequence<Character>>( // Note: Sequence, not Collection
    contentsOf newElements: __owned C, at i: Index
  ) {
    if C.self == BigString.self {
      let newElements = _identityCast(newElements, to: BigString.self)
      _guts.insert(contentsOf: newElements._guts, at: i._value)
    } else if C.self == BigSubstring.self {
      let newElements = _identityCast(newElements, to: BigSubstring.self)
      _guts.insert(contentsOf: newElements._guts, at: i._value)
    } else {
      _guts.insert(contentsOf: newElements, at: i._value)
    }
  }

  @discardableResult
  public mutating func remove(at i: Index) -> Character {
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
