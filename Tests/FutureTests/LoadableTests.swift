//===--- LoadableTests.swift ----------------------------------------------===//
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

final class LoadableTests: XCTestCase {

  func testLoadInt() {
    let b = UnsafeMutableRawBufferPointer.allocate(byteCount: 80, alignment: 8)
    defer { b.deallocate() }
    let span = RawSpan(unsafeBytes: .init(b), owner: b)

    let i0 = Int.random(in: 0..<999999)
    b.storeBytes(of: i0, as: Int.self)

    let i1 = span.load(as: Int.self)
    XCTAssertEqual(i1, i0)

    let o0 = Int.random(in: 1..<(80-MemoryLayout<Int>.size))
    b.storeBytes(of: i0, toByteOffset: o0, as: Int.self)

    let i2 = span.loadUnaligned(fromByteOffset: o0, as: Int.self)
    XCTAssertEqual(i2, i0)
  }

  func testViewBytes() {
    let b = UnsafeMutableBufferPointer<UInt>.allocate(capacity: 1)
    b.initializeElement(at: 0, to: UInt(0x03020100).littleEndian)
    let span = Span(unsafeElements: .init(b), owner: b).rawSpan
    let view = span.view(as: UInt8.self)
    for i in 0..<4 {
      XCTAssertEqual(i, Int(view[i]))
    }
  }

  func testLoadBool() {
    let b = UnsafeMutableRawBufferPointer.allocate(byteCount: 1, alignment: 1)
    defer { b.deallocate() }
    let span = RawSpan(unsafeBytes: .init(b), owner: b)

    b.storeBytes(of: true, as: Bool.self)
    XCTAssertEqual(span.load(as: Bool.self), true)

    b.storeBytes(of: false, as: Bool.self)
    XCTAssertEqual(span.load(as: Bool.self), false)

    for i in UInt8.min ... UInt8.max {
      b.storeBytes(of: i, as: UInt8.self)
      let r = span.load(as: Bool.self)
      XCTAssertNotEqual(r, i.isMultiple(of: 2))
    }
  }
}

enum Test: CaseIterable, Equatable, Hashable {
  case a, b, c, d
}

extension Test: Loadable {
  typealias RawBytes = UInt8

  init?(rawBytes: RawBytes) {
    for t in Test.allCases {
      if unsafeBitCast(t, to: RawBytes.self) == rawBytes {
        self = t
        return
      }
    }
    return nil
  }
}

extension LoadableTests {

  func testLoadLoadable() {
    let b = UnsafeMutableRawBufferPointer.allocate(byteCount: 8, alignment: 1)
    defer { b.deallocate() }
    let span = RawSpan(unsafeBytes: .init(b), owner: b)

    let i0 = Test.allCases.randomElement()!
    b.storeBytes(of: i0, as: Test.self)

    let i1 = span.load(as: Test.self)
    XCTAssertEqual(i1, i0)

    let o0 = Int.random(in: 1..<8)
    b.storeBytes(of: i0, toByteOffset: o0, as: Test.self)

    let i2 = span.loadUnaligned(fromByteOffset: o0, as: Test.self)
    XCTAssertEqual(i2, i0)
  }

  func testLoadTest() {
    XCTAssertEqual(
      MemoryLayout<Test>.size,
      MemoryLayout<Test.RawBytes>.size
    )

    var valid: Set<UInt8> = []
    var wrong: Set<UInt8> = []
    for i in UInt8.zero ... UInt8.max {
      let test = withUnsafePointer(to: i) {
        let span = RawSpan(unsafeStart: $0, byteCount: 1, owner: $0)
        return span.load(as: Test.self)
      }

      if let _ = test {
        valid.insert(i)
      } else {
        wrong.insert(i)
      }
    }

    XCTAssertEqual(valid.count, 4)
    XCTAssertEqual(valid.count + wrong.count, 256)
  }
}
