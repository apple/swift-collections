//
//  RepeatingContainerTests.swift
//  swift-collections
//
//  Created by Karoy Lorentey on 2025-04-21.
//

import XCTest
import _CollectionsTestSupport
import Future

@available(SwiftStdlib 6.0, *)
class RigidArrayTests: CollectionTestCase {
  func test_validate_Container() {
    let c = 100

    withLifetimeTracking { tracker in
      let expected = (0 ..< c).map { tracker.instance(for: $0) }
      let items = RigidArray(count: c, initializedBy: { expected[$0] })
      checkContainer(items, expectedContents: expected)
    }
  }
}
