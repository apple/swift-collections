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

#if compiler(>=6.3) && UnstableContainersPreview
final class MutableRefTests: CollectionTestCase {
  struct NoncopyablePayload: ~Copyable {
    var value: Int
    init(_ value: Int) { self.value = value }
  }

  func test_basic() {
    var x = 0
    var y = MutableRef(&x)

    var v = y.value
    XCTAssertEqual(v, 0)

    y.value += 10

    v = y.value
    XCTAssertEqual(v, 10)
    XCTAssertEqual(x, 10)
  }

  // MARK: init(_:) and value (read)

  func test_init_and_value_read_int() {
    var x = 42
    let ref = MutableRef(&x)
    expectEqual(ref.value, 42)
  }

  func test_init_and_value_read_string() {
    var s = "hello"
    let ref = MutableRef(&s)
    expectEqual(ref.value, "hello")
  }

  func test_init_and_value_read_noncopyable() {
    var payload = NoncopyablePayload(99)
    let ref = MutableRef(&payload)
    expectEqual(ref.value.value, 99)
  }

  // MARK: value (write)

  func test_value_write_int() {
    var x = 0
    var ref = MutableRef(&x)
    ref.value = 123
    expectEqual(ref.value, 123)
    expectEqual(x, 123)
  }

  func test_value_write_string() {
    var s = "before"
    var ref = MutableRef(&s)
    ref.value = "after"
    expectEqual(ref.value, "after")
    expectEqual(s, "after")
  }

  func test_value_write_noncopyable() {
    var payload = NoncopyablePayload(1)
    var ref = MutableRef(&payload)
    ref.value.value = 42
    expectEqual(ref.value.value, 42)
    expectEqual(payload.value, 42)
  }

  // MARK: value (in-place mutation)

  func test_value_inplace_mutation() {
    var x = 10
    var ref = MutableRef(&x)
    ref.value += 32
    expectEqual(ref.value, 42)
    expectEqual(x, 42)
  }

  func test_value_inplace_mutation_array() {
    var array = [1, 2, 3]
    var ref = MutableRef(&array)
    ref.value.append(4)
    expectEqual(ref.value, [1, 2, 3, 4])
    expectEqual(array, [1, 2, 3, 4])
  }

  // MARK: init(unsafeAddress:mutating:)

  func test_init_unsafeAddress_mutating() {
    var x = 789
    let pointer = unsafe withUnsafeMutablePointer(to: &x) { $0 }
    var ref = unsafe MutableRef(unsafeAddress: pointer, mutating: &x)
    expectEqual(ref.value, 789)
    ref.value = 111
    expectEqual(ref.value, 111)
  }

  // MARK: init(unsafeImmortalAddress:)

  func test_init_unsafeImmortalAddress() {
    var x = 555
    let pointer = unsafe withUnsafeMutablePointer(to: &x) { $0 }
    var ref = unsafe MutableRef(unsafeImmortalAddress: pointer)
    expectEqual(ref.value, 555)
    ref.value = 666
    expectEqual(ref.value, 666)
  }

  // MARK: Reference type identity

  func test_reference_type_identity() {
    let tracker = LifetimeTracker()
    var obj: LifetimeTracked<Int>? = tracker.instance(for: 7)
    let ref = MutableRef(&obj)
    expectNotNil(ref.value)
    expectEqual(ref.value!.payload, 7)
  }

  // MARK: Multiple writes through MutableRef

  func test_multiple_writes() {
    var x = 0
    var ref = MutableRef(&x)
    ref.value = 1
    expectEqual(ref.value, 1)
    ref.value = 2
    expectEqual(ref.value, 2)
    ref.value = 3
    expectEqual(ref.value, 3)
    expectEqual(x, 3)
  }

  // MARK: Optional.mutate()

  func test_optional_mutate_some() {
    var x: Int? = 77
    if var ref = x.mutate() {
      expectEqual(ref.value, 77)
      ref.value = 88
    } else {
      expectTrue(false, "Expected non-nil MutableRef from .some optional")
    }
    expectEqual(x, 88)
  }

  func test_optional_mutate_none() {
    var x: Int? = nil
    let ref = x.mutate()
    expectNil(ref)
  }

  func test_optional_mutate_noncopyable() {
    var x: NoncopyablePayload? = NoncopyablePayload(33)
    if var ref = x.mutate() {
      expectEqual(ref.value.value, 33)
      ref.value.value = 44
    } else {
      expectTrue(false, "Expected non-nil MutableRef from .some optional")
    }
    expectEqual(x!.value, 44)
  }

  // MARK: Optional.insert(_:)

  func test_optional_insert_into_nil() {
    var x: Int? = nil
    do {
      var ref = x.insert(42)
      expectEqual(ref.value, 42)
      ref.value = 99
    }
    expectEqual(x, 99)
  }

  func test_optional_insert_into_some() {
    var x: Int? = 10
    do {
      var ref = x.insert(20)
      expectEqual(ref.value, 20)
      ref.value = 30
    }
    expectEqual(x, 30)
  }

  func test_optional_insert_noncopyable() {
    var x: NoncopyablePayload? = nil
    do {
      var ref = x.insert(NoncopyablePayload(55))
      expectEqual(ref.value.value, 55)
      ref.value.value = 66
    }
    expectEqual(x!.value, 66)
  }

  // MARK: Deprecated API

  @available(*, deprecated)
  func test_subscript_deprecated_read() {
    var x = 11
    let ref = MutableRef(&x)
    expectEqual(ref[], 11)
  }

  @available(*, deprecated)
  func test_subscript_deprecated_write() {
    var x = 0
    var ref = MutableRef(&x)
    ref[] = 22
    expectEqual(ref[], 22)
    expectEqual(x, 22)
  }

  @available(*, deprecated)
  func test_Inout_typealias() {
    var x = 88
    var ref: Inout<Int> = Inout(&x)
    ref.value = 99
    expectEqual(ref.value, 99)
    expectEqual(x, 99)
  }

  @available(*, deprecated)
  func test_Target_typealias() {
    var x = 77
    let ref = MutableRef(&x)
    let v: MutableRef<Int>.Target = ref.value
    expectEqual(v, 77)
  }
}
#endif
