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
  internal struct UnicodeScalarView {
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
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UnicodeScalarView: Equatable {
  internal static func ==(left: Self, right: Self) -> Bool {
    left._base.utf8IsEqual(to: right._base)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UnicodeScalarView: Hashable {
  internal func hash(into hasher: inout Hasher) {
    _base.hashUTF8(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UnicodeScalarView: BidirectionalCollection {
  typealias Index = _BString.Index
  typealias Element = UnicodeScalar
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

#endif
