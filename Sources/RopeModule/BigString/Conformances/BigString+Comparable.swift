//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 6.2, *)
extension BigString: Comparable {
  public static func < (left: Self, right: Self) -> Bool {
    // FIXME: Implement properly normalized comparisons & hashing.
    // This is somewhat tricky as we shouldn't just normalize individual pieces of the string
    // split up on random Character boundaries -- Unicode does not promise that
    // norm(a + c) == norm(a) + norm(b) in this case.
    // To do this properly, we'll probably need to expose new stdlib entry points. :-/
    if left.isIdentical(to: right) { return false }
    // FIXME: Even if we keep doing characterwise comparisons, we should skip over shared subtrees.
    var it1 = left.makeIterator()
    var it2 = right.makeIterator()
    return _characterwiseIsLess(&it1, &it2)
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString {
  /// Lexicographically compare the remaining characters of two iterators, using the same ordering
  /// as `String`: the concatenation of the NFC-normalized UTF-8 encoding of each character is
  /// compared code unit by code unit.
  ///
  /// Note that this is not the same as comparing the characters one by one: when the first
  /// mismatching characters are such that the normalized form of one is a proper prefix of the
  /// other (e.g., `"\r"` and `"\r\n"`), the result depends on the characters that follow.
  internal static func _characterwiseIsLess(
    _ it1: inout some IteratorProtocol<Character>,
    _ it2: inout some IteratorProtocol<Character>
  ) -> Bool {
    // Skip over the common prefix, comparing whole characters.
    var a: Character
    var b: Character
    while true {
      switch (it1.next(), it2.next()) {
      case (nil, nil): return false
      case (nil, .some): return true
      case (.some, nil): return false
      case let (x?, y?):
        if x == y { continue }
        a = x
        b = y
      }
      break
    }

    func nfc(_ c: Character) -> [UInt8] {
      var result: [UInt8] = []
      String(c)._withNFCCodeUnits { result.append($0) }
      return result
    }

    // Compare the normalized code units from the first mismatch onward.
    var buffer1 = nfc(a)
    var buffer2 = nfc(b)
    var i1 = 0
    var i2 = 0
    while true {
      if i1 == buffer1.count {
        guard let next = it1.next() else {
          return i2 < buffer2.count || it2.next() != nil
        }
        buffer1 = nfc(next)
        i1 = 0
        continue
      }
      if i2 == buffer2.count {
        guard let next = it2.next() else { return false }
        buffer2 = nfc(next)
        i2 = 0
        continue
      }
      let c1 = buffer1[i1]
      let c2 = buffer2[i2]
      if c1 != c2 { return c1 < c2 }
      i1 += 1
      i2 += 1
    }
  }
}
