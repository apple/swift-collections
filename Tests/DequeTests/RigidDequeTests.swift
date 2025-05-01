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

#if COLLECTIONS_SINGLE_MODULE
@_spi(Testing) import Collections
#else
import _CollectionsTestSupport
@_spi(Testing) import DequeModule
import Future
#endif

#if false // FIXME: Debug compiler crash
@available(SwiftStdlib 6.0, *)
class RigidDequeTests: CollectionTestCase {
  func test_basic() {
    var deque = RigidDeque<Int>(capacity: 100)
    expectEqual(deque.count, 0)
  }

  func test_validate_Container() {
    let c = 100

    withEveryDeque("layout", ofCapacities: [c]) { layout in
      withLifetimeTracking { tracker in
        let deque = tracker.rigidDeque(with: layout)
        let contents = tracker.instances(for: 0 ..< layout.count)
        checkContainer(deque, expectedContents: contents)
      }
    }
  }
}
#endif
