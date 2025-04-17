//===--- MutableSpanTests.swift -------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import Future

#if false
@available(macOS 9999, *)
final class MutableRawSpanTests: XCTestCase {

  func testBasicInitializer() {
    var s = Array("\(#file)+\(#function)--\(Int.random(in: 1000...9999))".utf8)
    s.withUnsafeMutableBytes {
      let b = MutableRawSpan(_unsafeBytes: $0)
      XCTAssertEqual(b.byteCount, $0.count)
      XCTAssertFalse(b.isEmpty)
      XCTAssertEqual(b.byteOffsets, 0..<$0.count)
    }
  }

  func testIsEmpty() {
    var array = [0, 1, 2]
    array.withUnsafeMutableBufferPointer {
      var span = MutableRawSpan(_unsafeElements: $0)
      XCTAssertFalse(span.isEmpty)

      let e = $0.extracting(0..<0)
      span = MutableRawSpan(_unsafeElements: e)
      XCTAssertTrue(span.isEmpty)
    }
  }

  func testIndices() {
    let capacity = 4 as UInt8
    var a = Array(0..<capacity)
    a.withUnsafeMutableBytes {
      let view = MutableRawSpan(_unsafeBytes: $0)
      XCTAssertEqual(view.byteCount, view.byteOffsets.count)
      XCTAssert(view.byteOffsets.elementsEqual(0..<view.byteCount))
    }
  }

  public func testWithUnsafeBytes() {
    let capacity: UInt8 = 64
    var a = Array(0..<capacity)
    let i = Int.random(in: a.indices)
    a.withUnsafeMutableBytes {
      var view = MutableRawSpan(_unsafeBytes: $0)
      view.withUnsafeBytes {
        XCTAssertEqual($0.load(fromByteOffset: i, as: UInt8.self), $0[i])
      }

      let empty = UnsafeMutableRawBufferPointer(start: $0.baseAddress, count: 0)
      view = MutableRawSpan(_unsafeBytes: empty)
      view.withUnsafeBytes {
        XCTAssertEqual($0.count, 0)
        XCTAssertNil($0.baseAddress)
      }
    }
  }

  public func testWithUnsafeMutableBytes() {
    let capacity: UInt8 = 16
    var a = Array(0..<capacity)
    let i = Int.random(in: a.indices)
    a.withUnsafeMutableBytes {
      var view = MutableRawSpan(_unsafeBytes: $0)
      let o = view.unsafeLoad(fromByteOffset: i, as: UInt8.self)
      view.withUnsafeMutableBytes {
        $0.storeBytes(of: UInt8(i+1), toByteOffset: i, as: UInt8.self)
      }
      let m = view.unsafeLoad(fromByteOffset: i, as: UInt8.self)
      XCTAssertEqual(m, o+1)

      let empty = UnsafeMutableRawBufferPointer(start: $0.baseAddress, count: 0)
      view = MutableRawSpan(_unsafeBytes: empty)
      view.withUnsafeMutableBytes {
        XCTAssertEqual($0.count, 0)
        XCTAssertNil($0.baseAddress)
      }
    }
    XCTAssertEqual(Int(a[i]), i+1)
  }

  func testBytesProperty() {
    var array = [0, 1, 2]
    array.withUnsafeMutableBufferPointer {
      let mutable = MutableRawSpan(_unsafeElements: $0)
      let immutable = mutable.bytes
      XCTAssertEqual(mutable.byteCount, immutable.byteCount)
    }
  }

  func testUnsafeView() {
    var array = [0, 1, 2]
    array.withUnsafeMutableBufferPointer {
      let mutable = MutableRawSpan(_unsafeElements: $0)
      let view = mutable._unsafeView(as: Int.self)
      XCTAssertEqual($0[1], view[1])
    }
  }

  func testUnsafeMutableView() {
    var array = [0, 1, 2]
    let value = Int.random(in: 0..<1000)
    array.withUnsafeMutableBufferPointer {
      var mutable = MutableRawSpan(_unsafeElements: $0)
      var view = mutable._unsafeMutableView(as: Int.self)
      view[1] = value
    }
    XCTAssertEqual(array[1], value)
  }

  func testLoad() {
    let capacity = 4
    var s = (0..<capacity).map({ "\(#file)+\(#function) #\($0)" })
    s.withUnsafeMutableBytes {
      let span = MutableRawSpan(_unsafeBytes: $0)
      let stride = MemoryLayout<String>.stride

      let s0 = span.unsafeLoad(as: String.self)
      XCTAssertEqual(s0.contains("0"), true)
      let s1 = span.unsafeLoad(fromByteOffset: stride, as: String.self)
      XCTAssertEqual(s1.contains("1"), true)
      let s2 = span.unsafeLoad(fromUncheckedByteOffset: 2*stride, as: String.self)
      XCTAssertEqual(s2.contains("2"), true)
    }
  }

