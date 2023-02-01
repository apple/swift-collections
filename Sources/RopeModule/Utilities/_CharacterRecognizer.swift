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

/// CR and LF are common special cases in grapheme breaking logic
private var _CR: UInt8 { return 0x0d }
private var _LF: UInt8 { return 0x0a }

internal func _hasGraphemeBreakBetween(
  _ lhs: Unicode.Scalar, _ rhs: Unicode.Scalar
) -> Bool {
  
  // CR-LF is a special case: no break between these
  if lhs == Unicode.Scalar(_CR) && rhs == Unicode.Scalar(_LF) {
    return false
  }
  
  // Whether the given scalar, when it appears paired with another scalar
  // satisfying this property, has a grapheme break between it and the other
  // scalar.
  func hasBreakWhenPaired(_ x: Unicode.Scalar) -> Bool {
    // TODO: This doesn't generate optimal code, tune/re-write at a lower
    // level.
    //
    // NOTE: Order of case ranges affects codegen, and thus performance. All
    // things being equal, keep existing order below.
    switch x.value {
      // Unified CJK Han ideographs, common and some supplemental, amongst
      // others:
      //   U+3400 ~ U+A4CF
    case 0x3400...0xa4cf: return true
      
      // Repeat sub-300 check, this is beneficial for common cases of Latin
      // characters embedded within non-Latin script (e.g. newlines, spaces,
      // proper nouns and/or jargon, punctuation).
      //
      // NOTE: CR-LF special case has already been checked.
    case 0x0000...0x02ff: return true
      
      // Non-combining kana:
      //   U+3041 ~ U+3096
      //   U+30A1 ~ U+30FC
    case 0x3041...0x3096: return true
    case 0x30a1...0x30fc: return true
      
      // Non-combining modern (and some archaic) Cyrillic:
      //   U+0400 ~ U+0482 (first half of Cyrillic block)
    case 0x0400...0x0482: return true
      
      // Modern Arabic, excluding extenders and prependers:
      //   U+061D ~ U+064A
    case 0x061d...0x064a: return true
      
      // Precomposed Hangul syllables:
      //   U+AC00 ~ U+D7AF
    case 0xac00...0xd7af: return true
      
      // Common general use punctuation, excluding extenders:
      //   U+2010 ~ U+2029
    case 0x2010...0x2029: return true
      
      // CJK punctuation characters, excluding extenders:
      //   U+3000 ~ U+3029
    case 0x3000...0x3029: return true
      
      // Full-width forms:
      //   U+FF01 ~ U+FF9D
    case 0xFF01...0xFF9D: return true
      
    default: return false
    }
  }
  return hasBreakWhenPaired(lhs) && hasBreakWhenPaired(rhs)
}

// FIXME: This has terrible performance.
// FIXME: Replace with Unicode._CharacterRecognizer once it gets into a build.
struct _CharacterRecognizer {
  private var string: String
  
  init() {
    string = ""
  }
  
  init(first: Unicode.Scalar) {
    string = String(first)
  }
  
  static func quickBreak(
    between scalar1: Unicode.Scalar,
    and scalar2: Unicode.Scalar
  ) -> Bool? {
    if scalar1 == Unicode.Scalar(_CR) && scalar2 == Unicode.Scalar(_LF) { return false }
    if _hasGraphemeBreakBetween(scalar1, scalar2) { return true }
    return nil
  }
  
  mutating func hasBreak(
    before next: Unicode.Scalar
  ) -> Bool {
    let next = String(next)
    guard !string.isEmpty else {
      string = next
      return true
    }
    string.append(next)
    let i = string.index(after: string.startIndex)
    if i == string.endIndex { return false }
    string = next
    return true
  }
}

extension _CharacterRecognizer: Equatable {
  static func ==(left: Self, right: Self) -> Bool {
    left.string.utf8.elementsEqual(right.string.utf8)
  }
}

extension _CharacterRecognizer {
  mutating func firstBreak(
    in str: Substring
  ) -> Range<String.Index>? {
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
  }
}
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

extension String {
  // FIXME: Remove once the stdlib entry point gets into a build.
  func _index(roundingDown i: Index) -> Index {
    guard i < endIndex else { return endIndex }
    guard !i._isCharacterAligned else { return i }
    return index(before: index(after: i))
  }
}

extension Substring {
  // FIXME: Remove once the stdlib entry point gets into a build.
  func _index(roundingDown i: Index) -> Index {
    index(i, offsetBy: 0)
  }
  
  func _nextBreak(onOrAfter i: Index) -> Index {
    let nearestDown = _index(roundingDown: i)
    guard nearestDown != i else { return nearestDown }
    return index(after: nearestDown)
  }
}

extension String.UnicodeScalarView {
  // FIXME: Remove once the stdlib entry point gets into a build.
  func _index(roundingDown i: Index) -> Index {
    index(i, offsetBy: 0)
  }
}
