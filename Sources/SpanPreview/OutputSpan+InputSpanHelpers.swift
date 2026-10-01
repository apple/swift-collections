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

#if UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension OutputSpan where Element: ~Copyable {
  @inlinable
  @inline(__always)
  @_lifetime(self: copy self)
  @_lifetime(source: copy source)
  package mutating func _append(moving source: inout InputSpan<Element>) {
    // FIXME: This needs to be in the stdlib.
    unsafe source.withUnsafeMutableBufferPointer { src, srcCount in
      let srcItems = unsafe src._extracting(
        uncheckedFrom: src.count &- srcCount,
        to: src.count)
      unsafe self._append(moving: srcItems)
      srcCount = 0
    }
  }

  @_alwaysEmitIntoClient
  @_lifetime(self: copy self)
  package mutating func _consumeAll<Failure: Error>(
    consumingWith consumer: (inout InputSpan<Element>) throws(Failure) -> Void
  ) throws(Failure) {
    unsafe try self.withUnsafeMutableBufferPointer { buffer, count throws(Failure) in
      var span = unsafe InputSpan(
        buffer: buffer._extracting(first: count),
        initializedCount: count)
      try consumer(&span)
      _ = consume span
      count = 0
    }
  }
}
#endif
