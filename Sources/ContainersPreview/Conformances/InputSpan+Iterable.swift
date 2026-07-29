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

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension InputSpan: Iterable where Element: ~Copyable {
  public typealias BorrowingIterator = Span<Element>.BorrowingIterator

  @inlinable
  public var underestimatedCount: Int { count }

  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(self.span)
  }
}

#endif
