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
import Collections
#else
import _CollectionsTestSupport
import BasicContainers
#endif

struct ArrayLayout {
  var capacity: Int
  var count: Int

  init(capacity: Int, count: Int) {
    precondition(count >= 0 && count <= capacity)
    self.capacity = capacity
    self.count = count
  }
}

func withSomeArrayLayouts<E: Error>(
  _ label: String,
  ofCapacities capacities: some Sequence<Int>,
  file: StaticString = #filePath,
  line: UInt = #line,
  run body: (ArrayLayout) throws(E) -> Void
) throws(E) {
  let context = TestContext.current
  for capacity in capacities {
    var counts: Set<Int> = []
    counts.insert(0)
    counts.insert(capacity)
    counts.insert(capacity / 2)
    if capacity >= 1 {
      counts.insert(1)
      counts.insert(capacity - 1)
    }
    if capacity >= 2 {
      counts.insert(2)
      counts.insert(capacity - 2)
    }
    for count in counts {
      let layout = ArrayLayout(capacity: capacity, count: count)
      let entry = context.push("\(label): \(layout)", file: file, line: line)

      var done = false
      defer {
        context.pop(entry)
        if !done {
          print(context.currentTrace(title: "Throwing trace"))
        }
      }
      try body(layout)
      done = true
    }
  }
}

#if compiler(>=6.2)
extension RigidArray where Element: ~Copyable {
  init(layout: ArrayLayout, using generator: (Int) -> Element) {
    self.init(capacity: layout.capacity) { span in
      for i in 0 ..< layout.count {
        span.append(generator(i))
      }
    }
  }
}

extension UniqueArray where Element: ~Copyable {
  init(layout: ArrayLayout, using generator: (Int) -> Element) {
    self.init(consuming: RigidArray(layout: layout, using: generator))
  }
}

extension LifetimeTracker {
  func rigidArray<Element>(
    layout: ArrayLayout,
    using generator: (Int) -> Element = { $0 }
  ) -> RigidArray<LifetimeTracked<Element>> {
    RigidArray(layout: layout, using: { self.instance(for: generator($0)) })
  }

  func uniqueArray<Element>(
    layout: ArrayLayout,
    using generator: (Int) -> Element = { $0 }
  ) -> UniqueArray<LifetimeTracked<Element>> {
    let contents = RigidArray(layout: layout) {
      self.instance(for: generator($0))
    }
    return UniqueArray(consuming: contents)
  }
}
#endif
