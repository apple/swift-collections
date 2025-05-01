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

import XCTest
import _CollectionsTestSupport
import Future

#if false
@available(SwiftStdlib 6.0, *)
class RepeatingContainerTests: CollectionTestCase {
  func test_10() {
    withLifetimeTracking { tracker in
      let a = tracker.instance(for: 42)
      
      let items = RepeatingContainer(repeating: a, count: 10)
      let expected = [a, a, a, a, a, a, a, a, a, a]
      checkContainer(items, expectedContents: expected)
    }
  }
}
#endif
