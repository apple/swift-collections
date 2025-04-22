//
//  RepeatingContainerTests.swift
//  swift-collections
//
//  Created by Karoy Lorentey on 2025-04-21.
//

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
