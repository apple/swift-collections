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
import BasicContainers
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview

/// An `Iterable` source that is also a `Sequence`, handing out its items
/// one at a time and then throwing once they run out.
@available(SwiftStdlib 6.4, *)
package struct ThrowingIterableSequence<Element>: Iterable, Sequence {
  package typealias Failure = ThrowingIterableSequenceError
  package typealias Iterator = Array<Element>.Iterator

  package var items: [Element]

  package init(items: [Element]) { self.items = items }

  package func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(items: items)
  }

  package func makeIterator() -> Iterator { items.makeIterator() }

  package struct BorrowingIterator: BorrowingIteratorProtocol {
    package var items: [Element]
    package var offset = 0

    package init(items: [Element]) { self.items = items }

    @_lifetime(&self)
    package mutating func nextSpan(
      maxCount: Int
    ) throws(Failure) -> Span<Element> {
      guard offset < items.count else { throw ThrowingIterableSequenceError() }
      offset += 1
      return items.span.extracting(offset - 1 ..< offset)
    }
  }
}

package struct ThrowingIterableSequenceError: Error {}
#endif
