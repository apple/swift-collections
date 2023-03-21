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
extension BigString: RangeReplaceableCollection {
  public init() {
    self.init(_rope: _Rope())
  }

  public mutating func reserveCapacity(_ n: Int) {
    // Do nothing.
  }

  public mutating func replaceSubrange<S: Sequence<Character>>( // Note: Sequence, not Collection
    _ subrange: Range<Index>, with newElements: __owned S
  ) {
    if S.self == String.self {
      let newElements = _identityCast(newElements, to: String.self)
      self._replaceSubrange(subrange, with: newElements)
    } else if S.self == Substring.self {
      let newElements = _identityCast(newElements, to: Substring.self)
      self._replaceSubrange(subrange, with: newElements)
    } else if S.self == BigString.self {
      let newElements = _identityCast(newElements, to: BigString.self)
      self._replaceSubrange(subrange, with: newElements)
    } else if S.self == BigSubstring.self {
      let newElements = _identityCast(newElements, to: BigSubstring.self)
      self._replaceSubrange(subrange, with: newElements)
    } else {
      self._replaceSubrange(subrange, with: BigString(newElements))
    }
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned String
  ) {
    _replaceSubrange(subrange, with: newElements)
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned Substring
  ) {
    _replaceSubrange(subrange, with: newElements)
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned BigString
  ) {
    _replaceSubrange(subrange, with: newElements)
  }

  public mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned BigSubstring
  ) {
    _replaceSubrange(subrange, with: newElements)
  }

  public init<S: Sequence<Character>>(_ elements: S) {
    if S.self == String.self {
      let elements = _identityCast(elements, to: String.self)
      self.init(_from: elements)
    } else if S.self == Substring.self {
      let elements = _identityCast(elements, to: Substring.self)
      self.init(_from: elements)
    } else if S.self == BigString.self {
      self = _identityCast(elements, to: BigString.self)
    } else if S.self == BigSubstring.self {
      let elements = _identityCast(elements, to: BigSubstring.self)
      self.init(_from: elements)
    } else {
      self.init(_from: elements)
    }
  }

  public init(_ elements: String) {
    self.init(_from: elements)
  }

  public init(_ elements: Substring) {
    self.init(_from: elements)
  }

  public init(_ elements: BigString) {
    self = elements
  }

  public init(_ elements: BigSubstring) {
    self.init(_from: elements)
  }

  public init(repeating repeatedValue: Character, count: Int) {
    self.init(repeating: BigString(String(repeatedValue)), count: count)
  }

  public init(repeating repeatedValue: some StringProtocol, count: Int) {
    self.init(repeating: BigString(repeatedValue), count: count)
  }

  public init(repeating value: Self, count: Int) {
    precondition(count >= 0, "Negative count")
    guard count > 0 else {
      self.init()
      return
    }
    self.init()
    var c = 0

    var piece = value
    var current = 1

    while c < count {
      if count & current != 0 {
        self.append(contentsOf: piece)
        c |= current
      }
      piece.append(contentsOf: piece)
      current *= 2
    }
  }

  public init(repeating value: BigSubstring, count: Int) {
    self.init(repeating: BigString(value), count: count)
  }

  public mutating func append(_ newElement: __owned Character) {
    append(contentsOf: String(newElement))
  }

  public mutating func append<S: Sequence<Character>>(contentsOf newElements: __owned S) {
    if S.self == String.self {
      let newElements = _identityCast(newElements, to: String.self)
      append(contentsOf: newElements)
    } else if S.self == Substring.self {
      let newElements = _identityCast(newElements, to: Substring.self)
      append(contentsOf: newElements)
    } else if S.self == BigString.self {
      let newElements = _identityCast(newElements, to: BigString.self)
      append(contentsOf: newElements)
    } else if S.self == BigSubstring.self {
      let newElements = _identityCast(newElements, to: BigSubstring.self)
      append(contentsOf: newElements)
    } else {
      append(contentsOf: BigString(newElements))
    }
  }

  public mutating func append(contentsOf newElements: __owned String) {
    _append(contentsOf: newElements[...])
  }

  public mutating func append(contentsOf newElements: __owned Substring) {
    _append(contentsOf: newElements)
  }

  public mutating func append(contentsOf newElements: __owned BigString) {
    _append(contentsOf: newElements)
  }

  public mutating func append(contentsOf newElements: __owned BigSubstring) {
    _append(contentsOf: newElements._base, in: newElements._bounds)
  }

  public mutating func insert(_ newElement: Character, at i: Index) {
    insert(contentsOf: String(newElement), at: i)
  }

  public mutating func insert<S: Sequence<Character>>( // Note: Sequence, not Collection
    contentsOf newElements: __owned S, at i: Index
  ) {
    if S.self == String.self {
      let newElements = _identityCast(newElements, to: String.self)
      insert(contentsOf: newElements, at: i)
    } else if S.self == Substring.self {
      let newElements = _identityCast(newElements, to: Substring.self)
      insert(contentsOf: newElements, at: i)
    } else if S.self == BigString.self {
      let newElements = _identityCast(newElements, to: BigString.self)
      insert(contentsOf: newElements, at: i)
    } else if S.self == BigSubstring.self {
      let newElements = _identityCast(newElements, to: BigSubstring.self)
      insert(contentsOf: newElements, at: i)
    } else {
      insert(contentsOf: BigString(newElements), at: i)
    }
  }

  public mutating func insert(contentsOf newElements: __owned String, at i: Index) {
    _insert(contentsOf: newElements[...], at: i)
  }

  public mutating func insert(contentsOf newElements: __owned Substring, at i: Index) {
    _insert(contentsOf: newElements, at: i)
  }

  public mutating func insert(contentsOf newElements: __owned BigString, at i: Index) {
    _insert(contentsOf: newElements, at: i)
  }

  public mutating func insert(contentsOf newElements: __owned BigSubstring, at i: Index) {
    _insert(contentsOf: newElements._base, in: newElements._bounds, at: i)
  }

  @discardableResult
  public mutating func remove(at i: Index) -> Character {
    removeCharacter(at: i)
  }

  public mutating func removeSubrange(_ bounds: Range<Index>) {
    _removeSubrange(bounds)
  }

  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    self = BigString()
  }
}

#endif
