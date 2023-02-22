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
  mutating func removeSubrange(_ bounds: Range<Index>) {
    precondition(bounds.upperBound <= endIndex, "Index out of bounds")
    if bounds.isEmpty { return }
    let lower = bounds.lowerBound._utf8Offset
    let upper = bounds.upperBound._utf8Offset
    rope.removeSubrange(lower ..< upper, in: UTF8Metric())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  mutating func removeCharacter(at i: Index) -> Character {
    let start = self.resolve(i, preferEnd: false)
    let (character, end) = self._character(at: start)
    self.removeSubrange(start ..< end)
    return character
  }

  mutating func removeUnicodeScalar(at i: Index) -> Unicode.Scalar {
    precondition(i < endIndex, "Index out of bounds")
    let start = unicodeScalarIndex(roundingDown: i)
    let ropeIndex = start._rope!
    let chunkIndex = start._chunkIndex
    let chunk = rope[ropeIndex]
    let scalar = chunk.string.unicodeScalars[chunkIndex]
    let next = chunk.string.unicodeScalars.index(after: chunkIndex)
    let end = Index(baseUTF8Offset: start._utf8BaseOffset, rope: ropeIndex, chunk: next)
    self.removeSubrange(start ..< end)
    return scalar
  }
}

#endif
