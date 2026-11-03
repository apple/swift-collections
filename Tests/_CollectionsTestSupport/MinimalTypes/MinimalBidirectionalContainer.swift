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

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import BasicContainers
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview
/// A bidirectional container that relies on the default implementations of
/// every `BidirectionalContainer` requirement that has one.
@available(SwiftStdlib 6.4, *)
package struct MinimalBidirectionalContainer<Element: ~Copyable>: ~Copyable {
  package let base: RigidArray<Element>

  package init(_ base: consuming RigidArray<Element>) {
    self.base = base
  }
}

@available(SwiftStdlib 6.4, *)
extension MinimalBidirectionalContainer: BidirectionalContainer
where Element: ~Copyable {
  package typealias BorrowingIterator = ContainerIterator<Self>

  package var count: Int { base.count }
  package var startIndex: Int { base.startIndex }
  package var endIndex: Int { base.endIndex }

  package subscript(index: Int) -> Element {
    borrow { base[index] }
  }

  @_lifetime(borrow self)
  package func nextSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> Span<Element> {
    base.nextSpan(after: &index, maxCount: maxCount, limitedBy: limit)
  }

  package func spanBoundary(
    before index: Int, maxDistance: Int, limitedBy limit: Int
  ) -> (index: Int, distance: Int) {
    base.spanBoundary(
      before: index, maxDistance: maxDistance, limitedBy: limit)
  }
}
#endif
