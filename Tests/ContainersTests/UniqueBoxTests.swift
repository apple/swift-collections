//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import ContainersPreview
#endif

#if compiler(>=6.2)
final class UniqueBoxTests: CollectionTestCase {
  struct NoncopyablePayload: ~Copyable {
    var value: Int
    init(_ value: Int) { self.value = value }
  }

  func test_init() {
    let box = UniqueBox<Int>(42)
    expectEqual(box.value, 42)
  }

  func test_init_noncopyable() {
    let box = UniqueBox<NoncopyablePayload>(NoncopyablePayload(17))
    expectEqual(box.value.value, 17)
  }

  func test_init_reference_type_shares_instance() {
    // Boxing a reference type should not make a new copy of the referenced
    // object; the instance is shared.
    let obj = LifetimeTracked(99, for: LifetimeTracker())
    let box = UniqueBox<LifetimeTracked<Int>>(obj)
    expectTrue(box.value === obj)
  }

  func test_value_read() {
    let box = UniqueBox<String>("hello")
    expectEqual(box.value, "hello")
  }

  func test_value_write() {
    var box = UniqueBox<Int>(0)
    box.value = 123
    expectEqual(box.value, 123)
  }

  func test_value_inplace_mutation() {
    var box = UniqueBox<Int>(1)
    box.value += 41
    expectEqual(box.value, 42)
  }

  func test_value_mutation_noncopyable() {
    var box = UniqueBox<NoncopyablePayload>(NoncopyablePayload(1))
    box.value.value = 99
    expectEqual(box.value.value, 99)
  }

  func test_deinit_releases_payload() {
    let tracker = LifetimeTracker()
    do {
      let box = UniqueBox<LifetimeTracked<Int>>(tracker.instance(for: 0))
      expectEqual(tracker.instances, 1)
      _ = box
    }
    expectEqual(tracker.instances, 0)
  }

  func test_deinit_releases_noncopyable_payload() {
    let tracker = LifetimeTracker()
    do {
      let box = UniqueBox<LifetimeTrackedStruct<Int>>(
        tracker.structInstance(for: 7))
      expectEqual(tracker.instances, 1)
      _ = consume box
    }
    expectEqual(tracker.instances, 0)
  }

  func test_consume_returns_value() {
    let box = UniqueBox<Int>(55)
    let value = box.consume()
    expectEqual(value, 55)
  }

  func test_consume_noncopyable() {
    let box = UniqueBox<NoncopyablePayload>(NoncopyablePayload(33))
    let payload = box.consume()
    expectEqual(payload.value, 33)
  }

  func test_consume_does_not_leak_payload() {
    let tracker = LifetimeTracker()
    do {
      let box = UniqueBox<LifetimeTracked<Int>>(tracker.instance(for: 1))
      expectEqual(tracker.instances, 1)
      let extracted = box.consume()
      // After consume, the box is gone but the payload is still live.
      expectEqual(tracker.instances, 1)
      expectEqual(extracted.payload, 1)
      _ = extracted
    }
    expectEqual(tracker.instances, 0)
  }

  func test_clone_value_equality() {
    let original = UniqueBox<Int>(123)
    let copy = original.clone()
    expectEqual(original.value, 123)
    expectEqual(copy.value, 123)
  }

  func test_clone_independent_storage() {
    var original = UniqueBox<Int>(10)
    let copy = original.clone()
    original.value = 20
    expectEqual(original.value, 20)
    expectEqual(copy.value, 10)
  }

  func test_clone_semantics() {
    let tracker = LifetimeTracker()
    do {
      let original = UniqueBox<LifetimeTracked<Int>>(tracker.instance(for: 5))
      expectEqual(tracker.instances, 1)
      let clone = original.clone()
      // Clone must allocate a fresh payload instance.
      expectEqual(tracker.instances, 1)
      expectEqual(original.value.payload, 5)
      expectEqual(clone.value.payload, 5)
      _fixLifetime(original)
      _fixLifetime(clone)
    }
    expectEqual(tracker.instances, 0)
  }

  @available(SwiftStdlib 5.0, *)
  func test_span() {
    let box = UniqueBox<Int>(77)
    let span = box.span
    expectEqual(span.count, 1)
    expectEqual(span[0], 77)
  }

