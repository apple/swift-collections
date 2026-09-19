//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension MutableSpan where Element: ~Copyable {
  // FIXME: Replace with stdlib implementation when it becomes available
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  @_lifetime(source: copy source)
  package mutating func _updateSubrange(
    _ subrange: Range<Index>,
    moving source: inout InputSpan<Element>
  ) {
    precondition(
      subrange.lowerBound >= 0 && subrange.upperBound <= count,
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
          .moveUpdate(fromContentsOf: src._extracting(last: c))
        precondition(i == subrange.count)
#else
        var d = dst._ptr(at: subrange.lowerBound)
        var s = src._ptr(at: src.count - c)
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
  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  @_lifetime(source: copy source)
  package mutating func _updateAll(
    moving source: inout InputSpan<Element>
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
        let i = dst.moveUpdate(fromContentsOf: src._extracting(last: c))
        assert(i == count)
#else
        var d = dst._ptr(at: 0)
        var s = src._ptr(at: src.count - c)
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

#endif
