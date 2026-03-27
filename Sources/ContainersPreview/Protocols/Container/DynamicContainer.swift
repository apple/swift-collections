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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
public protocol DynamicContainer<Element>: RangeReplaceableContainer, ~Copyable
where Element: ~Copyable
{
  init()
  init(minimumCapacity: Int)

  mutating func reserveCapacity(_ minimumCapacity: Int)

  var freeCapacity: Int { get }
}

@available(SwiftStdlib 5.0, *)
extension DynamicContainer where Self: ~Copyable, Element: ~Copyable {
  @inlinable
  public init() {
    self.init(minimumCapacity: 0)
  }

  @inlinable
  public init<E: Error>(
    minimumCapacity: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init(minimumCapacity: minimumCapacity)
    try self.append(addingCount: minimumCapacity, initializingWith: initializer)
  }

  @inlinable
  public init<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    minimumCapacity: Int? = nil,
    from producer: consuming P
  ) throws(E)
  where P.Element: ~Copyable
  {
    self.init(minimumCapacity: minimumCapacity ?? producer.underestimatedCount)
    try self.append(from: producer)
  }

  @inlinable
  public mutating func append<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    from producer: consuming P
  ) throws(E)
  where P.Element: ~Copyable
  {
    while true {
      let c = Swift.max(producer.underestimatedCount, self.freeCapacity)
      try self.append(addingCount: c) { target throws(E) in
        while !target.isFull {
          guard try producer.generate(into: &target) else { return }
        }
      }
      // Nudge the container to resize itself, providing more `freeCapacity` in
      // the next iteration. Doing this separately avoids forcing the container
      // to unnecessarily reallocate itself when the producer is already
      // complete. (In exchange, we have to move a handful of items twice.)
      guard let next = try producer.next() else { return }
      self.append(next)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension DynamicContainer where Self: ~Copyable, Element: Copyable {
  @inlinable
  public init(repeating repeatedValue: Element, count: Int) {
    var c = count
    self.init(minimumCapacity: count) { target in
      c -= target.freeCapacity
      target.append(repeating: repeatedValue, count: target.freeCapacity)
    }
    precondition(c == 0, "Invalid DynamicContainer")
  }
}

#endif
