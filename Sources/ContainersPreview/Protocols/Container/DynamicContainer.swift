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

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 5.0, *)
public protocol DynamicContainer<Element>: RangeReplaceableContainer, ~Copyable
where Element: ~Copyable
{
  init()
  init(minimumCapacity: Int)

  mutating func reserveCapacity(_ minimumCapacity: Int)

  /// The number of items that can be added to the container without forcing
  /// it to allocate extra storage. This is primarily intended to serve as a
  /// hint for the batch size of appends, to allow bulk operation even if
  /// the number of items to be appended is not known in advance.
  ///
  /// If the container does not have simple, predictable allocation behavior,
  /// then this should return the size of the container's primitive allocation
  /// unit. For example, in a balanced rope that organizes its contents into a
  /// tree of fixed-capacity nodes, it may be a good choice to use the maximum
  /// node size as the (constant) free capacity, even though it may not
  /// correlate exactly with actual allocation behavior.
  ///
  /// If a container always reports a free capacity of 0, then appending a
  /// sequence of items of an unknown size may run slower than expected.
  ///
  /// - Complexity: O(1)
  var freeCapacity: Int { get }
}

@available(SwiftStdlib 5.0, *)
extension DynamicContainer where Self: ~Copyable, Element: ~Copyable {
  @_alwaysEmitIntoClient
  public init() {
    self.init(minimumCapacity: 0)
  }

  @_alwaysEmitIntoClient
  public init<E: Error>(
    minimumCapacity: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init(minimumCapacity: minimumCapacity)
    try self.append(addingCount: minimumCapacity, initializingWith: initializer)
  }

  @_alwaysEmitIntoClient
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

  @_alwaysEmitIntoClient
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
      if c > 0 {
        try self.append(addingCount: c) { target throws(E) in
          while !target.isFull {
            guard try producer.generate(into: &target) else { return }
          }
        }
      }
      // Nudge the container to resize itself, hopefully providing more
      // `freeCapacity` in the next iteration. Doing this separately avoids
      // forcing the container to unnecessarily reallocate itself when the
      // producer is already complete.
      //
      // In exchange, when neither the producer nor the container provides
      // a nonzero count/capacity, then every single item will be added
      // individually, resulting in appending all items one by one, but with
      // additional overhead spent on the repeared property invocations.
      guard let next = try producer.next() else { return }
      self.append(next)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension DynamicContainer where Self: ~Copyable, Element: Copyable {
  @_alwaysEmitIntoClient
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
