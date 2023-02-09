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
internal typealias _CharacterRecognizer = Unicode._CharacterRecognizer

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _CharacterRecognizer {
  mutating func firstBreak(
    in str: Substring
  ) -> Range<String.Index>? {
    #if true
    var str = str
    let scalarRange = str.withUTF8 { buffer in
      self._firstBreak(inUncheckedUnsafeUTF8Buffer: buffer)
    }
    guard let scalarRange else { return nil }
    let lower = str._utf8Index(at: scalarRange.lowerBound)
    let upper = str._utf8Index(at: scalarRange.upperBound)
    return lower ..< upper
    #else
    guard !str.isEmpty else { return nil }
    let c = self.string.utf8.count
    if c == 0 {
      // Report a break before the first scalar at start
      let lower = str.startIndex
      let upper = str.unicodeScalars.index(after: lower)
      self.string = String(str.unicodeScalars[lower])
      return lower ..< upper
    }
    
    self.string += str
    let i = self.string.index(after: self.string.startIndex)
    if i == self.string.endIndex { return nil }
    
    // Keep first scalar following break; discard everything else.
    let offset = self.string._utf8Offset(of: i)
    precondition(offset >= c)
    self.string = String(self.string.unicodeScalars[i])
    let scalarWidth = self.string.utf8.count
    
    let lower = str._utf8Index(at: offset - c)
    let upper = str._utf8Index(at: offset - c + scalarWidth)
    return lower ..< upper
    #endif
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _CharacterRecognizer {
  init(partialCharacter: Substring.UnicodeScalarView) {
    self.init()
    var it = partialCharacter.makeIterator()
    guard let first = it.next() else { return }
    _ = hasBreak(before: first)
    while let next = it.next() {
      let b = hasBreak(before: next)
      assert(!b)
    }
  }
  
  init(partialCharacter: Substring) {
    self.init(partialCharacter: partialCharacter.unicodeScalars)
  }
  
  mutating func consumePartialCharacter(_ s: Substring) {
    for scalar in s.unicodeScalars {
      let b = hasBreak(before: scalar)
      assert(!b)
    }
  }
  
  mutating func consumePartialCharacter(_ s: Substring.UnicodeScalarView) {
    for scalar in s {
      let b = hasBreak(before: scalar)
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
  
  mutating func consume(
    _ chunk: _BString.Chunk, upTo index: String.Index
  ) -> (firstBreak: String.Index, prevBreak: String.Index)? {
    let index = chunk.string.unicodeScalars._index(roundingDown: index)
    let first = chunk.firstBreak
    guard index > first else {
      consumePartialCharacter(chunk.string[..<index])
      return nil
    }
    let last = chunk.lastBreak
    let prev = index <= last ? chunk.string[first...].index(before: index) : last
    consumePartialCharacter(chunk.string[prev..<index])
    return (first, prev)
  }
  
  mutating func edgeCounts(
    consuming s: String
  ) -> (characters: Int, prefixCount: Int, suffixCount: Int) {
    let c = s.utf8.count
    guard let (chars, first, last) = consume(s[...]) else {
      return (0, c, c)
    }
    let prefix = s._utf8Offset(of: first)
    let suffix = c - s._utf8Offset(of: last)
    return (chars, prefix, suffix)
  }
}

#endif
