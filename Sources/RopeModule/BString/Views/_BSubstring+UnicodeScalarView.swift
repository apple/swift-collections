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
  internal struct UnicodeScalarView: Sendable {
    internal var _base: _BString
    internal var _bounds: Range<Index>

    internal init(_unchecked base: _BString, in bounds: Range<Index>) {
      self._base = base
      self._bounds = bounds
    }

    internal init(_ base: _BString, in bounds: Range<Index>) {
      self._base = base
      let lower = base.unicodeScalarIndex(roundingDown: bounds.lowerBound)
      let upper = base.unicodeScalarIndex(roundingDown: bounds.upperBound)
      self._bounds = Range(uncheckedBounds: (lower, upper))
    }

    internal init(_substring: _BSubstring) {
      self.init(_unchecked: _substring._base, in: _substring._bounds)
    }
  }

  internal var unicodeScalars: UnicodeScalarView {
    UnicodeScalarView(_substring: self)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal init(_ view: _BSubstring.UnicodeScalarView) {
    self.init(_from: view._base, in: view._bounds)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UnicodeScalarView {
  internal var base: _BString.UnicodeScalarView { _base.unicodeScalars }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UnicodeScalarView: Equatable {
  internal static func ==(left: Self, right: Self) -> Bool {
    _BString.utf8IsEqual(left._base, in: left._bounds, to: right._base, in: right._bounds)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UnicodeScalarView: Hashable {
  internal func hash(into hasher: inout Hasher) {
    _base.hashUTF8(into: &hasher, from: _bounds.lowerBound, to: _bounds.upperBound)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UnicodeScalarView: BidirectionalCollection {
  typealias Index = _BString.Index
  typealias Element = UnicodeScalar
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
    return _base.unicodeScalarIndex(after: i)
  }

  @inline(__always)
  internal func index(before i: Index) -> Index {
    precondition(i > startIndex, "Can't advance below start index")
    return _base.unicodeScalarIndex(before: i)
  }

  @inline(__always)
  internal func index(_ i: Index, offsetBy distance: Int) -> Index {
    precondition(i >= startIndex && i <= endIndex, "Index out of bounds")
    let j = _base.unicodeScalarIndex(i, offsetBy: distance)
    precondition(j >= startIndex && j <= endIndex, "Index out of bounds")
    return j
  }

  internal func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    precondition(i >= startIndex && i <= endIndex, "Index out of bounds")
    guard let j = _base.unicodeScalarIndex(i, offsetBy: distance, limitedBy: limit) else { return nil }
    precondition(j >= startIndex && j <= endIndex, "Index out of bounds")
    return j
  }

  internal func distance(from start: Index, to end: Index) -> Int {
    precondition(start >= startIndex && start <= endIndex, "Index out of bounds")
    precondition(end >= startIndex && end <= endIndex, "Index out of bounds")
    return _base.unicodeScalarDistance(from: start, to: end)
  }

  internal subscript(position: Index) -> UnicodeScalar {
    precondition(position >= startIndex && position < endIndex, "Index out of bounds")
    return _base[unicodeScalar: position]
  }

  internal subscript(bounds: Range<Index>) -> Self {
    precondition(
      bounds.lowerBound >= startIndex && bounds.upperBound <= endIndex,
      "Range out of bounds")
    return Self(_base, in: bounds)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UnicodeScalarView {
  /// Run the closure `body` to mutate the contents of this view within `range`, then update
  /// the bounds of this view to maintain their logical position in the resulting string.
  /// The `range` argument is validated to be within the original bounds of the substring.
  internal mutating func _mutateBasePreservingBounds<R>(
    in range: Range<Index>,
    with body: (inout _BString.UnicodeScalarView) -> R
  ) -> R {
    precondition(
      range.lowerBound >= _bounds.lowerBound && range.upperBound <= _bounds.upperBound,
      "Range out of bounds")

    let startOffset = self.startIndex._utf8Offset
    let endOffset = self.endIndex._utf8Offset
    let oldCount = self._base.utf8Count

    var view = _BString.UnicodeScalarView(_base: self._base)
    self._base = _BString()

    defer {
      // The Unicode scalar view is regular -- we just need to maintain the UTF-8 offsets of
      // our bounds across the mutation. No extra adjustment/rounding is necessary.
      self._base = view._base
      let delta = self._base.utf8Count - oldCount
      let start = _base.utf8Index(at: startOffset)._knownScalarAligned()
      let end = _base.utf8Index(at: endOffset + delta)._knownScalarAligned()
      self._bounds = start ..< end
    }
    return body(&view)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring.UnicodeScalarView: RangeReplaceableCollection {
  internal init() {
    self.init(_substring: _BSubstring())
  }
  
  internal mutating func reserveCapacity(_ n: Int) {
    // Do nothing.
  }
  
  internal mutating func replaceSubrange<C: Collection<UnicodeScalar>>(
    _ subrange: Range<Index>, with newElements: __owned C
  ) {
    _mutateBasePreservingBounds(in: subrange) { $0.replaceSubrange(subrange, with: newElements) }
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned String.UnicodeScalarView
  ) {
    _mutateBasePreservingBounds(in: subrange) { $0.replaceSubrange(subrange, with: newElements) }
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned Substring.UnicodeScalarView
  ) {
    _mutateBasePreservingBounds(in: subrange) { $0.replaceSubrange(subrange, with: newElements) }
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned _BString.UnicodeScalarView
  ) {
    _mutateBasePreservingBounds(in: subrange) { $0.replaceSubrange(subrange, with: newElements) }
  }

  internal mutating func replaceSubrange(
    _ subrange: Range<Index>, with newElements: __owned _BSubstring.UnicodeScalarView
  ) {
    _mutateBasePreservingBounds(in: subrange) { $0.replaceSubrange(subrange, with: newElements) }
  }

  internal init<S: Sequence<UnicodeScalar>>(_ elements: S) {
    let base = _BString.UnicodeScalarView(elements)
    self.init(base._base, in: base.startIndex ..< base.endIndex)
  }

  internal mutating func append<S: Sequence<UnicodeScalar>>(contentsOf newElements: __owned S) {
    _mutateBasePreservingBounds(in: endIndex ..< endIndex) {
      $0.append(contentsOf: newElements)
    }
  }

  internal mutating func insert(_ newElement: UnicodeScalar, at i: Index) {
    _mutateBasePreservingBounds(in: i ..< i) {
      $0.insert(newElement, at: i)
    }
  }


  internal mutating func insert<C: Collection<UnicodeScalar>>(
    contentsOf newElements: __owned C, at i: Index
  ) {
    _mutateBasePreservingBounds(in: i ..< i) {
      $0.insert(contentsOf: newElements, at: i)
    }
  }

  @discardableResult
  internal mutating func remove(at i: Index) -> UnicodeScalar {
    _mutateBasePreservingBounds(in: i ..< i) {
      $0.remove(at: i)
    }
  }

  internal mutating func removeSubrange(_ bounds: Range<Index>) {
    _mutateBasePreservingBounds(in: bounds) {
      $0.removeSubrange(bounds)
    }
  }

  internal mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    let bounds = _bounds
    _mutateBasePreservingBounds(in: bounds) {
      $0.removeSubrange(bounds)
    }
    assert(_bounds.isEmpty)
  }
}

#endif
