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
import SpanPreview
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

  @_alwaysEmitIntoClient
  public mutating func removeAll() {
    self._version.bump()
    unsafe _dismantleList(self._first)
    unsafe self._first = nil
    unsafe self._last = nil
    self._count = 0
  }

  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func removeSubrange(_ bounds: Range<Index>) -> Index {
    var bounds = bounds
    let _ = self.extract(&bounds)
    return bounds.lowerBound
  }

  @_alwaysEmitIntoClient
  public mutating func removeFirst(_ n: Int) {
    precondition(
      n >= 0 && n <= self._count, "Count of items to remove is out of bounds")
    var p = unsafe self._first
    var i = 0
    while let q = unsafe p, i < n {
      unsafe p = exchange(&q.pointee.next, with: nil)
      unsafe q.deinitialize(count: 1)
      unsafe q.deallocate()
      i &+= 1
    }
    unsafe self._first = p
    if unsafe p == nil {
      unsafe self._last = nil
    }
    self._count -= n
  }

#if UnstableContainersPreview
  @_alwaysEmitIntoClient
  public mutating func consumeAll(
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    self._version.bump()
    unsafe _consumeList(self._first, consumingWith: consumer)
    unsafe self._first = nil
    unsafe self._last = nil
    self._count = 0
  }
#endif

#if UnstableContainersPreview
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func consumeSubrange(
    _ bounds: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) -> Index {
    var bounds = bounds
    var items = self.extract(&bounds)
    items.consumeAll(consumingWith: consumer)
    return bounds.lowerBound
  }
#endif
}
#endif
