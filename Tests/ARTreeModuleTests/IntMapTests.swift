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

fileprivate func randomInts<T: FixedWidthInteger>(size: Int,
                                                  unique: Bool,
                                                  min: T,
                                                  max: T) -> [T] {

  if unique {
    return (0..<size - 1).shuffled().map { T($0) }
  } else {
    return (0..<size - 1).map { _ in .random(in: min...max) }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class IntMapTests: XCTestCase {
  func _testCommon<T: FixedWidthInteger & ConvertibleToOrderedBytes>(size: Int,
                                         unique: Bool,
                                         min: T,
                                         max: T,
                                         debug: Bool = false) throws {
    let testCase: [(T, Int)] = Array(
      randomInts(size: size,
                 unique: unique,
                 min: min,
                 max: max)
        .enumerated())
      .map { (v, k) in (k, v) }

    var t = RadixTree<T, Int>()
    var m: [T: Int] = [:]
    for (k, v) in testCase {
      if debug {
        print("Inserting \(k) --> \(v)")
      }
      _ = t.insert(k, v)
      m[k] = v
    }

    var total = 0
    var last = -1
    for (k, v) in t {
      total += 1
      if debug {
        print("Fetched \(k) --> \(v)")
      }
      XCTAssertEqual(v, m[k])
      XCTAssertLessThan(last, Int(k), "keys should be ordered")
      last = Int(k)

      if total > m.count {
        break
      }
    }

    XCTAssertEqual(total, m.count)
  }

  func testUnsignedIntUnique() throws {
    try _testCommon(size: 100000,
                    unique: true,
                    min: 0 as UInt,
                    max: 1 << 50 as UInt)
  }

  func testUnsignedIntWithDuplicatesSmallSet() throws {
    try _testCommon(size: 100,
                    unique: false,
                    min: 0 as UInt,
                    max: 50 as UInt)
  }

  func testUnsignedIntWithDuplicatesLargeSet() throws {
    try _testCommon(size: 1000000,
                    unique: false,
                    min: 0 as UInt,
                    max: 100000 as UInt)
  }
}
