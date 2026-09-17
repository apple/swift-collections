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

#if compiler(>=6.2) && UnstableContainersPreview
extension MutableSpan where Element: ~Copyable {
  // FIXME: Replace with stdlib implementation when it becomes available
  @_alwaysEmitIntoClient
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
    self.withUnsafeMutableBufferPointer { dst in
      source.withUnsafeMutableBufferPointer { src, c in
        // FIXME: Make sure this calls memcpy when Element is bitwise movable.
        let i = dst
          .extracting(unchecked: subrange)
          .moveUpdate(fromContentsOf: src.extracting(last: c))
        precondition(i == subrange.count)
        c = 0
      }
    }
  }

  // FIXME: Replace with stdlib implementation when it becomes available
  @_alwaysEmitIntoClient
  package mutating func _updateAll(
    moving source: inout InputSpan<Element>
  ) {
    let count = self.count
    precondition(
      source.count == count,
      "updateSubrange source count doesn't match target")
    self.withUnsafeMutableBufferPointer { dst in
      source.withUnsafeMutableBufferPointer { src, c in
        // FIXME: Make sure this calls memcpy when Element is bitwise movable.
        let i = dst.moveUpdate(fromContentsOf: src.extracting(last: c))
        assert(i == count)
        c = 0
      }
    }
  }
}

#endif
