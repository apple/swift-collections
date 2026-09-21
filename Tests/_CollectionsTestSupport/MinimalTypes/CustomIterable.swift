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

import XCTest

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 5.0, *)
package struct CustomIterable<Element: ~Copyable, Failure: Error>: ~Copyable {
  package let underestimatedCount: Int
  package let _chunkSize: Int
  package let _generator: (Int) throws(Failure) -> Element?

  package init(
    underestimatedCount: Int = 0,
    chunkSize: Int,
    generatingWith generator: borrowing @escaping (Int) throws(Failure) -> Element?
  ) {
    self.underestimatedCount = underestimatedCount
    self._chunkSize = chunkSize
    self._generator = copy generator
  }
}


@available(SwiftStdlib 5.0, *)
extension CustomIterable: Iterable where Element: ~Copyable {
  package typealias BorrowingIterator = CustomBorrowingIterator<Element, Failure>

  package borrowing func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(
      underestimatedCount: self.underestimatedCount,
      chunkSize: self._chunkSize,
      generatingWith: self._generator)
  }
}

#endif
