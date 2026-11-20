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

import Synchronization
#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import SpanPreview
#endif

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
@safe
@frozen
public struct LinkedList<Element: ~Copyable>: ~Copyable {
  /// A pointer to the list's first node, if any.
  @usableFromInline
  package var _first: UnsafeMutablePointer<_Node>?

  /// A pointer to the list's last node, if any.
  @usableFromInline
  package var _last: UnsafeMutablePointer<_Node>?

  @usableFromInline
  package var _count: Int

  /// The list's current version number. This gets bumped whenever one or more
  /// nodes get added, removed or reordered in the list.
  @usableFromInline
  package var _version: _LinkedListVersion

  /// Create an empty list.
  @_alwaysEmitIntoClient
  public init() {
    unsafe _first = nil
    unsafe _last = nil
    _count = 0
    _version = .empty
  }

  @_alwaysEmitIntoClient
  package init(
    _first: UnsafeMutablePointer<_Node>?,
    last: UnsafeMutablePointer<_Node>?,
    count: Int
  ) {
    unsafe assert(
      _first == nil
      ? last == nil && count == 0
      : last != nil && count > 0)
    unsafe self._first = _first
    unsafe self._last = last
    self._count = count
    self._version = .new()
  }

  @inlinable
  deinit {
    unsafe _dismantleList(_first)
  }
}

/// Carefully destroy the list of nodes starting at `list`, avoiding
/// unbounded recursion in node deinit.
///
/// Each node is deinitialized and deallocated.
@available(SwiftStdlib 6.4, *)
@inlinable
package func _dismantleList<Element: ~Copyable>(
  _ list: UnsafeMutablePointer<LinkedList<Element>._Node>?
) {
  var p = unsafe list
  while let q = unsafe p {
    unsafe p = exchange(&q.pointee.next, with: nil)
    let buffer = unsafe UnsafeMutableBufferPointer(start: q, count: 1)
    unsafe buffer.deinitialize()
    unsafe buffer.deallocate()
  }
}

@available(SwiftStdlib 6.4, *)
@inlinable
package func _consumeList<Element: ~Copyable>(
  _ list: UnsafeMutablePointer<LinkedList<Element>._Node>?,
  consumingWith consumer: (inout InputSpan<Element>) -> Void
) {
  var p = unsafe list
  while let q = unsafe p {
    unsafe p = exchange(&q.pointee.next, with: nil)
    let v = unsafe LinkedList<Element>._Node._ptrToValue(in: q)
    let buffer = unsafe UnsafeMutableBufferPointer(start: v, count: 1)
    var span = unsafe InputSpan(buffer: buffer, initializedCount: 1)
    consumer(&span)
    _ = consume span
    unsafe q.deallocate()
  }
}

#endif
