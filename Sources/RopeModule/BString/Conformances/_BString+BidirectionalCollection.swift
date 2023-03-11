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
extension _BString: BidirectionalCollection {
  typealias SubSequence = _BSubstring

  var isEmpty: Bool {
    rope.summary.isZero
  }

  var startIndex: Index {
    Index(_utf8Offset: 0)._knownCharacterAligned()
  }

  var endIndex: Index {
    Index(_utf8Offset: utf8Count)._knownCharacterAligned()
  }

  internal var count: Int { characterCount }

  @inline(__always)
  internal func index(after i: Index) -> Index {
    characterIndex(after: i)
  }

  @inline(__always)
  internal func index(before i: Index) -> Index {
    characterIndex(before: i)
  }

  @inline(__always)
  internal func index(_ i: Index, offsetBy distance: Int) -> Index {
    characterIndex(i, offsetBy: distance)
  }

  internal func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    characterIndex(i, offsetBy: distance, limitedBy: limit)
  }

  internal func distance(from start: Index, to end: Index) -> Int {
    characterDistance(from: start, to: end)
  }

  internal subscript(position: Index) -> Character {
    self[character: position]
  }

  internal subscript(bounds: Range<Index>) -> _BSubstring {
    _BSubstring(self, in: bounds)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal func index(roundingDown i: Index) -> Index {
    characterIndex(roundingDown: i)
  }

  internal func index(roundingUp i: Index) -> Index {
    characterIndex(roundingUp: i)
  }
}

#endif
