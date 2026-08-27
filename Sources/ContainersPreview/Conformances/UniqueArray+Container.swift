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
import BasicContainers
#endif

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
extension UniqueArray: Container where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(
    from start: Index, to end: Index
  ) -> BorrowingIterator {
    _storage.makeBorrowingIterator(from: start, to: end)
  }

  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: inout BorrowingIterator) -> Index {
    _storage.currentIndex(of: &iterator)
  }
}

@available(SwiftStdlib 6.4, *)
extension UniqueArray: BidirectionalContainer where Element: ~Copyable {}

@available(SwiftStdlib 6.4, *)
extension UniqueArray: RandomAccessContainer where Element: ~Copyable {}

@available(SwiftStdlib 6.4, *)
extension UniqueArray: MutableContainer where Element: ~Copyable {}

@available(SwiftStdlib 6.4, *)
extension UniqueArray: RangeReplaceableContainer where Element: ~Copyable {}

@available(SwiftStdlib 6.4, *)
extension UniqueArray: DynamicContainer where Element: ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: Copyable {
}

#endif
