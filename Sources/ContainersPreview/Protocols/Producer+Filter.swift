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
extension Producer where Self: ~Copyable & ~Escapable {
  @_lifetime(copy self)
  public consuming func filter(
    // Note: The predicate is not throwing to avoid difficult exception safety problems
    _ isIncluded: @escaping (borrowing Element) -> Bool
  ) -> ConsumingFilterProducer<Self> {
    ConsumingFilterProducer(_base: self, isIncluded: isIncluded)
  }
}

@available(SwiftStdlib 5.0, *)
public struct ConsumingFilterProducer<
  Base: Producer & ~Copyable & ~Escapable
>: ~Copyable, ~Escapable {
  public typealias Element = Base.Element
  public typealias ProducerError = Base.ProducerError

  @_alwaysEmitIntoClient
  public var _base: Base
  @_alwaysEmitIntoClient
  public let _isIncluded: (borrowing Element) -> Bool

  @inlinable
  @_lifetime(copy _base)
  public init(
    _base: consuming Base,
    isIncluded: @escaping (borrowing Element) -> Bool
  ) {
    self._base = _base
    self._isIncluded = isIncluded
  }
}

@available(SwiftStdlib 5.0, *)
extension ConsumingFilterProducer: Escapable
where
  Base: ~Copyable,
  Base: Escapable
{}

@available(SwiftStdlib 5.0, *)
extension ConsumingFilterProducer: Producer where Base: ~Copyable & ~Escapable {

  @inlinable
  public var underestimatedCount: Int {
    _base.underestimatedCount
  }

  @inlinable
  public mutating func next() throws(ProducerError) -> Element? {
    while let next = try _base.next() {
      if _isIncluded(next) { return next }
    }
    return nil
  }

  @inlinable
  @discardableResult
  @_lifetime(target: copy target)
  @_lifetime(self: copy self)
  public mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(ProducerError) -> Bool {
    let startCount = target.count
    repeat {
      let prevCount = target.count
      defer {
        target._remove(from: prevCount, where: { !_isIncluded($0) })
      }
      guard try _base.generate(into: &target) else { break }
    } while target.count == startCount
    return target.count > startCount
  }
}

#endif
