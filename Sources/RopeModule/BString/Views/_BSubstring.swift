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
struct _BSubstring: Sendable {
  var _base: _BString
  var _bounds: Range<Index>

  init(_unchecked base: _BString, in bounds: Range<Index>) {
    self._base = base
    self._bounds = bounds
  }

  init(_ base: _BString, in bounds: Range<Index>) {
    self._base = base
    // Sub-character slicing could change character boundaries in the tree, requiring
    // resyncing metadata. This would not be acceptable to do during slicing, so let's
    // round substring bounds down to the nearest character.
    let start = base.characterIndex(roundingDown: bounds.lowerBound)
    let end = base.characterIndex(roundingDown: bounds.upperBound)
    self._bounds = Range(uncheckedBounds: (start, end))
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring {
  internal var base: _BString { _base }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring {
  func _foreachChunk(
    _ body: (Substring) -> Void
  ) {
    self._base._foreachChunk(from: _bounds.lowerBound, to: _bounds.upperBound, body)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring: CustomStringConvertible {
  internal var description: String {
    String(_from: _base, in: _bounds)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring: ExpressibleByStringLiteral {
  internal init(stringLiteral value: String) {
    self.init(value)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring: LosslessStringConvertible {
  // init?(_: String) is implemented by RangeReplaceableCollection.init(_:)
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring: Equatable {
  internal static func ==(left: Self, right: Self) -> Bool {
    _BString.characterwiseIsEqual(left._base, in: left._bounds, to: right._base, in: right._bounds)
  }

  internal func isIdentical(to other: Self) -> Bool {
    guard self._base.isIdentical(to: other._base) else { return false }
    return self._bounds == other._bounds
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring: Hashable {
  internal func hash(into hasher: inout Hasher) {
    _base.hashCharacters(into: &hasher, from: _bounds)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring: Comparable {
  internal static func < (left: Self, right: Self) -> Bool {
    // FIXME: Implement properly normalized comparisons & hashing.
    // This is somewhat tricky as we shouldn't just normalize individual pieces of the string
    // split up on random Character boundaries -- Unicode does not promise that
    // norm(a + c) == norm(a) + norm(b) in this case.
    // To do this properly, we'll probably need to expose new stdlib entry points. :-/
    if left.isIdentical(to: right) { return false }
    // FIXME: Even if we keep doing characterwise comparisons, we should skip over shared subtrees.
    var it1 = left.makeIterator()
    var it2 = right.makeIterator()
    while true {
      switch (it1.next(), it2.next()) {
      case (nil, nil): return false
      case (nil, .some): return true
      case (.some, nil): return false
      case let (a?, b?):
        if a == b { continue }
        return a < b
      }
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring: Sequence {
  typealias Element = Character

  internal struct Iterator: IteratorProtocol {
    let _end: _BString.Index
    var _it: _BString.Iterator

    init(_substring: _BSubstring) {
      self._it = _substring._base.makeCharacterIterator(from: _substring.startIndex)
      self._end = _substring.endIndex
    }

    internal mutating func next() -> Character? {
      guard _it.isBelow(_end) else { return nil }
      return _it.next()
    }
  }

  internal func makeIterator() -> Iterator {
    Iterator(_substring: self)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring: BidirectionalCollection {
  typealias Index = _BString.Index
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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring {
  /// Run the closure `body` to mutate the contents of this view within `range`, then update
  /// the bounds of this view to maintain an approximation of their logical position in the
  /// resulting string.
  ///
  /// The `range` argument is validated to be within the original bounds of the substring.
  internal mutating func _mutateBasePreservingBounds<R>(
    in range: Range<Index>,
    with body: (inout _BString) -> R
  ) -> R {
    precondition(
      range.lowerBound >= _bounds.lowerBound && range.upperBound <= _bounds.upperBound,
      "Range out of bounds")

    let startOffset = self.startIndex._utf8Offset
    let endOffset = self.endIndex._utf8Offset
    let oldCount = self._base.utf8Count

    defer {
      // Substring mutations may change grapheme boundaries across the bounds of the original
      // substring value, and we need to ensure that the substring's bounds remain well-aligned.
      // Unfortunately, there are multiple ways of doing this, none of which are obviously
      // superior to others. To keep the behavior easier to explan, we emulate substring
      // initialization and round the start and end indices down to the nearest Character boundary
      // after each mutation.
      let delta = self._base.utf8Count - oldCount
      let start = _base.characterIndex(roundingDown: Index(_utf8Offset: startOffset))
      let end = _base.characterIndex(roundingDown: Index(_utf8Offset: endOffset + delta))
      self._bounds = start ..< end
    }
    return body(&self._base)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring: RangeReplaceableCollection {
  init() {
    let str = _BString()
    let bounds = Range(uncheckedBounds: (str.startIndex, str.endIndex))
    self.init(_unchecked: str, in: bounds)
  }

  internal mutating func replaceSubrange<C: Collection>(
    _ subrange: Range<Index>, with newElements: C
  ) where C.Element == Character {
    _mutateBasePreservingBounds(in: subrange) {
      $0.replaceSubrange(subrange, with: newElements)
    }
  }
}

#endif
