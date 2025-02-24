//===--- OutputSpanTests.swift --------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import Span

@available(macOS 9999, *)
struct Allocation<T>: ~Copyable {
  let allocation: UnsafeMutablePointer<T>
  let capacity: Int
  var count: Int? = nil

  init(of count: Int = 1, _ t: T.Type) {
    precondition(count >= 0)
    capacity = count
    allocation = UnsafeMutablePointer<T>.allocate(capacity: capacity)
  }

  var isEmpty: Bool { (count ?? 0) == 0 }

  mutating func initialize<E>(
    _ body: (/* mutating */ inout OutputSpan<T>) throws(E) -> Void
  ) throws(E) {
    if count != nil { fatalError() }
    var outputBuffer = OutputSpan<T>(
      _initializing: allocation, capacity: capacity
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

  borrowing func withSpan<E, R: ~Copyable>(
    _ body: (borrowing Span<T>) throws(E) -> R
  ) throws(E) -> R {
    try body(Span(_unsafeStart: allocation, count: count ?? 0))
  }

  deinit {
    if let count {
      allocation.deinitialize(count: count)
    }
    allocation.deallocate()
  }
}

enum MyTestError: Error { case error }

@available(macOS 9999, *)
final class OutputSpanTests: XCTestCase {

  func testOutputBufferInitialization() {
    let c = 48
    let allocation = UnsafeMutablePointer<UInt8>.allocate(capacity: c)
    defer { allocation.deallocate() }

    let ob = OutputSpan(_initializing: allocation, capacity: c)
    let initialized = ob.relinquishBorrowedMemory()
    XCTAssertNotNil(initialized.baseAddress)
    XCTAssertEqual(initialized.count, 0)
  }

  func testInitializeBufferByAppendingElements() {
    var a = Allocation(of: 48, Int.self)
    let c = 10
    a.initialize {
      for i in 0...c {
        $0.append(i)
      }
      let oops = $0.deinitializeLastElement()
      XCTAssertEqual(oops, c)
    }
    a.withSpan {
      XCTAssertEqual($0.count, c)
      XCTAssert($0._elementsEqual(0..<c))
    }
  }

  func testInitializeBufferByAppendingRepeatedElements() {
    var a = Allocation(of: 48, Int.self)
    let c = 10
    a.initialize {
      $0.append(repeating: c, count: c)
      let oops = $0.deinitializeLastElement()
      XCTAssertEqual(oops, c)
      XCTAssertEqual($0.count, c-1)
    }
    a.withSpan { span in
      XCTAssertEqual(span.count, c-1)
      XCTAssert(span._elementsEqual(Array(repeating: c, count: c-1)))
    }
  }

  func testInitializeBufferFromSequence() {
    var a = Allocation(of: 48, Int.self)
    a.initialize {
      var it = $0.append(from: 0..<18)
      XCTAssertNil(it.next())
    }
    a.withSpan { span in
      XCTAssertEqual(span.count, 18)
      XCTAssert(span._elementsEqual(0..<18))
    }
  }

  func testInitializeBufferFromCollectionNotContiguous() {
    var a = Allocation(of: 48, Int.self)
    let c = 24
    a.initialize {
      $0.append(fromContentsOf: 0..<c)

      let span = $0.span
      XCTAssertEqual(span.count, c)
      XCTAssert(span._elementsEqual(0..<c))
    }
  }

  func testInitializeBufferFromContiguousCollection() {
    var a = Allocation(of: 48, Int.self)
    let c = 24
    a.initialize {
      $0.append(fromContentsOf: Array(0..<c))

      let prefix = $0.span
      XCTAssertEqual(prefix.count, c)
      XCTAssert(prefix._elementsEqual(0..<c))
    }
    a.withSpan { span in
      XCTAssertEqual(span.count, c)
      XCTAssert(span._elementsEqual(0..<c))
    }
  }

  func testInitializeBufferFromSpan() {
    var a = Allocation(of: 48, Int.self)
    let c = 24
    a.initialize {
      let array = Array(0..<c)
      #if false
      array.withUnsafeBufferPointer {
        // let storage = Span(_unsafeElements: $0)
        let storage = Span<Int>(_unsafeElements: .init(start: nil, count: 0))
        $0.append(fromContentsOf: storage)
      }
      #else
      $0.append(fromContentsOf: array)
      #endif
    }
    a.withSpan { span in
      XCTAssertEqual(span.count, c)
      XCTAssert(span._elementsEqual(0..<c))
    }
  }

  func testInitializeBufferFromEmptyContiguousCollection() {
    var a = Allocation(of: 48, Int.self)
    a.initialize {
      $0.append(fromContentsOf: [])
    }
    a.withSpan { span in
      XCTAssertEqual(span.count, 0)
    }
    XCTAssertTrue(a.isEmpty)
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
    XCTAssertFalse(a.isEmpty)
    a.withSpan {
      XCTAssertEqual($0.count, c)
    }
  }

  func testDeinitializeBuffer() throws {
    var a = Allocation(of: 48, Int.self)
    do {
      try a.initialize {
        $0.append(0)
        $0.append(1)
        XCTAssertTrue($0.count > 0)
        throw MyTestError.error
      }
    }
    catch MyTestError.error {
      XCTAssertEqual(a.isEmpty, true)
    }
  }

  func testMutateOutputSpan() throws {
    let b = UnsafeMutableBufferPointer<Int>.allocate(capacity: 10)
    defer { b.deallocate() }

    var span = OutputSpan(_initializing: b)
    XCTAssertEqual(span.count, 0)
    span.append(fromContentsOf: 1...9)
    XCTAssertEqual(span.count, 9)

    var mutable = span.mutableSpan
//    span.append(20) // exclusivity violation
    for i in 0..<mutable.count {
      mutable[i] *= 2
    }

    span.append(20)

    let r = span.relinquishBorrowedMemory()
    XCTAssert(r.elementsEqual((0..<10).map({2*(1+$0)})))
    r.deinitialize()
  }
}
