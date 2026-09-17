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

extension MutableSpan where Element: ~Copyable {
  // FIXME: Replace with stdlib implementation when it becomes available
  // (See also InputSpan-taking variant in SpanPreview)
  @_alwaysEmitIntoClient
  package mutating func _updateSubrange(
    _ subrange: Range<Index>,
    moving source: inout OutputSpan<Element>
  ) {
    precondition(
      subrange.lowerBound >= 0 && subrange.upperBound <= count,
      "Index range out of bounds")
    precondition(
      subrange.count == source.count,
      "updateSubrange source count doesn't match target")
    self.withUnsafeMutableBufferPointer { dst in
      source.withUnsafeMutableBufferPointer { src, c in
        // FIXME: Make sure this calls memcpy when Element is bitwise movable.
        let i = dst
          .extracting(unchecked: subrange)
          .moveUpdate(fromContentsOf: src.extracting(first: c))
        precondition(i == subrange.count)
        c = 0
      }
    }
  }

  // FIXME: Replace with stdlib implementation when it becomes available
  // (See also InputSpan-taking variant in SpanPreview)
  @_alwaysEmitIntoClient
  package mutating func _updateAll(
    moving source: inout OutputSpan<Element>
  ) {
    let count = self.count
    precondition(
      source.count == count,
      "updateSubrange source count doesn't match target")
    self.withUnsafeMutableBufferPointer { dst in
      source.withUnsafeMutableBufferPointer { src, c in
        // FIXME: Make sure this calls memcpy when Element is bitwise movable.
        let i = dst.moveUpdate(fromContentsOf: src.extracting(first: c))
        assert(i == count)
      }
    }
  }
}

extension MutableSpan /* where Element: Copyable */ {
  // FIXME: Replace with stdlib implementation when it becomes available
  @_alwaysEmitIntoClient
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
        let i = dst.extracting(unchecked: subrange).update(fromContentsOf: src)
        precondition(i == subrange.count)
      }
    }
  }

  // FIXME: Replace with stdlib implementation when it becomes available
  @_alwaysEmitIntoClient
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

#endif
