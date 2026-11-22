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

#if !COLLECTIONS_SINGLE_MODULE
import SpanPreview
#endif

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public var freeCapacity: Int { 0 }

#if UnstableContainersPreview
  /// - Returns: A valid index range addressing the newly inserted items.
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func replaceSubrange<E: Error>(
    _ subrange: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void,
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Range<Index> {
    let index = consumeSubrange(subrange, consumingWith: consumer)
    return try self.insert(addingCount: newItemCount, at: index, initializingWith: initializer)
  }
#endif
}
#endif
