//===--- StdlibSpanExtensionTests.swift -----------------------------------===//
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

enum ErrorForTesting: Error, Equatable { case error, errorToo, errorAsWell }

final class StdlibSpanExtensionTests: XCTestCase {

#if false //FIXME: rdar://134382237 -- nightly toolchain cannot `import Darwin`
  func testDataSpan() throws {
    let a = Data(0..<4)
    a.withSpan {
      for i in $0._indices {
        XCTAssertEqual($0[i], UInt8(i))
      }
    }
    do throws(ErrorForTesting) {
      try a.withSpan { _ throws(ErrorForTesting) in throw .error }
    } catch {
      XCTAssertEqual(error, .error)
    }
  }

  func testDataRawSpan() throws {
    let a = Data(0..<4)
    a.withBytes {
      for i in $0._byteOffsets {
        XCTAssertEqual(
          $0.unsafeLoad(fromByteOffset: i, as: UInt8.self), UInt8(i)
        )
      }
    }
    do throws(ErrorForTesting) {
      try a.withBytes { _ throws(ErrorForTesting) in throw .error }
    } catch {
      XCTAssertEqual(error, .error)
    }
  }
#endif

  func testArraySpan() throws {
    let a = (0..<4).map(String.init(_:))
    do throws(ErrorForTesting) {
      a.withSpan {
        for i in $0._indices {
          XCTAssertEqual($0[i], String(i))
        }
      }
      try a.withSpan { _ throws(ErrorForTesting) in throw .error }
    } catch {
      XCTAssertEqual(error, .error)
    }
  }

  func testArrayRawSpan() throws {
    let c = 4
    let a = Array(0..<c)
    a.withBytes {
      for i in 0..<c {
        XCTAssertEqual(
          i, $0.unsafeLoad(
            fromByteOffset: i*MemoryLayout<Int>.stride, as: Int.self
          )
        )
      }
    }
    do throws(ErrorForTesting) {
      try a.withBytes { _ throws(ErrorForTesting) in throw .error }
    } catch {
      XCTAssertEqual(error, .error)
    }
  }

  func testContiguousArraySpan() throws {
    let a = ContiguousArray((0..<4).map(String.init(_:)))
    a.withSpan {
      for i in $0._indices {
        XCTAssertEqual($0[i], String(i))
      }
    }
    do throws(ErrorForTesting) {
      try a.withSpan { _ throws(ErrorForTesting) in throw .error }
    } catch {
      XCTAssertEqual(error, .error)
    }
  }

  func testContiguousArrayRawSpan() throws {
    let c = 4
    let a = ContiguousArray(0..<c)
    a.withBytes {
      for i in 0..<c {
        XCTAssertEqual(
          i, $0.unsafeLoad(
            fromByteOffset: i*MemoryLayout<Int>.stride, as: Int.self
          )
        )
      }
    }
    XCTAssertThrowsError(try a.withBytes({ _ in throw ErrorForTesting.error }))
  }

  func testArraySliceSpan() throws {
    let a = (0..<7).map(String.init(_:)).prefix(upTo: 4)
    print(a.count)
    a.withSpan {
      print($0._indices)
      for i in $0._indices {
        print(i)
        let v = $0[i]
        _ = v
        XCTAssertEqual($0[i], String(i))
      }
    }
    do throws(ErrorForTesting) {
      try a.withSpan { _ throws(ErrorForTesting) in throw .error }
    } catch {
      XCTAssertEqual(error, .error)
    }
  }

  func testArraySliceRawSpan() throws {
    let c = 4
    let a = Array(0..<7).prefix(upTo: c)
    a.withBytes {
      for i in 0..<c {
        XCTAssertEqual(
          i, $0.unsafeLoad(
            fromByteOffset: i*MemoryLayout<Int>.stride, as: Int.self
          )
        )
      }
    }
    XCTAssertThrowsError(try a.withBytes({ _ in throw ErrorForTesting.error }))
  }

  func testCollectionOfOneSpan() throws {
    let a = CollectionOfOne("CollectionOfOne is an obscure Collection type.")
    a.withSpan {
      XCTAssertTrue($0._elementsEqual(a))
    }
    XCTAssertThrowsError(try a.withSpan({ _ in throw ErrorForTesting.error }))
  }

  func testCollectionOfOneRawSpan() throws {
    let a = CollectionOfOne(Int(UInt8.random(in: 0 ..< .max)))
    a.withBytes {
      for i in $0._byteOffsets {
        let v = $0.unsafeLoad(fromByteOffset: i, as: UInt8.self)
        if v != 0 {
          XCTAssertEqual(Int(v), a.first)
        }
      }
    }
    XCTAssertThrowsError(try a.withBytes({ _ in throw ErrorForTesting.error }))
  }

  func testUTF8ViewSpan() throws {
    let strings: [String] = [
      "small",
      "Not a small string, if I can count code units correctly.",
      NSString("legacy string if I can get it to behave.") as String
    ]
    for s in strings {
      s.utf8.withSpan {
        XCTAssertEqual($0.count, s.utf8.count)
      }
    }
    let a = strings[0].utf8
    XCTAssertThrowsError(try a.withSpan({ _ in throw ErrorForTesting.error }))
  }
}
