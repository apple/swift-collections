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

#if compiler(>=6.4) && UnstableContainersPreview && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension RigidSet: Container where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: inout BorrowingIterator) -> Index {
    precondition(_validateIterator(iterator))
    if iterator._bucketIterator.isAtEnd {
      return Index(_bucket: iterator._endBucket)
    }
    return Index(_bucket: iterator._bucketIterator.currentBucket)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(
    from start: Index, to end: Index
  ) -> BorrowingIterator {
    _checkValidIndex(start)
    _checkValidIndex(end)
    return BorrowingIterator(_set: self, from: start, to: end)
  }
}

#if false // FIXME
@available(SwiftStdlib 5.0, *)
extension RigidSet: DrainableContainer where Element: ~Copyable {
  public struct SubrangeConsumer: ~Copyable & ~Escapable {
    //...
  }

  public func consume(_ subrange: Range<Index>) -> SubrangeConsumer {
    //...
  }
}
#endif

#endif
