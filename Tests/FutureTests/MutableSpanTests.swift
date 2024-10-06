//===--- MutableSpanTests.swift -------------------------------------------===//
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
@testable import Future

class ID {
  let id: Int
  init(id: Int) {
    self.id = id
  }
  deinit {
    // print(id)
  }
}

final class MutableSpanTests: XCTestCase {

  func testOptionalStorage() {
//    XCTAssertEqual(
//      MemoryLayout<MutableSpan<UInt8>>.size, MemoryLayout<MutableSpan<UInt8>?>.size
//    )
//    XCTAssertEqual(
//      MemoryLayout<MutableSpan<UInt8>>.stride, MemoryLayout<MutableSpan<UInt8>?>.stride
//    )
//    XCTAssertEqual(
//      MemoryLayout<MutableSpan<UInt8>>.alignment, MemoryLayout<MutableSpan<UInt8>?>.alignment
//    )
  }

  func testInitOrdinaryElement() {
    let capacity = 4
    var s = (0..<capacity).map({ "\(#file)+\(#function)--\($0)" })
    s.withUnsafeMutableBufferPointer {
      let b = MutableSpan(_unsafeElements: $0)
      XCTAssertEqual(b.count, $0.count)
    }
  }

  func testInitBitwiseCopyableElement() {
    let capacity = 4
    var a = Array(0..<capacity)
    a.withUnsafeMutableBufferPointer {
      let b = MutableSpan(_unsafeElements: $0)
      XCTAssertEqual(b.count, $0.count)
    }

    a.withUnsafeMutableBytes {
      let b = MutableSpan<UInt>(_unsafeBytes: $0)
      XCTAssertEqual(b.count, capacity)

      let r = MutableSpan<Int8>(_unsafeBytes: $0)
      XCTAssertEqual(r.count, capacity*MemoryLayout<Int>.stride)
    }

//    let v = UnsafeRawBufferPointer(start: nil, count: 0)
//    XCTAssertNil(MutableSpan<Int>(unsafeRawBufferPointer: v))
  }

//  public func testIteratorOrdinaryElement() {
//    let capacity = 4
//    var s = (0..<capacity).map({ "\(#file)+\(#function)--\($0)" })
//    s.withUnsafeMutableBufferPointer {
//      let view = MutableSpan(_unsafeElements: $0)
//
//      var iterator = view.makeIterator()
//      var buffered = 0
//      while let value = iterator.next() {
//        XCTAssertEqual(value.isEmpty, false)
//        buffered += 1
//      }
//      XCTAssertEqual(buffered, $0.count)
//    }
//  }

//  public func testIteratorBitwiseCopyable() {
//    let count = 4
//    let offset = 1
//    XCTAssertLessThan(offset, MemoryLayout<UInt64>.stride)
//    let bytes = count*MemoryLayout<UInt64>.stride + offset
//    let align = MemoryLayout<UInt64>.alignment
//    let p = UnsafeMutableRawPointer.allocate(byteCount: bytes, alignment: align)
//    defer { p.deallocate() }
//    for i in 0..<bytes where i%8 == offset {
//      p.storeBytes(of: 1, toByteOffset: i, as: UInt8.self)
//    }
//
//    let orig = p.loadUnaligned(as: Int64.self)
//    XCTAssertNotEqual(orig, 1)
//
//    // MutableSpan doesn't need to be aligned for accessing `BitwiseCopyable` types.
//    let buffer = MutableSpan<Int64>(_unsafeStart: p+offset, byteCount: count*8)
//
//    var buffered = 0
//    for value in 0..<buffer.count {
//      XCTAssertNotEqual(value, 1)
//      buffered += 1
//    }
//    XCTAssertEqual(buffered, count)
//  }

  func testIsEmpty() {
    var array = [0, 1, 2]
    array.withUnsafeMutableBufferPointer {
      let span = MutableSpan(_unsafeElements: $0)
      XCTAssertFalse(span.isEmpty)

      let empty = MutableSpan(_unsafeElements: .init(rebasing: $0.prefix(0)))
      XCTAssertTrue(empty.isEmpty)
    }
  }

  func testSpanFromMutableSpan() {
    var array = [0, 1, 2]
    array.withUnsafeMutableBufferPointer {
      let mutable = MutableSpan(_unsafeElements: $0)
      let immutable  = Span(_unsafeMutableSpan: mutable)
      XCTAssertEqual(mutable.count, immutable.count)
    }
  }

