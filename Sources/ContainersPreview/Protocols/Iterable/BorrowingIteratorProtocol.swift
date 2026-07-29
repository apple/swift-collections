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

#if compiler(>=6.4) && UnstableContainersPreview

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@available(SwiftStdlib 6.4, *)
extension BorrowingIteratorProtocol
where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @available(SwiftStdlib 6.4, *)
  @_unsafeNonescapableResult // FIXME: Eep; _overrideLifetime(_:mutating:) doesn't work
  @_lifetime(&self)
  @_lifetime(self: copy self)
  public mutating func next() throws(Failure) -> Ref<Element>? {
    let span = try nextSpan(maxCount: 1)
    guard !span.isEmpty else { return nil }
    return Ref(span[unchecked: 0])
  }
}

@available(SwiftStdlib 6.4, *)
extension BorrowingIteratorProtocol
  where Self: ~Copyable & ~Escapable, Element: Copyable
{
  @_lifetime(self: copy self)
  @inlinable
  @_transparent
  package mutating func _copyContents(into target: inout OutputSpan<Element>) throws(Failure) {
    try target.withUnsafeMutableBufferPointer { (dst, dstCount) throws(Failure) -> Void in
      var tail = dst._extracting(droppingFirst: dstCount)
      while !tail.isEmpty {
        let src = try nextSpan(maxCount: tail.count)
        if src.isEmpty { break }
        tail._initializeAndDropPrefix(copying: src)
        dstCount += src.count
      }
    }
  }
}

#endif
