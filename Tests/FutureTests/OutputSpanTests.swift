//===--- OutputSpanTests.swift --------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import Future

struct Allocation<T>: ~Copyable {
  let allocation: UnsafeMutablePointer<T>
  let capacity: Int
  var count: Int? = nil

  init(of count: Int = 1, _ t: T.Type) {
    precondition(count >= 0)
    capacity = count
    allocation = UnsafeMutablePointer<T>.allocate(capacity: capacity)
  }

  var isInitialized: Bool { count != nil }

  mutating func initialize(
    _ body: (/* mutating */ inout OutputSpan<T>) throws -> Void
  ) rethrows {
    if count != nil { fatalError() }
    var outputBuffer = OutputSpan<T>(
      initializing: allocation, capacity: capacity, owner: self
    )
    do {
      try body(&outputBuffer)
      let initialized = outputBuffer.relinquishBorrowedMemory()
      assert(initialized.baseAddress == allocation)
      count = initialized.count
    }
    catch {
      outputBuffer.deinitialize()
      let empty = outputBuffer.relinquishBorrowedMemory()
      assert(empty.baseAddress == allocation)
      assert(empty.count == 0)
      throw error
    }
  }

  borrowing func examine<E, R>(
    _ body: (borrowing Span<T>) throws(E) -> R
  ) throws(E) -> R {
    try body(initializedPrefix)
  }

  var initializedPrefix: Span<T> {
    Span(_unsafeStart: allocation, count: count ?? 0)
  }

//  mutating func mutate<R>(
//    _ body: (/* mutating */ inout MutableBufferView<T>) -> R
//  ) -> R {
//    guard let count else { fatalError() }
//    var mutable = MutableBufferView<T>(
//      baseAddress: allocation, count: count, dependsOn: /*self*/ allocation
//    )
//    return body(&mutable)
//  }

  deinit {
    if let count {
      allocation.deinitialize(count: count)
    }
    allocation.deallocate()
  }
}

enum MyTestError: Error { case error }

final class OutputBufferTests: XCTestCase {

  func testOutputBufferInitialization() {
    let c = 48
    let allocation = UnsafeMutablePointer<UInt8>.allocate(capacity: c)
    defer { allocation.deallocate() }

    let ob = OutputSpan(initializing: allocation, capacity: c, owner: allocation)
    let initialized = ob.relinquishBorrowedMemory()
    XCTAssertNotNil(initialized.baseAddress)
    XCTAssertEqual(initialized.count, 0)
  }

  func testInitializeBufferByAppendingElements() {
    var a = Allocation(of: 48, Int.self)
    let c = 10
    a.initialize {
      for i in 0...c {
        $0.appendElement(i)
      }
      let oops = $0.deinitializeLastElement()
      XCTAssertEqual(oops, c)
    }
    a.examine {
      XCTAssertEqual($0.count, c)
      XCTAssert($0._elementsEqual(0..<c))
    }
    let span = a.initializedPrefix
    XCTAssertEqual(span.count, c)
    XCTAssert(span._elementsEqual(0..<c))
  }

  func testInitializeBufferFromSequence() {
    var a = Allocation(of: 48, Int.self)
    a.initialize {
      var it = $0.append(from: 0..<18)
      XCTAssertNil(it.next())
    }
    let span = a.initializedPrefix
    XCTAssertEqual(span.count, 18)
    XCTAssert(span._elementsEqual(0..<18))
  }

  func testInitializeBufferFromCollectionNotContiguous() {
    var a = Allocation(of: 48, Int.self)
    let c = 24
    a.initialize {
      $0.append(fromContentsOf: 0..<c)

      let span = $0.initializedPrefix
      XCTAssertEqual(span.count, c)
      XCTAssert(span._elementsEqual(0..<c))
    }
  }

  func testInitializeBufferFromContiguousCollection() {
    var a = Allocation(of: 48, Int.self)
    let c = 24
    a.initialize {
      $0.append(fromContentsOf: Array(0..<c))

      let prefix = $0.initializedPrefix
      XCTAssertEqual(prefix.count, c)
      XCTAssert(prefix._elementsEqual(0..<c))
    }
    let span = a.initializedPrefix
    XCTAssertEqual(span.count, c)
    XCTAssert(span._elementsEqual(0..<c))
  }

  func testInitializeBufferFromSpan() {
    var a = Allocation(of: 48, Int.self)
    let c = 24
    a.initialize {
      let array = Array(0..<c)
      #if false
//      let storage = array.storage
      let storage = Span<Int>(_unsafeElements: UnsafeBufferPointer<Int>(start: nil, count: 0))
      $0.append(fromContentsOf: storage)
      #else
      $0.append(fromContentsOf: array)
      #endif
    }

    let span = a.initializedPrefix
    XCTAssertEqual(span.count, c)
    XCTAssert(span._elementsEqual(0..<c))
  }

  func testInitializeBufferFromEmptyContiguousCollection() {
    var a = Allocation(of: 48, Int.self)
    a.initialize {
      $0.append(fromContentsOf: [])
    }
    XCTAssertTrue(a.isInitialized)
    XCTAssertTrue(a.initializedPrefix.isEmpty)
  }

  func testMoveAppend() {
    class I {
      let i: Int
      init(_ i: Int) {
        self.i = i
      }
    }
    let c = 20
    let b = UnsafeMutableBufferPointer<I>.allocate(capacity: c)
    for i in 0..<c {
      b.initializeElement(at: i, to: I(i))
    }
    var a = Allocation(of: 48, I.self)
    a.initialize {
      $0.moveAppend(fromContentsOf: b)
      $0.moveAppend(fromContentsOf: b[c..<c])
    }
    XCTAssertTrue(a.isInitialized)
    XCTAssertEqual(a.initializedPrefix.count, c)
  }

  func testDeinitializeBuffer() throws {
    var a = Allocation(of: 48, Int.self)
    do {
      try a.initialize {
        $0.appendElement(0)
        $0.appendElement(1)
        XCTAssertTrue($0.initialized > 0)
        throw MyTestError.error
      }
    }
    catch MyTestError.error {
      XCTAssertEqual(a.isInitialized, false)
    }
  }
}
