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
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension UniqueArray: Iterable where Element: ~Copyable {
  public typealias BorrowingIterator = Span<Element>.BorrowingIterator

  @inlinable
  public var underestimatedCount: Int { count }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func makeBorrowingIterator() -> BorrowingIterator {
    self._storage.makeBorrowingIterator()
  }
}
#endif
