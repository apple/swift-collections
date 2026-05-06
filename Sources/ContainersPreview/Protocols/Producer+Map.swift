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
extension Producer where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_lifetime(copy self)
  public consuming func map<T: ~Copyable>(
    _ transform: @escaping (consuming Element) throws(Failure) -> T
  ) -> ConsumingMapProducer<Self, T> {
    ConsumingMapProducer(_base: self, transform: transform)
  }
}

@available(SwiftStdlib 5.0, *)
public struct ConsumingMapProducer<
  Base: Producer & ~Copyable & ~Escapable,
  Element: ~Copyable,
>: ~Copyable, ~Escapable
where Base.Element: ~Copyable
{
  public typealias Failure = Base.Failure

  @_alwaysEmitIntoClient
  public var _base: Base
  @_alwaysEmitIntoClient
  public let _transform: (consuming Base.Element) throws(Failure) -> Element

  @inlinable
  @_lifetime(copy _base)
  public init(
    _base: consuming Base,
    transform: @escaping (consuming Base.Element) throws(Failure) -> Element
  ) {
    self._base = _base
    self._transform = transform
  }
}


#if false // FIXME: This does not work with SuppressedAssociatedTypesWithDefaults
// error: Conditional conformance to 'Escapable' must explicitly state whether
// 'Base.Element' is required to conform to 'Escapable' or not
// (Even though it states exactly that.)
@available(SwiftStdlib 5.0, *)
extension ConsumingMapProducer: Escapable
where
  Element: ~Copyable,
  Base: ~Copyable,
  Base: Escapable,
  Base.Element: ~Copyable
{}
#endif

@available(SwiftStdlib 5.0, *)
extension ConsumingMapProducer: Producer where Base: ~Copyable & ~Escapable {

  @inlinable
  public var underestimatedCount: Int {
    _base.underestimatedCount
  }

  @inlinable
  public mutating func next() throws(Failure) -> Element? {
    guard let next = try _base.next() else { return nil }
    return try _transform(next)
  }

  @inlinable
  @discardableResult
  @_lifetime(target: copy target)
  @_lifetime(self: copy self)
  public mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Failure) -> Bool {
    let c = Swift.min(target.freeCapacity, _producerBufferSize)
    return try _withUnsafeTemporaryAllocation(
      of: Base.Element.self, capacity: c
    ) { buffer throws(Failure) in
      var outputSpan = OutputSpan(buffer: buffer, initializedCount: 0)
      let result = try _base.generate(into: &outputSpan)
      let c = outputSpan.finalize(for: buffer)
      for i in 0 ..< c {
        target.append(try _transform(buffer.moveElement(from: i)))
      }
      return result
    }
  }
}

#endif
