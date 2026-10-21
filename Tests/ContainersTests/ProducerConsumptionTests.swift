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

import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview
private enum TestFailure: Error {
  case closure
  case producer
}

private struct Token: ~Copyable {
  nonisolated(unsafe) static var created: [Int] = []
  nonisolated(unsafe) static var destroyed: [Int] = []

  let value: Int

  init(_ value: Int) {
    self.value = value
    unsafe Token.created.append(value)
  }

  deinit {
    unsafe Token.destroyed.append(value)
  }
}

@available(SwiftStdlib 6.4, *)
final class ProducerConsumptionTests: CollectionTestCase {
  func test_reduce_throwing() {
    withEvery("offset", in: [0, 2, 7, 8, 9, 10]) { offset in
      unsafe Token.created = []
      unsafe Token.destroyed = []
      _ = try? producer(state: 0) {
        (state: inout Int) throws(TestFailure) -> Token? in
        guard state < 10 else { return nil }
        defer { state += 1 }
        return Token(state)
      }
      .reduce(0) { count, token throws(TestFailure) in
        guard token.value != offset else { throw .closure }
        return count + 1
      }
      expectEqual(unsafe Token.destroyed.sorted(), unsafe Token.created)
    }
  }

  func test_reduce_into_throwing() {
    withEvery("offset", in: [0, 2, 7, 8, 9, 10]) { offset in
      unsafe Token.created = []
      unsafe Token.destroyed = []
      _ = try? producer(state: 0) {
        (state: inout Int) throws(TestFailure) -> Token? in
        guard state < 10 else { return nil }
        defer { state += 1 }
        return Token(state)
      }
      .reduce(into: 0) { count, token throws(TestFailure) in
        guard token.value != offset else { throw .closure }
        count += 1
      }
      expectEqual(unsafe Token.destroyed.sorted(), unsafe Token.created)
    }
  }

  func test_throwingConsumption_CustomProducer() {
    withEvery("count", in: [0, 1, 7, 8, 9, 16, 17, 30]) { count in
      checkThrowingConsumption(
        expectedContents: Array(0 ..< count), error: TestFailure.closure
      ) { tracker, body in
        body(CustomProducer<LifetimeTracked<Int>, TestFailure> {
          offset throws(TestFailure) in
          offset < count ? tracker.instance(for: offset) : nil
        })
      }
      checkThrowingConsumption(
        expectedContents: Array(0 ..< count),
        throwsAtEnd: true,
        error: TestFailure.closure
      ) { tracker, body in
        body(CustomProducer<LifetimeTracked<Int>, TestFailure> {
          offset throws(TestFailure) in
          guard offset < count else { throw .producer }
          return tracker.instance(for: offset)
        })
      }
    }
  }

  func test_throwingConsumption_UnfoldProducer() {
    withEvery("count", in: [0, 1, 7, 8, 9, 16, 17, 30]) { count in
      checkThrowingConsumption(
        expectedContents: Array(0 ..< count), error: TestFailure.closure
      ) { tracker, body in
        body(producer(state: 0) {
          (state: inout Int) throws(TestFailure) -> LifetimeTracked<Int>? in
          guard state < count else { return nil }
          defer { state += 1 }
          return tracker.instance(for: state)
        })
      }
      checkThrowingConsumption(
        expectedContents: Array(0 ..< count),
        throwsAtEnd: true,
        error: TestFailure.closure
      ) { tracker, body in
        body(producer(state: 0) {
          (state: inout Int) throws(TestFailure) -> LifetimeTracked<Int>? in
          guard state < count else { throw .producer }
          defer { state += 1 }
          return tracker.instance(for: state)
        })
      }
    }
  }

  func test_throwingConsumption_ConsumingMapProducer() {
    withEvery("count", in: [0, 1, 7, 8, 9, 16, 17, 30]) { count in
      let expected = (0 ..< count).map { 2 * $0 }
      checkThrowingConsumption(
        expectedContents: expected, error: TestFailure.closure
      ) { tracker, body in
        body(CustomProducer<LifetimeTracked<Int>, TestFailure> {
          offset throws(TestFailure) in
          offset < count ? tracker.instance(for: offset) : nil
        }
        .map { item throws(TestFailure) in
          tracker.instance(for: 2 * item.payload)
        })
      }
      checkThrowingConsumption(
        expectedContents: expected,
        throwsAtEnd: true,
        error: TestFailure.closure
      ) { tracker, body in
        body(CustomProducer<LifetimeTracked<Int>, TestFailure> {
          offset throws(TestFailure) in
          guard offset < count else { throw .producer }
          return tracker.instance(for: offset)
        }
        .map { item throws(TestFailure) in
          tracker.instance(for: 2 * item.payload)
        })
      }
      checkThrowingConsumption(
        expectedContents: expected,
        throwsAtEnd: true,
        error: TestFailure.closure
      ) { tracker, body in
        body(CustomProducer<LifetimeTracked<Int>, TestFailure> {
          offset throws(TestFailure) in
          offset <= count ? tracker.instance(for: offset) : nil
        }
        .map { item throws(TestFailure) in
          guard item.payload < count else { throw .producer }
          return tracker.instance(for: 2 * item.payload)
        })
      }
    }
  }

  func test_throwingConsumption_ConsumingFilterProducer() {
    withEvery("count", in: [0, 1, 7, 8, 9, 16, 17, 30]) { count in
      let expected = (0 ..< count).filter { $0 % 16 < 8 }
      checkThrowingConsumption(
        expectedContents: expected, error: TestFailure.closure
      ) { tracker, body in
        body(CustomProducer<LifetimeTracked<Int>, TestFailure> {
          offset throws(TestFailure) in
          offset < count ? tracker.instance(for: offset) : nil
        }
        .filter { $0.payload % 16 < 8 })
      }
      checkThrowingConsumption(
        expectedContents: expected,
        throwsAtEnd: true,
        error: TestFailure.closure
      ) { tracker, body in
        body(CustomProducer<LifetimeTracked<Int>, TestFailure> {
          offset throws(TestFailure) in
          guard offset < count else { throw .producer }
          return tracker.instance(for: offset)
        }
        .filter { $0.payload % 16 < 8 })
      }
    }
  }
}
#endif
