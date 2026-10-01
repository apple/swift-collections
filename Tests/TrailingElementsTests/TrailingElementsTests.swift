//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import Testing

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import TrailingElementsModule
#endif

struct Point {
  var x: Int
  var y: Int
}

struct Coordinates {
  var numCoordinates: Int
}

extension Coordinates: TrailingElements {
  typealias Element = Point
  var trailingCount: Int { numCoordinates }
}

struct OneByteWithPointers: @unsafe TrailingElements {
  var byte: UInt8

  init(count: Int) {
    self.byte = UInt8(count)
  }

  typealias Element = OpaquePointer
  var trailingCount: Int { Int(byte) }
}

struct ManyBytesWithPointers: @unsafe TrailingElements {
  var bytes: (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8)

  init(count: Int) {
    self.bytes = (
      UInt8(count), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
  }

  typealias Element = OpaquePointer
  var trailingCount: Int { Int(bytes.0) }
}

@Suite("Trailing elements tests")
struct TrailingElementsTests {
  @Test func simpleCoordinates() {
    var coords = TrailingArray(
      header: Coordinates(numCoordinates: 3)
    ) { outputSpan in
      outputSpan.append(Point(x: 1, y: 2))
      outputSpan.append(Point(x: 2, y: 3))
      outputSpan.append(Point(x: 3, y: 4))
    }

    #expect(coords[0].x == 1)
    #expect(coords[1].x == 2)
    #expect(coords[2].x == 3)

    coords[1].y = 17
    #expect(coords[1].y == 17)
  }

  @Test func repeatingInit() {
    var coords = TrailingArray(
      header: Coordinates(numCoordinates: 3), repeating: Point(x: 1, y: 1))

    #expect(coords[0].x == 1)
    #expect(coords[1].x == 1)
    #expect(coords[2].x == 1)

    coords[1].x = 17
    #expect(coords[0].x == 1)
    #expect(coords[1].x == 17)
    #expect(coords[2].x == 1)
  }

  @Test func temporaryCoordinates() {
    TrailingArray.withTemporaryValue(
      header: Coordinates(numCoordinates: 3)
    ) { outputSpan in
      outputSpan.append(Point(x: 1, y: 2))
      outputSpan.append(Point(x: 2, y: 3))
      outputSpan.append(Point(x: 3, y: 4))
    } body: { coords in
      #expect(coords[0].x == 1)
      #expect(coords[1].x == 2)
      #expect(coords[2].x == 3)
    }
  }

  @Test(arguments: 0 ... 10)
  func underalignedByteOnHeap(count: Int) {
    var pointers = unsafe TrailingArray(
      header: OneByteWithPointers(count: count)
    ) { outputSpan in
      for i in 0..<count {
        unsafe outputSpan.append(OpaquePointer(bitPattern: i+1)!)
      }
    }

    for i in 0..<count {
      #expect(unsafe pointers[i] == OpaquePointer(bitPattern: i+1))
    }

    unsafe pointers.withUnsafeMutablePointers { headerPtr, elementsPtr in
      let p1 = unsafe headerPtr.advanced(by: MemoryLayout<OneByteWithPointers>.stride)
      let p2 = elementsPtr.baseAddress
      #expect(unsafe UnsafeMutableRawPointer(p1) == UnsafeMutableRawPointer(p2))
    }
  }

  @Test(arguments: 0 ... 10)
  func underalignedByteOnStack(count: Int) {
    unsafe TrailingArray.withTemporaryValue(header: OneByteWithPointers(count: count)) { outputSpan in
      for i in 0..<count {
        unsafe outputSpan.append(OpaquePointer(bitPattern: i+1)!)
      }
    } body: { pointers in
      for i in 0..<count {
        #expect(unsafe pointers[i] == OpaquePointer(bitPattern: i+1))
      }

      unsafe pointers.withUnsafeMutablePointers { headerPtr, elementsPtr in
        let p1 = unsafe headerPtr.advanced(by: MemoryLayout<OneByteWithPointers>.stride)
        let p2 = elementsPtr.baseAddress
        #expect(unsafe UnsafeMutableRawPointer(p1) == UnsafeMutableRawPointer(p2))
      }
    }
  }

  @Test(arguments: 0 ... 10)
  func underalignedBytesOnHeap(count: Int) {
    var pointers = unsafe TrailingArray(header: ManyBytesWithPointers(count: count)) { outputSpan in
      for i in 0..<count {
        unsafe outputSpan.append(OpaquePointer(bitPattern: i+1)!)
      }
    }

    for i in 0..<count {
      #expect(unsafe pointers[i] == OpaquePointer(bitPattern: i+1))
    }

    unsafe pointers.withUnsafeMutablePointers { headerPtr, elementsPtr in
      let p1 = unsafe headerPtr.advanced(by: MemoryLayout<OneByteWithPointers>.stride)
      let p2 = elementsPtr.baseAddress
      #expect(unsafe UnsafeMutableRawPointer(p1) == UnsafeMutableRawPointer(p2))
    }
  }

  @Test(arguments: 0 ... 10)
  func underalignedBytesOnStack(count: Int) {
    unsafe TrailingArray.withTemporaryValue(header: ManyBytesWithPointers(count: count)) { outputSpan in
      for i in 0..<count {
        unsafe outputSpan.append(OpaquePointer(bitPattern: i+1)!)
      }
    } body: { pointers in
      for i in 0..<count {
        #expect(unsafe pointers[i] == OpaquePointer(bitPattern: i+1))
      }

      unsafe pointers.withUnsafeMutablePointers { headerPtr, elementsPtr in
        let p1 = unsafe headerPtr.advanced(by: MemoryLayout<OneByteWithPointers>.stride)
        let p2 = elementsPtr.baseAddress
        #expect(unsafe UnsafeMutableRawPointer(p1) == UnsafeMutableRawPointer(p2))
      }
    }
  }
}
