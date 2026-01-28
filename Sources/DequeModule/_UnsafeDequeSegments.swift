//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

@frozen
@usableFromInline
internal struct _UnsafeDequeSegments<Element: ~Copyable> {
  @usableFromInline
  internal let first: UnsafeBufferPointer<Element>

  @usableFromInline
  internal let second: UnsafeBufferPointer<Element>?

  @_alwaysEmitIntoClient
  @_transparent
  internal init(
    _ first: UnsafeBufferPointer<Element>,
    _ second: UnsafeBufferPointer<Element>? = nil
  ) {
    self.first = first
    self.second = second
    assert(first.count > 0 || second == nil)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal init(
    start: UnsafePointer<Element>,
    count: Int
  ) {
    self.init(UnsafeBufferPointer(start: start, count: count))
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal init(
    first start1: UnsafePointer<Element>,
    count count1: Int,
    second start2: UnsafePointer<Element>,
    count count2: Int
  ) {
    self.init(UnsafeBufferPointer(start: start1, count: count1),
              UnsafeBufferPointer(start: start2, count: count2))
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal var count: Int { first.count + (second?.count ?? 0) }

  @_alwaysEmitIntoClient
  @_transparent
  internal func isIdentical(to other: Self) -> Bool {
    guard self.first._isIdentical(to: other.first) else { return false }
    switch (self.second, other.second) {
    case (nil, nil): return true
    case let (a?, b?): return a._isIdentical(to: b)
    default: return false
    }
  }
}

@frozen
@usableFromInline
internal struct _UnsafeMutableDequeSegments<Element: ~Copyable> {
  @usableFromInline
  internal let first: UnsafeMutableBufferPointer<Element>

  @usableFromInline
  internal let second: UnsafeMutableBufferPointer<Element>?

  @_alwaysEmitIntoClient
  @_transparent
  internal init() {
    self.first = .init(start: nil, count: 0)
    self.second = nil
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal init(
    _ first: UnsafeMutableBufferPointer<Element>,
    _ second: UnsafeMutableBufferPointer<Element>? = nil
  ) {
    self.first = first
    self.second = second?.count == 0 ? nil : second
    assert(first.count > 0 || second == nil)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal init(
    start: UnsafeMutablePointer<Element>,
    count: Int
  ) {
    self.init(UnsafeMutableBufferPointer(start: start, count: count))
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal init(
    first start1: UnsafeMutablePointer<Element>,
    count count1: Int,
    second start2: UnsafeMutablePointer<Element>,
    count count2: Int
  ) {
    self.init(UnsafeMutableBufferPointer(start: start1, count: count1),
              UnsafeMutableBufferPointer(start: start2, count: count2))
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal init(mutating buffer: _UnsafeDequeSegments<Element>) {
    self.init(.init(mutating: buffer.first),
              buffer.second.map { .init(mutating: $0) })
  }
}

extension _UnsafeMutableDequeSegments {
  @_alwaysEmitIntoClient
  @_transparent
  internal init(
    _ first: UnsafeMutableBufferPointer<Element>.SubSequence,
    _ second: UnsafeMutableBufferPointer<Element>? = nil
  ) {
    self.init(UnsafeMutableBufferPointer(rebasing: first), second)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal init(
    _ first: UnsafeMutableBufferPointer<Element>,
    _ second: UnsafeMutableBufferPointer<Element>.SubSequence
  ) {
    self.init(first, UnsafeMutableBufferPointer(rebasing: second))
  }
}

extension _UnsafeMutableDequeSegments where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal var count: Int { first.count + (second?.count ?? 0) }

  @_alwaysEmitIntoClient
  @_transparent
  internal func prefix(_ n: Int) -> Self {
    assert(n >= 0)
    if n >= self.count {
      return self
    }
    if n <= first.count {
      return Self(first._extracting(first: n))
    }
    return Self(first, second!._extracting(first: n - first.count))
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func suffix(_ n: Int) -> Self {
    assert(n >= 0)
    if n >= self.count {
      return self
    }
    guard let second = second else {
      return Self(first._extracting(last: n))
    }
    if n <= second.count {
      return Self(second._extracting(last: n))
    }
    return Self(first._extracting(last: n - second.count), second)
  }
}

extension _UnsafeMutableDequeSegments where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal func deinitialize() {
    first.deinitialize()
    second?.deinitialize()
  }
}

extension _UnsafeMutableDequeSegments {
  @discardableResult
  @_alwaysEmitIntoClient
  @_transparent
  internal func initialize<I: IteratorProtocol>(
    copyingPrefixOf iterator: inout I
  ) -> Int
  where I.Element == Element {
    var copied = 0
    var gap = first
    var wrapped = false
    while true {
      if copied == gap.count {
        guard !wrapped, let second = second, second.count > 0 else { break }
        gap = second
        copied = 0
        wrapped = true
      }
      guard let next = iterator.next() else { break }
      (gap.baseAddress! + copied).initialize(to: next)
      copied += 1
    }
    return wrapped ? first.count + copied : copied
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func initialize<S: Sequence>(
    fromSequencePrefix elements: __owned S
  ) -> (iterator: S.Iterator, count: Int)
  where S.Element == Element {
    guard second == nil || first.count >= elements.underestimatedCount else {
      var it = elements.makeIterator()
      let copied = initialize(copyingPrefixOf: &it)
      return (it, copied)
    }
    // Note: Array._copyContents traps when not given enough space, so we
    // need to check if we have enough contiguous space available above.
    //
    // FIXME: Add support for segmented (a.k.a. piecewise contiguous)
    // collections to the stdlib.
    var (it, copied) = elements._copyContents(initializing: first)
    if copied == first.count, let second = second {
      var i = 0
      while i < second.count {
        guard let next = it.next() else { break }
        (second.baseAddress! + i).initialize(to: next)
        i += 1
      }
      copied += i
    }
    return (it, copied)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func initialize(
    copying elements: UnsafeBufferPointer<Element>
  ) {
    assert(self.count == elements.count)
    if let second = second {
      let wrap = first.count
      first.initializeAll(fromContentsOf: elements._extracting(first: wrap))
      second.initializeAll(fromContentsOf: elements._extracting(last: second.count))
    } else {
      first.initializeAll(fromContentsOf: elements)
    }
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func initialize(
    copying elements: UnsafeMutableBufferPointer<Element>
  ) {
    self.initialize(copying: UnsafeBufferPointer(elements))
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func initialize(
    copying elements: __owned some Collection<Element>
  ) {
    assert(self.count == elements.count)
    if let second = second {
      let wrap = elements.index(elements.startIndex, offsetBy: first.count)
      first.initializeAll(fromContentsOf: elements[..<wrap])
      second.initializeAll(fromContentsOf: elements[wrap...])
    } else {
      first.initializeAll(fromContentsOf: elements)
    }
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func reassign<C: Collection>(
    copying elements: C
  ) where C.Element == Element {
    assert(elements.count == self.count)
    deinitialize()
    initialize(copying: elements)
  }
}
