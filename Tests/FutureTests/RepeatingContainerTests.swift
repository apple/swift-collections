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
