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


#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension UniqueDictionary {
  @inlinable
  @inline(__always)
  public func isTriviallyIdentical(to other: borrowing Self) -> Bool {
    self._storage.isTriviallyIdentical(to: other._storage)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDictionary {
  @inlinable
  @inline(__always)
  public func isEqual(
    to other: borrowing Self,
    by areEquivalent: (borrowing Value, borrowing Value) -> Bool
  ) -> Bool {
    self._storage.isEqual(to: other._storage, by: areEquivalent)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDictionary: GeneralizedEquatable where Value: GeneralizedEquatable { // Should be Equatable
  @inlinable
  @inline(__always)
  public static func ==(left: borrowing Self, right: borrowing Self) -> Bool {
    left.isEqual(to: right, by: ==)
  }
}

#endif
