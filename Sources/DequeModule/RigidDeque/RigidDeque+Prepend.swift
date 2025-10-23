//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  internal mutating func uncheckedPrepend(_ newElement: consuming Element) {
    _handle.uncheckedPrepend(newElement)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func prepend(_ newElement: consuming Element) {
    precondition(!isFull, "RigidDeque is full")
    uncheckedPrepend(newElement)
  }
}

#endif
