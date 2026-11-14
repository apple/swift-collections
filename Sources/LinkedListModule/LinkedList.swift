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

#if compiler(>=6.4)
import Synchronization

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

  /// The list's current version number. This is a composite of two bitfields,
  /// a 16-bit local version, and a 48-bit global version number:
  ///
  ///     b63:16                                           b15:0
  ///    ┌────────────────────────────────────────────────┬────────────────┐
  ///    │ Global version                                 │ Local version  │
  ///    └────────────────────────────────────────────────┴────────────────┘
  ///
  /// The local version number is incremented directly whenever one or more
  /// nodes get added, removed or reordered in the list. The global version
  /// comes from a process-wide global counter.
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
/// Each node is deinitialized and deallocatedstruct
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

#endif
