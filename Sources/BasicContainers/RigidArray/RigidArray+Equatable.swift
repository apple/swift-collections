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

#if compiler(>=6.2)

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  public func isTriviallyIdentical(to other: borrowing Self) -> Bool {
    self._storage._isIdentical(to: other._storage)
    && self._count == other._count
  }
}

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension RigidArray: Equatable where Element: Equatable & ~Copyable {
  @inlinable
  public static func ==(
    left: borrowing Self,
    right: borrowing Self
  ) -> Bool {
    left.span._elementsEqual(to: right.span)
  }
}
#else
@available(SwiftStdlib 5.0, *)
extension RigidArray /*: Equatable */ where Element: Equatable /* & ~Copyable */ {
  @inlinable
  public static func ==(
    left: borrowing Self,
    right: borrowing Self
  ) -> Bool {
    left.span._elementsEqual(to: right.span)
  }
}
#endif

#endif
