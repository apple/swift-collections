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

#if DEBUG // These unit tests need access to PriorityQueueModule internals
import XCTest
@testable import PriorityQueueModule

class NodeTests: XCTestCase {
  func test_levelCalculation() {
    // Check alternating min and max levels in the heap
    var isMin = true
    for exp in 0...12 {
      // Check [2^exp, 2^(exp + 1))
      for offset in Int(pow(2, Double(exp)) - 1)..<Int(pow(2, Double(exp + 1)) - 1) {
        let node = _Node(offset: offset)
        XCTAssertEqual(node.isMinLevel, isMin)
      }
      isMin.toggle()
    }
  }
}
#endif // DEBUG
