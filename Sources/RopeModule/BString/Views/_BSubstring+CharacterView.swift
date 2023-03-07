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
extension _BSubstring {
  internal struct CharacterView {
    internal var _base: _BString
    internal var _bounds: Range<Index>

    internal init(_unchecked base: _BString, in bounds: Range<Index>) {
      self._base = base
      self._bounds = bounds
    }

    internal init(_ base: _BString, in bounds: Range<Index>) {
      self._base = base
      let lower = base.characterIndex(roundingDown: bounds.lowerBound)
      let upper = base.characterIndex(roundingDown: bounds.upperBound)
      self._bounds = Range(uncheckedBounds: (lower, upper))
    }

    internal init(_substring: _BSubstring) {
      self.init(_unchecked: _substring._base, in: _substring._bounds)
    }
  }

  internal var characters: CharacterView {
    CharacterView(_substring: self)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.CharacterView {
  internal var base: _BString.CharacterView { _base.characters }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.CharacterView: Equatable {
  internal static func ==(left: Self, right: Self) -> Bool {
    _BString.characterIsEqual(left._base, in: left._bounds, to: right._base, in: right._bounds)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.CharacterView: Hashable {
  internal func hash(into hasher: inout Hasher) {
    _base.hashCharacters(into: &hasher, from: _bounds)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.CharacterView: BidirectionalCollection {
  typealias Index = _BString.Index
  typealias Element = Character
  typealias SubSequence = Self

  @inline(__always)
  internal var startIndex: Index { _bounds.lowerBound }

  @inline(__always)
  internal var endIndex: Index { _bounds.upperBound }

  internal var count: Int {
    distance(from: _bounds.lowerBound, to: _bounds.upperBound)
  }

  @inline(__always)
  internal func index(after i: Index) -> Index {
    precondition(i < endIndex, "Can't advance above end index")
    return _base.characterIndex(after: i)
  }

  @inline(__always)
  internal func index(before i: Index) -> Index {
    precondition(i > startIndex, "Can't advance below start index")
    return _base.characterIndex(before: i)
  }

  @inline(__always)
  internal func index(_ i: Index, offsetBy distance: Int) -> Index {
    precondition(i >= startIndex && i <= endIndex, "Index out of bounds")
    let j = _base.characterIndex(i, offsetBy: distance)
    precondition(j >= startIndex && j <= endIndex, "Index out of bounds")
    return j
  }

  internal func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    precondition(i >= startIndex && i <= endIndex, "Index out of bounds")
    guard let j = _base.characterIndex(i, offsetBy: distance, limitedBy: limit) else { return nil }
    precondition(j >= startIndex && j <= endIndex, "Index out of bounds")
    return j
  }

  internal func distance(from start: Index, to end: Index) -> Int {
    precondition(start >= startIndex && start <= endIndex, "Index out of bounds")
    precondition(end >= startIndex && end <= endIndex, "Index out of bounds")
    return _base.characterDistance(from: start, to: end)
  }

  internal subscript(position: Index) -> Character {
    precondition(position >= startIndex && position < endIndex, "Index out of bounds")
    return _base[character: position]
  }

  internal subscript(bounds: Range<Index>) -> Self {
    precondition(
      bounds.lowerBound >= startIndex && bounds.upperBound <= endIndex,
      "Range out of bounds")
    return Self(_base, in: bounds)
  }
}

#endif
