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
extension UniqueSet where Element: ~Copyable {
  @inlinable
  public init() {
    self.init(_storage: .init())
  }
  
  @inlinable
  public init(minimumCapacity: Int) {
    precondition(minimumCapacity >= 0, "Capacity must be nonnegative")
    let table = _HTable(minimumCapacity: minimumCapacity)
    self.init(_storage: RigidSet(_table: table))
  }
  
  @inlinable
  public init(consuming set: consuming RigidSet<Element>) {
    self.init(_storage: set)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public init<E: Error>(
    minimumCapacity: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init(minimumCapacity: minimumCapacity)
    try self.insert(
      maximumCount: minimumCapacity,
      initializingWith: initializer)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public init<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    minimumCapacity: Int? = nil, from producer: inout P
  ) throws(E) {
    let c = producer.underestimatedCount
    if let minimumCapacity {
      self.init(minimumCapacity: Swift.min(minimumCapacity, c))
    } else {
      self.init(minimumCapacity: c)
    }
    try self.insert(from: &producer)
  }
#endif
}

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: Copyable {
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public init<
    S: BorrowingSequence<Element> & ~Copyable & ~Escapable
  >(
    copying items: borrowing S
  ) {
    self.init()
    self.insert(copying: items)
  }
#endif
  
  @_alwaysEmitIntoClient
  public init(copying items: some Sequence<Element>) {
    self.init()
    self.insert(copying: items)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public init<
    S: BorrowingSequence<Element> & Sequence<Element>
  >(
    copying items: borrowing S
  ) {
    self.init()
    self._insert(copying: items)
  }
#endif
}

#endif
