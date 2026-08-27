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
import BasicContainers
import InternalCollectionsUtilities
import SpanPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview && UnstableHashedContainers
@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public init<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    capacity: Int,
    from producer: inout P
  ) throws(E)
  where P.Element: ~Copyable
  {
    self.init(capacity: capacity)
    try self.insert(addingCount: capacity, from: &producer)
  }

  @_alwaysEmitIntoClient
  public init<
    E: Error,
    P: CountedProducer<Element, E> & ~Copyable & ~Escapable
  >(
    capacity: Int?,
    from producer: inout P
  ) throws(E)
  where P.Element: ~Copyable
  {
    let c = capacity ?? producer.count
    self.init(capacity: c)
    try self.insert(addingCount: c, from: &producer)
  }

  @_alwaysEmitIntoClient
  public init<
    D: Drain<Element> & ~Copyable & ~Escapable
  >(
    capacity: Int? = nil,
    from drain: inout D
  ) {
    let c = capacity ?? drain.count
    self.init(capacity: c)
    self.insert(addingCount: c, from: &drain)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet /* where Element: Copyable */ {
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<S: Container<Element> & Collection<Element>>(
    capacity: Int? = nil,
    copying contents: S
  )
  where S.Element == Element {
    self.init(capacity: capacity ?? contents.count)
    self._insert(copying: contents)
  }

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<S: Container<Element> & Sequence<Element>>(
    capacity: Int? = nil,
    copying contents: S
  )
  where S.Element == Element {
    self.init(capacity: capacity ?? contents.count)
    self._insert(copying: contents)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public mutating func insert<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    addingCount newItemCount: Int? = nil,
    from producer: inout P
  ) throws(E)
  where P.Element: ~Copyable
  {
    try self.insert(
      addingCount: newItemCount ?? freeCapacity
    ) { target throws(E) in
      while !target.isFull {
        guard try producer.generate(into: &target) else { break }
      }
    }
  }

  @_alwaysEmitIntoClient
  public mutating func insert<
    E: Error,
    P: CountedProducer<Element, E> & ~Copyable & ~Escapable
  >(
    from producer: consuming P
  ) throws(E) {
    try self.insert(addingCount: producer.count, from: &producer)
    try producer._expectEnd("Invalid CountedProducer")
  }

  @_alwaysEmitIntoClient
  public mutating func insert<
    D: Drain<Element> & ~Copyable & ~Escapable
  >(
    from drain: consuming D
  ) {
    var remainder = drain.count
    while remainder > 0 {
      var span = drain.drainNext(maxCount: remainder)
      guard !span.isEmpty else { break }
      remainder &-= span.count
      while let next = span.popFirst() {
        self.insert(next)
      }
    }
    drain._expectEnd("Invalid Drain")
  }
}

#endif
