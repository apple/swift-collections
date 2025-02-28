//===--- SpanTests.swift --------------------------------------------------===//
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
final class SpanTests: XCTestCase {

  func testInitWithOrdinaryElement() {
    let capacity = 4
    var s = (0..<capacity).map({ "\(#file)+\(#function)--\($0)" })
    s.withUnsafeBufferPointer {
      var span = Span(_unsafeElements: $0)
      XCTAssertEqual(span.count, capacity)

      let pointer = $0.baseAddress!
      span = Span(_unsafeStart: pointer, count: $0.count)
      XCTAssertEqual(span.count, capacity)
    }

    s.withUnsafeMutableBufferPointer {
      var span = Span(_unsafeElements: $0)
      XCTAssertEqual(span.count, capacity)

      let pointer: UnsafeMutablePointer = $0.baseAddress!
      span = Span(_unsafeStart: pointer, count: $0.count)
      XCTAssertEqual(span.count, capacity)
    }
  }

  func testInitWithBitwiseCopyableElement() {
    let capacity = 4
    var a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      var span = Span(_unsafeElements: $0)
      XCTAssertEqual(span.count, capacity)

      let pointer = $0.baseAddress!
      span = Span(_unsafeStart: pointer, count: $0.count)
      XCTAssertEqual(span.count, capacity)
    }

    a.withUnsafeMutableBufferPointer {
      var span = Span(_unsafeElements: $0)
      XCTAssertEqual(span.count, capacity)

      let pointer: UnsafeMutablePointer = $0.baseAddress!
      span = Span(_unsafeStart: pointer, count: $0.count)
      XCTAssertEqual(span.count, capacity)
    }

    a.withUnsafeBytes {
      let b = Span<UInt>(_unsafeBytes: $0)
      XCTAssertEqual(b.count, capacity)

      let r = Span<Int8>(_unsafeBytes: $0)
      XCTAssertEqual(r.count, capacity*MemoryLayout<Int>.stride)

      let p = $0.baseAddress!
      let span = Span<Int>(
        _unsafeStart: p, byteCount: capacity*MemoryLayout<Int>.stride
      )
      XCTAssertEqual(span.count, capacity)
    }

