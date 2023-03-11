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
extension _BString: RangeReplaceableCollection {
  internal init() {
    self.init(rope: Rope())
  }

  internal mutating func reserveCapacity(_ n: Int) {
    // Do nothing.
  }

  internal mutating func replaceSubrange<C: Collection<Character>>(
    _ subrange: Range<Index>, with newElements: __owned C
  ) {
    if C.self == String.self {
      let newElements = _identityCast(newElements, to: String.self)
      self._replaceSubrange(subrange, with: newElements)
    } else if C.self == Substring.self {
      let newElements = _identityCast(newElements, to: Substring.self)
      self._replaceSubrange(subrange, with: newElements)
    } else if C.self == _BString.self {
      let newElements = _identityCast(newElements, to: _BString.self)
      self._replaceSubrange(subrange, with: newElements)
    } else if C.self == _BSubstring.self {
      let newElements = _identityCast(newElements, to: _BSubstring.self)
      self._replaceSubrange(subrange, with: newElements)
    } else {
      self._replaceSubrange(subrange, with: _BString(newElements))
    }
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned String
  ) {
    _replaceSubrange(subrange, with: newElements)
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned Substring
  ) {
    _replaceSubrange(subrange, with: newElements)
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned _BString
  ) {
    _replaceSubrange(subrange, with: newElements)
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned _BSubstring
  ) {
    _replaceSubrange(subrange, with: newElements)
  }

  internal init<S: Sequence<Character>>(_ elements: S) {
    if S.self == String.self {
      let elements = _identityCast(elements, to: String.self)
      self.init(_from: elements)
    } else if S.self == Substring.self {
      let elements = _identityCast(elements, to: Substring.self)
      self.init(_from: elements)
    } else if S.self == _BString.self {
      self = _identityCast(elements, to: _BString.self)
    } else if S.self == _BSubstring.self {
      let elements = _identityCast(elements, to: _BSubstring.self)
      self.init(_from: elements)
    } else {
      self.init(_from: elements)
    }
  }

  internal init(_ elements: String) {
    self.init(_from: elements)
  }

  internal init(_ elements: Substring) {
    self.init(_from: elements)
  }

  internal init(_ elements: _BString) {
    self = elements
  }

  internal init(_ elements: _BSubstring) {
    self.init(_from: elements)
  }

  internal init(repeating repeatedValue: Character, count: Int) {
    self.init(repeating: _BString(String(repeatedValue)), count: count)
  }

  internal init(repeating repeatedValue: some StringProtocol, count: Int) {
    self.init(repeating: _BString(repeatedValue), count: count)
  }

  internal init(repeating value: Self, count: Int) {
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

  internal mutating func append(_ newElement: __owned Character) {
    append(contentsOf: String(newElement))
  }

  internal mutating func append<S: Sequence<Character>>(contentsOf newElements: __owned S) {
    if S.self == String.self {
      let newElements = _identityCast(newElements, to: String.self)
      append(contentsOf: newElements)
    } else if S.self == Substring.self {
      let newElements = _identityCast(newElements, to: Substring.self)
      append(contentsOf: newElements)
    } else if S.self == _BString.self {
      let newElements = _identityCast(newElements, to: _BString.self)
      append(contentsOf: newElements)
    } else if S.self == _BSubstring.self {
      let newElements = _identityCast(newElements, to: _BSubstring.self)
      append(contentsOf: newElements)
    } else {
      append(contentsOf: _BString(newElements))
    }
  }

  internal mutating func append(contentsOf newElements: __owned String) {
    _append(contentsOf: newElements[...])
  }

  internal mutating func append(contentsOf newElements: __owned Substring) {
    _append(contentsOf: newElements)
  }

  internal mutating func append(contentsOf newElements: __owned _BString) {
    _append(contentsOf: newElements)
  }

  internal mutating func append(contentsOf newElements: __owned _BSubstring) {
    _append(contentsOf: newElements._base, in: newElements._bounds)
  }

  internal mutating func insert(_ newElement: Character, at i: Index) {
    insert(contentsOf: String(newElement), at: i)
  }

  internal mutating func insert<C: Collection<Character>>(
    contentsOf newElements: __owned C, at i: Index
  ) {
    if C.self == String.self {
      let newElements = _identityCast(newElements, to: String.self)
      insert(contentsOf: newElements, at: i)
    } else if C.self == Substring.self {
      let newElements = _identityCast(newElements, to: Substring.self)
      insert(contentsOf: newElements, at: i)
    } else if C.self == _BString.self {
      let newElements = _identityCast(newElements, to: _BString.self)
      insert(contentsOf: newElements, at: i)
    } else if C.self == _BSubstring.self {
      let newElements = _identityCast(newElements, to: _BSubstring.self)
      insert(contentsOf: newElements, at: i)
    } else {
      insert(contentsOf: _BString(newElements), at: i)
    }
  }

  internal mutating func insert(contentsOf newElements: __owned String, at i: Index) {
    _insert(contentsOf: newElements[...], at: i)
  }

  internal mutating func insert(contentsOf newElements: __owned Substring, at i: Index) {
    _insert(contentsOf: newElements, at: i)
  }

  internal mutating func insert(contentsOf newElements: __owned _BString, at i: Index) {
    _insert(contentsOf: newElements, at: i)
  }

  internal mutating func insert(contentsOf newElements: __owned _BSubstring, at i: Index) {
    _insert(contentsOf: newElements._base, in: newElements._bounds, at: i)
  }

  @discardableResult
  internal mutating func remove(at i: Index) -> Character {
    removeCharacter(at: i)
  }

  internal mutating func removeSubrange(_ bounds: Range<Index>) {
    _removeSubrange(bounds)
  }

  internal mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    self = _BString()
  }
}

#endif
