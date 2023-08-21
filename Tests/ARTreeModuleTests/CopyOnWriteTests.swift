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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class ARTreeCopyOnWriteTests: XCTestCase {
  func testCopyOnWriteBasicInsert() throws {
    var t1 = ARTree<Int>()
    _ = t1.insert(key: [10, 20], value: 10)
    _ = t1.insert(key: [20, 30], value: 20)
    var t2 = t1
    _ = t2.insert(key: [30, 40], value: 30)
    _ = t2.insert(key: [40, 50], value: 40)

    XCTAssertEqual(
      t1.description,
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 10: 2[10, 20] -> 10\n" +
      "└──○ 20: 2[20, 30] -> 20")
    XCTAssertEqual(
      t2.description,
      "○ Node4 {childs=4, partial=[]}\n" +
      "├──○ 10: 2[10, 20] -> 10\n" +
      "├──○ 20: 2[20, 30] -> 20\n" +
      "├──○ 30: 2[30, 40] -> 30\n" +
      "└──○ 40: 2[40, 50] -> 40")
  }

  func testCopyOnWriteBasicDelete() throws {
    var t1 = ARTree<Int>()
    _ = t1.insert(key: [10, 20], value: 10)
    _ = t1.insert(key: [20, 30], value: 20)
    var t2 = t1
    _ = t2.insert(key: [30, 40], value: 30)
    _ = t2.insert(key: [40, 50], value: 40)
    var t3 = t2
    t3.delete(key: [30, 40])
    t3.delete(key: [10, 20])
    t3.delete(key: [20])

    XCTAssertEqual(
      t1.description,
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 10: 2[10, 20] -> 10\n" +
      "└──○ 20: 2[20, 30] -> 20")
    XCTAssertEqual(
      t2.description,
      "○ Node4 {childs=4, partial=[]}\n" +
      "├──○ 10: 2[10, 20] -> 10\n" +
      "├──○ 20: 2[20, 30] -> 20\n" +
      "├──○ 30: 2[30, 40] -> 30\n" +
      "└──○ 40: 2[40, 50] -> 40")
    XCTAssertEqual(
      t3.description,
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 20: 2[20, 30] -> 20\n" +
      "└──○ 40: 2[40, 50] -> 40")
  }
}