  func testLoadUnaligned() {
    let capacity = 64
    var a = Array(0..<UInt8(capacity))
    a.withUnsafeMutableBytes {
      var span = MutableRawSpan(_unsafeBytes: $0)

      let suffix = span._extracting(droppingFirst: 2)
      let u0 = suffix.unsafeLoadUnaligned(as: UInt64.self)
      XCTAssertEqual(u0 & 0xff, 2)
      XCTAssertEqual(u0.byteSwapped & 0xff, 9)
      let u1 = span.unsafeLoadUnaligned(fromByteOffset: 6, as: UInt64.self)
      XCTAssertEqual(u1 & 0xff, 6)
      let u3 = span.unsafeLoadUnaligned(fromUncheckedByteOffset: 7, as: UInt32.self)
      XCTAssertEqual(u3 & 0xff, 7)
    }
  }

  func testStoreBytes() {
    let count = 4
    var a = Array(repeating: 0, count: count)
    a.withUnsafeMutableBytes {
      var span = MutableRawSpan(_unsafeBytes: $0)
      span.storeBytes(of: .max, as: UInt8.self)
      span.storeBytes(
        of: .max, toByteOffset: MemoryLayout<UInt>.stride/2, as: UInt.self
      )
    }
    XCTAssertEqual(a[0].littleEndian & 0xffff, 0xff)
    XCTAssertEqual(a[0].bigEndian & 0xffff, 0xffff)
  }

  public func testUpdateFromSequence() {
    let capacity = 8
    var a = Array(repeating: Int.max, count: capacity)
    XCTAssertEqual(a.allSatisfy({ $0 == .max }), true)
    a.withUnsafeMutableBufferPointer {
      let empty = UnsafeMutableBufferPointer<Int>(start: nil, count: 0)
      var span = MutableRawSpan(_unsafeElements: empty)
      var (iterator, updated) = span.update(from: 0..<0)
      XCTAssertNil(iterator.next())
      XCTAssertEqual(updated, 0)

      span = MutableRawSpan(_unsafeElements: $0)
      (iterator, updated) = span.update(from: 0..<0)
      XCTAssertNil(iterator.next())
      XCTAssertEqual(updated, 0)

      (iterator, updated) = span.update(from: 0..<10000)
      XCTAssertNotNil(iterator.next())
      XCTAssertEqual(updated, capacity*MemoryLayout<Int>.stride)
    }
    XCTAssertEqual(a.elementsEqual(0..<capacity), true)
  }

  public func testUpdateFromCollection() {
    let capacity = 8
    var a = Array(repeating: Int.max, count: capacity)
    let e = Array(EmptyCollection<UInt>())
    XCTAssertEqual(a.allSatisfy({ $0 == .max }), true)
    a.withUnsafeMutableBytes {
      let emptyPrefix = $0.prefix(0)
      var span = MutableRawSpan(_unsafeBytes: emptyPrefix)
      var updated = span.update(fromContentsOf: e)
      XCTAssertEqual(updated, 0)


      updated = span.update(fromContentsOf: AnyCollection(e))
      XCTAssertEqual(updated, 0)

      span = MutableRawSpan(_unsafeBytes: $0)
      updated = span.update(fromContentsOf: 0..<capacity)
      XCTAssertEqual(updated, capacity*MemoryLayout<Int>.stride)
    }
    XCTAssertEqual(a.elementsEqual(0..<capacity), true)
  }

  public func testUpdateFromContiguousMemory() {
    let capacity = 8
    var a = Array(repeating: Int.max, count: capacity)
    XCTAssertEqual(a.allSatisfy({ $0 == .max }), true)
    a.withUnsafeMutableBytes {
      var span = MutableRawSpan(_unsafeBytes: $0)
      let array = Array(0..<capacity)
      var updated = span.update(fromContentsOf: array.prefix(0))
      XCTAssertEqual(updated, 0)

      updated = span.update(fromContentsOf: array)
      XCTAssertEqual(updated, capacity*MemoryLayout<Int>.stride)
    }
    XCTAssertEqual(a.elementsEqual(0..<capacity), true)

    a.withUnsafeMutableBytes {
      var span = MutableRawSpan(_unsafeBytes: $0)
      var array = Array(repeating: Int.min, count: capacity)
      array.withUnsafeMutableBytes {
        let source = MutableRawSpan(_unsafeBytes: $0)
        let updated = span.update(fromContentsOf: source)
        XCTAssertEqual(updated, capacity*MemoryLayout<Int>.stride)
      }
    }
    XCTAssertEqual(a.allSatisfy({ $0 == Int.min }), true)

    a.withUnsafeMutableBytes {
      var span = MutableRawSpan(_unsafeBytes: $0)
      let array = Array(0..<capacity)
      array.withUnsafeBufferPointer {
        let source = Span(_unsafeElements: $0)
        let updated = span.update(fromContentsOf: source)
        XCTAssertEqual(updated, capacity*MemoryLayout<Int>.stride)
      }
    }
    XCTAssertEqual(a.elementsEqual(0..<capacity), true)
  }

