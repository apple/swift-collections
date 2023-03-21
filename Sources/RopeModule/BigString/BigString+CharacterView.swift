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
  public struct Index {
    internal var _value: _BString.Index

    internal init(_ value: _BString.Index) {
      self._value = value
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.Index: CustomStringConvertible {
  public var description: String {
    "\(_value)"
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.Index: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    left._value == right._value
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.Index: Comparable {
  public static func <(left: Self, right: Self) -> Bool {
    left._value < right._value
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.Index: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_value)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: Equatable {
  public static func == (left: Self, right: Self) -> Bool {
    left._guts == right._guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: Comparable {
  public static func < (left: Self, right: Self) -> Bool {
    left._guts < right._guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: Hashable {
  public func hash(into hasher: inout Hasher) {
    _guts.hashCharacters(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: Sequence {
  public typealias Element = Character
  public typealias Iterator = _BString.Iterator

  public func makeIterator() -> Iterator {
    _guts.makeIterator()
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: BidirectionalCollection {
  public typealias SubSequence = BigSubstring

  public var count: Int { _guts.count }

  public var startIndex: Index { Index(_guts.startIndex) }
  public var endIndex: Index { Index(_guts.endIndex) }
  public func index(after i: Index) -> Index { Index(_guts.index(after: i._value)) }
  public func index(before i: Index) -> Index { Index(_guts.index(before: i._value)) }
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
  public subscript(bounds: Range<Index>) -> BigSubstring {
    BigSubstring(_guts: _guts[bounds._base])
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: RangeReplaceableCollection {
  public init() {
    self.init(_guts: _BString())
  }

  public mutating func reserveCapacity(_ n: Int) {}

  public mutating func replaceSubrange<C: Sequence<Character>>( // Note: Sequence, not Collection
    _ subrange: Range<Index>,
    with newElements: __owned C
  ) {
    if C.self == BigString.self {
      let newElements = _identityCast(newElements, to: BigString.self)
      replaceSubrange(subrange, with: newElements)
    } else if C.self == BigSubstring.self {
      let newElements = _identityCast(newElements, to: BigSubstring.self)
      replaceSubrange(subrange, with: newElements)
    } else {
      _guts.replaceSubrange(subrange._base, with: newElements)
    }
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>,
    with newElements: __owned BigString
  ) {
    _guts.replaceSubrange(subrange._base, with: newElements._guts)
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>,
    with newElements: __owned BigSubstring
  ) {
    _guts.replaceSubrange(subrange._base, with: newElements._guts)
  }

  public init<S: Sequence<Character>>(_ elements: S) {
    if S.self == BigString.self {
      let newElements = _identityCast(elements, to: BigString.self)
      self.init(_guts: newElements._guts)
    } else if S.self == BigSubstring.self {
      let newElements = _identityCast(elements, to: BigSubstring.self)
      self.init(_guts: _BString(newElements._guts))
    } else {
      self.init(_guts: _BString(elements))
    }
  }

  public init(_ elements: BigString) {
    self._guts = elements._guts
  }

  public init(_ elements: BigSubstring) {
    self._guts = _BString(elements._guts)
  }

  public init(repeating repeatedValue: Character, count: Int) {
    self._guts = _BString(repeating: _BString(String(repeatedValue)), count: count)
  }

  public init(repeating repeatedValue: some StringProtocol, count: Int) {
    self._guts = _BString(repeating: _BString(repeatedValue), count: count)
  }

  public init(repeating repeatedValue: BigString, count: Int) {
    self._guts = _BString(repeating: repeatedValue._guts, count: count)
  }

  public init(repeating repeatedValue: BigSubstring, count: Int) {
    self._guts = _BString(repeating: repeatedValue._guts, count: count)
  }

  public mutating func append(_ newElement: __owned Character) {
    _guts.append(newElement)
  }

  public mutating func append<S: Sequence<Character>>(
    contentsOf newElements: __owned S
  ) {
    if S.self == BigString.self {
      let newElements = _identityCast(newElements, to: BigString.self)
      self.append(contentsOf: newElements)
    } else if S.self == BigSubstring.self {
      let newElements = _identityCast(newElements, to: BigSubstring.self)
      self.append(contentsOf: newElements)
    } else {
      _guts.append(contentsOf: newElements)
    }
  }

  public mutating func append(contentsOf newElements: __owned BigString) {
    _guts.append(contentsOf: newElements._guts)
  }

  public mutating func append(contentsOf newElements: __owned BigSubstring) {
    _guts.append(contentsOf: newElements._guts)
  }

  public mutating func insert(_ newElement: __owned Character, at i: Index) {
    _guts.insert(newElement, at: i._value)
  }

  public mutating func insert<S: Sequence<Character>>( // Note: Sequence, not Collection
    contentsOf newElements: __owned S, at i: Index
  ) {
    if S.self == BigString.self {
      let newElements = _identityCast(newElements, to: BigString.self)
      self.insert(contentsOf: newElements, at: i)
    } else if S.self == BigSubstring.self {
      let newElements = _identityCast(newElements, to: BigSubstring.self)
      self.insert(contentsOf: newElements, at: i)
    } else {
      _guts.insert(contentsOf: newElements, at: i._value)
    }
  }

  public mutating func insert(contentsOf newElements: __owned BigString, at i: Index) {
    _guts.insert(contentsOf: newElements._guts, at: i._value)
  }

  public mutating func insert(contentsOf newElements: __owned BigSubstring, at i: Index) {
    _guts.insert(contentsOf: newElements._guts, at: i._value)
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
