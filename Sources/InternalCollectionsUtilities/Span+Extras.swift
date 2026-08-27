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

#if compiler(>=6.2)

@_frozen
@usableFromInline
package struct _ShamSpanIterator {
  // FIXME: Remove this when `Span.BorrowingIterator` becomes actually usable.
  // (I.e., when it exposes this data in a usable way.)
  @_alwaysEmitIntoClient
  package var _basePointer: UnsafeRawPointer?

  @_alwaysEmitIntoClient
  package var _baseCount: Int

  @_alwaysEmitIntoClient
  package var _start: Int

  @_alwaysEmitIntoClient
  package var _count: Int
}

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension Span.BorrowingIterator where Element: ~Copyable {
  @inlinable
  package mutating func _withShamIterator<R: ~Copyable>(
    _ body: (borrowing _ShamSpanIterator) -> R
  ) -> R {
    precondition(
      MemoryLayout<Self>.stride == MemoryLayout<_ShamSpanIterator>.stride)
    return Swift.withUnsafeBytes(of: &self) { buffer in
      buffer.withMemoryRebound(to: _ShamSpanIterator.self) { shamBuffer in
        return body(shamBuffer[0])
      }
    }
  }
}

@available(SwiftStdlib 6.4, *)
extension Span where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  package func _makeBorrowingIterator(from start: Int, to end: Int) -> BorrowingIterator {
    // Note: This is declared `copy self` so that types can forward to it without having to override lifetimes.
    #if false // FIXME: Span's iterator needs to provide a public "slicing" initializer
    return BorrowingIterator(self, from: start, to: end)
    #else
    var it = BorrowingIterator(self.extracting(first: end))
    let c = it.skip(by: start)
    precondition(c == start)
    return it
    #endif
  }
}
#endif

@available(SwiftStdlib 5.0, *)
extension Span where Element: ~Copyable {
  // Note: This is declared `copy self` so that types can forward to it without having to override lifetimes.
  // FIXME: This has the proper lifetime declaration but can't fulfill the Container requirement.
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  package func _nextSpan(after index: inout Int) -> Self {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    let result = self.extracting(last: count - index)
    index = count
    return result
  }

  // Note: This is declared `copy self` so that types can forward to it without having to override lifetimes.
  // FIXME: This has the proper lifetime declaration but can't fulfill the Container requirement.
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  package func _nextSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> Self {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(maxCount > 0, "maxCount must be positive")
    precondition(limit >= 0 && limit <= count, "Index out of bounds")
    var end = index &+ Swift.min(maxCount, count &- index)
    if limit >= index, limit < end {
      end = limit
    }
    let r = self.extracting(unchecked: Range(uncheckedBounds: (index, end)))
    index = end
    return r
  }

  @_alwaysEmitIntoClient
  package func _spanBoundary(
    before index: Index, maxDistance: Int, limitedBy limit: Index
  ) -> (index: Index, distance: Int) {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(limit >= 0 && limit <= count, "Index out of bounds")
    precondition(maxDistance > 0, "maxDistance must be positive")
    let p = index._clampedDown(towards: 0, maxDistance: maxDistance, limitedBy: limit)
    return (p, index &- p)
  }

}

@available(SwiftStdlib 5.0, *)
extension Span where Element: ~Copyable {
  @_lifetime(copy self)
  @_alwaysEmitIntoClient
  package mutating func _trim(first maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Cannot have a prefix of negative length")
    let cut = Swift.min(maxLength, count)
    guard cut > 0 else { return .init() }
    let result = self.extracting(first: cut)
    self = self.extracting(droppingFirst: cut)
    return result
  }

  @_lifetime(copy self)
  @_alwaysEmitIntoClient
  package mutating func _trim(last maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Cannot have a suffix of negative length")
    let cut = Swift.min(maxLength, count)
    guard cut > 0 else { return .init() }
    let result = self.extracting(last: cut)
    self = self.extracting(droppingLast: cut)
    return result
  }
}

#if compiler(>=6.4)
@available(SwiftStdlib 5.0, *)
extension Span where Element: Equatable & ~Copyable {
  @_alwaysEmitIntoClient
  package func _elementsEqual(to other: borrowing Self) -> Bool {
    return self.withUnsafeBufferPointer { a in
      other.withUnsafeBufferPointer { b in
        guard a.count == b.count else { return false }
        guard a.baseAddress != b.baseAddress else { return true }
        var i = 0
        while i < self.count {
          guard a[i] == b[i] else { return false }
          i &+= 1
        }
        return true
      }
    }
  }
}
#else
@available(SwiftStdlib 5.0, *)
extension Span where Element: Equatable /* & ~Copyable */ {
  @_alwaysEmitIntoClient
  package func _elementsEqual(to other: borrowing Self) -> Bool {
    return self.withUnsafeBufferPointer { a in
      other.withUnsafeBufferPointer { b in
        guard a.count == b.count else { return false }
        guard a.baseAddress != b.baseAddress else { return true }
        var i = 0
        while i < self.count {
          guard a[i] == b[i] else { return false }
          i &+= 1
        }
        return true
      }
    }
  }
}
#endif

#if compiler(>=6.4)
@available(SwiftStdlib 5.0, *)
extension Span where Element: Hashable & ~Copyable {
  @_alwaysEmitIntoClient
  package func _hashContents(into hasher: inout Hasher) {
    // Note: no discriminating combine call -- caller is expected to do that
    // separately when needed.
    var i = 0
    while i < self.count {
      hasher.combine(self[unchecked: i])
      i &+= 1
    }

  }
}
#else
@available(SwiftStdlib 5.0, *)
extension Span where Element: Hashable /* & ~Copyable */ {
  @_alwaysEmitIntoClient
  package func _hashContents(into hasher: inout Hasher) {
    // Note: no discriminating combine call -- caller is expected to do that
    // separately when needed.
    var i = 0
    while i < self.count {
      hasher.combine(self[unchecked: i])
      i &+= 1
    }

  }
}
#endif

#if compiler(>=6.4)
@available(SwiftStdlib 5.0, *)
extension Span where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  package func clamped(to limits: borrowing Self) -> Self {
    if self.isEmpty || limits.isEmpty { return .init() }
    let buffer = self.withUnsafeBufferPointer { buffer in
      limits.withUnsafeBufferPointer { limits in
        let start = buffer.baseAddress!
        let end = start + buffer.count
        let limitStart = limits.baseAddress!
        let limitEnd = limitStart + limits.count

        let clampedStart = (
          limitStart > start ? limitStart
          : limitEnd < start ? limitEnd
          : start)
        let clampedEnd = (
          limitEnd < end ? limitEnd
          : limitStart > end ? limitStart
          : end)
        let count = clampedEnd.distance(to: clampedStart)
        return UnsafeBufferPointer(start: clampedStart, count: count)
      }
    }
    return _overrideLifetime(Span(_unsafeElements: buffer), copying: self)
  }
}
#endif

#endif
