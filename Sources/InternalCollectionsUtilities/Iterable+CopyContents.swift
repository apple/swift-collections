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

#if compiler(>=6.4)

@available(SwiftStdlib 6.4, *)
extension Iterable where Self: ~Copyable & ~Escapable, Element: Copyable {
  @inlinable
  @unsafe
  package func _copyContents(
    intoPrefixOf buffer: UnsafeMutableBufferPointer<Element>,
    count: inout Int
  ) throws(Failure) {
    // `count` is bumped after each span, so that if the iterator throws, the
    // caller still accounts for (and eventually releases) the items that were
    // already copied.
    var target = unsafe buffer
    var it = self.makeBorrowingIterator()
    while target.count != 0 {
      let span = try it.nextSpan(maxCount: target.count)
      if span.isEmpty { return }
      unsafe target._initializeAndDropPrefix(copying: span)
      count += span.count
    }
    let test = try it.nextSpan()
    precondition(test.isEmpty, "Contents do not fit in target buffer")
  }
}

#endif
