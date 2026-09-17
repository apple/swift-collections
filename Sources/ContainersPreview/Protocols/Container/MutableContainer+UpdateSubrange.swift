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

#if !COLLECTIONS_SINGLE_MODULE
import SpanPreview
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension MutableContainer
where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public mutating func updateSubrange<E: Error>(
    _ subrange: Range<Index>,
    updatingWith updater: (inout MutableSpan<Element>) throws(E) -> Void
  ) throws(E) {
    var i = subrange.lowerBound
    while true {
      var span = self.nextMutableSpan(after: &i, limitedBy: subrange.upperBound)
      guard !span.isEmpty else { break }
      try updater(&span)
    }
  }

  @_alwaysEmitIntoClient
  public mutating func updateElements<
    Failure: Error,
    Source: Producer<Element, Failure> & ~Copyable & ~Escapable
  >(
    after index: inout Index,
    from source: inout Source
  ) throws(Failure) where Source.Element: ~Copyable {
    // We cannot do in-place bulk updates, because we wouldn't be able to
    // gracefully recover from a producer failure.
    // See the `Failure == Never` refinement below for the faster (& far more
    // convenient) in-place variant.

    // `offset` is the offset of the next item to update in the mutable span
    // that starts at `index`. The loop invariant is that this remains zero;
    // however, when `source` terminates before we reach the end of the
    // container, then this can be left with some positive value that we must
    // use to advance `index` before returning -- so that we properly indicate
    // how far we updated elements in `self`.
    var offset = 0
    defer {
      if offset > 0 {
        index = self.index(index, offsetBy: offset)
      }
    }
    while offset == 0 {
      var next = index
      var dst = self.nextMutableSpan(after: &next)
      guard !dst.isEmpty else { break }
      try withTemporaryAllocation(
        of: Element.self,
        capacity: Swift.min(_producerBufferSize, dst.count)
      ) { buf throws(Failure) in
        while offset < dst.count {
          defer {
            if !buf.isEmpty {
              // We need to updating all items that were successfully generated,
              // whether or not we've run into failure/eof.
              let j = offset &+ buf.count
              dst._updateSubrange(Range(uncheckedBounds: (offset, j)), moving: &buf)
              offset = j
            }
          }
          guard try source.fill(&buf) else { return }
        }
        index = next
        offset = 0
      }
    }
  }

  @_alwaysEmitIntoClient
  public mutating func updateElements<
    Source: CountedProducer<Element, Never> & ~Copyable & ~Escapable
  >(
    after index: inout Index,
    from source: inout Source
  ) where Source.Element: ~Copyable {
    // With a CountedProducer that doesn't throw, we can implement
    // bulk updating in place.
    var remaining = source.count
    while remaining > 0 {
      var target = self.nextMutableSpan(after: &index, maxCount: remaining)
      guard !target.isEmpty else { break }
      remaining -= target.count
      target.withUnsafeMutableBufferPointer { buf in
        buf.deinitialize()
        var dst = OutputSpan(buffer: buf, initializedCount: 0)
        source.fill(&dst)
        let c = dst.finalize(for: buf)
        precondition(c == buf.count, "Invalid CountedProducer")
      }
    }
  }

  @_alwaysEmitIntoClient
  public mutating func updateSubrange<
    Source: CountedProducer<Element, Never> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Index>,
    from source: consuming Source
  ) where Source.Element: ~Copyable {
    var remaining = source.count
    var i = subrange.lowerBound
    while remaining > 0 {
      var target = self.nextMutableSpan(
        after: &i,
        maxCount: remaining,
        limitedBy: subrange.upperBound)
      guard !target.isEmpty else { break }
      remaining -= target.count
      target.withUnsafeMutableBufferPointer { buf in
        buf.deinitialize()
        var dst = OutputSpan(buffer: buf, initializedCount: 0)
        source.fill(&dst)
        let c = dst.finalize(for: buf)
        precondition(c == buf.count, "Invalid CountedProducer")
      }
      precondition(
        remaining == 0 && i == subrange.upperBound,
        "updateSubrange source length does not match target range")
    }
  }

  @_alwaysEmitIntoClient
  public mutating func updateSubrange(
    _ subrange: Range<Index>,
    from source: consuming some Drain<Element> & ~Copyable & ~Escapable
  ) {
    var i = subrange.lowerBound
    while true {
      var dst = self.nextMutableSpan(after: &i, limitedBy: subrange.upperBound)
      var j = 0
      guard !dst.isEmpty else { break }
      repeat {
        var src = source.drainNext(maxCount: dst.count &- j)
        precondition(
          !src.isEmpty,
          "updateSubrange source length does not match target range")
        let k = j &+ src.count
        dst._updateSubrange(Range(uncheckedBounds: (j, k)), moving: &src)
        j = k
      } while !dst.isEmpty
    }
    precondition(i == subrange.upperBound, "Invalid MutableContainer")
    source._expectEnd("updateSubrange source length does not match target range")
  }
}

@available(SwiftStdlib 6.4, *)
extension MutableContainer
where Self: ~Copyable & ~Escapable, Element: Copyable
{
  @_alwaysEmitIntoClient
  public mutating func updateElements<
    Failure: Error,
    Source: BorrowingIteratorProtocol<Element, Failure> & ~Copyable & ~Escapable
  >(
    after index: inout Index,
    copying source: inout Source
  ) throws(Failure) {
  outer:
    while true {
      var next = index
      var dst = self.nextMutableSpan(after: &next)
      guard !dst.isEmpty else { break }
      var offset = 0
      defer {
        if offset > 0 {
          index = self.index(index, offsetBy: offset)
        }
      }
      while offset < dst.count {
        let src = try source.nextSpan(maxCount: dst.count)
        if src.isEmpty { break outer }
        dst._updateSubrange(
          Range(uncheckedBounds: (offset, offset + src.count)),
          copying: src)

      }
      index = next
      offset = 0
    }
  }

  @_alwaysEmitIntoClient
  public mutating func updateSubrange(
    _ subrange: Range<Index>,
    from source: borrowing some Container<Element> & ~Copyable & ~Escapable
  ) {
    var it = source.makeBorrowingIterator()
    var index = subrange.lowerBound
    while true {
      var dst = self.nextMutableSpan(after: &index, limitedBy: subrange.upperBound)
      guard !dst.isEmpty else { break }
      var offset = 0
      while offset < dst.count {
        let src = it.nextSpan(maxCount: dst.count)
        precondition(!src.isEmpty, "updateSubrange source length does not match target range")
        let end = offset + src.count
        dst._updateSubrange(Range(uncheckedBounds: (offset, end)), copying: src)
        offset = end
      }
    }
    precondition(
      it.nextSpan().isEmpty,
      "updateSubrange source length does not match target range")
  }
}

#endif
