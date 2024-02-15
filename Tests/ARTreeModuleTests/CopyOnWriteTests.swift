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

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import ARTreeModule
import _CollectionsTestSupport
#endif

@testable import ARTreeModule

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
final class ARTreeCopyOnWriteTests: CollectionTestCase {
  func testCopyOnWriteBasicInsert() throws {
    var t1 = ARTree<Int>()
    _ = t1.insert(key: [10, 20], value: 10)
    _ = t1.insert(key: [20, 30], value: 20)
    var t2 = t1
    _ = t2.insert(key: [30, 40], value: 30)
    _ = t2.insert(key: [40, 50], value: 40)

    expectEqual(
      t1.description,
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 10: 2[10, 20] -> 10\n" +
      "└──○ 20: 2[20, 30] -> 20")
    expectEqual(
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

    expectEqual(
      t1.description,
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 10: 2[10, 20] -> 10\n" +
      "└──○ 20: 2[20, 30] -> 20")
    expectEqual(
      t2.description,
      "○ Node4 {childs=4, partial=[]}\n" +
      "├──○ 10: 2[10, 20] -> 10\n" +
      "├──○ 20: 2[20, 30] -> 20\n" +
      "├──○ 30: 2[30, 40] -> 30\n" +
      "└──○ 40: 2[40, 50] -> 40")
    expectEqual(
      t3.description,
      "○ Node4 {childs=2, partial=[]}\n" +
      "├──○ 20: 2[20, 30] -> 20\n" +
      "└──○ 40: 2[40, 50] -> 40")
  }

  func testCopyOnWriteSharedPrefixInsert() throws {
    var t1 = ARTree<Int>()
    _ = t1.insert(key: [1, 2, 3, 4, 5], value: 1)
    _ = t1.insert(key: [2, 3, 4, 5, 6], value: 2)
    _ = t1.insert(key: [3, 4, 5, 6, 7], value: 3)
    _ = t1.insert(key: [4, 5, 6, 7, 8], value: 4)
    _ = t1.insert(key: [8, 9, 10, 12, 12], value: 5)
    _ = t1.insert(key: [1, 2, 3, 5, 6], value: 6)
    _ = t1.insert(key: [1, 2, 3, 6, 7], value: 7)
    _ = t1.insert(key: [2, 3, 5, 5, 6], value: 8)
    _ = t1.insert(key: [4, 5, 6, 8, 8], value: 9)
    _ = t1.insert(key: [4, 5, 6, 9, 9], value: 10)
    let t1_descp = "○ Node16 {childs=5, partial=[]}\n" +
                   "├──○ 1: Node4 {childs=3, partial=[2, 3]}\n" +
                   "│  ├──○ 4: 5[1, 2, 3, 4, 5] -> 1\n" +
                   "│  ├──○ 5: 5[1, 2, 3, 5, 6] -> 6\n" +
                   "│  └──○ 6: 5[1, 2, 3, 6, 7] -> 7\n" +
                   "├──○ 2: Node4 {childs=2, partial=[3]}\n" +
                   "│  ├──○ 4: 5[2, 3, 4, 5, 6] -> 2\n" +
                   "│  └──○ 5: 5[2, 3, 5, 5, 6] -> 8\n" +
                   "├──○ 3: 5[3, 4, 5, 6, 7] -> 3\n" +
                   "├──○ 4: Node4 {childs=3, partial=[5, 6]}\n" +
                   "│  ├──○ 7: 5[4, 5, 6, 7, 8] -> 4\n" +
                   "│  ├──○ 8: 5[4, 5, 6, 8, 8] -> 9\n" +
                   "│  └──○ 9: 5[4, 5, 6, 9, 9] -> 10\n" +
                   "└──○ 8: 5[8, 9, 10, 12, 12] -> 5"
    expectEqual(t1_descp, t1.description)

    var t2 = t1
    t2.insert(key: [5, 6, 7], value: 11)
    let t2_descp = "○ Node16 {childs=6, partial=[]}\n" +
                   "├──○ 1: Node4 {childs=3, partial=[2, 3]}\n" +
                   "│  ├──○ 4: 5[1, 2, 3, 4, 5] -> 1\n" +
                   "│  ├──○ 5: 5[1, 2, 3, 5, 6] -> 6\n" +
                   "│  └──○ 6: 5[1, 2, 3, 6, 7] -> 7\n" +
                   "├──○ 2: Node4 {childs=2, partial=[3]}\n" +
                   "│  ├──○ 4: 5[2, 3, 4, 5, 6] -> 2\n" +
                   "│  └──○ 5: 5[2, 3, 5, 5, 6] -> 8\n" +
                   "├──○ 3: 5[3, 4, 5, 6, 7] -> 3\n" +
                   "├──○ 4: Node4 {childs=3, partial=[5, 6]}\n" +
                   "│  ├──○ 7: 5[4, 5, 6, 7, 8] -> 4\n" +
                   "│  ├──○ 8: 5[4, 5, 6, 8, 8] -> 9\n" +
                   "│  └──○ 9: 5[4, 5, 6, 9, 9] -> 10\n" +
                   "├──○ 5: 3[5, 6, 7] -> 11\n" +
                   "└──○ 8: 5[8, 9, 10, 12, 12] -> 5"
    expectEqual(t1.description, t1_descp)
    expectEqual(t2.description, t2_descp)
    t2.delete(key: [2, 3, 4, 5, 6])
    let t2_descp_2 = "○ Node16 {childs=6, partial=[]}\n" +
                     "├──○ 1: Node4 {childs=3, partial=[2, 3]}\n" +
                     "│  ├──○ 4: 5[1, 2, 3, 4, 5] -> 1\n" +
                     "│  ├──○ 5: 5[1, 2, 3, 5, 6] -> 6\n" +
                     "│  └──○ 6: 5[1, 2, 3, 6, 7] -> 7\n" +
                     "├──○ 2: 5[2, 3, 5, 5, 6] -> 8\n" +
                     "├──○ 3: 5[3, 4, 5, 6, 7] -> 3\n" +
                     "├──○ 4: Node4 {childs=3, partial=[5, 6]}\n" +
                     "│  ├──○ 7: 5[4, 5, 6, 7, 8] -> 4\n" +
                     "│  ├──○ 8: 5[4, 5, 6, 8, 8] -> 9\n" +
                     "│  └──○ 9: 5[4, 5, 6, 9, 9] -> 10\n" +
                     "├──○ 5: 3[5, 6, 7] -> 11\n" +
                     "└──○ 8: 5[8, 9, 10, 12, 12] -> 5"
    expectEqual(t1.description, t1_descp)
    expectEqual(t2.description, t2_descp_2)

    var t3 = t2
    t3.insert(key: [3, 4, 7], value: 11)
    expectEqual(t1.description, t1_descp)
    expectEqual(t2.description, t2_descp_2)
    t3.delete(key: [1, 2, 3, 4, 5])
    t3.delete(key: [1, 2, 3, 6, 7])
    t3.insert(key: [5, 6, 8], value: 14)
    t3.insert(key: [8, 9, 10, 13, 14], value: 15)
    let t3_descp = "○ Node16 {childs=6, partial=[]}\n" +
                   "├──○ 1: 5[1, 2, 3, 5, 6] -> 6\n" +
                   "├──○ 2: 5[2, 3, 5, 5, 6] -> 8\n" +
                   "├──○ 3: Node4 {childs=2, partial=[4]}\n" +
                   "│  ├──○ 5: 5[3, 4, 5, 6, 7] -> 3\n" +
                   "│  └──○ 7: 3[3, 4, 7] -> 11\n" +
                   "├──○ 4: Node4 {childs=3, partial=[5, 6]}\n" +
                   "│  ├──○ 7: 5[4, 5, 6, 7, 8] -> 4\n" +
                   "│  ├──○ 8: 5[4, 5, 6, 8, 8] -> 9\n" +
                   "│  └──○ 9: 5[4, 5, 6, 9, 9] -> 10\n" +
                   "├──○ 5: Node4 {childs=2, partial=[6]}\n" +
                   "│  ├──○ 7: 3[5, 6, 7] -> 11\n" +
                   "│  └──○ 8: 3[5, 6, 8] -> 14\n" +
                   "└──○ 8: Node4 {childs=2, partial=[9, 10]}\n" +
                   "│  ├──○ 12: 5[8, 9, 10, 12, 12] -> 5\n" +
                   "│  └──○ 13: 5[8, 9, 10, 13, 14] -> 15"
    expectEqual(t1.description, t1_descp)
    expectEqual(t2.description, t2_descp_2)
    expectEqual(t3.description, t3_descp)
    t1.delete(key: [1, 2, 3, 4, 5])
    t1.delete(key: [2, 3, 4, 5, 6])
    t1.delete(key: [3, 4, 5, 6, 7])
    t1.delete(key: [4, 5, 6, 7, 8])
    t1.delete(key: [8, 9, 10, 12, 12])
    t1.delete(key: [1, 2, 3, 5, 6])
    t1.delete(key: [1, 2, 3, 6, 7])
    t1.delete(key: [2, 3, 5, 5, 6])
    t1.delete(key: [4, 5, 6, 8, 8])
    t1.delete(key: [4, 5, 6, 9, 9])
    expectEqual(t1.description, "<>")
    expectEqual(t2.description, t2_descp_2)
    expectEqual(t3.description, t3_descp)
  }

  func testCopyOnWriteReplaceValue() throws {
    var t1 = ARTree<Int>()
    let testCases: [[UInt8]] = [
      [1, 2, 3, 4, 5],
      [2, 3, 4, 5, 6],
      [3, 4, 5, 6, 7],
      [4, 5, 6, 7, 8],
      [8, 9, 10, 12, 12],
      [1, 2, 3, 5, 6],
      [1, 2, 3, 6, 7],
      [2, 3, 5, 5, 6],
      [4, 5, 6, 8, 8],
      [4, 5, 6, 9, 9]
    ]

    for (idx, test) in testCases.enumerated() {
        t1.insert(key: test, value: idx + 1)
    }
    var t2 = t1
    for (idx, test) in testCases[2...5].enumerated() {
        t2.insert(key: test, value: idx + 10)
    }

    let t1_descp = "○ Node16 {childs=5, partial=[]}\n" +
                   "├──○ 1: Node4 {childs=3, partial=[2, 3]}\n" +
                   "│  ├──○ 4: 5[1, 2, 3, 4, 5] -> 1\n" +
                   "│  ├──○ 5: 5[1, 2, 3, 5, 6] -> 6\n" +
                   "│  └──○ 6: 5[1, 2, 3, 6, 7] -> 7\n" +
                   "├──○ 2: Node4 {childs=2, partial=[3]}\n" +
                   "│  ├──○ 4: 5[2, 3, 4, 5, 6] -> 2\n" +
                   "│  └──○ 5: 5[2, 3, 5, 5, 6] -> 8\n" +
                   "├──○ 3: 5[3, 4, 5, 6, 7] -> 3\n" +
                   "├──○ 4: Node4 {childs=3, partial=[5, 6]}\n" +
                   "│  ├──○ 7: 5[4, 5, 6, 7, 8] -> 4\n" +
                   "│  ├──○ 8: 5[4, 5, 6, 8, 8] -> 9\n" +
                   "│  └──○ 9: 5[4, 5, 6, 9, 9] -> 10\n" +
                   "└──○ 8: 5[8, 9, 10, 12, 12] -> 5"
    let t2_descp = "○ Node16 {childs=5, partial=[]}\n" +
                   "├──○ 1: Node4 {childs=3, partial=[2, 3]}\n" +
                   "│  ├──○ 4: 5[1, 2, 3, 4, 5] -> 1\n" +
                   "│  ├──○ 5: 5[1, 2, 3, 5, 6] -> 13\n" +
                   "│  └──○ 6: 5[1, 2, 3, 6, 7] -> 7\n" +
                   "├──○ 2: Node4 {childs=2, partial=[3]}\n" +
                   "│  ├──○ 4: 5[2, 3, 4, 5, 6] -> 2\n" +
                   "│  └──○ 5: 5[2, 3, 5, 5, 6] -> 8\n" +
                   "├──○ 3: 5[3, 4, 5, 6, 7] -> 10\n" +
                   "├──○ 4: Node4 {childs=3, partial=[5, 6]}\n" +
                   "│  ├──○ 7: 5[4, 5, 6, 7, 8] -> 11\n" +
                   "│  ├──○ 8: 5[4, 5, 6, 8, 8] -> 9\n" +
                   "│  └──○ 9: 5[4, 5, 6, 9, 9] -> 10\n" +
                   "└──○ 8: 5[8, 9, 10, 12, 12] -> 12"
    expectEqual(t1.description, t1_descp)
    expectEqual(t2.description, t2_descp)
  }
}
