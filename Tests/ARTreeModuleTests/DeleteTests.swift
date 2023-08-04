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

final class ARTreeDeleteTests: XCTestCase {
  func testDeleteBasic() throws {
    var t = ARTree<[UInt8]>()
    t.insert(key: [10, 20, 30], value: [11, 21, 31])
    t.insert(key: [11, 21, 31], value: [12, 22, 32])
    t.insert(key: [12, 22, 32], value: [13, 23, 33])
    t.delete(key: [11, 21, 31])
    XCTAssertEqual(
      t.description,
      "○ Node4 {childs=2, partial=[]}\n" + "├──○ 10: 3[10, 20, 30] -> [11, 21, 31]\n"
        + "└──○ 12: 3[12, 22, 32] -> [13, 23, 33]")
  }

  func testDeleteAll() throws {
    var t = ARTree<[UInt8]>()
    t.insert(key: [10, 20, 30], value: [11, 21, 31])
    t.insert(key: [11, 21, 31], value: [12, 22, 32])
    t.insert(key: [12, 22, 32], value: [13, 23, 33])
    t.delete(key: [10, 20, 30])
    t.delete(key: [11, 21, 31])
    t.delete(key: [12, 22, 32])
    XCTAssertEqual(t.description, "<>")
  }

  func testDeleteNested1() throws {
    var t = ARTree<[UInt8]>()
    t.insert(key: [1, 2, 3], value: [1])
    t.insert(key: [4, 5, 6], value: [2])
    t.insert(key: [1, 2, 4], value: [3])
    t.delete(key: [1, 2, 4])
    XCTAssertEqual(
      t.description,
      "○ Node4 {childs=2, partial=[]}\n" + "├──○ 1: 3[1, 2, 3] -> [1]\n"
        + "└──○ 4: 3[4, 5, 6] -> [2]")
    t.delete(key: [1, 2, 3])
    XCTAssertEqual(t.description, "○ 3[4, 5, 6] -> [2]")
    t.delete(key: [4, 5, 6])
    XCTAssertEqual(t.description, "<>")
  }

  func testDeleteNested2() throws {
    var t = ARTree<[UInt8]>()
    t.insert(key: [1, 2, 3, 4, 5, 6], value: [1])
    t.insert(key: [4, 5, 6, 7, 8, 9], value: [2])
    t.insert(key: [1, 2, 4, 5, 6, 7], value: [3])
    t.insert(key: [1, 2, 3, 4, 8, 9], value: [4])
    t.insert(key: [1, 2, 3, 4, 9, 9], value: [5])
    t.delete(key: [1, 2, 3, 4, 5, 6])
    XCTAssertEqual(
      t.description,
      "○ Node4 {childs=2, partial=[]}\n" + "├──○ 1: Node4 {childs=2, partial=[2]}\n"
        + "│  ├──○ 3: Node4 {childs=2, partial=[4]}\n"
        + "│  │  ├──○ 8: 6[1, 2, 3, 4, 8, 9] -> [4]\n"
        + "│  │  └──○ 9: 6[1, 2, 3, 4, 9, 9] -> [5]\n" + "│  └──○ 4: 6[1, 2, 4, 5, 6, 7] -> [3]\n"
        + "└──○ 4: 6[4, 5, 6, 7, 8, 9] -> [2]")
  }

  func testDeleteNonExistWithCommonPrefix() throws {
    var t = ARTree<[UInt8]>()
    t.insert(key: [1, 2, 3, 4, 5, 6], value: [1])
    t.insert(key: [4, 5, 6, 7, 8, 9], value: [2])
    t.delete(key: [1, 2, 3])
    XCTAssertEqual(
      t.description,
      "○ Node4 {childs=2, partial=[]}\n" + "├──○ 1: 6[1, 2, 3, 4, 5, 6] -> [1]\n"
        + "└──○ 4: 6[4, 5, 6, 7, 8, 9] -> [2]")
  }

