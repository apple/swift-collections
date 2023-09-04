//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest

@testable import ARTreeModule

fileprivate func randomByteArray(minSize: Int,
                                 maxSize: Int,
                                 minByte: UInt8,
                                 maxByte: UInt8) -> [UInt8] {
  let size = Int.random(in: minSize...maxSize)
  var result: [UInt8] = (0..<size - 1).map { _ in .random(in: minByte...maxByte) }
  result.append(0)
  return result
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class ARTreeGetValueTests: XCTestCase {
  func testGetValueNil() throws {
    let t = ARTree<[UInt8]>()
    XCTAssertEqual(t.getValue(key: [10, 20, 30]), nil)
  }

  func testGetValueBasic() throws {
    var t = ARTree<[UInt8]>()
    t.insert(key: [10, 20, 30], value: [11, 21, 31])
    t.insert(key: [11, 21, 31], value: [12, 22, 32])
    t.insert(key: [12, 22, 32], value: [13, 23, 33])
    XCTAssertEqual(t.getValue(key: [10, 20, 30]), [11, 21, 31])
    XCTAssertEqual(t.getValue(key: [11, 21, 31]), [12, 22, 32])
    XCTAssertEqual(t.getValue(key: [12, 22, 32]), [13, 23, 33])
  }

  func testGetValueRandom() throws {
    // (0) Parameters.
    let reps = 100
    let numKv = 10000
    let minSize = 10
    let maxSize = 100
    let minByte: UInt8 = 1
    let maxByte: UInt8 = 30

    for iteration in 1...reps {
      if iteration == (reps / 10) * iteration {
        print("Iteration: \(iteration)")
      }

      // (1) Generate test set.
      var tree = ARTree<[UInt8]>()
      var testSet: [[UInt8]: ([UInt8], [UInt8])] = [:]
      for _ in 0..<numKv {
        let key = randomByteArray(
          minSize: minSize, maxSize: maxSize,
          minByte: minByte, maxByte: maxByte)
        let value = randomByteArray(
          minSize: minSize, maxSize: maxSize,
          minByte: minByte, maxByte: maxByte)
        testSet[key] = (key, value)
      }
      var testSetArray = Array(testSet.values)

      // (2) Insert into tree.
      for (_, (key, value)) in testSetArray.enumerated() {
        tree.insert(key: key, value: value)
        // print("Inserted: \(idx + 1) \(key) -> \(value)")
        // for (k, v) in testSetArray[0...idx] {
        //     let obs = tree.getValue(key: k)
        //     if obs ?? [] != v {
        //         print("Missed After Insert: \(k): \(obs) instead of \(v)")
        //         print(tree)
        //         XCTAssert(false)
        //         return
        //     }
        // }
      }

      // (3) Shuffle test-set.
      testSetArray.shuffle()

      // (4) Check the entries in tree.
      var missed = 0
      for (key, value) in testSetArray {
        let obs = tree.getValue(key: key) ?? []
        if obs != value {
          print("Missed: \(key): \(value) got \(obs)")
          missed += 1
        }
      }

      XCTAssertEqual(missed, 0)
      if missed > 0 {
        print("Total = \(numKv), Matched = \(numKv - missed), Missed = \(missed)")
        print(tree)
        return
      }
    }
  }
}
