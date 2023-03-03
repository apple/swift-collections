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
struct _BSubstring {
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
extension _BString {
  internal subscript(bounds: Range<Index>) -> _BSubstring {
    _BSubstring(self, in: bounds)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring {
  internal var base: _BString { _base }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BSubstring {
  typealias Index = _BString.Index

  internal var startIndex: Index { _bounds.lowerBound }

  internal var endIndex: Index { _bounds.upperBound }

  internal subscript(bounds: Range<Index>) -> _BSubstring {
    precondition(
      bounds.lowerBound >= startIndex && bounds.upperBound <= endIndex,
      "Range out of bounds")
    return _BSubstring(self._base, in: bounds)
  }
}

#endif