  func testDeleteCompressToLeaf() throws {
    var t = ARTree<[UInt8]>()
    t.insert(key: [1, 2, 3, 4, 5, 6], value: [1])
    t.insert(key: [4, 5, 6, 7, 8, 9], value: [2])
    t.insert(key: [1, 2, 4, 5, 6, 7], value: [3])
    t.insert(key: [1, 2, 3, 4, 8, 9], value: [4])
    t.insert(key: [1, 2, 3, 4, 9, 9], value: [5])
    t.delete(key: [1, 2, 3, 4, 5, 6])
    t.delete(key: [1, 2, 3, 4, 8, 9])
    XCTAssertEqual(
      t.description,
      "○ Node4 {childs=2, partial=[]}\n" + "├──○ 1: Node4 {childs=2, partial=[2]}\n"
        + "│  ├──○ 3: 6[1, 2, 3, 4, 9, 9] -> [5]\n" + "│  └──○ 4: 6[1, 2, 4, 5, 6, 7] -> [3]\n"
        + "└──○ 4: 6[4, 5, 6, 7, 8, 9] -> [2]")
  }

  func testDeleteCompressToNode4() throws {
    var t = ARTree<[UInt8]>()
    t.insert(key: [1, 2, 3, 4, 5], value: [1])
    t.insert(key: [2, 3, 4, 5, 5], value: [2])
    t.insert(key: [3, 4, 5, 6, 7], value: [3])
    t.insert(key: [4, 5, 6, 7, 8], value: [4])
    t.insert(key: [5, 6, 7, 8, 9], value: [5])
    XCTAssertEqual(
      t.description,
      "○ Node16 {childs=5, partial=[]}\n" + "├──○ 1: 5[1, 2, 3, 4, 5] -> [1]\n"
        + "├──○ 2: 5[2, 3, 4, 5, 5] -> [2]\n" + "├──○ 3: 5[3, 4, 5, 6, 7] -> [3]\n"
        + "├──○ 4: 5[4, 5, 6, 7, 8] -> [4]\n" + "└──○ 5: 5[5, 6, 7, 8, 9] -> [5]")
    t.delete(key: [3, 4, 5, 6, 7])
    t.delete(key: [4, 5, 6, 7, 8])
    XCTAssertEqual(
      t.description,
      "○ Node4 {childs=3, partial=[]}\n" + "├──○ 1: 5[1, 2, 3, 4, 5] -> [1]\n"
        + "├──○ 2: 5[2, 3, 4, 5, 5] -> [2]\n" + "└──○ 5: 5[5, 6, 7, 8, 9] -> [5]")
  }

  func testDeleteCompressToNode16() throws {
    var t = ARTree<[UInt8]>()
    for i: UInt8 in 0...16 {
      t.insert(key: [i, i + 1], value: [i])
    }
    XCTAssertEqual(t.root?.type(), .node48)
    t.delete(key: [3, 4])
    t.delete(key: [4, 5])
    XCTAssertEqual(
      t.description,
      "○ Node48 {childs=15, partial=[]}\n" + "├──○ 0: 2[0, 1] -> [0]\n" + "├──○ 1: 2[1, 2] -> [1]\n"
        + "├──○ 2: 2[2, 3] -> [2]\n" + "├──○ 5: 2[5, 6] -> [5]\n" + "├──○ 6: 2[6, 7] -> [6]\n"
        + "├──○ 7: 2[7, 8] -> [7]\n" + "├──○ 8: 2[8, 9] -> [8]\n" + "├──○ 9: 2[9, 10] -> [9]\n"
        + "├──○ 10: 2[10, 11] -> [10]\n" + "├──○ 11: 2[11, 12] -> [11]\n"
        + "├──○ 12: 2[12, 13] -> [12]\n" + "├──○ 13: 2[13, 14] -> [13]\n"
        + "├──○ 14: 2[14, 15] -> [14]\n" + "├──○ 15: 2[15, 16] -> [15]\n"
        + "└──○ 16: 2[16, 17] -> [16]")
    t.delete(key: [5, 6])
    t.delete(key: [6, 7])
    XCTAssertEqual(
      t.description,
      "○ Node16 {childs=13, partial=[]}\n" + "├──○ 0: 2[0, 1] -> [0]\n" + "├──○ 1: 2[1, 2] -> [1]\n"
        + "├──○ 2: 2[2, 3] -> [2]\n" + "├──○ 7: 2[7, 8] -> [7]\n" + "├──○ 8: 2[8, 9] -> [8]\n"
        + "├──○ 9: 2[9, 10] -> [9]\n" + "├──○ 10: 2[10, 11] -> [10]\n"
        + "├──○ 11: 2[11, 12] -> [11]\n" + "├──○ 12: 2[12, 13] -> [12]\n"
        + "├──○ 13: 2[13, 14] -> [13]\n" + "├──○ 14: 2[14, 15] -> [14]\n"
        + "├──○ 15: 2[15, 16] -> [15]\n" + "└──○ 16: 2[16, 17] -> [16]")
  }

