//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension UniqueSet: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = RigidSet<Element>.BorrowingIterator
  
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @inlinable
  public func _customContainsEquatableElement(
    _ element: borrowing Element
  ) -> Bool? {
    self.contains(element)
  }

  @inlinable
  @_lifetime(borrow self)
  public borrowing func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(_set: _storage)
  }
}
#endif