  func testExtracting() {
    let capacity = 4
    var b = (0..<capacity).map(Int8.init)
    b.withUnsafeMutableBytes {
      var span = MutableRawSpan(_unsafeBytes: $0)

      var sub = span._extracting(0..<2)
      XCTAssertEqual(sub.byteCount, 2)
      XCTAssertEqual(sub.unsafeLoad(as: UInt8.self), 0)

      sub = span._extracting(..<2)
      XCTAssertEqual(sub.byteCount, 2)
      XCTAssertEqual(sub.unsafeLoad(as: UInt8.self), 0)

      sub = span._extracting(...)
      XCTAssertEqual(sub.byteCount, 4)
      XCTAssertEqual(sub.unsafeLoad(as: UInt8.self), 0)

      sub = span._extracting(2...)
      XCTAssertEqual(sub.byteCount, 2)
      XCTAssertEqual(sub.unsafeLoad(as: UInt8.self), 2)
    }
  }

  func testExtractingUnchecked() {
    let capacity = 32
    var b = (0..<capacity).map(UInt8.init)
    b.withUnsafeMutableBytes {
      var span = MutableRawSpan(_unsafeBytes: $0.prefix(8))
      let beyond = span._extracting(unchecked: 16...23)
      XCTAssertEqual(beyond.byteCount, 8)
      let fromBeyond = beyond.unsafeLoad(as: UInt8.self)
      XCTAssertEqual(fromBeyond, 16)
    }
  }

  func testPrefix() {
    let capacity = 4
    var a = Array(0..<UInt8(capacity))
    a.withUnsafeMutableBytes {
      var prefix: MutableRawSpan
      var span = MutableRawSpan(_unsafeBytes: $0)
      XCTAssertEqual(span.byteCount, capacity)

      prefix = span._extracting(first: 1)
      XCTAssertEqual(prefix.unsafeLoad(as: UInt8.self), 0)

      prefix = span._extracting(first: capacity)
      XCTAssertEqual(
        prefix.unsafeLoad(fromByteOffset: capacity-1, as: UInt8.self),
        UInt8(capacity-1)
      )

      prefix = span._extracting(droppingLast: capacity)
      XCTAssertEqual(prefix.isEmpty, true)

      prefix = span._extracting(droppingLast: 1)
      XCTAssertEqual(
        prefix.unsafeLoad(fromByteOffset: capacity-2, as: UInt8.self),
        UInt8(capacity-2)
      )
    }

    do {
      let b = UnsafeMutableRawBufferPointer(start: nil, count: 0)
      var span = MutableRawSpan(_unsafeBytes: b)
      XCTAssertEqual(span.byteCount, b.count)
      XCTAssertEqual(span._extracting(first: 1).byteCount, b.count)
      XCTAssertEqual(span._extracting(droppingLast: 1).byteCount, b.count)
    }
  }

  func testSuffix() {
    let capacity = 4
    var a = Array(0..<UInt8(capacity))
    a.withUnsafeMutableBytes {
      var prefix: MutableRawSpan
      var span = MutableRawSpan(_unsafeBytes: $0)
      XCTAssertEqual(span.byteCount, capacity)
      
      prefix = span._extracting(last: capacity)
      XCTAssertEqual(prefix.unsafeLoad(as: UInt8.self), 0)

      prefix = span._extracting(last: capacity-1)
      XCTAssertEqual(prefix.unsafeLoad(as: UInt8.self), 1)

      prefix = span._extracting(last: 1)
      XCTAssertEqual(prefix.unsafeLoad(as: UInt8.self), UInt8(capacity-1))

      prefix = span._extracting(droppingFirst: capacity)
      XCTAssertTrue(prefix.isEmpty)

      prefix = span._extracting(droppingFirst: 1)
      XCTAssertEqual(prefix.unsafeLoad(as: UInt8.self), 1)
    }

    do {
      let b = UnsafeMutableRawBufferPointer(start: nil, count: 0)
      var span = MutableRawSpan(_unsafeBytes: b)
      XCTAssertEqual(span.byteCount, b.count)
      XCTAssertEqual(span._extracting(last: 1).byteCount, b.count)
      XCTAssertEqual(span._extracting(droppingFirst: 1).byteCount, b.count)
    }
  }
}
#endif