  func testDeleteCompressToNode48() throws {
    var t = ARTree<[UInt8]>()
    for i: UInt8 in 0...48 {
      t.insert(key: [i, i + 1], value: [i])
    }
    XCTAssertEqual(t.root?.type(), .node256)
    for i: UInt8 in 24...40 {
      if i % 2 == 0 {
        t.delete(key: [i, i + 1])
      }
    }
    XCTAssertEqual(
      t.description,
      "○ Node48 {childs=40, partial=[]}\n" + "├──○ 0: 2[0, 1] -> [0]\n" + "├──○ 1: 2[1, 2] -> [1]\n"
        + "├──○ 2: 2[2, 3] -> [2]\n" + "├──○ 3: 2[3, 4] -> [3]\n" + "├──○ 4: 2[4, 5] -> [4]\n"
        + "├──○ 5: 2[5, 6] -> [5]\n" + "├──○ 6: 2[6, 7] -> [6]\n" + "├──○ 7: 2[7, 8] -> [7]\n"
        + "├──○ 8: 2[8, 9] -> [8]\n" + "├──○ 9: 2[9, 10] -> [9]\n" + "├──○ 10: 2[10, 11] -> [10]\n"
        + "├──○ 11: 2[11, 12] -> [11]\n" + "├──○ 12: 2[12, 13] -> [12]\n"
        + "├──○ 13: 2[13, 14] -> [13]\n" + "├──○ 14: 2[14, 15] -> [14]\n"
        + "├──○ 15: 2[15, 16] -> [15]\n" + "├──○ 16: 2[16, 17] -> [16]\n"
        + "├──○ 17: 2[17, 18] -> [17]\n" + "├──○ 18: 2[18, 19] -> [18]\n"
        + "├──○ 19: 2[19, 20] -> [19]\n" + "├──○ 20: 2[20, 21] -> [20]\n"
        + "├──○ 21: 2[21, 22] -> [21]\n" + "├──○ 22: 2[22, 23] -> [22]\n"
        + "├──○ 23: 2[23, 24] -> [23]\n" + "├──○ 25: 2[25, 26] -> [25]\n"
        + "├──○ 27: 2[27, 28] -> [27]\n" + "├──○ 29: 2[29, 30] -> [29]\n"
        + "├──○ 31: 2[31, 32] -> [31]\n" + "├──○ 33: 2[33, 34] -> [33]\n"
        + "├──○ 35: 2[35, 36] -> [35]\n" + "├──○ 37: 2[37, 38] -> [37]\n"
        + "├──○ 39: 2[39, 40] -> [39]\n" + "├──○ 41: 2[41, 42] -> [41]\n"
        + "├──○ 42: 2[42, 43] -> [42]\n" + "├──○ 43: 2[43, 44] -> [43]\n"
        + "├──○ 44: 2[44, 45] -> [44]\n" + "├──○ 45: 2[45, 46] -> [45]\n"
        + "├──○ 46: 2[46, 47] -> [46]\n" + "├──○ 47: 2[47, 48] -> [47]\n"
        + "└──○ 48: 2[48, 49] -> [48]")
  }
}
