//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import InternalCollectionsUtilities
import ContainersPreview
import BasicContainers
#endif

/// Tracks the life times of `LifetimeTracked` instances, providing a method
/// to validate checkpoints where no instances should exist.
///
/// - Note: `LifetimeTracker` is not designed for multithreaded use. Trying to
///     instantiate or deinitialize instances belonging to the same tracker
///     from multiple concurrent threads (or reentrantly) will lead to
///     exclusivity violations and therefore undefined behavior.
public class LifetimeTracker {
  @usableFromInline
  package var _instances = 0
  
  @usableFromInline
  package var _nextSerialNumber = 0

  public init() {}

  deinit {
    check()
  }
  
  @inlinable
  public var instances: Int { _instances }

  public func check(file: StaticString = #filePath, line: UInt = #line) {
    expectEqual(instances, 0,
                "Potential leak of \(instances) objects",
                file: file, line: line)
  }

  public func instance<Payload>(for payload: Payload) -> LifetimeTracked<Payload> {
    LifetimeTracked(payload, for: self)
  }

  public func structInstance<Payload: ~Copyable>(
    for payload: consuming Payload
  ) -> LifetimeTrackedStruct<Payload> {
    LifetimeTrackedStruct(payload, for: self)
  }

  public func instances<S: Sequence>(for items: S) -> [LifetimeTracked<S.Element>] {
    return items.map { LifetimeTracked($0, for: self) }
  }

#if compiler(>=6.2)
  @available(SwiftStdlib 5.0, *)
  public func structInstances<Element>(
    count: Int,
    generator: (Int) -> Element
  ) -> RigidArray<LifetimeTrackedStruct<Element>> {
    var i = 0
    return RigidArray<LifetimeTrackedStruct<Element>>(capacity: count) { span in
      while i < count, !span.isFull {
        span.append(LifetimeTrackedStruct(copying: generator(i), for: self))
        i += 1
      }
    }
  }
#endif

  public func instances<S: Sequence, T>(
    for items: S, by transform: (S.Element) -> T
  ) -> [LifetimeTracked<T>] {
    items.map { instance(for: transform($0)) }
  }
}

@inlinable
public func withLifetimeTracking<E: Error, R>(
  file: StaticString = #filePath,
  line: UInt = #line,
  _ body: (LifetimeTracker) throws(E) -> R
) throws(E) -> R {
  let tracker = LifetimeTracker()
  defer { tracker.check(file: file, line: line) }
  return try body(tracker)
}
