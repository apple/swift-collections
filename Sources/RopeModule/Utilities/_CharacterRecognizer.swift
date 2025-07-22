//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2)

@available(SwiftStdlib 6.2, *)
internal typealias _CharacterRecognizer = Unicode._CharacterRecognizer

@available(SwiftStdlib 6.2, *)
extension _CharacterRecognizer {
  internal func _isKnownEqual(to other: Self) -> Bool {
    return self == other
  }
}


@available(SwiftStdlib 6.2, *)
extension _CharacterRecognizer {
  mutating func firstBreak(
    in str: Substring
  ) -> Range<String.Index>? {
    let r = str.utf8.withContiguousStorageIfAvailable { buffer in
      self._firstBreak(inUncheckedUnsafeUTF8Buffer: buffer)
    }
    if let r {
      guard let scalarRange = r else { return nil }
      let lower = str._utf8Index(at: scalarRange.lowerBound)
      let upper = str._utf8Index(at: scalarRange.upperBound)
      return lower ..< upper
    }
    guard !str.isEmpty else { return nil }

    var i = str.startIndex
    while i < str.endIndex {
      let next = str.unicodeScalars.index(after: i)
      let scalar = str.unicodeScalars[i]
      if self.hasBreak(before: scalar) {
        return i ..< next
      }
      i = next
    }
    return nil
  }
}

@available(SwiftStdlib 6.2, *)
extension _CharacterRecognizer {
  mutating func firstBreak(
    in c: BigString._Chunk,
    from range: Range<BigString._Chunk.Index>
  ) -> Range<BigString._Chunk.Index>? {
    let bias = range.lowerBound.utf8Offset
    let r = c.utf8Span(from: range.lowerBound, to: range.upperBound).span.withUnsafeBufferPointer {
      _firstBreak(inUncheckedUnsafeUTF8Buffer: $0)
    }

    guard let r else {
      return nil
    }

    let lower = BigString._Chunk.Index(utf8Offset: r.lowerBound + bias)
    let upper = BigString._Chunk.Index(utf8Offset: r.upperBound + bias)
    return lower ..< upper
  }
}

@available(SwiftStdlib 6.2, *)
extension _CharacterRecognizer {
  init(partialCharacter: UTF8Span) {
    self.init()

    var iter = partialCharacter.makeUnicodeScalarIterator()

    guard let first = iter.next() else {
      return
    }
    _ = hasBreak(before: first)

    while let s = iter.next() {
      let b = hasBreak(before: s)
      assert(!b)
    }
  }

  mutating func consumePartialCharacter(_ span: UTF8Span) {
    var iter = span.makeUnicodeScalarIterator()

    while let s = iter.next() {
      let b = hasBreak(before: s)
      assert(!b)
    }
  }

  mutating func consumeUntilFirstBreak(
    in s: Substring.UnicodeScalarView,
    from i: inout String.Index
  ) -> String.Index? {
    while i < s.endIndex {
      defer { s.formIndex(after: &i) }
      if hasBreak(before: s[i]) {
        return i
      }
    }
    return nil
  }

  init(consuming str: some StringProtocol) {
    self.init()
    _ = self.consume(str)
  }

  mutating func consume(
    _ s: some StringProtocol
  ) -> (characters: Int, firstBreak: String.Index, lastBreak: String.Index)? {
    consume(Substring(s))
  }

  mutating func consume(
    _ s: Substring
  ) -> (characters: Int, firstBreak: String.Index, lastBreak: String.Index)? {
    consume(s.unicodeScalars)
  }

  mutating func consume(
    _ s: Substring.UnicodeScalarView
  ) -> (characters: Int, firstBreak: String.Index, lastBreak: String.Index)? {
    var i = s.startIndex
    guard let first = consumeUntilFirstBreak(in: s, from: &i) else {
      return nil
    }
    var characters = 1
    var last = first
    while let next = consumeUntilFirstBreak(in: s, from: &i) {
      characters += 1
      last = next
    }
    return (characters, first, last)
  }

  mutating func consumeUntilFirstBreak(
    _ c: BigString._Chunk,
    in range: Range<BigString._Chunk.Index>,
    from i: inout BigString._Chunk.Index
  ) -> BigString._Chunk.Index? {
    while i < range.upperBound {
      defer {
        i = c.scalarIndex(after: i)
      }
      if hasBreak(before: c[scalar: i]) {
        return i
      }
    }
    return nil
  }

  mutating func consume(
    _ chunk: BigString._Chunk,
    _ range: Range<BigString._Chunk.Index>
  ) -> (characters: Int, firstBreak: BigString._Chunk.Index, lastBreak: BigString._Chunk.Index)? {
    var i = range.lowerBound

    guard let first = consumeUntilFirstBreak(chunk, in: range, from: &i) else {
      return nil
    }

    var characters = 1
    var last = first

    while let next = consumeUntilFirstBreak(chunk, in: range, from: &i) {
      characters += 1
      last = next
    }

    return (characters, first, last)
  }

  mutating func edgeCounts(
    consuming c: BigString._Chunk
  ) -> (characters: Int, prefixCount: Int, suffixCount: Int) {
    let count = c.utf8Count
    guard let (chars, first, last) = consume(c, c.startIndex..<c.endIndex) else {
      return (0, count, count)
    }
    let prefix = first.utf8Offset
    let suffix = count - last.utf8Offset
    return (chars, prefix, suffix)
  }
}

#endif // compiler(>=6.2)
