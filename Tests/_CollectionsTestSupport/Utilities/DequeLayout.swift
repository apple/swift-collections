//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import InternalCollectionsUtilities
import DequeModule
#endif

public struct DequeLayout: Hashable, CustomStringConvertible {
  public let capacity: Int
  public let startSlot: Int
  public let count: Int
  public let startValue: Int

  public init(capacity: Int, startSlot: Int, count: Int, startValue: Int = 0) {
    self.capacity = capacity
    self.startSlot = startSlot
    self.count = count
    self.startValue = startValue
  }

  public var freeCapacity: Int { capacity - count }
  public var valueRange: Range<Int> { startValue ..< startValue + count }

  public var description: String {
    var result = "DequeLayout(capacity: \(capacity), startSlot: \(startSlot), count: \(count)"
    if count > 0 {
      result += ", startValue: \(startValue)"
    }
    result += ")"
    return result
  }

  public var isWrapped: Bool {
    startSlot + count > capacity
  }

  public var wrapIndex: Int? {
    isWrapped ? capacity - startSlot : nil
  }
}

public func withEveryDeque<C: Collection>(
  _ label: String,
  ofCapacities capacities: C,
  startValue: Int = 0,
  file: StaticString = #filePath, line: UInt = #line,
  _ body: (DequeLayout) throws -> Void
) rethrows -> Void where C.Element == Int {
  // Exhaustive tests for all deque layouts of various capacities
  for capacity in capacities {
    for startSlot in 0 ..< capacity {
      for count in 0 ... capacity {
        let layout = DequeLayout(
          capacity: capacity,
          startSlot: startSlot,
          count: count,
          startValue: startValue)
        let entry = TestContext.current.push("\(label): \(layout)", file: file, line: line)
        defer { TestContext.current.pop(entry) }
        try body(layout)
      }
    }
  }
}

public func withEveryFullDeque<C: Collection>(
  _ label: String,
  ofCapacities capacities: C,
  startValue: Int = 0,
  file: StaticString = #filePath, line: UInt = #line,
  _ body: (DequeLayout) throws -> Void
) rethrows -> Void where C.Element == Int {
  // Exhaustive tests for all deque layouts of various capacities
  for capacity in capacities {
    for startSlot in 0 ..< capacity {
      let layout = DequeLayout(
        capacity: capacity,
        startSlot: startSlot,
        count: capacity,
        startValue: startValue)
      let entry = TestContext.current.push("\(label): \(layout)", file: file, line: line)
      defer { TestContext.current.pop(entry) }
      try body(layout)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @inlinable
  public init(
    layout: DequeLayout,
    generator: (Int) -> Element
  ) {
    var offset = layout.startValue
    self.init(_capacity: layout.capacity, startSlot: layout.startSlot) { target in
      while !target.isFull, offset < layout.startValue + layout.count {
        target.append(generator(offset))
        offset += 1
      }
    }
    precondition(self.count == layout.count)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque<Int> {
  @inlinable
  public init(layout: DequeLayout) {
    var offset = layout.startValue
    self.init(_capacity: layout.capacity, startSlot: layout.startSlot) { target in
      while !target.isFull, offset < layout.startValue + layout.count {
        target.append(offset)
        offset += 1
      }
    }
    precondition(self.count == layout.count)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  @inlinable
  public init(
    layout: DequeLayout,
    generator: (Int) -> Element
  ) {
    self.init(consuming: RigidDeque(layout: layout, generator: generator))
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque<Int> {
  @inlinable
  public init(layout: DequeLayout) {
    self.init(consuming: RigidDeque(layout: layout))
  }
}
