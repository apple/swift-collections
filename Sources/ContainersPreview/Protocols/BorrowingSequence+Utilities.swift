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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence_ where Self: ~Copyable & ~Escapable, Element_: Copyable, Failure == Never {
  @inlinable
  package func _copyContents(
    intoPrefixOf buffer: UnsafeMutableBufferPointer<Element_>
  ) -> Int {
    var target = buffer
    var it = self.makeBorrowingIterator_()
    while target.count != 0 {
      let span = it.nextSpan_(maximumCount: target.count)
      if span.isEmpty {
        return buffer.count - target.count
      }
      target._initializeAndDropPrefix(copying: span)
    }
    let test = it.nextSpan_()
    precondition(test.isEmpty, "Contents do not fit in target buffer")
    return buffer.count
  }
}

#endif
