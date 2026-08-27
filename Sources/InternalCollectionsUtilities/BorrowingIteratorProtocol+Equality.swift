//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4)

@available(SwiftStdlib 6.4, *)
extension BorrowingIteratorProtocol
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable & Equatable
{
  @_alwaysEmitIntoClient
  package consuming func _elementsEqual<
    Other: BorrowingIteratorProtocol<Element, Failure> & ~Copyable & ~Escapable
  >(
    _ other: consuming Other,
  ) throws(Failure) -> Bool
  where Other.Element: ~Copyable
  {
#if true
    // Note: This is the less efficient implementation of elementsEqual. The
    // variant in the #elseif branch below would be preferable, but it doesn't
    // work yet. (It lets both iterators run at their native speeds, with no
    // artificial maxCounts.)
    while true {
      let a = try self.nextSpan()
      var i = 0
      if a.isEmpty {
        return try other.nextSpan().isEmpty
      }
      while i < a.count {
        let b = try other.nextSpan(maxCount: a.count - i)
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
#elseif false // FIXME: rdar://150228920 Exclusive access scopes aren't expanded enough
    var a = Span<Element>()
    var b = Span<Element>()
    while true {
      if a.isEmpty {
        a = self.nextSpan()
      }
      if b.isEmpty {
        b = other.nextSpan()
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
#else // Third variant, using _spanwiseZip
    var result = true
    try _spanwiseZip(state: &result, with: other) { state, a, b in
      if a.isEmpty || b.isEmpty {
        state = false
        return false
      }
      precondition(a.count == b.count)
      for i in 0 ..< a.count {
        guard a[unchecked: i] == b[unchecked: i] else {
          state = false
          return false
        }
      }
      return true
    }
    return result
#endif
  }
}

@available(SwiftStdlib 6.4, *)
extension BorrowingIteratorProtocol
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @_alwaysEmitIntoClient
  package consuming func _elementsEqual<
    Other: BorrowingIteratorProtocol & ~Copyable & ~Escapable
  >(
    _ other: consuming Other,
    by areEquivalent: (borrowing Element, borrowing Other.Element) throws(Failure) -> Bool
  ) throws(Failure) -> Bool
  where Other.Element: ~Copyable, Other.Failure == Failure
  {
    // Note: This is the less efficient implementation of elementsEqual.
    // (See the note on the Equatable variant above.)
    while true {
      let a = try self.nextSpan()
      var i = 0
      if a.isEmpty {
        return try other.nextSpan().isEmpty
      }
      while i < a.count {
        let b = try other.nextSpan(maxCount: a.count - i)
        if b.isEmpty {
          return false
        }
        precondition(b.count <= a.count - i)

        var j = 0
        while j < b.count {
          guard try areEquivalent(a[unchecked: i], b[unchecked: j])
          else { return false }
          i &+= 1
          j &+= 1
        }
      }
    }
  }
}

#endif
