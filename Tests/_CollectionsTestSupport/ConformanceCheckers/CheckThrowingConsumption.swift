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

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import BasicContainers
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview
private enum ConsumingOperation: String, CaseIterable {
  case reduce = "`reduce(_:_:)`"
  case reduceInto = "`reduce(into:_:)`"
  case mapGenerate = "`map(_:)` with `generate(into:)`"
  case mapNext = "`map(_:)` with `next()`"
}

private struct ClosureError: Error, Equatable {}

private final class PinningTracker: LifetimeTracker {
  var pinned: [LifetimeTracked<Int>] = []

  override func instance<Payload>(
    for payload: Payload
  ) -> LifetimeTracked<Payload> {
    let item = super.instance(for: payload)
    if let item = item as? LifetimeTracked<Int> {
      _ = unsafe Unmanaged.passRetained(item).retain()
      pinned.append(item)
    }
    return item
  }

  override func instances<S: Sequence>(
    for items: S
  ) -> [LifetimeTracked<S.Element>] {
    items.map(instance(for:))
  }

  func unpin() -> (destroyedAgain: [Int], leaked: [Int]) {
    var pinned = self.pinned
    self.pinned = []
    var result: (destroyedAgain: [Int], leaked: [Int]) = ([], [])
    for i in pinned.indices {
      var pins = 2
      while pins > 0, !isKnownUniquelyReferenced(&pinned[i]) {
        unsafe Unmanaged.passUnretained(pinned[i]).release()
        pins -= 1
      }
      if pins > 0 {
        result.destroyedAgain.append(pinned[i].payload)
      } else if !isKnownUniquelyReferenced(&pinned[i]) {
        result.leaked.append(pinned[i].payload)
      }
    }
    return result
  }
}

private final class ThrowingClosure<Failure: Error> {
  let offset: Int
  let error: Failure
  var visited: [Int] = []
  var threw = false
  var calledAfterThrowing = false
  var generatedIntoFullTarget = false

  init(throwingAt offset: Int, error: Failure) {
    self.offset = offset
    self.error = error
  }

  func callAsFunction(_ item: borrowing LifetimeTracked<Int>) throws(Failure) {
    calledAfterThrowing = calledAfterThrowing || threw
    visited.append(item.payload)
    guard visited.count <= offset else {
      threw = true
      throw error
    }
  }
}

@available(SwiftStdlib 6.4, *)
private struct ObservedProducer<Base: Producer & ~Copyable & ~Escapable>
: ~Copyable, ~Escapable {
  var base: Base
  let closure: ThrowingClosure<Base.Failure>

  @_lifetime(copy base)
  init(_ base: consuming Base, closure: ThrowingClosure<Base.Failure>) {
    self.base = base
    self.closure = closure
  }
}

@available(SwiftStdlib 6.4, *)
extension ObservedProducer: Producer where Base: ~Copyable & ~Escapable {
  typealias Element = Base.Element
  typealias Failure = Base.Failure

  @discardableResult
  @_lifetime(target: copy target)
  mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Failure) -> Int {
    guard !target.isFull else {
      closure.generatedIntoFullTarget = true
      return 0
    }
    return try base.generate(into: &target)
  }

  mutating func next() throws(Failure) -> Element? {
    try base.next()
  }
}

@available(SwiftStdlib 6.4, *)
private func generateAll<P: Producer & ~Copyable & ~Escapable>(
  _ producer: consuming P,
  capacity: Int
) throws(P.Failure) -> [Int] where P.Element == LifetimeTracked<Int> {
  var producer = producer
  var items = RigidArray<LifetimeTracked<Int>>(capacity: capacity)
  try items.append(addingCount: capacity) { target throws(P.Failure) in
    while !target.isFull, try producer.generate(into: &target) > 0 {}
  }
  return (0 ..< items.count).map { items[$0].payload }
}

