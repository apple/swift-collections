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
extension InlineArray: Iterable_ where Element: ~Copyable {
  public typealias Element_ = Element
  public typealias BorrowingIterator_ = Span<Element>.BorrowingIterator_

  @inlinable
  public var underestimatedCount_: Int { count }

  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator_() -> BorrowingIterator_ {
    BorrowingIterator_(self.span)
  }
}

#endif
