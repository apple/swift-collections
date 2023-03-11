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
  func isIdentical(to other: Self) -> Bool {
    self.rope.isIdentical(to: other.rope)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString: Equatable {
  internal static func ==(left: Self, right: Self) -> Bool {
    left.characterwiseIsEqual(to: right)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal func characterwiseIsEqual(to other: Self) -> Bool {
    // FIXME: Implement properly normalized comparisons & hashing.
    // This is somewhat tricky as we shouldn't just normalize individual pieces of the string
    // split up on random Character boundaries -- Unicode does not promise that
    // norm(a + c) == norm(a) + norm(b) in this case.
    // To do this properly, we'll probably need to expose new stdlib entry points. :-/
    if self.isIdentical(to: other) { return true }
    guard self.characterCount == other.characterCount else { return false }
    // FIXME: Even if we keep doing characterwise comparisons, we should skip over shared subtrees.
    var it1 = self.makeCharacterIterator()
    var it2 = other.makeCharacterIterator()
    var a: Character? = nil
    var b: Character? = nil
    repeat {
      a = it1.next()
      b = it2.next()
      guard a == b else { return false }
    } while a != nil
    return true
  }

  internal static func characterwiseIsEqual(
    _ left: Self,
    in leftRange: Range<Index>,
    to right: Self,
    in rightRange: Range<Index>
  ) -> Bool {
    // FIXME: Implement properly normalized comparisons & hashing.
    // This is somewhat tricky as we shouldn't just normalize individual pieces of the string
    // split up on random Character boundaries -- Unicode does not promise that
    // norm(a + c) == norm(a) + norm(b) in this case.
    // To do this properly, we'll probably need to expose new stdlib entry points. :-/
    if left.isIdentical(to: right), leftRange == rightRange { return true }

    // FIXME: Even if we keep doing characterwise comparisons, we should skip over shared subtrees.
    var it1 = left.makeCharacterIterator(from: leftRange.lowerBound)
    var it2 = right.makeCharacterIterator(from: rightRange.lowerBound)

    if leftRange._isEmptyUTF8 { return rightRange._isEmptyUTF8 }

    let leftEnd = left.resolve(leftRange.upperBound, preferEnd: true)
    let rightEnd = right.resolve(rightRange.upperBound, preferEnd: true)

    var a: Character? = nil
    var b: Character? = nil
    while it1.isBelow(leftEnd), it2.isBelow(rightEnd) {
      a = it1.next()
      b = it2.next()
      assert(a != nil && b != nil)
      guard a == b else { return false }
    }
    return !it1.isBelow(leftEnd) && !it2.isBelow(rightEnd)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  /// Lexicographically compare the UTF-8 representations of `left` to `right`, returning a Boolean
  /// value indicating whether `left` is equal to `right`.
  internal func utf8IsEqual(to other: Self) -> Bool {
    if self.isIdentical(to: other) { return true }
    guard self.rope.summary == other.rope.summary else { return false }

    // FIXME: Implement a structural comparison that ignores shared subtrees when possible.
    // This is somewhat tricky as this is only possible to do when the shared subtrees start
    // at the same logical position in both trees. Additionally, the two input trees may not
    // have the same height, even if they are equal.

    var it1 = self.makeUTF8Iterator()
    var it2 = other.makeUTF8Iterator()
    var remaining = self.utf8Count

    while remaining > 0 {
      let consumed = it1.next(maximumCount: remaining) { b1 in
        let consumed = it2.next(maximumCount: b1.count) { b2 in
          guard b2.elementsEqual(b1.prefix(b2.count)) else { return (0, 0) }
          return (b2.count, b2.count)
        }
        return (consumed, consumed)
      }
      guard consumed > 0 else { return false }
      remaining -= consumed
    }
    return true
  }

  internal static func utf8IsEqual(
    _ left: Self,
    in leftRange: Range<Index>,
    to right: Self,
    in rightRange: Range<Index>
  ) -> Bool {
    let leftUTF8Count = left.utf8Distance(from: leftRange.lowerBound, to: leftRange.upperBound)
    let rightUTF8Count = right.utf8Distance(from: rightRange.lowerBound, to: rightRange.upperBound)
    guard leftUTF8Count == rightUTF8Count else { return false }

    var remaining = leftUTF8Count
    var it1 = left.makeUTF8Iterator(from: leftRange.lowerBound)
    var it2 = right.makeUTF8Iterator(from: rightRange.lowerBound)

    while remaining > 0 {
      let consumed = it1.next(maximumCount: remaining) { b1 in
        let consumed = it2.next(maximumCount: b1.count) { b2 in
          guard b2.elementsEqual(b1.prefix(b2.count)) else { return (0, 0) }
          return (b2.count, b2.count)
        }
        return (consumed, consumed)
      }
      guard consumed > 0 else { return false }
      remaining -= consumed
    }
    return true

  }
}

#endif
