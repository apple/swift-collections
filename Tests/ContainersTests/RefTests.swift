//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_CONTAINERS_PREVIEW
import XCTest
import ContainersPreview
import Synchronization

final class RefTests: XCTestCase {
  @available(SwiftStdlib 5.0, *)
  func test_basic() {
    let x: Atomic<Int>? = Atomic(0)
    
    if let y = x.borrow() {
      XCTAssertEqual(y[].load(ordering: .relaxed), 0)
    }
  }
}
#endif
