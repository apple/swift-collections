//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A type that tracks the number of live instances.
///
/// `LifetimeTracked` is useful to check for leaks in algorithms and data
/// structures. The easiest way to produce instances is to use the
/// `withLifetimeTracking` function:
///
///      class FooTests: XCTestCase {
///        func testFoo() {
///          withLifetimeTracking([1, 2, 3]) { instances in
///            _ = instances.sorted(by: >)
///          }
///        }
///      }
public struct LifetimeTrackedStruct<Payload: ~Copyable>: ~Copyable {
  public let tracker: LifetimeTracker
  internal var serialNumber: Int = 0
  public var payload: Payload

  public init(_ payload: consuming Payload, for tracker: LifetimeTracker) {
    tracker.instances += 1
    tracker._nextSerialNumber += 1
    self.tracker = tracker
    self.serialNumber = tracker._nextSerialNumber
    self.payload = payload
  }

  deinit {
    precondition(serialNumber != 0, "Double deinit")
    tracker.instances -= 1
  }
}

