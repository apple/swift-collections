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
    // See the `CountedProducer<Element, Never>` refinement below for the faster
    // in-place variant.
    try withTemporaryAllocation(
      of: Element.self, capacity: _producerBufferSize
    ) { scratch throws(Failure) in
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
        while offset < dst.count {
          defer {
            if !scratch.isEmpty {
              // We need to update all items that were successfully generated,
              // whether or not we've run into failure/eof.
              let j = offset &+ scratch.count
              dst._updateSubrange(
                Range(uncheckedBounds: (offset, j)),
                moving: &scratch)
              offset = j
            }
          }
          let r = try scratch._append(
            addingCount: Swift.min(dst.count &- offset, scratch.freeCapacity)
          ) { src throws(Failure) in try source.generate(into: &src) }
          guard r > 0 else { return }
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
      target._edit { dst in
        dst.removeAll()
        source.generate(into: &dst)
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
    // With a CountedProducer that doesn't throw, we can implement
    // bulk updating in place.
    var remaining = source.count
    var i = subrange.lowerBound
    while remaining > 0 {
      var target = self.nextMutableSpan(
        after: &i,
        maxCount: remaining,
        limitedBy: subrange.upperBound)
      guard !target.isEmpty else { break }
      remaining -= target.count
      target._edit { dst in
        // Note: we cannot throw here while `dst` isn't full -- this is why
        // `Source` is required not to throw. (We have
        // `updateElements(after:from:)` to support the throwing case, but at
        // the cost of slower operation and a far more unwieldy interface.)
        dst.removeAll()
        source.generate(into: &dst)
        precondition(dst.isFull, "Invalid CountedProducer")
      }
    }
    precondition(
      remaining == 0 && i == subrange.upperBound,
      "updateSubrange source length does not match target range")
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
      while j < dst.count {
        var src = source.drainNext(maxCount: dst.count &- j)
        precondition(
          !src.isEmpty,
          "updateSubrange source length does not match target range")
        let k = j &+ src.count
        dst._updateSubrange(Range(uncheckedBounds: (j, k)), moving: &src)
        j = k
      }
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
        let src = try source.nextSpan(maxCount: dst.count &- offset)
        if src.isEmpty { break outer }
        let range = Range(uncheckedBounds: (offset, offset &+ src.count))
        dst._updateSubrange(range, copying: src)
        offset = range.upperBound
      }
      index = next
      offset = 0
    }
  }

  @_alwaysEmitIntoClient
  public mutating func updateSubrange(
    _ subrange: Range<Index>,
    copying source: borrowing some Container<Element> & ~Copyable & ~Escapable
  ) {
    var it = source.makeBorrowingIterator()
    var index = subrange.lowerBound
    while true {
      var dst = self.nextMutableSpan(after: &index, limitedBy: subrange.upperBound)
      guard !dst.isEmpty else { break }
      var offset = 0
      while offset < dst.count {
        let src = it.nextSpan(maxCount: dst.count &- offset)
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
