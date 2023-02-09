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
    let (start, chunk) = self.path(to: i, preferEnd: false)
    let startBase = baseIndex(with: i, at: start.chunk)
    let (character, end, endBase) = self._character(at: start, base: startBase, in: chunk)
    let j = endBase!._advanceUTF8(by: end.chunk._utf8Offset)
    self.removeSubrange(i ..< j)
    return character
  }

  mutating func removeUnicodeScalar(at i: Index) -> Unicode.Scalar {
    let (path, chunk) = self.path(to: i, preferEnd: false)
    assert(path.chunk < chunk.string.endIndex)
    let base = baseIndex(with: i, at: path.chunk)
    let scalar = chunk.string.unicodeScalars[path.chunk]
    let end = chunk.string.unicodeScalars.index(after: path.chunk)
    let j = index(base: base, offsetBy: end)
    self.removeSubrange(i ..< j)
    return scalar
  }
}

#endif