    a.withUnsafeMutableBytes {
      let b = Span<UInt>(_unsafeBytes: $0)
      XCTAssertEqual(b.count, capacity)

      let p = $0.baseAddress!
      let span = Span<Int>(
        _unsafeStart: p, byteCount: capacity*MemoryLayout<Int>.stride
      )
      XCTAssertEqual(span.count, capacity)
    }
  }

  func testIsEmpty() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)
      XCTAssertFalse(span.isEmpty)

      let emptyBuffer = UnsafeBufferPointer(rebasing: $0.dropFirst(capacity))
      let empty = Span(_unsafeElements: emptyBuffer)
      XCTAssertTrue(empty.isEmpty)
    }
  }

  func testRawSpanFromSpan() {
    let count = 4
    let array = Array(0..<count)
    array.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)
      let raw  = RawSpan(_elements: span)
      XCTAssertEqual(raw.byteCount, span.count*MemoryLayout<Int>.stride)
    }
  }

  func testSpanIndices() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)
      XCTAssertEqual(span.count, span.indices.count)

      var i = 0
      for j in span.indices {
        XCTAssertEqual(i, j)
        i += 1
      }
    }
  }

  func testElementsEqual() {
    let capacity = 4
    let a = Array<Int>(unsafeUninitializedCapacity: capacity) {
      for i in $0.indices {
        $0.initializeElement(at: i, to: .random(in: 0..<10))
      }
      $1 = $0.count
    }
    a.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)

      XCTAssertEqual(span._elementsEqual(span._extracting(first: 1)), false)
      XCTAssertEqual(span._extracting(0..<0)._elementsEqual(span._extracting(last: 0)), true)
      XCTAssertEqual(span._elementsEqual(span), true)
      XCTAssertEqual(span._extracting(0..<3)._elementsEqual(span._extracting(last: 3)), false)

      let copy = span.withUnsafeBufferPointer(Array.init)
      copy.withUnsafeBufferPointer {
        let spanOfCopy = Span(_unsafeElements: $0)
        XCTAssertTrue(span._elementsEqual(spanOfCopy))
      }
    }
  }

  func testElementsEqualCollection() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)

      XCTAssertEqual(span._elementsEqual(a), true)
      XCTAssertEqual(span._extracting(0..<0)._elementsEqual([]), true)
      XCTAssertEqual(span._elementsEqual(a.dropLast()), false)
    }
  }

  func testElementsEqualSequence() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)

      let s = AnySequence(a)
      XCTAssertEqual(span._elementsEqual(s), true)
      XCTAssertEqual(span._extracting(0..<(capacity-1))._elementsEqual(s), false)
      XCTAssertEqual(span._elementsEqual(s.dropFirst()), false)
    }
  }

  func testElementSubscript() {
    let capacity = 4
    let a = (0..<capacity).map(String.init)
    a.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)
      XCTAssertEqual(span[3], String(3))
    }
  }

  func testElementSubscriptBitwiseCopyable() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)
      XCTAssertEqual(span[3], 3)
    }
  }

  func testRangeOfIndicesSubscriptBitwiseCopyable() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let v = Span(_unsafeElements: $0)
      XCTAssertTrue(v._elementsEqual(v._extracting(0..<v.count)))
      XCTAssertTrue(v._elementsEqual(v._extracting(0...)))
      XCTAssertTrue(v._elementsEqual(v._extracting(..<v.count)))
      XCTAssertTrue(v._elementsEqual(v._extracting(...)))
    }
  }

  func testExtracting() {
    let capacity = 4
    let b = (0..<capacity).map(String.init)
    b.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)
      let sub1 = span._extracting(0..<2)
      let sub2 = span._extracting(..<2)
      let sub3 = span._extracting(...)
      let sub4 = span._extracting(2...)
      XCTAssertTrue(sub1._elementsEqual(sub2))
      XCTAssertTrue(sub3._elementsEqual(span))
      XCTAssertFalse(sub4._elementsEqual(sub3))
    }
  }

  func testExtractingUnchecked() {
    let capacity = 32
    let b = (0..<capacity).map(String.init)
    b.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)
      let prefix = span._extracting(0..<8)
      let beyond = prefix._extracting(unchecked: 16...23)
      XCTAssertEqual(beyond.count, 8)
      XCTAssertEqual(beyond[0], "16")
    }
  }

  func testPrefix() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(_unsafeElements: $0)
      XCTAssertEqual(span.count, capacity)
      XCTAssertEqual(span._extracting(first: 1)[0], 0)
      XCTAssertEqual(span._extracting(first: capacity)[capacity-1], capacity-1)
      XCTAssertEqual(span._extracting(droppingLast: capacity).count, 0)
      XCTAssertEqual(span._extracting(droppingLast: 1)[capacity-2], capacity-2)
    }

    do {
      let b = UnsafeBufferPointer<Int>(start: nil, count: 0)
      let span = Span(_unsafeElements: b)
      XCTAssertEqual(span.count, b.count)
      XCTAssertEqual(span._extracting(first: 1).count, b.count)
      XCTAssertEqual(span._extracting(droppingLast: 1).count, b.count)
    }
  }

  func testSuffix() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span<Int>(_unsafeElements: $0)
      XCTAssertEqual(span.count, capacity)
      XCTAssertEqual(span._extracting(last: capacity)[0], 0)
      XCTAssertEqual(span._extracting(last: capacity-1)[0], 1)
      XCTAssertEqual(span._extracting(last: 1)[0], capacity-1)
      XCTAssertEqual(span._extracting(droppingFirst: capacity).count, 0)
      XCTAssertEqual(span._extracting(droppingFirst: 1)[0], 1)
    }

    do {
      let b = UnsafeBufferPointer<Int>(start: nil, count: 0)
      let span = Span(_unsafeElements: b)
      XCTAssertEqual(span.count, b.count)
      XCTAssertEqual(span._extracting(last: 1).count, b.count)
      XCTAssertEqual(span._extracting(droppingFirst: 1).count, b.count)
    }
  }

  public func testWithUnsafeBuffer() {
    let capacity: UInt8 = 64
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      ub in
      let span = Span(_unsafeElements: ub)
      span.withUnsafeBufferPointer {
        let i = Int.random(in: 0..<$0.count)
        XCTAssertEqual($0[i], ub[i])
      }

      let emptyBuffer = UnsafeBufferPointer(rebasing: ub[0..<0])
      XCTAssertEqual(emptyBuffer.baseAddress, ub.baseAddress)

      let emptySpan = Span(_unsafeElements: emptyBuffer)
      emptySpan.withUnsafeBufferPointer {
        XCTAssertNil($0.baseAddress)
      }
    }
  }

  public func testWithUnsafeBytes() {
    let capacity: UInt8 = 64
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      ub in
      let span = Span(_unsafeElements: ub)

      span.withUnsafeBytes {
        let i = Int.random(in: $0.indices)
        XCTAssertEqual($0.load(fromByteOffset: i, as: UInt8.self), ub[i])
      }

      let emptyBuffer = UnsafeBufferPointer(rebasing: ub[0..<0])
      XCTAssertEqual(emptyBuffer.baseAddress, ub.baseAddress)

      let emptySpan = Span(_unsafeElements: emptyBuffer)
      emptySpan.withUnsafeBytes {
        XCTAssertNil($0.baseAddress)
      }
    }
  }

  func testIdentity() {
    let b = UnsafeMutableBufferPointer<Int>.allocate(capacity: 8)
    _ = b.initialize(fromContentsOf: 0..<8)
    defer { b.deallocate() }

    let span = Span(_unsafeElements: b)
    let pre = span._extracting(first: 6)
    let suf = span._extracting(last: 6)

    XCTAssertFalse(
      pre.isIdentical(to: suf)
    )
    XCTAssertFalse(
      pre.isIdentical(to: span)
    )
    XCTAssertTrue(
      pre._extracting(last: 4).isIdentical(to: suf._extracting(first: 4))
    )
  }

  func testIndicesOf() {
    let b = UnsafeMutableBufferPointer<Int>.allocate(capacity: 8)
    _ = b.initialize(fromContentsOf: 0..<8)
    defer { b.deallocate() }

    let span = Span(_unsafeElements: b)
    let subSpan1 = span._extracting(first: 6)
    let subSpan2 = span._extracting(last: 6)
    let emptySpan = span._extracting(first: 0)
/*  This isn't relevant until we can support unaligned spans
    let unalignedSpan = RawSpan(_unsafeSpan: span)
                          ._extracting(droppingFirst: 6)
                          ._extracting(droppingLast: 2)
                          .unsafeView(as: Int.self)
*/
    let nilBuffer = UnsafeBufferPointer<Int>(start: nil, count: 0)
    let nilSpan = Span(_unsafeElements: nilBuffer)

    var bounds: Range<Int>?
    bounds = span.indices(of: subSpan1)
    XCTAssertEqual(bounds, span.indices.prefix(6))
    bounds = span.indices(of: subSpan2)
    XCTAssertEqual(bounds, span.indices.suffix(6))
    bounds = subSpan2.indices(of: subSpan1)
    XCTAssertNil(bounds)
    bounds = subSpan1.indices(of: subSpan2)
    XCTAssertNil(bounds)
    bounds = subSpan2.indices(of: span)
    XCTAssertNil(bounds)
    bounds = nilSpan.indices(of: emptySpan)
    XCTAssertNil(bounds)
    bounds = span.indices(of: nilSpan)
    XCTAssertNil(bounds)
    bounds = nilSpan.indices(of: nilSpan)
    XCTAssertEqual(bounds, 0..<0)
  }

