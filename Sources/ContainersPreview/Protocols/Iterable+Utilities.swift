//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence where Self: ~Copyable & ~Escapable, Element: Copyable {
  @inlinable
  package func _copyContents(
    intoPrefixOf buffer: UnsafeMutableBufferPointer<Element>
  ) -> Int {
    var target = buffer
    var it = self.makeBorrowingIterator()
    while target.count != 0 {
      let span = it.nextSpan(maximumCount: target.count)
      if span.isEmpty {
        return buffer.count - target.count
      }
      target._initializeAndDropPrefix(copying: span)
    }
    let test = it.nextSpan()
    precondition(test.isEmpty, "Contents do not fit in target buffer")
    return buffer.count
  }
}

#if true
@available(SwiftStdlib 5.0, *)
extension BorrowingSequence where Self: ~Copyable & ~Escapable {
  @inlinable
  public func elementsEqual<
    Other: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(
    _ other: borrowing Other,
  ) -> Bool where Element: Equatable {
    switch (self.estimatedCount, other.estimatedCount) {
    case let (.exactly(a), .exactly(b)):
      guard a == b else { return false }
    default:
      break
    }
    var it1 = self.makeBorrowingIterator()
    var it2 = other.makeBorrowingIterator()
    while true {
      let a = it1.nextSpan()
      var i = 0
      if a.isEmpty {
        return it2.nextSpan().isEmpty
      }
      while i < a.count {
        let b = it2.nextSpan(maximumCount: a.count)
        if b.isEmpty {
          return false
        }
        precondition(b.count <= a.count - i)
      
        var j = 0
        while j < b.count {
          guard a[unchecked: i] == b[unchecked: j] else { return false }
          i &+= 1
          j &+= 1
        }
      }
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence where Self: ~Copyable & ~Escapable {
  /// Returns a Boolean value indicating whether two borrowing sequences contain
  /// equivalent elements in the same order, using the given predicate as the
  /// equivalence test.
  ///
  /// The predicate must form an *equivalence relation* over the elements. That
  /// is, for any elements `a`, `b`, and `c`, the following conditions must
  /// hold:
  ///
  /// - `areEquivalent(a, a)` is always `true`. (Reflexivity)
  /// - `areEquivalent(a, b)` implies `areEquivalent(b, a)`. (Symmetry)
  /// - If `areEquivalent(a, b)` and `areEquivalent(b, c)` are both `true`, then
  ///   `areEquivalent(a, c)` is also `true`. (Transitivity)
  ///
  /// - Parameters:
  ///   - other: A BorrowingSequence to compare to this BorrowingSequence.
  ///   - areEquivalent: A predicate that returns `true` if its two arguments
  ///     are equivalent; otherwise, `false`.
  /// - Returns: `true` if this BorrowingSequence and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the count of the longer of the input sequences.
  @inlinable
  public func elementsEqual<
    E: Error,
    Other: BorrowingSequence & ~Copyable & ~Escapable
  >(
    _ other: borrowing Other,
    by areEquivalent: (borrowing Element, borrowing Other.Element) throws(E) -> Bool
  ) throws(E) -> Bool {
    switch (self.estimatedCount, other.estimatedCount) {
    case let (.exactly(a), .exactly(b)):
      guard a == b else { return false }
    default:
      break
    }
    var it1 = self.makeBorrowingIterator()
    var it2 = other.makeBorrowingIterator()
    while true {
      let a = it1.nextSpan()
      var i = 0
      if a.isEmpty {
        return it2.nextSpan().isEmpty
      }
      while i < a.count {
        let b = it2.nextSpan(maximumCount: a.count)
        if b.isEmpty {
          return false
        }
        precondition(b.count <= a.count - i)
      
        var j = 0
        while j < b.count {
          guard try areEquivalent(a[unchecked: i], b[unchecked: j]) else {
            return false
          }
          i &+= 1
          j &+= 1
        }
      }
    }
  }
}

#else // rdar://150228920
@available(SwiftStdlib 5.0, *)
extension BorrowingSequence where Self: ~Copyable & ~Escapable {
  @inlinable
  public func elementsEqual<
    Other: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(
    _ other: borrowing Other,
  ) -> Bool where Element: Equatable {
    var it1 = self.makeBorrowingIterator()
    var it2 = other.makeBorrowingIterator()
    var a = Span<Element>()
    var b = Span<Element>()
  loop:
    while true {
      if a.isEmpty {
        a = it1.nextSpan()
      }
      if b.isEmpty {
        b = it2.nextSpan()
      }
      if a.isEmpty || b.isEmpty {
        return a.isEmpty && b.isEmpty
      }
      
      let c = Swift.min(a.count, b.count)
      var i = 0
      while i < c {
        guard a[unchecked: i] == b[unchecked: i] else { return false }
        i &+= 1
      }
      a = a.extracting(droppingFirst: c)
      b = b.extracting(droppingFirst: c)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence where Self: ~Copyable & ~Escapable {
  @inlinable
  @discardableResult
  internal func _spanwiseZip<
    Other: BorrowingSequence & ~Copyable & ~Escapable,
    State: ~Copyable, E: Error
  >(
    state: inout State,
    with other: borrowing Other,
    by process: (inout State, Span<Element>, Span<Other.Element>) throws(E) -> Bool
  ) throws(E) -> Int {
    var it1 = self.makeBorrowingIterator()
    var it2 = other.makeBorrowingIterator()
    var a = Span<Element>()
    var b = Span<Other.Element>()
    var offset = 0 // Offset of the start of the current spans
  loop:
    while true {
      if a.isEmpty {
        a = it1.nextSpan()
      }
      if b.isEmpty {
        b = it2.nextSpan()
      }
      if a.isEmpty || b.isEmpty {
        return offset
      }
      
      let c = Swift.min(a.count, b.count)
      guard try process(&state, a.extracting(first: c), b.extracting(first: c)) else {
        return offset
      }
      a = a.extracting(droppingFirst: c)
      b = b.extracting(droppingFirst: c)
      offset += c
    }
  }
  
  /// Returns a Boolean value indicating whether this BorrowingSequence and another
  /// BorrowingSequence contain equivalent elements in the same order, using the given
  /// predicate as the equivalence test.
  ///
  /// The predicate must form an *equivalence relation* over the elements. That
  /// is, for any elements `a`, `b`, and `c`, the following conditions must
  /// hold:
  ///
  /// - `areEquivalent(a, a)` is always `true`. (Reflexivity)
  /// - `areEquivalent(a, b)` implies `areEquivalent(b, a)`. (Symmetry)
  /// - If `areEquivalent(a, b)` and `areEquivalent(b, c)` are both `true`, then
  ///   `areEquivalent(a, c)` is also `true`. (Transitivity)
  ///
  /// - Parameters:
  ///   - other: A BorrowingSequence to compare to this BorrowingSequence.
  ///   - areEquivalent: A predicate that returns `true` if its two arguments
  ///     are equivalent; otherwise, `false`.
  /// - Returns: `true` if this BorrowingSequence and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the count of the longer of the input sequences.
  @inlinable
  public func elementsEqual<
    E: Error,
    Other: BorrowingSequence & ~Copyable & ~Escapable
  >(
    _ other: borrowing Other,
    by areEquivalent: (borrowing Element, borrowing Other.Element) throws(E) -> Bool
  ) throws(E) -> Bool {
    guard self.count == other.count else { return false }
    var result = true
    try _spanwiseZip(state: &result, with: other) { state, a, b throws(E) in
      assert(a.count == b.count)
      for i in a.indices {
        guard try areEquivalent(a[i], b[i]) else {
          state = false
          return false
        }
      }
      return true
    }
    return result
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence where Self: ~Copyable & ~Escapable, Element: Equatable {
  @inlinable
  public func elementsEqual<
    Other: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(
    _ other: borrowing Other,
  ) -> Bool {
    self.elementsEqual(other, by: ==)
  }
}
#endif

#endif
