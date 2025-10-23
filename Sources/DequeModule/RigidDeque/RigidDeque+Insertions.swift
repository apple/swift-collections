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
  public mutating func insert(_ newElement: consuming Element, at index: Int) {
    precondition(!isFull, "RigidDeque is full")
    precondition(index >= 0 && index <= count,
                 "Can't insert element at invalid index")
    _handle.uncheckedInsert(newElement, at: index)
  }
}

#endif
