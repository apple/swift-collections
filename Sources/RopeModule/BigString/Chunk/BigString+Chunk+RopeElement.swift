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

#if compiler(>=6.2) && !$Embedded

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk: RopeElement {
  typealias Summary = BigString.Summary

  var summary: BigString.Summary {
    Summary(self)
  }

  var isEmpty: Bool { utf8Count == 0 }

  var isUndersized: Bool { utf8Count < Self.minUTF8Count }

  func invariantCheck() {
#if COLLECTIONS_INTERNAL_CHECKS
    precondition(string.endIndex._canBeUTF8)
    let c = utf8Count
    if c == 0 {
      precondition(counts == Counts(), "Non-empty counts")
      return
    }
    precondition(c <= Self.maxUTF8Count, "Oversized chunk")
    //precondition(utf8Count >= Self.minUTF8Count, "Undersized chunk")

    precondition(counts.utf8 == utf8Distance(from: startIndex, to: endIndex), "UTF-8 count mismatch")
    precondition(counts.utf16 == utf16Distance(from: startIndex, to: endIndex), "UTF-16 count mismatch")
    precondition(counts.unicodeScalars == scalarDistance(from: startIndex, to: endIndex), "Scalar count mismatch")

    precondition(counts.prefix <= c, "Invalid prefix count")
    precondition(counts.suffix <= c && counts.suffix > 0, "Invalid suffix count")
    if Int(counts.prefix) + Int(counts.suffix) <= c {
      let i = firstBreak
      let j = lastBreak
      precondition(i <= j, "Overlapping prefix and suffix")
      precondition(counts.characters == characterDistance(from: i, to: endIndex), "Inconsistent character count")
      precondition(j == characterIndex(before: endIndex, in: i..<endIndex), "Inconsistent suffix count")
    } else {
      // Anomalous case
      precondition(counts.prefix == c, "Inconsistent prefix count (continuation)")
      precondition(counts.suffix == c, "Inconsistent suffix count (continuation)")
      precondition(counts.characters == 0, "Inconsistent character count (continuation)")
    }
#endif
  }

  mutating func rebalance(nextNeighbor right: inout Self) -> Bool {
    if self.isEmpty {
      swap(&self, &right)
      return true
    }
    guard !right.isEmpty else { return true }
    guard self.isUndersized || right.isUndersized else { return false }
    let sum = self.utf8Count + right.utf8Count
    let desired = BigString._Ingester.desiredNextChunkSize(remaining: sum)

    precondition(desired != self.utf8Count)
    if desired < self.utf8Count {
      let i = Index(utf8Offset: desired)
      let j = scalarIndex(roundingDown: i)
      Self._redistributeData(&self, &right, splittingLeftAt: j)
    } else {
      let i = Index(utf8Offset: desired - utf8Count)
      let j = right.scalarIndex(roundingDown: i)
      Self._redistributeData(&self, &right, splittingRightAt: j)
    }
    assert(right.isEmpty || (!self.isUndersized && !right.isUndersized))
    return right.isEmpty
  }

  mutating func rebalance(prevNeighbor left: inout Self) -> Bool {
    if self.isEmpty {
      swap(&self, &left)
      return true
    }
    guard !left.isEmpty else { return true }
    guard left.isUndersized || self.isUndersized else { return false }
    let sum = left.utf8Count + self.utf8Count
    let desired = BigString._Ingester.desiredNextChunkSize(remaining: sum)

    precondition(desired != self.utf8Count)
    if desired < self.utf8Count {
      let i = Index(utf8Offset: utf8Count - desired)
      let j = scalarIndex(roundingDown: i)
      let k = (i == j ? i : scalarIndex(after: j))
      Self._redistributeData(&left, &self, splittingRightAt: k)
    } else {
      let i = Index(utf8Offset: left.utf8Count + utf8Count - desired)
      let j = left.scalarIndex(roundingDown: i)
      let k = (i == j ? i : left.scalarIndex(after: j))
      Self._redistributeData(&left, &self, splittingLeftAt: k)
    }
    assert(left.isEmpty || (!left.isUndersized && !self.isUndersized))
    return left.isEmpty
  }

  mutating func split(at i: BigString._Chunk.Index) -> Self {
    ensureUnique()
    assert(i == scalarIndex(roundingDown: i))
    let c = splitCounts(at: i)
    let new = Self(copying: utf8Span(from: i), c.right)
    self = Self(copying: utf8Span(from: startIndex, to: i), c.left)
    return new
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  static func _redistributeData(
    _ left: inout Self,
    _ right: inout Self,
    splittingRightAt i: Index
  ) {
    assert(i == right.scalarIndex(roundingDown: i))
    assert(i > right.startIndex)
    guard i < right.endIndex else {
      left.append(right)
      right.clear()
      return
    }
    let counts = right.splitCounts(at: i)
    left._append(right.utf8Span(from: right.startIndex, to: i), counts.left)
    right = Self(copying: right.utf8Span(from: i, to: right.endIndex), counts.right)
  }

  static func _redistributeData(
    _ left: inout Self,
    _ right: inout Self,
    splittingLeftAt i: Index
  ) {
    assert(i == left.scalarIndex(roundingDown: i))

    assert(i < left.endIndex)
    guard i > left.startIndex else {
      left.append(right)
      right.clear()
      swap(&left, &right)
      return
    }
    let counts = left.splitCounts(at: i)
    right._prepend(left.utf8Span(from: i, to: left.endIndex), counts.right)
    left = Self(copying: left.utf8Span(from: left.startIndex, to: i), counts.left)
  }
}

#endif // compiler(>=6.2) && !$Embedded