  func testRawSpanFromMutableSpan() {
    let count = 4
    var array = Array(0..<count)
    array.withUnsafeMutableBufferPointer {
      let span = MutableSpan(_unsafeElements: $0)
      let raw  = span._unsafeRawSpan
      XCTAssertEqual(raw.byteCount, count*MemoryLayout<Int>.stride)
    }
  }

  func testSpanIndices() {
    let capacity = 4
    var a = Array(0..<capacity)
    a.withUnsafeMutableBufferPointer {
      let view = MutableSpan(_unsafeElements: $0)
      XCTAssertEqual(view.count, view._indices.count)
      XCTAssert(view._indices.elementsEqual(0..<view.count))
    }
  }

  func testElementsEqual() {
    let capacity = 4
    var a = Array<Int>(unsafeUninitializedCapacity: capacity) {
      for i in $0.indices {
        $0.initializeElement(at: i, to: .random(in: 0..<10))
      }
      $1 = $0.count
    }
    a.withUnsafeMutableBufferPointer {
      var v1 = MutableSpan(_unsafeElements: $0)

      XCTAssertEqual(v1._elementsEqual(Span(_unsafeMutableSpan: v1)._extracting(first: 1)), false)
      XCTAssertEqual(Span(_unsafeMutableSpan: v1)._extracting(first: 0)._elementsEqual(Span(_unsafeMutableSpan: v1)._extracting(last: 0)), true)
      XCTAssertEqual(v1._elementsEqual(v1), true)
      XCTAssertEqual(Span(_unsafeMutableSpan: v1)._extracting(first: 3)._elementsEqual(Span(_unsafeMutableSpan: v1)._extracting(last: 3)), false)

      var b = v1.withUnsafeMutableBufferPointer { Array($0) }
      b.withUnsafeMutableBufferPointer {
        let v2 = MutableSpan(_unsafeElements: $0)
        XCTAssertEqual(v1._elementsEqual(v2), true)
      }
    }
  }

  func testElementsEqualCollection() {
    let capacity = 4
    var a = Array(0..<capacity)
    a.withUnsafeMutableBufferPointer {
      let span = MutableSpan(_unsafeElements: $0)
      let a = $0.indices.randomElement()!
      let emptySpan = MutableSpan(_unsafeElements: .init(rebasing: $0[a..<a]))

      XCTAssertEqual(span._elementsEqual($0), true)
      XCTAssertEqual(emptySpan._elementsEqual([]), true)
      XCTAssertEqual(span._elementsEqual($0.dropLast()), false)
    }
  }

  func testElementsEqualSequence() {
    let capacity = 4
    var a = Array(0..<capacity)
    let s = AnySequence(a)
    a.withUnsafeMutableBufferPointer {
      let span = MutableSpan(_unsafeElements: $0)
      let subSpan = MutableSpan(_unsafeElements: .init(rebasing: $0.dropLast()))

      XCTAssertEqual(span._elementsEqual(s), true)
      XCTAssertEqual(subSpan._elementsEqual(s), false)
      XCTAssertEqual(span._elementsEqual(s.dropFirst()), false)
    }
  }

  func testIndexingSubscript() {
    let capacity = 4
    var a = Array(0..<capacity)
    a.withUnsafeMutableBufferPointer {
      [first = a.first] in
      var v = MutableSpan(_unsafeElements: $0)
      XCTAssertEqual(v[0], first)

      v[0] += 1
      XCTAssertEqual(v[0], first?.advanced(by: 1))
    }

    var b = a.map(String.init)
    b.withUnsafeMutableBufferPointer {
      [first = b.first] in
      var v = MutableSpan(_unsafeElements: $0)
      XCTAssertEqual(v[0], first)

      v[0].append("!")
      XCTAssertEqual(v[0], first?.appending("!"))
    }
  }

  public func testWithUnsafeBufferPointer() {
    let capacity: UInt8 = 64
    var a = Array(0..<capacity)
    let i = Int.random(in: a.indices)
    a.withUnsafeMutableBufferPointer {
      let view = MutableSpan(_unsafeElements: $0)
      view.withUnsafeBufferPointer {
        XCTAssertEqual($0[i], $0[i])
      }
    }
  }

  public func testWithUnsafeBytes() {
    let capacity: UInt8 = 64
    var a = Array(0..<capacity)
    let i = Int.random(in: a.indices)
    a.withUnsafeMutableBufferPointer {
      let view = MutableSpan(_unsafeElements: $0)
      view.withUnsafeBytes {
        XCTAssertEqual($0.load(fromByteOffset: i, as: UInt8.self), $0[i])
      }
    }
  }

