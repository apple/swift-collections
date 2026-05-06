//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
import XCTest
import ContainersPreview
import Synchronization

final class RefTests: XCTestCase {
  @available(SwiftStdlib 5.0, *)
  func test_optional() {
    let x: Atomic<Int>? = Atomic(42)

    if let y = x.borrow() {
      XCTAssertEqual(y[].load(ordering: .relaxed), 42)
    }
  }
}
#endif
