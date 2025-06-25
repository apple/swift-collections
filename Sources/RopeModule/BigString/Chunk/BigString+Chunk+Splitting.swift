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

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  func splitCounts(at i: Index) -> (left: Counts, right: Counts) {
    precondition(i <= endIndex)
    guard i < endIndex else {
      return (self.counts, Counts())
    }
    guard i > startIndex else {
      return (Counts(), self.counts)
    }
    let i = scalarIndex(roundingDown: i)

    let leftUTF16: Int
    let leftScalars: Int
    let rightUTF16: Int
    let rightScalars: Int
    if i.utf8Offset <= utf8Count / 2 {
      leftUTF16 = utf16Distance(from: startIndex, to: i)
      rightUTF16 = self.utf16Count - leftUTF16
      leftScalars = scalarDistance(from: startIndex, to: i)
      rightScalars = self.unicodeScalarCount - leftScalars
    } else {
      rightUTF16 = utf16Distance(from: i, to: endIndex)
      leftUTF16 = self.utf16Count - rightUTF16
      rightScalars = scalarDistance(from: i, to: endIndex)
      leftScalars = self.unicodeScalarCount - rightScalars
    }

    let left = _counts(upTo: i, utf16: leftUTF16, scalars: leftScalars)
    let right = _counts(from: i, utf16: rightUTF16, scalars: rightScalars)

    assert(left.utf8 + right.utf8 == self.counts.utf8)
    assert(left.utf16 + right.utf16 == self.counts.utf16)
    assert(left.unicodeScalars + right.unicodeScalars == self.counts.unicodeScalars)
    assert(left.characters + right.characters == self.counts.characters)
    return (left, right)
  }

  func counts(upTo i: Index) -> Counts {
    precondition(i <= endIndex)
    let i = scalarIndex(roundingDown: i)
    guard i > startIndex else { return Counts() }
    guard i < endIndex else { return self.counts }

    let utf16 = utf16Distance(from: startIndex, to: i)
    let scalars = scalarDistance(from: startIndex, to: i)
    return _counts(from: i, utf16: utf16, scalars: scalars)
  }

  func _counts(upTo i: Index, utf16: Int, scalars: Int) -> Counts {
    assert(i > startIndex && i < endIndex)

    var result = Counts(
      utf8: utf8Distance(from: startIndex, to: i),
      utf16: utf16,
      unicodeScalars: scalars,
      characters: 0,
      prefix: 0,
      suffix: 0)

    let firstBreak = self.firstBreak
    let lastBreak = self.lastBreak

    if i <= firstBreak {
      result.characters = 0
      result._prefix = result.utf8
      result._suffix = result.utf8
    } else if i > lastBreak {
      result._characters = self.counts._characters
      result._prefix = self.counts._prefix
      result._suffix = self.counts._suffix - (self.counts.utf8 - result.utf8)
    } else { // i > firstBreak, i <= lastBreak
      result._prefix = self.counts._prefix
      assert(!(firstBreak..<i).isEmpty)
      var state = _CharacterRecognizer()
      let (characters, _, last) = state.consume(self, firstBreak..<i)!
      result.characters = characters
      result.suffix = utf8Distance(from: last, to: i)
    }
    return result
  }

  func counts(from i: Index) -> Counts {
    precondition(i <= endIndex)
    let i = scalarIndex(roundingDown: i)
    guard i > startIndex else { return self.counts }
    guard i < endIndex else { return Counts() }

    let utf16 = utf16Distance(from: i, to: endIndex)
    let scalars = scalarDistance(from: i, to: endIndex)
    return _counts(from: i, utf16: utf16, scalars: scalars)
  }

  func _counts(from i: Index, utf16: Int, scalars: Int) -> Counts {
    assert(i > startIndex && i < endIndex)
    var result = Counts(
      utf8: utf8Distance(from: i, to: endIndex),
      utf16: utf16,
      unicodeScalars: scalars,
      characters: 0,
      prefix: 0,
      suffix: 0)

    let firstBreak = self.firstBreak
    let lastBreak = self.lastBreak

    if i > lastBreak {
      result._characters = 0
      result._prefix = result.utf8
      result._suffix = result.utf8
    } else if i <= firstBreak {
      result._characters = self.counts._characters
      result.prefix = self.counts.prefix - i.utf8Offset
      result._suffix = self.counts._suffix
    } else { // i > firstBreak, i <= lastBreak
      result._suffix = self.counts._suffix
      let prevBreak = characterIndex(roundingDown: i, in: firstBreak..<lastBreak)
      var state = _CharacterRecognizer(partialCharacter: utf8Span(from: prevBreak, to: i))
      if let (characters, first, _) = state.consume(self, i..<lastBreak) {
        assert(first >= i)
        result.characters = characters + 1
        result.prefix = utf8Distance(from: i, to: first)
      } else {
        result.characters = 1
        result.prefix = utf8Distance(from: i, to: lastBreak)
      }
    }
    return result
  }
}
