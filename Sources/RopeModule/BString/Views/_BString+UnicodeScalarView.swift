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
  internal struct UnicodeScalarView: Sendable {
    var _base: _BString

    @inline(__always)
    init(_base: _BString) {
      self._base = _base
    }
  }

  @inline(__always)
  internal var unicodeScalars: UnicodeScalarView {
    UnicodeScalarView(_base: self)
  }

  internal init(_ view: _BString.UnicodeScalarView) {
    self = view._base
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UnicodeScalarView: Equatable {
  internal static func ==(left: Self, right: Self) -> Bool {
    _BString.utf8IsEqual(left._base, to: right._base)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UnicodeScalarView: Hashable {
  internal func hash(into hasher: inout Hasher) {
    _base.hashUTF8(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UnicodeScalarView: Sequence {
  typealias Element = UnicodeScalar
  typealias Iterator = _BString.UnicodeScalarIterator

  internal func makeIterator() -> _BString.UnicodeScalarIterator {
    _base.makeUnicodeScalarIterator()
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UnicodeScalarView: BidirectionalCollection {
  typealias Index = _BString.Index
  typealias SubSequence = _BSubstring.UnicodeScalarView

  @inline(__always)
  internal var startIndex: Index { _base.startIndex }

  @inline(__always)
  internal var endIndex: Index { _base.endIndex }

  internal var count: Int { _base.unicodeScalarCount }

  @inline(__always)
  internal func index(after i: Index) -> Index {
    _base.unicodeScalarIndex(after: i)
  }

  @inline(__always)
  internal func index(before i: Index) -> Index {
    _base.unicodeScalarIndex(before: i)
  }

  @inline(__always)
  internal func index(_ i: Index, offsetBy distance: Int) -> Index {
    _base.unicodeScalarIndex(i, offsetBy: distance)
  }

  internal func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    _base.unicodeScalarIndex(i, offsetBy: distance, limitedBy: limit)
  }

  internal func distance(from start: Index, to end: Index) -> Int {
    _base.unicodeScalarDistance(from: start, to: end)
  }

  internal subscript(position: Index) -> UnicodeScalar {
    _base[unicodeScalar: position]
  }

  internal subscript(bounds: Range<Index>) -> _BSubstring.UnicodeScalarView {
    _BSubstring.UnicodeScalarView(_base, in: bounds)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UnicodeScalarView: RangeReplaceableCollection {
  internal init() {
    self._base = _BString()
  }

  internal mutating func reserveCapacity(_ n: Int) {
    // Do nothing.
  }

  internal mutating func replaceSubrange<C: Collection<UnicodeScalar>>(
    _ subrange: Range<Index>, with newElements: __owned C
  ) {
    if C.self == String.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: String.UnicodeScalarView.self)
      _base._replaceSubrange(subrange, with: String(newElements))
    } else if C.self == Substring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: Substring.UnicodeScalarView.self)
      _base._replaceSubrange(subrange, with: Substring(newElements))
    } else if C.self == _BString.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: _BString.UnicodeScalarView.self)
      _base._replaceSubrange(subrange, with: newElements._base)
    } else if C.self == _BSubstring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: _BSubstring.UnicodeScalarView.self)
      _base._replaceSubrange(subrange, with: newElements._base, in: newElements._bounds)
    } else {
      _base._replaceSubrange(subrange, with: _BString(_from: newElements))
    }
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned String.UnicodeScalarView
  ) {
    _base._replaceSubrange(subrange, with: String(newElements))
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned Substring.UnicodeScalarView
  ) {
    _base._replaceSubrange(subrange, with: Substring(newElements))
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned _BString.UnicodeScalarView
  ) {
    _base._replaceSubrange(subrange, with: newElements._base)
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned _BSubstring.UnicodeScalarView
  ) {
    _base._replaceSubrange(subrange, with: newElements._base, in: newElements._bounds)
  }

  internal init<S: Sequence<UnicodeScalar>>(_ elements: S) {
    if S.self == String.UnicodeScalarView.self {
      let elements = _identityCast(elements, to: String.UnicodeScalarView.self)
      self.init(_base: _BString(_from: elements))
    } else if S.self == Substring.UnicodeScalarView.self {
      let elements = _identityCast(elements, to: Substring.UnicodeScalarView.self)
      self.init(_base: _BString(_from: elements))
    } else if S.self == _BString.UnicodeScalarView.self {
      let elements = _identityCast(elements, to: _BString.UnicodeScalarView.self)
      self.init(_base: elements._base)
    } else if S.self == _BSubstring.UnicodeScalarView.self {
      let elements = _identityCast(elements, to: _BSubstring.UnicodeScalarView.self)
      self.init(_base: _BString(_from: elements._base, in: elements._bounds))
    } else {
      self.init(_base: _BString(_from: elements))
    }
  }

  internal init(_ elements: String.UnicodeScalarView) {
    self.init(_base: _BString(_from: elements))
  }

  internal init(_ elements: Substring.UnicodeScalarView) {
    self.init(_base: _BString(_from: elements))
  }

  internal init(_ elements: _BString.UnicodeScalarView) {
    self.init(_base: elements._base)
  }

  internal init(_ elements: _BSubstring.UnicodeScalarView) {
    self.init(_base: _BString(_from: elements._base, in: elements._bounds))
  }

  internal init(repeating repeatedValue: UnicodeScalar, count: Int) {
    self.init(_base: _BString(repeating: _BString(String(repeatedValue)), count: count))
  }

  internal init(repeating repeatedValue: some StringProtocol, count: Int) {
    self.init(_base: _BString(repeating: _BString(_from: repeatedValue), count: count))
  }

  internal init(repeating value: _BString.UnicodeScalarView, count: Int) {
    self.init(_base: _BString(repeating: value._base, count: count))
  }

  internal init(repeating value: _BSubstring.UnicodeScalarView, count: Int) {
    let value = _BString(value)
    self.init(_base: _BString(repeating: value, count: count))
  }

  internal mutating func append(_ newElement: __owned UnicodeScalar) {
    _base.append(contentsOf: String(newElement))
  }

  internal mutating func append<S: Sequence<UnicodeScalar>>(contentsOf newElements: __owned S) {
    if S.self == String.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: String.UnicodeScalarView.self)
      append(contentsOf: newElements)
    } else if S.self == Substring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: Substring.UnicodeScalarView.self)
      append(contentsOf: newElements)
    } else if S.self == _BString.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: _BString.UnicodeScalarView.self)
      append(contentsOf: newElements)
    } else if S.self == _BSubstring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: _BSubstring.UnicodeScalarView.self)
      append(contentsOf: newElements)
    } else {
      _base.append(contentsOf: _BString(_from: newElements))
    }
  }

  internal mutating func append(contentsOf newElements: __owned String.UnicodeScalarView) {
    _base.append(contentsOf: String(newElements))
  }

  internal mutating func append(contentsOf newElements: __owned Substring.UnicodeScalarView) {
    _base.append(contentsOf: Substring(newElements))
  }

  internal mutating func append(contentsOf newElements: __owned _BString.UnicodeScalarView) {
    _base.append(contentsOf: newElements._base)
  }

  internal mutating func append(contentsOf newElements: __owned _BSubstring.UnicodeScalarView) {
    _base._append(contentsOf: newElements._base, in: newElements._bounds)
  }

  internal mutating func insert(_ newElement: UnicodeScalar, at i: Index) {
    _base.insert(contentsOf: String(newElement), at: i)
  }

  internal mutating func insert<C: Collection<UnicodeScalar>>(
    contentsOf newElements: __owned C, at i: Index
  ) {
    if C.self == String.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: String.UnicodeScalarView.self)
      insert(contentsOf: newElements, at: i)
    } else if C.self == Substring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: Substring.UnicodeScalarView.self)
      insert(contentsOf: newElements, at: i)
    } else if C.self == _BString.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: _BString.UnicodeScalarView.self)
      insert(contentsOf: newElements, at: i)
    } else if C.self == _BSubstring.UnicodeScalarView.self {
      let newElements = _identityCast(newElements, to: _BSubstring.UnicodeScalarView.self)
      insert(contentsOf: newElements, at: i)
    } else {
      _base.insert(contentsOf: _BString(_from: newElements), at: i)
    }
  }

  internal mutating func insert(
    contentsOf newElements: __owned String.UnicodeScalarView,
    at i: Index
  ) {
    _base.insert(contentsOf: String(newElements), at: i)
  }

  internal mutating func insert(
    contentsOf newElements: __owned Substring.UnicodeScalarView,
    at i: Index
  ) {
    _base.insert(contentsOf: Substring(newElements), at: i)
  }

  internal mutating func insert(
    contentsOf newElements: __owned _BString.UnicodeScalarView,
    at i: Index
  ) {
    _base.insert(contentsOf: newElements._base, at: i)
  }

  internal mutating func insert(
    contentsOf newElements: __owned _BSubstring.UnicodeScalarView,
    at i: Index
  ) {
    _base._insert(contentsOf: newElements._base, in: newElements._bounds, at: i)
  }

  @discardableResult
  internal mutating func remove(at i: Index) -> UnicodeScalar {
    _base.removeUnicodeScalar(at: i)
  }

  internal mutating func removeSubrange(_ bounds: Range<Index>) {
    _base._removeSubrange(bounds)
  }

  internal mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    self._base = _BString()
  }
}

#endif
