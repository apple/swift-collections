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

@available(SwiftStdlib 5.0, *)
extension MutableSpan where Element: ~Copyable {
  // FIXME: Replace with stdlib implementation when it becomes available
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  package mutating func _edit<E: Error, R: ~Copyable>(
    _ body: (inout OutputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    // Note: while `body` is allowed to throw, it must always leave
    // the output span fully populated, even if it ends up doing that.
    try self.withUnsafeMutableBufferPointer { buf throws(E) in
      var span = unsafe OutputSpan(buffer: buf, initializedCount: buf.count)
      defer {
        let c = unsafe span.finalize(for: buf)
        span = OutputSpan()
        precondition(c == buf.count, "MutableSpan.edit must not change the size of the span")
      }
      return try body(&span)
    }
  }

  // FIXME: Replace with stdlib implementation when it becomes available
  // (See also InputSpan-taking variant in SpanPreview)
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  package mutating func _updateSubrange(
    _ subrange: Range<Index>,
    moving source: inout OutputSpan<Element>
  ) {
    precondition(
      subrange.lowerBound >= 0 && subrange.upperBound <= self.count,
      "Index range out of bounds")
    precondition(
      subrange.count == source.count,
      "updateSubrange source count doesn't match target")
    guard !subrange.isEmpty else { return }
    self.withUnsafeMutableBufferPointer { dst in
      source.withUnsafeMutableBufferPointer { src, c in
        // FIXME: Make sure this calls memcpy when Element is bitwise movable.
#if false // FIXME: UMBP.moveUpdate(fromContentsOf:) is broken as of 2026-09-17 (rdar://187733648)
        let i = dst
          ._extracting(unchecked: subrange)
          .moveUpdate(fromContentsOf: src._extracting(first: c))
        precondition(i == subrange.count)
#else
        var d = dst._ptr(at: subrange.lowerBound)
        var s = src._ptr(at: 0)
        for i in 0 ..< c {
          d.pointee = s.move()
          d += 1
          s += 1
        }
#endif
        c = 0
      }
    }
  }

  // FIXME: Replace with stdlib implementation when it becomes available
  // (See also InputSpan-taking variant in SpanPreview)
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  package mutating func _updateAll(
    moving source: inout OutputSpan<Element>
  ) {
    let count = self.count
    precondition(
      source.count == count,
      "updateSubrange source count doesn't match target")
    guard !self.isEmpty else { return }
    self.withUnsafeMutableBufferPointer { dst in
      source.withUnsafeMutableBufferPointer { src, c in
        // FIXME: Make sure this calls memcpy when Element is bitwise movable.
#if false // FIXME: UMBP.moveUpdate(fromContentsOf:) is broken as of 2026-09-17 (rdar://187733648)
        let i = dst.moveUpdate(fromContentsOf: src._extracting(first: c))
        assert(i == count)
#else
        var d = dst._ptr(at: 0)
        var s = src._ptr(at: 0)
        for i in 0 ..< c {
          d.pointee = s.move()
          d += 1
          s += 1
        }
#endif
        c = 0
      }
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension MutableSpan /* where Element: Copyable */ {
  // FIXME: Replace with stdlib implementation when it becomes available
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  package mutating func _updateSubrange(
    _ subrange: Range<Index>,
    copying source: borrowing Span<Element>
  ) {
    precondition(
      subrange.lowerBound >= 0 && subrange.upperBound <= count,
      "Index range out of bounds")
    precondition(
      subrange.count == source.count,
      "updateSubrange source count doesn't match target")
    self.withUnsafeMutableBufferPointer { dst in
      source.withUnsafeBufferPointer { src in
        // FIXME: Make sure this calls memcpy when Element is BitwiseCopyable.
        let i = dst._extracting(unchecked: subrange).update(fromContentsOf: src)
        precondition(i == subrange.count)
      }
    }
  }

  // FIXME: Replace with stdlib implementation when it becomes available
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  package mutating func _updateAll(
    copying source: borrowing Span<Element>
  ) {
    precondition(
      source.count == self.count,
      "updateSubrange source count doesn't match target")
    let i = self.withUnsafeMutableBufferPointer { dst in
      source.withUnsafeBufferPointer { src in
        // FIXME: Make sure this calls memcpy when Element is BitwiseCopyable.
        dst.update(fromContentsOf: src)
      }
    }
    precondition(i == self.count)
  }
}
