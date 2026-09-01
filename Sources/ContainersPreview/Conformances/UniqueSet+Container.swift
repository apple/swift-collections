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

#if !COLLECTIONS_SINGLE_MODULE
import BasicContainers
import SpanPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension UniqueSet: Container where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: inout BorrowingIterator) -> Index {
    _storage.currentIndex(of: &iterator)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(
    from start: Index, to end: Index
  ) -> BorrowingIterator {
    _storage.makeBorrowingIterator(from: start, to: end)
  }
}

#if false // FIXME
@available(SwiftStdlib 5.0, *)
extension UniqueSet: DrainableContainer where Element: ~Copyable {
  public struct SubrangeConsumer: ~Copyable & ~Escapable {
    //...
  }

  public func consume(_ subrange: Range<Index>) -> SubrangeConsumer {
    //...
  }
}
#endif

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public init<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    minimumCapacity: Int? = nil, from producer: inout P
  ) throws(E)
  where P.Element: ~Copyable
  {
    let c = producer.underestimatedCount
    if let minimumCapacity {
      self.init(minimumCapacity: Swift.min(minimumCapacity, c))
    } else {
      self.init(minimumCapacity: c)
    }
    try self.insert(from: &producer)
  }

  @_alwaysEmitIntoClient
  public mutating func insert<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    from producer: inout P
  ) throws(E)
  where P.Element: ~Copyable
  {
    var done = false
    while !done {
      _ensureFreeCapacity(Swift.max(producer.underestimatedCount, 1))
      try self.insert(addingCount: self.freeCapacity) { target throws(E) in
        while !target.isFull, !done {
          done = try !producer.generate(into: &target)
        }
      }
    }
  }

  @_alwaysEmitIntoClient
  public mutating func insert<
    D: Drain<Element> & ~Copyable & ~Escapable
  >(
    from drain: inout D
  ) {
    while true {
      var span = drain.drainNext()
      guard !span.isEmpty else { break }
      while let next = span.popFirst() {
        self.insert(next)
      }
    }
  }
}

#endif
