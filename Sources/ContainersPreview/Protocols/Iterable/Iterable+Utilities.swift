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

@available(SwiftStdlib 6.4, *)
extension Iterable where Self: ~Copyable & ~Escapable, Element: Copyable {
  @inlinable
  package func _copyContents(
    intoPrefixOf buffer: UnsafeMutableBufferPointer<Element>
  ) throws(Failure) -> Int {
    var target = buffer
    var it = self.makeBorrowingIterator()
    while target.count != 0 {
      let span = try it.nextSpan(maxCount: target.count)
      if span.isEmpty {
        return buffer.count - target.count
      }
      target._initializeAndDropPrefix(copying: span)
    }
    let test = try it.nextSpan()
    precondition(test.isEmpty, "Contents do not fit in target buffer")
    return buffer.count
  }
}

#endif
