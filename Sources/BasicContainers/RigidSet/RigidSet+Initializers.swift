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

#if compiler(>=6.4) && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @inlinable
  @inline(__always)
  public init() {
    self.init(capacity: 0)
  }
  
  @inlinable
  public init(capacity: Int) {
    precondition(capacity >= 0, "Capacity must be nonnegative")
    self.init(_table: _HTable(capacity: capacity))
  }
  
  @inlinable
  public init(consuming set: consuming UniqueSet<Element>) {
    self.init() // FIXME: Language limitation as of 6.3; this should not be needed here.
    // error: Conditional initialization or destruction of noncopyable types is
    // not supported; this variable must be consistently in an initialized or
    // uninitialized state through every code path
    self = set._storage
  }
  
  @inlinable
  public init<E: Error>(
    capacity: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init(capacity: capacity)
    try self.insert(addingCount: capacity, initializingWith: initializer)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet /* where Element: Copyable */ {
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<
    S: Iterable & ~Copyable & ~Escapable
  >(
    capacity: Int,
    copying contents: borrowing S
  ) throws(S.Failure)
  where S.Element == Element {
    self.init(capacity: capacity)
    try self._insert(copying: contents)
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    capacity: Int,
    copying contents: some Sequence<Element>
  ) {
    self.init(capacity: capacity)
    self.insert(copying: contents)
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    capacity: Int? = nil,
    copying contents: some Collection<Element>
  ) {
    self.init(capacity: capacity ?? contents.count)
    self.insert(copying: contents)
  }

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<S: Iterable & Sequence<Element>>(
    capacity: Int,
    copying contents: borrowing S
  ) throws(S.Failure)
  where S.Element == Element {
    self.init(capacity: capacity)
    try self._insert(copying: contents)
  }

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<S: Iterable & Collection<Element>>(
    capacity: Int? = nil,
    copying contents: S
  ) throws(S.Failure)
  where S.Element == Element {
    self.init(capacity: capacity ?? contents.count)
    try self._insert(copying: contents)
  }
}

#endif
