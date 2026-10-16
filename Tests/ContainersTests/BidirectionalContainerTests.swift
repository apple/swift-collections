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

import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import BasicContainers
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
final class BidirectionalContainerTests: CollectionTestCase {
  func test_validate_BidirectionalContainer() {
    withEvery("count", in: [0, 1, 2, 10]) { count in
      withLifetimeTracking { tracker in
        let expected = tracker.instances(for: 0 ..< count)
        let items = MinimalBidirectionalContainer(RigidArray(copying: expected))
        checkBidirectionalContainer(items, expectedContents: expected)
      }
    }
  }
}
#endif