  public func testWithUnsafeMutableBufferPointer() {
    let capacity: UInt8 = 64
    var a = Array(0..<capacity)
    let i = Int.random(in: a.indices)
    a.withUnsafeMutableBufferPointer {
      var view = MutableSpan(_unsafeElements: $0)
      view.withUnsafeMutableBufferPointer {
        $0[i] += 1
        // $0 = .allocate(capacity: 64)
      }

      var emptySpan = MutableSpan<UInt8>(
        _unsafeElements: .init(start: $0.baseAddress, count: 0)
      )
      emptySpan.withUnsafeMutableBufferPointer {
        XCTAssertEqual($0.count, 0)
        XCTAssertNil($0.baseAddress)
      }
    }
    XCTAssertEqual(Int(a[i]), i+1)
  }

  public func testWithUnsafeMutableBytes() {
    let capacity: UInt8 = 64
    var a = Array(0..<capacity)
    let i = Int.random(in: a.indices)
    a.withUnsafeMutableBufferPointer {
      var view = MutableSpan(_unsafeElements: $0)
      view.withUnsafeMutableBytes {
        $0.storeBytes(of: UInt8(i+1), toByteOffset: i, as: UInt8.self)
      }

      var emptySpan = MutableSpan<UInt8>(
        _unsafeElements: .init(start: $0.baseAddress, count: 0)
      )
      emptySpan.withUnsafeMutableBytes {
        XCTAssertEqual($0.count, 0)
        XCTAssertNil($0.baseAddress)
      }
    }
    XCTAssertEqual(Int(a[i]), i+1)
  }

