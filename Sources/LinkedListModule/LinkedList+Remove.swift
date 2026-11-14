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
#endif

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable {
  /// This method invalidates all previously returned list indices.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func remove(at index: inout Index) -> Element {
    guard let node = unsafe _currentNode(of: index) else {
      preconditionFailure("Index out of bounds")
    }
    let next = unsafe exchange(&node.pointee.next, with: nil)
    if let previous = unsafe index._previousNode {
      unsafe previous.pointee.next = next
    } else {
      unsafe assert(_first == node)
      unsafe _first = next
    }
    if unsafe next == nil {
      unsafe assert(_last == node)
      unsafe _last = index._previousNode
    }
    _count &-= 1
    _version.bump()
    index._version = _version

    let result = unsafe node.move().deconstruct()
    unsafe node.deallocate()
    return result
  }
}
#endif
