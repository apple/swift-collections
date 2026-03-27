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
extension UniqueSet {
  @inlinable
  @inline(__always)
  public func isTriviallyIdentical(to other: borrowing Self) -> Bool {
    self._storage.isTriviallyIdentical(to: other._storage)
  }
}

@available(SwiftStdlib 6.4, *)
extension UniqueSet: Equatable {
  @inlinable
  @inline(__always)
  public static func ==(left: borrowing Self, right: borrowing Self) -> Bool {
    left._storage == right._storage
  }
}

#endif