  public func testUpdateRepeatingBitwiseCopyable() {
    var a = Array(0..<8)
    XCTAssertEqual(a.contains(.max), false)
    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0)
      span.update(repeating: .max)
    }
    XCTAssertEqual(a.allSatisfy({ $0 == .max }), true)
  }

  public func testUpdateRepeating() {
    var a = (0..<8).map(ID.init(id:))
    XCTAssertEqual(a.map(\.id).contains(.max), false)
    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0)
      span.update(repeating: ID(id: .max))
    }
    XCTAssertEqual(a.allSatisfy({ $0.id == .max }), true)
  }

  public func testUpdateFromSequenceBitwiseCopyable() {
    let capacity = 8
    var a = Array(repeating: Int.max, count: capacity)
    XCTAssertEqual(a.allSatisfy({ $0 == .max }), true)
    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan<Int>(_unsafeElements: .init(start: nil, count: 0))
      var (iterator, updated) = span.update(from: 0..<0)
      XCTAssertNil(iterator.next())
      XCTAssertEqual(updated, 0)

      span = MutableSpan(_unsafeElements: $0)
      (iterator, updated) = span.update(from: 0..<0)
      XCTAssertNil(iterator.next())
      XCTAssertEqual(updated, 0)

      (iterator, updated) = span.update(from: 0..<10000)
      XCTAssertNotNil(iterator.next())
      XCTAssertEqual(updated, capacity)
    }
    XCTAssertEqual(a.elementsEqual(0..<capacity), true)
  }

  public func testUpdateFromSequence() {
    let capacity = 8
    var a = Array(repeating: ID(id: .max), count: capacity)
    XCTAssertEqual(a.allSatisfy({ $0.id == .max }), true)
    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0.prefix(0))
      var (iterator, updated) = span.update(from: [])
      XCTAssertNil(iterator.next())
      XCTAssertEqual(updated, 0)

      span = MutableSpan(_unsafeElements: $0)
      (iterator, updated) = span.update(from: [])
      XCTAssertNil(iterator.next())
      XCTAssertEqual(updated, 0)

      (iterator, updated) = span.update(from: (0..<12).map(ID.init(id:)))
      XCTAssertNotNil(iterator.next())
      XCTAssertEqual(updated, capacity)
    }
    XCTAssertEqual(a.map(\.id).elementsEqual(0..<capacity), true)
  }

  public func testUpdateFromCollectionBitwiseCopyable() {
    let capacity = 8
    var a = Array(repeating: Int.max, count: capacity)
    XCTAssertEqual(a.allSatisfy({ $0 == .max }), true)
    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0.prefix(0))
      var updated = span.update(fromContentsOf: [])
      XCTAssertEqual(updated, 0)


      updated = span.update(fromContentsOf: AnyCollection([]))
      XCTAssertEqual(updated, 0)

      span = MutableSpan(_unsafeElements: $0)
      updated = span.update(fromContentsOf: 0..<capacity)
      XCTAssertEqual(updated, capacity)
    }
    XCTAssertEqual(a.elementsEqual(0..<capacity), true)
  }

  public func testUpdateFromCollection() {
    let capacity = 8
    var a = Array(repeating: ID(id: .max), count: capacity)
    XCTAssertEqual(a.allSatisfy({ $0.id == .max }), true)
    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0.prefix(0))
      var updated = span.update(fromContentsOf: [])
      XCTAssertEqual(updated, 0)

      updated = span.update(fromContentsOf: AnyCollection([]))
      XCTAssertEqual(updated, 0)

      span = MutableSpan(_unsafeElements: $0)
      let elements = (0..<capacity).map(ID.init(id:))
      updated = span.update(fromContentsOf: AnyCollection(elements))
      XCTAssertEqual(updated, capacity)
    }
    XCTAssertEqual(a.map(\.id).elementsEqual(0..<capacity), true)
  }

  public func testUpdateFromContiguousMemoryBitwiseCopyable() {
    let capacity = 8
    var a = Array(repeating: Int.max, count: capacity)
    XCTAssertEqual(a.allSatisfy({ $0 == .max }), true)
    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0.prefix(0))
      var update = span.update(fromContentsOf: [])
      XCTAssertEqual(update, 0)

      span = MutableSpan(_unsafeElements: $0)
      let array = Array(0..<capacity)
      update = span.update(fromContentsOf: array)
      XCTAssertEqual(update, capacity)
    }
    XCTAssertEqual(a.elementsEqual(0..<capacity), true)
  }

  public func testUpdateFromContiguousMemory() {
    let capacity = 8
    var a = Array(repeating: ID(id: .max), count: capacity)
    XCTAssertEqual(a.allSatisfy({ $0.id == .max }), true)
    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0.prefix(0))
      var updated = span.update(fromContentsOf: UnsafeBufferPointer(start: nil, count: 0))
      XCTAssertEqual(updated, 0)

      span = MutableSpan(_unsafeElements: $0)
      let elements = (0..<capacity).map(ID.init(id:))
      updated = span.update(fromContentsOf: elements)
      XCTAssertEqual(updated, capacity)
    }
    XCTAssertEqual(a.map(\.id).elementsEqual(0..<capacity), true)
  }

  public func testUpdateFromRawContiguousMemory() {
    let capacity = 8
    var a = Array(repeating: Int32.max, count: capacity)
    XCTAssertEqual(a.allSatisfy({ $0 == .max }), true)
    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0.prefix(0))
      let empty = UnsafeRawBufferPointer(start: $0.baseAddress, count: 0)
      var updated = span.update(fromContentsOf: empty)
      XCTAssertEqual(updated, 0)

      span = MutableSpan(_unsafeElements: $0)
      let b = Array(UInt32(0)..<UInt32(capacity))
      updated = b.withUnsafeBytes { span.update(fromContentsOf: $0) }
      XCTAssertEqual(updated, capacity)
    }
    XCTAssertEqual(a.elementsEqual(0..<Int32(capacity)), true)
  }

  public func testMoveUpdate() {
    let capacity = 8
    var a = Array(repeating: ID(id: .max), count: capacity)

    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0)
      let empty = UnsafeMutableBufferPointer(start: $0.baseAddress, count: 0)
      let updated = span.moveUpdate(fromContentsOf: empty)
      XCTAssertEqual(updated, 0)
    }
    XCTAssertEqual(a.allSatisfy({ $0.id == .max }), true)

    var b = UnsafeMutableBufferPointer<ID>.allocate(capacity: capacity)

    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0)

      var o = OutputSpan(_initializing: b)
      o.append(fromContentsOf: (0..<capacity).map(ID.init(id:)))
      XCTAssertEqual(o.count, capacity)

      let updated = span.moveUpdate(fromContentsOf: o)
      XCTAssertEqual(updated, capacity)
    }
    XCTAssertEqual(a.map(\.id).elementsEqual(0..<capacity), true)

    b.deallocate()
    b = .allocate(capacity: 2*capacity)
    let i = b.initialize(fromContentsOf: (0..<2*capacity).map(ID.init(id:)))
    XCTAssertEqual(i, 2*capacity)

    a.withUnsafeMutableBufferPointer {
      var span = MutableSpan(_unsafeElements: $0)
      let updated = span.moveUpdate(fromContentsOf: b.suffix(capacity))
      XCTAssertEqual(updated, capacity)
    }
    XCTAssertEqual(a.map(\.id).elementsEqual(capacity..<2*capacity), true)

    a = []
    b.prefix(capacity).deinitialize()
    b.deallocate()
  }
}
