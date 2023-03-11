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
    left._guts.characterwiseIsEqual(to: right._guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: Comparable {
  public static func < (left: Self, right: Self) -> Bool {
    left._guts.characterwiseIsLess(than: right._guts)
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
  public struct Iterator: IteratorProtocol {
    public typealias Element = Character

    internal var _base: _BString.CharacterIterator

    internal init(_base: _BString.CharacterIterator) {
      self._base = _base
    }

    public mutating func next() -> Character? {
      _base.next()
    }
  }

  public func makeIterator() -> Iterator {
    Iterator(_base: _guts.makeCharacterIterator())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: BidirectionalCollection {
  public typealias Element = Character

  public var count: Int {
    _guts.characterCount
  }

  public var startIndex: Index {
    Index(_guts.startIndex)
  }

  public var endIndex: Index {
    Index(_guts.endIndex)
  }

  public func index(after i: Index) -> Index {
    Index(_guts.characterIndex(after: i._value))
  }

  public func index(before i: Index) -> Index {
    Index(_guts.characterIndex(before: i._value))
  }

  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    Index(_guts.characterIndex(i._value, offsetBy: distance))
  }

  public func distance(from start: Index, to end: Index) -> Int {
    _guts.characterDistance(from: start._value, to: end._value)
  }

  public subscript(position: Index) -> Character {
    _guts[character: position._value]
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: RangeReplaceableCollection {
  public mutating func replaceSubrange(
    _ subrange: Range<Index>,
    with newElements: __owned some Collection<Character>
  ) {
    if let newElements = newElements as? Self {
      replaceSubrange(subrange, with: newElements)
    } else if let newElements = newElements as? String {
      replaceSubrange(subrange, with: newElements)
    } else if let newElements = newElements as? Substring {
      replaceSubrange(subrange, with: newElements)
    } else {
      _guts.replaceSubrange(subrange._base, with: _BString(newElements))
    }
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>,
    with newElements: __owned String
  ) {
    _guts.replaceSubrange(subrange._base, with: newElements)
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>,
    with newElements: __owned Substring
  ) {
    _guts.replaceSubrange(subrange._base, with: newElements)
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>,
    with newElements: __owned BigString
  ) {
    _guts.replaceSubrange(subrange._base, with: newElements._guts)
  }

  public mutating func reserveCapacity(_ n: Int) {}

  public init(_ elements: some Sequence<Character>) {
    if let elements = elements as? Self {
      self._guts = elements._guts
    } else if let elements = elements as? String {
      self._guts = _BString(elements)
    } else if let elements = elements as? Substring {
      self._guts = _BString(elements)
    } else {
      self._guts = _BString(elements)
    }
  }

  public init(_ elements: String) {
    self._guts = _BString(elements)
  }

  public init(_ elements: Substring) {
    self._guts = _BString(elements)
  }

  public init(_ elements: Self) {
    self._guts = elements._guts
  }

  public init(_ elements: Self.SubSequence) {
    let lower = elements.startIndex._value
    let upper = elements.endIndex._value
    self._guts = _BString(_from: elements.base._guts, in: lower ..< upper)
  }

  public init(repeating repeatedValue: Character, count: Int) {
    self._guts = _BString(repeating: _BString(String(repeatedValue)), count: count)
  }

  public init(repeating repeatedValue: some StringProtocol, count: Int) {
    self._guts = _BString(repeating: _BString(repeatedValue), count: count)
  }

  public init(repeating repeatedValue: Self, count: Int) {
    self._guts = _BString(repeating: repeatedValue._guts, count: count)
  }

  public mutating func append(_ newElement: __owned Character) {
    _guts.append(contentsOf: String(newElement))
  }

  public mutating func append(contentsOf newElements: __owned some Sequence<Character>) {
    if let newElements = newElements as? Self {
      self.append(contentsOf: newElements)
    } else if let newElements = newElements as? String {
      self.append(contentsOf: newElements)
    } else if let newElements = newElements as? Substring {
      self.append(contentsOf: newElements)
    } else {
      _guts.append(contentsOf: _BString(newElements))
    }
  }

  public mutating func append(contentsOf newElements: __owned String) {
    _guts.append(contentsOf: newElements)
  }

  public mutating func append(contentsOf newElements: __owned Substring) {
    _guts.append(contentsOf: newElements)
  }

  public mutating func append(contentsOf newElements: __owned Self) {
    _guts.append(contentsOf: newElements._guts)
  }

  public mutating func append(contentsOf newElements: __owned Self.SubSequence) {
    let lower = newElements.startIndex._value
    let upper = newElements.endIndex._value
    _guts._append(contentsOf: newElements.base._guts, in: lower ..< upper)
  }

  public mutating func insert(_ newElement: __owned Character, at i: Index) {
    _guts.insert(contentsOf: String(newElement), at: i._value)
  }

  public mutating func insert(contentsOf newElements: some Collection<Character>, at i: Index) {
    if let newElements = newElements as? Self {
      self.insert(contentsOf: newElements, at: i)
    } else if let newElements = newElements as? String {
      self.insert(contentsOf: newElements, at: i)
    } else if let newElements = newElements as? Substring {
      self.insert(contentsOf: newElements, at: i)
    } else {
      _guts.insert(contentsOf: _BString(newElements), at: i._value)
    }
  }

  public mutating func insert(contentsOf newElements: String, at i: Index) {
    _guts.insert(contentsOf: newElements, at: i._value)
  }

  public mutating func insert(contentsOf newElements: Substring, at i: Index) {
    _guts.insert(contentsOf: newElements, at: i._value)
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
  public mutating func remove(at i: Index) -> Character {
    _guts.removeCharacter(at: i._value)
  }

  public mutating func removeSubrange(_ bounds: Range<Index>) {
    _guts.removeSubrange(bounds._base)
  }

  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    _guts = _BString()
  }
}

#endif