@available(SwiftStdlib 6.4, *)
private func nextAll<P: Producer & ~Copyable & ~Escapable>(
  _ producer: consuming P
) throws(P.Failure) -> [Int] where P.Element == LifetimeTracked<Int> {
  var producer = producer
  var items: [Int] = []
  while let item = try producer.next() {
    items.append(item.payload)
  }
  return items
}

@available(SwiftStdlib 6.4, *)
private func checkConsumption<
  P: ~Copyable & ~Escapable,
  Failure: Error & Equatable
>(
  expectedContents: [Int],
  throwsAtEnd: Bool,
  error: Failure,
  file: StaticString,
  line: UInt,
  withProducer: (LifetimeTracker, (consuming P) -> Void) -> Void,
  consume: @escaping (
    ConsumingOperation, consuming P, ThrowingClosure<Failure>
  ) throws(Failure) -> [Int]
) {
  let entry = TestContext.current.push(
    "checkThrowingConsumption", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  let count = expectedContents.count

  func check(
    _ operation: ConsumingOperation,
    throwingAt offset: Int
  ) throws(ValidationError) {
    let name = operation.rawValue
    let tracker = PinningTracker()
    let closure = ThrowingClosure(throwingAt: offset, error: error)
    var result: [Int]? = nil
    var thrown: Failure? = nil
    withProducer(tracker) { producer in
      do throws(Failure) {
        result = try consume(operation, producer, closure)
      } catch {
        thrown = error
      }
    }
    let (destroyedAgain, leaked) = tracker.unpin()
    let throwingOffset: Any = offset < count ? offset : "none"

    guard !closure.calledAfterThrowing else {
      throw ValidationError(
        "\(name) must not call its closure again after it throws",
        ["throwing offset": throwingOffset,
         "visited": closure.visited])
    }
    guard !closure.generatedIntoFullTarget else {
      throw ValidationError(
        "\(name) must not call `generate(into:)` with a full target",
        ["throwing offset": throwingOffset])
    }
    let expected = Array(expectedContents.prefix(offset + 1))
    guard
      expected.starts(with: closure.visited),
      throwsAtEnd || closure.visited.count == expected.count
    else {
      throw ValidationError(
        "\(name) must pass the items to its closure in order, until it throws",
        ["throwing offset": throwingOffset,
         "expected": expected,
         "actual": closure.visited])
    }
    if closure.threw {
      guard thrown == error else {
        throw ValidationError(
          "\(name) must rethrow the error thrown by its closure",
          ["throwing offset": throwingOffset,
           "thrown": thrown as Any])
      }
    } else if throwsAtEnd {
      guard let thrown, thrown != error else {
        throw ValidationError(
          "\(name) must rethrow the error thrown by the producer",
          ["throwing offset": throwingOffset])
      }
    } else {
      guard let result else {
        throw ValidationError(
          "\(name) must not throw unless its closure or the producer throws")
      }
      guard result == expectedContents else {
        throw ValidationError(
          "\(name) must return the results of its closure",
          ["expected": expectedContents,
           "actual": result])
      }
    }
    guard destroyedAgain.isEmpty, leaked.isEmpty else {
      throw ValidationError(
        "\(name) must destroy every item exactly once",
        ["throwing offset": throwingOffset,
         "destroyed more than once": destroyedAgain,
         "leaked": leaked])
    }
  }

  for operation in ConsumingOperation.allCases {
    do throws(ValidationError) {
      for offset in 0 ... count {
        try check(operation, throwingAt: offset)
      }
    } catch {
      expectFailure(error.message, file: file, line: line)
    }
  }
}

/// Test that the operations that pass the items of a `Producer` to a closure
/// obey the following law when the closure throws `error` on the item at a
/// given offset, for every offset in `0 ... expectedContents.count` (the last
/// one meaning that the closure never throws):
///
/// - The closure is called on the items in `expectedContents`, in order, up to
///   and including the one it throws on, and never again.
/// - The operation rethrows the closure's error, or, if the closure never
///   throws, returns the results of all its calls.
/// - The operation never calls `generate(into:)` with a full target.
/// - Once the producer and its source are destroyed, every item created for
///   the producer has been destroyed exactly once, including items generated
///   but not yet passed to the closure, and items still inside the producer.
///
/// The operations are `reduce(_:_:)`, `reduce(into:_:)`, and `map(_:)`
/// followed by calls to `generate(into:)` or to `next()` until the end.
///
/// If `throwsAtEnd` is true, generating the item after `expectedContents`
/// throws an error other than `error` instead. The operation must then rethrow
/// that error if the closure never throws, but the closure may be called on
/// fewer items, as the operation may discard the items generated by the call
/// that threw.
///
/// `withProducer` must pass a new producer generating `expectedContents` to
/// its second argument, creating its items with the `instance(for:)` or
/// `instances(for:)` method of the given tracker.
@available(SwiftStdlib 6.4, *)
package func checkThrowingConsumption<P: Producer & ~Copyable & ~Escapable>(
  expectedContents: [Int],
  throwsAtEnd: Bool = false,
  error: P.Failure,
  file: StaticString = #filePath,
  line: UInt = #line,
  withProducer: (LifetimeTracker, (consuming P) -> Void) -> Void
) where P.Element == LifetimeTracked<Int>, P.Failure: Equatable {
  checkConsumption(
    expectedContents: expectedContents,
    throwsAtEnd: throwsAtEnd,
    error: error,
    file: file,
    line: line,
    withProducer: withProducer
  ) { operation, producer, closure throws(P.Failure) in
    let producer = ObservedProducer(producer, closure: closure)
    switch operation {
    case .reduce:
      return try producer.reduce([]) { result, item throws(P.Failure) in
        try closure(item)
        return result + [item.payload]
      }
    case .reduceInto:
      return try producer.reduce(into: []) { result, item throws(P.Failure) in
        try closure(item)
        result.append(item.payload)
      }
    case .mapGenerate:
      return try generateAll(
        producer.map { item throws(P.Failure) in
          try closure(item)
          return item
        },
        capacity: expectedContents.count + 1)
    case .mapNext:
      return try nextAll(
        producer.map { item throws(P.Failure) in
          try closure(item)
          return item
        })
    }
  }
}

/// Test that the `Drain` variants of `reduce(_:_:)`, `reduce(into:_:)`, and
/// `map(_:)` followed by calls to `generate(into:)` or to `next()` until the
/// end obey the law that the `Producer` variant of `checkThrowingConsumption`
/// checks, except for the clause about full targets.
///
/// `withDrain` must pass a new drain over `expectedContents` to its second
/// argument, creating its items with the `instance(for:)` or
/// `instances(for:)` method of the given tracker.
@available(SwiftStdlib 6.4, *)
package func checkThrowingConsumption<D: Drain & ~Copyable & ~Escapable>(
  expectedContents: [Int],
  file: StaticString = #filePath,
  line: UInt = #line,
  withDrain: (LifetimeTracker, (consuming D) -> Void) -> Void
) where D.Element == LifetimeTracked<Int> {
  checkConsumption(
    expectedContents: expectedContents,
    throwsAtEnd: false,
    error: ClosureError(),
    file: file,
    line: line,
    withProducer: withDrain
  ) { operation, drain, closure throws(ClosureError) in
    switch operation {
    case .reduce:
      return try drain.reduce([]) { result, item throws(ClosureError) in
        try closure(item)
        return result + [item.payload]
      }
    case .reduceInto:
      return try drain.reduce(into: []) { result, item throws(ClosureError) in
        try closure(item)
        result.append(item.payload)
      }
    case .mapGenerate:
      return try generateAll(
        drain.map { item throws(ClosureError) in
          try closure(item)
          return copy item
        },
        capacity: expectedContents.count + 1)
    case .mapNext:
      return try nextAll(
        drain.map { item throws(ClosureError) in
          try closure(item)
          return copy item
        })
    }
  }
}
#endif
