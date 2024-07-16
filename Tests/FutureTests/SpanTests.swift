//===--- SpanTests.swift --------------------------------------------------===//
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

final class SpanTests: XCTestCase {

  func testOptionalStorage() {
//    XCTAssertEqual(
//      MemoryLayout<Span<UInt8>>.size, MemoryLayout<Span<UInt8>?>.size
//    )
//    XCTAssertEqual(
//      MemoryLayout<Span<UInt8>>.stride, MemoryLayout<Span<UInt8>?>.stride
//    )
//    XCTAssertEqual(
//      MemoryLayout<Span<UInt8>>.alignment, MemoryLayout<Span<UInt8>?>.alignment
//    )
  }

  func testInitWithOrdinaryElement() {
    let capacity = 4
    var s = (0..<capacity).map({ "\(#file)+\(#function)--\($0)" })
    s.withUnsafeBufferPointer {
      var span = Span(unsafeElements: $0, owner: s)
      XCTAssertEqual(span.count, capacity)

      span = Span(unsafeStart: $0.baseAddress!, count: $0.count, owner: s)
      XCTAssertEqual(span.count, capacity)
    }

    s.withUnsafeMutableBufferPointer {
      var span = Span(unsafeElements: $0, owner: $0)
      XCTAssertEqual(span.count, capacity)

      let pointer: UnsafeMutablePointer = $0.baseAddress!
      span = Span(unsafeStart: pointer, count: $0.count, owner: $0)
      XCTAssertEqual(span.count, capacity)
    }
  }

  func testInitWithBitwiseCopyableElement() {
    let capacity = 4
    var a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      var span = Span(unsafeElements: $0, owner: a)
      XCTAssertEqual(span.count, capacity)

      span = Span(unsafeStart: $0.baseAddress!, count: $0.count, owner: a)
      XCTAssertEqual(span.count, capacity)
    }

    a.withUnsafeMutableBufferPointer {
      var span = Span(unsafeElements: $0, owner: $0)
      XCTAssertEqual(span.count, capacity)

      let pointer: UnsafeMutablePointer = $0.baseAddress!
      span = Span(unsafeStart: pointer, count: $0.count, owner: $0)
      XCTAssertEqual(span.count, capacity)
    }

    a.withUnsafeBytes {
      let b = Span<UInt>(unsafeBytes: $0, owner: $0)
      XCTAssertEqual(b.count, capacity)

      let r = Span<Int8>(unsafeBytes: $0, owner: $0)
      XCTAssertEqual(r.count, capacity*MemoryLayout<Int>.stride)

      let p = Span<Int>(
        unsafeStart: $0.baseAddress!,
        byteCount: capacity*MemoryLayout<Int>.stride,
        owner: $0
      )
      XCTAssertEqual(p.count, capacity)
    }

