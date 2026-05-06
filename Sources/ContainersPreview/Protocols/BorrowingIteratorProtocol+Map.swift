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
extension BorrowingIteratorProtocol_
where
  Self: ~Copyable & ~Escapable,
  Element_: ~Copyable
{
  @inlinable
  @_lifetime(copy self)
  public consuming func map<E: Error, T: ~Copyable>(
    _ transform: @escaping (borrowing Element_) throws(E) -> T
  ) throws(E) -> BorrowingMapProducer<Self, T, E> {
    BorrowingMapProducer(_base: self, transform: transform)
  }
}

@available(SwiftStdlib 5.0, *)
public struct BorrowingMapProducer<
  Base: BorrowingIteratorProtocol_ & ~Copyable & ~Escapable,
  Element: ~Copyable,
  Error: Swift.Error
>: ~Copyable, ~Escapable {
  @_alwaysEmitIntoClient
  public let _transform: (borrowing Base.Element_) throws(Error) -> Element

  @_alwaysEmitIntoClient
  public var _it: Base

  @inlinable
  @_lifetime(copy _base)
  internal init(
    _base: consuming Base,
    transform: @escaping (borrowing Base.Element_) throws(Error) -> Element
  ) {
    self._transform = transform
    self._it = _base
  }
}

// FIXME: Sendable

@available(SwiftStdlib 5.0, *)
extension BorrowingMapProducer: Producer
where
  Base: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  public typealias Failure = Error

  @inlinable
  public var underestimatedCount: Int {
    0 // FIXME
  }

  @inlinable
  public mutating func next() throws(Failure) -> Element? {
    let span = _it.nextSpan_(maximumCount: 1)
    guard !span.isEmpty else { return nil }
    return try _transform(span[unchecked: 0])
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
      let span = _it.nextSpan_(maximumCount: target.freeCapacity)
      guard !span.isEmpty else { break }
      success = true
      var i = 0
      while i < span.count {
        try target.append(_transform(span[unchecked: i]))
        i &+= 1
      }
    }
    return success
  }
}

#endif
