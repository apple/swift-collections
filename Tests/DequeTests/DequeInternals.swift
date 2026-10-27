//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import DequeModule
#endif

@available(SwiftStdlib 5.0, *)
internal struct RigidTestData<Element>: ~Copyable {
  var deque: RigidDeque<Element>
  var contents: [Element]

  init(_ deque: consuming RigidDeque<Element>, _ contents: [Element]) {
    self.deque = deque
    self.contents = contents
  }

  mutating func take() -> RigidDeque<Element> {
    exchange(&self.deque, with: .init())
  }

  consuming func consume() -> RigidDeque<Element> {
    exchange(&self.deque, with: .init())
  }
}

@available(SwiftStdlib 5.0, *)
internal struct UniqueTestData<Element>: ~Copyable {
  var deque: UniqueDeque<Element>
  var contents: [Element]

  init(_ deque: consuming RigidDeque<Element>, _ contents: [Element]) {
    self.init(UniqueDeque(consuming: deque), contents)
  }

  init(_ deque: consuming UniqueDeque<Element>, _ contents: [Element]) {
    self.deque = deque
    self.contents = contents
  }
}

extension Deque {
  init<C: Collection>(layout: DequeLayout, contents: C) where C.Element == Element {
    precondition(contents.count == layout.count)
    self.init(_capacity: layout.capacity, startSlot: layout.startSlot, contents: Array(contents))
  }
}

extension LifetimeTracker {
  func deque(
    with layout: DequeLayout
  ) -> (deque: Deque<LifetimeTracked<Int>>, contents: [LifetimeTracked<Int>]) {
    let contents = self.instances(for: layout.valueRange)
    let deque = Deque(layout: layout, contents: contents)
    return (deque, contents)
  }

  @available(SwiftStdlib 5.0, *)
  func rigidDeque(
    with layout: DequeLayout
  ) -> RigidTestData<LifetimeTracked<Int>> {
    let contents = self.instances(for: layout.valueRange)
    var it = contents.makeIterator()
    let deque = RigidDeque(layout: layout) { _ in it.next()! }
    return RigidTestData(deque, contents)
  }

  @available(SwiftStdlib 5.0, *)
  func uniqueDeque(
    with layout: DequeLayout
  ) -> UniqueTestData<LifetimeTracked<Int>> {
    let contents = self.instances(for: layout.valueRange)
    var it = contents.makeIterator()
    let deque = RigidDeque(layout: layout) { _ in it.next()! }
    return UniqueTestData(deque, contents)
  }
}
