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

#if compiler(>=6.2)

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

@available(SwiftStdlib 5.0, *)
extension RigidDeque /*: Equatable */ where Element: Equatable /* & ~Copyable */ {
  public func isTriviallyIdentical(to other: borrowing Self) -> Bool {
    self._handle.isIdentical(to: other._handle)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque /*: Equatable */ where Element: Equatable /* & ~Copyable */ {
  @inlinable
  public static func ==(
    left: borrowing Self,
    right: borrowing Self
  ) -> Bool {
    guard left.count == right.count else { return false }
    guard !left.isTriviallyIdentical(to: right) else { return true }
    
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
    return left.elementsEqual(right)
#else
    for i in 0 ..< left.count {
      guard left[i] == right[i] else { return false }
    }
    return true
#endif
  }
}

#endif
