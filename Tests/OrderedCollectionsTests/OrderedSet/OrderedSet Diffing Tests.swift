//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import OrderedCollections
import CollectionsTestSupport

class OrderedSetDiffingTests: CollectionTestCase {

  func _validate<T: Hashable>(from a: Array<T>, to b: Array<T>, mutations: Int? = nil) {
    let d = b.difference(from: a)
    let e = a.difference(from: b)
    expectEqual(d.count, e.count)
    if let mutations = mutations {
      expectEqual(d.count, mutations)
    }
    expectEqual(a.applying(d), b)
    expectEqual(b.applying(d.inverse()), a)
    expectEqual(a.applying(e.inverse()), b)
    expectEqual(b.applying(e), a)
  }

  func test_equal() {
    let a = [1, 2, 3, 4, 5]
    _validate(from: a, to: a, mutations: 0)
  }

  func test_moveTrap() {
    let a = [1, 2, 3]
    let b = [3, 2]
    _validate(from: a, to: b, mutations: 3)
  }

  func test_minimalish() {
    let a = ["g", "1", "2",      "w", "o", "a", "e", "t", "4",               "8"]
    let b = [     "1", "2", "3",                "e",      "4", "5", "6", "7"]
    _validate(from: a, to: b, mutations: 10)
  }

  func test_arrowDefeatingMinimalDiff() {
    // Arrow diff only finds one match ("n") instead of two ("o", "c")
    let a = [               "o", "c", "n"]
    let b = ["n", "d", "y", "o", "c"]
    _validate(from: a, to: b, mutations: 4)
  }

  func test_fuzzerDiscovered00() {
    //                  X     X        X
    let a = [3, 5, 8, 0, 7, 9]
    let b = [8, 5, 9, 7, 0, 6]
    //                     X        X  X
    _validate(from: a, to: b)
  }

  func test_fuzz() {
    for _ in 0..<1000 {
      let a = (0..<10).map { _ in Int.random(in: 0..<10) }
      let b = (0..<10).map { _ in Int.random(in: 0..<10) }
      _validate(from: a, to: b)
    }
  }
}
