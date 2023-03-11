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
  internal struct UTF16View: Sendable {
    internal var _base: _BString
    internal var _bounds: Range<Index>

    internal init(_unchecked base: _BString, in bounds: Range<Index>) {
      self._base = base
      self._bounds = bounds
    }

    internal init(_ base: _BString, in bounds: Range<Index>) {
      self._base = base
      let lower = base.utf16Index(roundingDown: bounds.lowerBound)
      let upper = base.utf16Index(roundingDown: bounds.upperBound)
      self._bounds = Range(uncheckedBounds: (lower, upper))
    }

    internal init(_substring: _BSubstring) {
      self.init(_unchecked: _substring._base, in: _substring._bounds)
    }
  }

  internal var utf16: UTF16View {
    UTF16View(_substring: self)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UTF16View {
  internal var base: _BString.UTF16View { _base.utf16 }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UTF16View: Equatable {
  internal static func ==(left: Self, right: Self) -> Bool {
    var i1 = left._bounds.lowerBound
    var i2 = right._bounds.lowerBound

    var j1 = left._bounds.upperBound
    var j2 = right._bounds.upperBound

    // Compare first code units, if they're trailing surrogates.
    guard i1._isUTF16TrailingSurrogate == i2._isUTF16TrailingSurrogate else { return false }
    if i1._isUTF16TrailingSurrogate {
      guard left[i1] == right[i2] else { return false }
      left.formIndex(after: &i1)
      left.formIndex(after: &i2)
    }
    guard i1 < j1, i2 < j2 else { return i1 == j1 && i2 == j2 }

    // Compare last code units, if they're trailing surrogates.
    guard j1._isUTF16TrailingSurrogate == j2._isUTF16TrailingSurrogate else { return false }
    if j1._isUTF16TrailingSurrogate {
      left.formIndex(before: &j1)
      right.formIndex(before: &j2)
      guard left[j1] == right[j2] else { return false}
    }

    return _BString.utf8IsEqual(left._base, in: i1 ..< j1, to: right._base, in: i2 ..< j2)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UTF16View: Hashable {
  internal func hash(into hasher: inout Hasher) {
    for codeUnit in self {
      hasher.combine(codeUnit)
    }
    hasher.combine(0xFFFF as UInt16)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UTF16View: Sequence {
  typealias Element = UInt16

  internal struct Iterator: IteratorProtocol {
    var _it: _BString.UTF16Iterator
    var _end: _BString.Index

    init(_substring: _BSubstring.UTF16View) {
      self._it = _substring._base.makeUTF16Iterator(from: _substring.startIndex)
      self._end = _substring.endIndex
    }

    internal mutating func next() -> UInt16? {
      guard _it._index < _end else { return nil }
      return _it.next()
    }
  }

  internal func makeIterator() -> Iterator {
    Iterator(_substring: self)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UTF16View: BidirectionalCollection {
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
    return _base.utf16Index(after: i)
  }

  @inline(__always)
  internal func index(before i: Index) -> Index {
    precondition(i > startIndex, "Can't advance below start index")
    return _base.utf16Index(before: i)
  }

  @inline(__always)
  internal func index(_ i: Index, offsetBy distance: Int) -> Index {
    precondition(i >= startIndex && i <= endIndex, "Index out of bounds")
    let j = _base.utf16Index(i, offsetBy: distance)
    precondition(j >= startIndex && j <= endIndex, "Index out of bounds")
    return j
  }

  internal func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    precondition(i >= startIndex && i <= endIndex, "Index out of bounds")
    guard let j = _base.utf16Index(i, offsetBy: distance, limitedBy: limit) else { return nil }
    precondition(j >= startIndex && j <= endIndex, "Index out of bounds")
    return j
  }

  internal func distance(from start: Index, to end: Index) -> Int {
    precondition(start >= startIndex && start <= endIndex, "Index out of bounds")
    precondition(end >= startIndex && end <= endIndex, "Index out of bounds")
    return _base.utf16Distance(from: start, to: end)
  }

  internal subscript(position: Index) -> UInt16 {
    precondition(position >= startIndex && position < endIndex, "Index out of bounds")
    return _base[utf16: position]
  }

  internal subscript(bounds: Range<Index>) -> Self {
    precondition(
      bounds.lowerBound >= startIndex && bounds.upperBound <= endIndex,
      "Range out of bounds")
    return Self(_base, in: bounds)
  }
}

#endif
