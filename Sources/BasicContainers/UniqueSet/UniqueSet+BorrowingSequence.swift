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
import ContainersPreview
#endif

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_HASHED_CONTAINERS && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension UniqueSet: BorrowingSequence_ where Element: ~Copyable {
  public typealias BorrowingIterator = RigidSet<Element>.BorrowingIterator
  
  @inlinable
  public var underestimatedCount: Int { count }
  
  @inlinable
  public func _customContainsEquatableElement_(
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