//  func testSpanIterator() {
//    class C {
//      let id: Int
//      init(id: Int) { self.id = id }
//    }
//
//    let b = UnsafeMutableBufferPointer<C>.allocate(capacity: 8)
//    _ = b.initialize(fromContentsOf: (0..<8).map(C.init(id:)))
//    defer {
//      b.deinitialize()
//      b.deallocate()
//    }
//
//    let span = Span(_unsafeElements: b)
//    var iterator = Span.Iterator(from: span)
//    var i = 0
//    while let c = iterator.next() {
//      XCTAssertEqual(i, c.id)
//      i += 1
//    }
//  }

  func testTypeErasedSpanOfBitwiseCopyable() {
    let b = UnsafeMutableRawBufferPointer.allocate(byteCount: 64, alignment: 8)
    defer { b.deallocate() }
    let initialized = b.initializeMemory(as: UInt8.self, fromContentsOf: 0..<64)
    XCTAssertEqual(initialized.count, 64)
    defer { initialized.deinitialize() }

    func test<T>(_ span: Span<T>) -> T {
      span[0]
    }

    // let span = Span<Int32>(_unsafeBytes: b.dropFirst().dropLast(7))

    let suffix = b.dropFirst(4)
    let span = Span<Int32>(_unsafeBytes: suffix)
    let first = test(span)
    XCTAssertEqual(first, 0x07060504)
  }
}
