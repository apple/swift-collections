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
import ContainersPreview
#endif

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

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
    try self.insert(maximumCount: capacity, initializingWith: initializer)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public init<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    capacity: Int,
    from producer: inout P
  ) throws(E) {
    self.init(capacity: capacity)
    try self.insert(maximumCount: capacity, from: &producer)
  }
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public init<
    D: Drain<Element> & ~Copyable & ~Escapable
  >(
    capacity: Int,
    from drain: inout D
  ) {
    self.init(capacity: capacity)
    self.insert(maximumCount: capacity, from: &drain)
  }
#endif
}

@available(SwiftStdlib 5.0, *)
extension RigidSet /* where Element: Copyable */ {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<
    S: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(
    capacity: Int,
    copying contents: borrowing S
  ) {
    self.init(capacity: capacity)
    self._insert(copying: contents)
  }
#endif
  
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

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<
    S: BorrowingSequence<Element> & Sequence<Element>
  >(
    capacity: Int,
    copying contents: borrowing S
  ) {
    self.init(capacity: capacity)
    self._insert(copying: contents)
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public init<
    S: BorrowingSequence<Element> & Collection<Element>
  >(
    capacity: Int? = nil,
    copying contents: S
  ) {
    self.init(capacity: capacity ?? contents.count)
    self._insert(copying: contents)
  }
#endif
}

#endif
