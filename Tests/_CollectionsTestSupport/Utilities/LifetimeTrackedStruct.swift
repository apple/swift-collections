//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
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
@frozen
public struct LifetimeTrackedStruct<Payload: ~Copyable>: ~Copyable {
  public let tracker: LifetimeTracker

  @usableFromInline
  internal var serialNumber: Int = 0

  public var payload: Payload

  @inlinable
  public init(_ payload: consuming Payload, for tracker: LifetimeTracker) {
    tracker._instances += 1
    tracker._nextSerialNumber += 1
    self.tracker = tracker
    self.serialNumber = tracker._nextSerialNumber
    self.payload = payload
  }

  public init(copying payload: Payload, for tracker: LifetimeTracker)
  where Payload: Copyable
  {
    tracker._instances += 1
    tracker._nextSerialNumber += 1
    self.tracker = tracker
    self.serialNumber = tracker._nextSerialNumber
    self.payload = payload
  }

  @inlinable
  deinit {
    precondition(serialNumber != 0, "Double deinit")
    tracker._instances -= 1
    // Can't mutate in deinit yet
    // serialNumber = -serialNumber
  }
}

#if compiler(>=6.2)
extension LifetimeTrackedStruct: TestPrintable where Payload: TestPrintable & ~Copyable {
  public var testDescription: String {
    return "\(payload.testDescription)"
  }
}
#endif

extension LifetimeTrackedStruct/*: Equatable*/ where Payload: Equatable /*& ~Copyable*/ {
  public static func == (left: borrowing Self, right: borrowing Self) -> Bool {
    return left.payload == right.payload
  }
}

extension LifetimeTrackedStruct/*: Hashable*/ where Payload: Hashable /*& ~Copyable*/ {
  public func _rawHashValue(seed: Int) -> Int {
    payload._rawHashValue(seed: seed)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(payload)
  }

  public var hashValue: Int {
    payload.hashValue
  }
}

extension LifetimeTrackedStruct/*: Comparable*/ where Payload: Comparable /*& ~Copyable*/ {
  public static func < (left: borrowing Self, right: borrowing Self) -> Bool {
    return left.payload < right.payload
  }
}

