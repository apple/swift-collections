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
extension _BString {
  internal struct CharacterView {
    var _base: _BString

    @inline(__always)
    init(_base: _BString) {
      self._base = _base
    }
  }

  @inline(__always)
  internal var characters: CharacterView {
    CharacterView(_base: self)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.CharacterView: Equatable {
  internal static func ==(left: Self, right: Self) -> Bool {
    left._base.characterIsEqual(to: right._base)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.CharacterView: Hashable {
  internal func hash(into hasher: inout Hasher) {
    _base.hashCharacters(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.CharacterView: BidirectionalCollection {
  typealias Index = _BString.Index
  typealias Element = Character
  typealias SubSequence = _BSubstring.CharacterView

  @inline(__always)
  internal var startIndex: Index { _base.startIndex }

  @inline(__always)
  internal var endIndex: Index { _base.endIndex }

  internal var count: Int { _base.characterCount }

  @inline(__always)
  internal func index(after i: Index) -> Index {
    _base.characterIndex(after: i)
  }

  @inline(__always)
  internal func index(before i: Index) -> Index {
    _base.characterIndex(before: i)
  }

  @inline(__always)
  internal func index(_ i: Index, offsetBy distance: Int) -> Index {
    _base.characterIndex(i, offsetBy: distance)
  }

  internal func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    _base.characterIndex(i, offsetBy: distance, limitedBy: limit)
  }

  internal func distance(from start: Index, to end: Index) -> Int {
    _base.characterDistance(from: start, to: end)
  }

  internal subscript(position: Index) -> Character {
    _base[character: position]
  }

  internal subscript(bounds: Range<Index>) -> _BSubstring.CharacterView {
    _BSubstring.CharacterView(_base, in: bounds)
  }
}

#endif
