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
extension UInt8 {
  /// Returns true if this is a leading code unit in the UTF-8 encoding of a Unicode scalar that
  /// is outside the BMP.
  var _isUTF8NonBMPLeadingCodeUnit: Bool { self >= 0b11110000 }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Chunk {
  func characterDistance(from start: String.Index, to end: String.Index) -> Int {
    let firstBreak = self.firstBreak
    let (start, a) = start < firstBreak ? (firstBreak, 1) : (start, 0)
    let (end, b) = end < firstBreak ? (firstBreak, 1) : (end, 0)
    let d = wholeCharacters.distance(from: start, to: end)
    return d + a - b
  }

  /// If this returns false, the next position is on the first grapheme break following this
  /// chunk.
  func formCharacterIndex(after i: inout String.Index) -> Bool {
    if i >= lastBreak {
      i = string.endIndex
      return false
    }
    let first = firstBreak
    if i < first {
      i = first
      return true
    }
    wholeCharacters.formIndex(after: &i)
    return true
  }

  /// If this returns false, the right position is `distance` steps from the first grapheme break
  /// following this chunk if `distance` was originally positive. Otherwise the right position is
  /// `-distance` steps from the first grapheme break preceding this chunk.
  func formCharacterIndex(
    _ i: inout String.Index, offsetBy distance: inout Int
  ) -> (found: Bool, forward: Bool) {
    if distance == 0 {
      if i < firstBreak {
        i = string.startIndex
        return (false, false)
      }
      if i >= lastBreak {
        i = lastBreak
        return (true, false)
      }
      i = wholeCharacters._index(roundingDown: i)
      return (true, false)
    }
    if distance > 0 {
      if i >= lastBreak {
        i = string.endIndex
        distance -= 1
        return (false, true)
      }
      if i < firstBreak {
        i = firstBreak
        distance -= 1
        if distance == 0 { return (true, true) }
      }
      if
        distance <= characterCount,
        let r = wholeCharacters.index(i, offsetBy: distance, limitedBy: string.endIndex)
      {
        i = r
        distance = 0
        return (i < string.endIndex, true)
      }
      distance -= wholeCharacters.distance(from: i, to: lastBreak) + 1
      i = string.endIndex
      return (false, true)
    }
    if i <= firstBreak {
      i = string.startIndex
      if i == firstBreak { distance += 1 }
      return (false, false)
    }
    if i > lastBreak {
      i = lastBreak
      distance += 1
      if distance == 0 { return (true, false) }
    }
    if
      distance.magnitude <= characterCount,
      let r = self.wholeCharacters.index(i, offsetBy: distance, limitedBy: firstBreak)
    {
      i = r
      distance = 0
      return (true, false)
    }
    distance += self.wholeCharacters.distance(from: firstBreak, to: i)
    i = string.startIndex
    return (false, false)
  }
}

#endif