  @available(SwiftStdlib 5.0, *)
  func test_span_noncopyable() {
    let box = UniqueBox<NoncopyablePayload>(NoncopyablePayload(8))
    let span = box.span
    expectEqual(span.count, 1)
    expectEqual(span[0].value, 8)
  }

  @available(SwiftStdlib 5.0, *)
  func test_mutableSpan() {
    var box = UniqueBox<Int>(100)
    var span = box.mutableSpan
    expectEqual(span.count, 1)
    expectEqual(span[0], 100)
    span[0] = 999
    _ = consume span
    expectEqual(box.value, 999)
  }

  @available(SwiftStdlib 5.0, *)
  func test_mutableSpan_noncopyable() {
    var box = UniqueBox<NoncopyablePayload>(NoncopyablePayload(1))
    do {
      var span = box.mutableSpan
      expectEqual(span.count, 1)
      span[0].value = 42
      _ = consume span
    }
    expectEqual(box.value.value, 42)
  }

  func test_sendable_conformance_static() {
    // Compile-time assertion: UniqueBox<T> conforms to Sendable when T does.
    func requireSendable<T: Sendable & ~Copyable>(_ type: T.Type) {}
    requireSendable(UniqueBox<Int>.self)
    requireSendable(UniqueBox<String>.self)
  }

  // MARK: Deprecated API

  @available(*, deprecated)
  func test_subscript_get() {
    let box = UniqueBox<Int>(11)
    expectEqual(box[], 11)
  }

  @available(*, deprecated)
  func test_subscript_set() {
    var box = UniqueBox<Int>(0)
    box[] = 22
    expectEqual(box[], 22)
    expectEqual(box.value, 22)
  }

  @available(*, deprecated)
  func test_copy_returns_value() {
    let box = UniqueBox<Int>(33)
    expectEqual(box.copy(), 33)
    // Original box is still readable afterwards.
    expectEqual(box.value, 33)
  }

  @available(*, deprecated)
  func test_Box_typealias_is_UniqueBox() {
    let box: Box<Int> = Box<Int>(44)
    expectEqual(box.value, 44)
  }

  @available(*, deprecated)
  func test_T_typealias_is_Value() {
    let box = UniqueBox<Int>(55)
    let value: UniqueBox<Int>.T = box.value
    expectEqual(value, 55)
  }

  // MARK: Preview-gated API

#if UnstableContainersPreview
  @available(SwiftStdlib 5.0, *)
  func test_borrow_read() {
    let box = UniqueBox<Int>(123)
    let ref = box.borrow()
    expectEqual(ref.value, 123)
  }

  @available(SwiftStdlib 5.0, *)
  func test_borrow_noncopyable() {
    let box = UniqueBox<NoncopyablePayload>(NoncopyablePayload(7))
    let ref = box.borrow()
    expectEqual(ref.value.value, 7)
  }
#endif

#if compiler(>=6.3) && UnstableContainersPreview
  func test_mutate_read() {
    var box = UniqueBox<Int>(10)
    let ref = box.mutate()
    expectEqual(ref.value, 10)
  }

  func test_mutate_write() {
    var box = UniqueBox<Int>(0)
    do {
      var ref = box.mutate()
      ref.value = 200
      _ = consume ref
    }
    expectEqual(box.value, 200)
  }

  func test_mutate_noncopyable() {
    var box = UniqueBox<NoncopyablePayload>(NoncopyablePayload(1))
    do {
      var ref = box.mutate()
      ref.value.value = 300
      _ = consume ref
    }
    expectEqual(box.value.value, 300)
  }

  func test_leak_read() {
    let box = UniqueBox<Int>(88)
    let ref = box.leak()
    expectEqual(ref.value, 88)
  }

  func test_leak_write() {
    let box = UniqueBox<Int>(0)
    var ref = box.leak()
    ref.value = 77
    expectEqual(ref.value, 77)
  }

  func test_leak_noncopyable() {
    let box = UniqueBox<NoncopyablePayload>(NoncopyablePayload(1))
    var ref = box.leak()
    expectEqual(ref.value.value, 1)
    ref.value.value = 9
    expectEqual(ref.value.value, 9)
  }
#endif
}
#endif