    a.withUnsafeMutableBytes {
      let b = Span<UInt>(unsafeBytes: $0, owner: $0)
      XCTAssertEqual(b.count, capacity)

      let p = Span<Int>(
        unsafeStart: $0.baseAddress!,
        byteCount: capacity*MemoryLayout<Int>.stride,
        owner: $0
      )
      XCTAssertEqual(p.count, capacity)
    }
  }

  func testIsEmpty() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)
      XCTAssertFalse(span.isEmpty)

      let empty = Span(
        unsafeElements: .init(rebasing: $0.dropFirst(capacity)), owner: $0
      )
      XCTAssertTrue(empty.isEmpty)
    }
  }

  func testRawSpanFromSpan() {
    let count = 4
    let array = Array(0..<count)
    array.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)
      let raw  = span.rawSpan
      XCTAssertEqual(raw.byteCount, span.count*MemoryLayout<Int>.stride)
    }
  }

  func testSpanIndices() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)
      XCTAssertEqual(span.count, span._indices.count)

      var i = 0
      for j in span._indices {
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
      let span = Span(unsafeElements: $0, owner: $0)

      XCTAssertEqual(span._elementsEqual(span.extracting(first: 1)), false)
      XCTAssertEqual(span.extracting(0..<0)._elementsEqual(span.extracting(last: 0)), true)
      XCTAssertEqual(span._elementsEqual(span), true)
      XCTAssertEqual(span.extracting(0..<3)._elementsEqual(span.extracting(last: 3)), false)

      let copy = span.withUnsafeBufferPointer(Array.init)
      copy.withUnsafeBufferPointer {
        let spanOfCopy = Span(unsafeElements: $0, owner: $0)
        XCTAssertTrue(span._elementsEqual(spanOfCopy))
      }
    }
  }

  func testElementsEqualCollection() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)

      XCTAssertEqual(span._elementsEqual(a), true)
      XCTAssertEqual(span.extracting(0..<0)._elementsEqual([]), true)
      XCTAssertEqual(span._elementsEqual(a.dropLast()), false)
    }
  }

  func testElementsEqualSequence() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)

      let s = AnySequence(a)
      XCTAssertEqual(span._elementsEqual(s), true)
      XCTAssertEqual(span.extracting(0..<(capacity-1))._elementsEqual(s), false)
      XCTAssertEqual(span._elementsEqual(s.dropFirst()), false)
    }
  }

  func testRangeOfIndicesSubscript() {
    let capacity = 4
    let a = (0..<capacity).map(String.init)
    a.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)
      XCTAssertTrue(span._elementsEqual(span.extracting(0..<span.count)))
      XCTAssertTrue(span._elementsEqual(span.extracting(0...)))
      XCTAssertTrue(span._elementsEqual(span.extracting(uncheckedBounds: ..<span.count)))
      XCTAssertTrue(span._elementsEqual(span.extracting(...)))
    }
  }

  func testRangeOfIndicesSubscriptBitwiseCopyable() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let v = Span(unsafeElements: $0, owner: $0)
      XCTAssertTrue(v._elementsEqual(v.extracting(0..<v.count)))
      XCTAssertTrue(v._elementsEqual(v.extracting(0...)))
      XCTAssertTrue(v._elementsEqual(v.extracting(uncheckedBounds: ..<v.count)))
      XCTAssertTrue(v._elementsEqual(v.extracting(...)))
    }
  }

  func testOffsetSubscript() {
    let capacity = 4
    let a = (0..<capacity).map(String.init)
    a.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)
      XCTAssertEqual(span[3], String(3))
    }
  }

  func testOffsetSubscriptBitwiseCopyable() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)
      XCTAssertEqual(span[3], 3)
    }
  }

  func testRangeOfOffsetsSubscript() {
    let capacity = 4
    let a = (0..<capacity).map(String.init)
    a.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)
      XCTAssertTrue(span._elementsEqual(span.extracting(0..<capacity)))
      XCTAssertTrue(span._elementsEqual(span.extracting(0...)))
      XCTAssertTrue(span._elementsEqual(span.extracting(uncheckedBounds: ..<capacity)))
    }
  }

  func testFirstAndLast() {
    let r = Int.random(in: 0..<1000)
    let a = [r]
    a.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)
      XCTAssertEqual(span.first, r)
      XCTAssertEqual(span.last, r)

      let emptySpan = span.extracting(0..<0)
      XCTAssertEqual(emptySpan.first, nil)
      XCTAssertEqual(emptySpan.last, nil)
    }
  }

  func testPrefix() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span(unsafeElements: $0, owner: $0)
      XCTAssertEqual(span.count, capacity)
      XCTAssertEqual(span.extracting(first: 1).last, 0)
      XCTAssertEqual(span.extracting(first: capacity).last, capacity-1)
      XCTAssertEqual(span.extracting(droppingLast: capacity).last, nil)
      XCTAssertEqual(span.extracting(droppingLast: 1).last, capacity-2)
    }

    do {
      let b = UnsafeBufferPointer<Int>(start: nil, count: 0)
      let span = Span(unsafeElements: b, owner: b)
      XCTAssertEqual(span.count, b.count)
      XCTAssertEqual(span.extracting(first: 1).count, b.count)
      XCTAssertEqual(span.extracting(droppingLast: 1).count, b.count)
    }
  }

  func testSuffix() {
    let capacity = 4
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      let span = Span<Int>(unsafeElements: $0, owner: $0)
      XCTAssertEqual(span.count, capacity)
      XCTAssertEqual(span.extracting(last: capacity).first, 0)
      XCTAssertEqual(span.extracting(last: capacity-1).first, 1)
      XCTAssertEqual(span.extracting(last: 1).first, capacity-1)
      XCTAssertEqual(span.extracting(droppingFirst: capacity).first, nil)
      XCTAssertEqual(span.extracting(droppingFirst: 1).first, 1)
    }

    do {
      let b = UnsafeBufferPointer<Int>(start: nil, count: 0)
      let span = Span(unsafeElements: b, owner: b)
      XCTAssertEqual(span.count, b.count)
      XCTAssertEqual(span.extracting(last: 1).count, b.count)
      XCTAssertEqual(span.extracting(droppingFirst: 1).count, b.count)
    }  }

  public func testWithUnsafeBytes() {
    let capacity: UInt8 = 64
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      ub in
      let span = Span(unsafeElements: ub, owner: ub)

      span.withUnsafeBytes {
        let i = Int.random(in: 0..<$0.count)
        XCTAssertEqual($0.load(fromByteOffset: i, as: UInt8.self), ub[i])
      }

      span.withUnsafeBufferPointer {
        let i = Int.random(in: 0..<$0.count)
        XCTAssertEqual($0[i], ub[i])
      }
    }
  }

  public func testWithUnsafeBuffer() {
    let capacity: UInt8 = 64
    let a = Array(0..<capacity)
    a.withUnsafeBufferPointer {
      ub in
      let span = Span(unsafeElements: ub, owner: ub)

      span.withUnsafeBytes {
        let i = Int.random(in: 0..<$0.count)
        XCTAssertEqual($0[i], ub[i])
      }

      span.withUnsafeBufferPointer {
        let i = Int.random(in: 0..<$0.count)
        XCTAssertEqual($0[i], ub[i])
      }

      let emptyBuffer = UnsafeBufferPointer(rebasing: ub[0..<0])
      XCTAssertEqual(emptyBuffer.baseAddress, ub.baseAddress)

      let empty = Span(unsafeElements: emptyBuffer, owner: ub)
      empty.withUnsafeBufferPointer {
        XCTAssertNil($0.baseAddress)
      }
    }
  }

  public func testBorrowing1() {
    let capacity = 8
    let a = Array(0..<capacity)
    var span = a.storage
    let prefix = span.extracting(0..<2)
    span = span.extracting(1...)
    XCTAssertEqual(span.count, capacity-1)
    XCTAssertEqual(prefix.count, 2)
  }

  public func testBorrowing2() {
    let capacity = 8
    let a = Array(0..<capacity)
    var span = a.storage
    let prefix = span.extracting(0..<2)
    span = span.extracting(1...)
    XCTAssertEqual(span.count, capacity-1)
    XCTAssertEqual(prefix.count, 2)
  }

  func testContainment() {
    let b = UnsafeMutableBufferPointer<Int>.allocate(capacity: 8)
    _ = b.initialize(fromContentsOf: 0..<8)
    defer { b.deallocate() }

    let span = Span(unsafeElements: .init(b), owner: b)
    let subSpan = span.extracting(last: 2)
    let emptySpan = span.extracting(first: 0)
    let fakeSpan = Span(
      unsafeStart: b.baseAddress!.advanced(by: 8), count: 8, owner: b
    )
    let nilSpan = Span<Int>(
      unsafeElements: UnsafeBufferPointer(start: nil, count: 0), owner: b
    )

    XCTAssertTrue(span.contains(subSpan))
    XCTAssertFalse(subSpan.contains(span))
    XCTAssertTrue(span.contains(emptySpan))
    XCTAssertFalse(emptySpan.contains(span))
    XCTAssertFalse(span.contains(fakeSpan))
    XCTAssertFalse(fakeSpan.contains(span))
    XCTAssertTrue(span.contains(nilSpan))
    XCTAssertTrue(fakeSpan.contains(nilSpan))
    XCTAssertTrue(nilSpan.contains(emptySpan))
  }

  func testOffsets() {
    let b = UnsafeMutableBufferPointer<Int>.allocate(capacity: 8)
    _ = b.initialize(fromContentsOf: 0..<8)
    defer { b.deallocate() }

    let span = Span(unsafeElements: .init(b), owner: b)
    let subSpan = span.extracting(last: 2)
    let emptySpan = span.extracting(first: 0)
    let nilSpan = Span<Int>(
      unsafeElements: UnsafeBufferPointer(start: nil, count: 0), owner: b
    )

    var bounds: Range<Int>
    bounds = span.offsets(of: subSpan)
    XCTAssertEqual(bounds, span._indices.suffix(2))
    bounds = span.offsets(of: emptySpan)
    XCTAssertEqual(bounds, span._indices.prefix(0))
    bounds = span.offsets(of: nilSpan)
    XCTAssertEqual(bounds, 0..<0)
    bounds = nilSpan.offsets(of: emptySpan)
    XCTAssertEqual(bounds, 0..<0)
  }
}
