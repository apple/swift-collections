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

#if compiler(>=6.4) && UnstableContainersPreview
import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import InternalCollectionsUtilities
import _CollectionsTestSupport
import ContainersPreview
#endif

@available(SwiftStdlib 6.4, *)
final class RefTests: CollectionTestCase {
  struct NoncopyablePayload: ~Copyable {
    var value: Int
    init(_ value: Int) { self.value = value }
  }

  // MARK: init(_:) and value

  @available(SwiftStdlib 6.4, *)
  func test_init_and_value_int() {
    let x = 42
    let ref = Ref(x)
    expectEqual(ref.value, 42)
  }

  @available(SwiftStdlib 6.4, *)
  func test_init_and_value_string() {
    let s = "hello"
    let ref = Ref(s)
    expectEqual(ref.value, "hello")
  }

  @available(SwiftStdlib 6.4, *)
  func test_init_and_value_noncopyable() {
    let payload = NoncopyablePayload(99)
    let ref = Ref(payload)
    expectEqual(ref.value.value, 99)
  }

  @available(SwiftStdlib 6.4, *)
  func test_value_reflects_original() {
    let array = [1, 2, 3]
    let ref = Ref(array)
    expectEqual(ref.value, [1, 2, 3])
  }

  @available(SwiftStdlib 6.4, *)
  func test_value_reference_type() {
    let tracker = LifetimeTracker()
    let obj = tracker.instance(for: 7)
    let ref = Ref(obj)
    expectTrue(ref.value === obj)
    expectEqual(ref.value.payload, 7)
  }

  // MARK: init(unsafeAddress:borrowing:)

  @available(SwiftStdlib 6.4, *)
  func test_init_unsafeAddress_borrowing() {
    let x = 123
    withUnsafePointer(to: x) { pointer in
      let ref = Ref(unsafeAddress: pointer, borrowing: x)
      expectEqual(ref.value, 123)
    }
  }

  // MARK: Ref is Copyable

  @available(SwiftStdlib 6.4, *)
  func test_ref_is_copyable() {
    let x = 42
    let ref1 = Ref(x)
    let ref2 = ref1
    expectEqual(ref1.value, 42)
    expectEqual(ref2.value, 42)
  }

}
#endif
