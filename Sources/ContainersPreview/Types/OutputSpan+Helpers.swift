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

#if compiler(>=6.2) && UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension OutputSpan where Element: ~Copyable {
  @_lifetime(source: copy source)
  @inlinable
  @inline(__always)
  @_lifetime(self: copy self)
  package mutating func _append(moving source: inout InputSpan<Element>) {
    // FIXME: This needs to be in the stdlib.
    source.withUnsafeMutableBufferPointer { src, srcCount in
      let srcItems = src._extracting(
        uncheckedFrom: src.count &- srcCount,
        to: src.count)
      self._append(moving: srcItems)
      srcCount = 0
    }
  }

  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  package mutating func _consumeAll(
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    self.withUnsafeMutableBufferPointer { buffer, count in
      var span = InputSpan(
        buffer: buffer._extracting(first: count),
        initializedCount: count)
      consumer(&span)
      _ = consume span
      count = 0
    }
  }
}
#endif
