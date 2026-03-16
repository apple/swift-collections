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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension Drain where Self: ~Copyable & ~Escapable {
  @inlinable
  @_lifetime(copy self)
  public consuming func map<E: Error, T: ~Copyable>(
    _ transform: @escaping (borrowing Element) throws(E) -> T
  ) throws(E) -> DrainMapProducer<Self, T, E> {
    DrainMapProducer(_base: self, transform: transform)
  }
}

@available(SwiftStdlib 5.0, *)
public struct DrainMapProducer<
  Base: Drain & ~Copyable & ~Escapable,
  Element: ~Copyable,
  ProducerError: Error
>: ~Copyable, ~Escapable {
  @_alwaysEmitIntoClient
  public let _transform: (consuming Base.Element) throws(ProducerError) -> Element

  @_alwaysEmitIntoClient
  public var _base: Base

  @inlinable
  @_lifetime(copy _base)
  internal init(
    _base: consuming Base,
    transform: @escaping (consuming Base.Element) throws(ProducerError) -> Element
  ) {
    self._base = _base
    self._transform = transform
  }
}

@available(SwiftStdlib 5.0, *)
extension DrainMapProducer
where
  Base: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @inlinable
  public var underestimatedCount: Int {
    _base.underestimatedCount
  }

  @inlinable
  public mutating func next() throws(ProducerError) -> Element? {
    guard let next = _base.next() else { return nil }
    return try _transform(next)
  }

  @inlinable
  @discardableResult
  @_lifetime(target: copy target)
  @_lifetime(self: copy self)
  public mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Error) -> Bool {
    var success = false
    while !target.isFull {
      var source = _base.drainNext(maximumCount: target.freeCapacity)
      if source.isEmpty { break }
      success = true
      while !source.isEmpty {
        try target.append(_transform(source.removeFirst()))
      }
    }
    return success
  }
}

#endif
