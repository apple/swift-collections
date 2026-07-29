//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4) && UnstableContainersPreview

@_lifetime(copy state)
public func producer<
  State: ~Copyable & ~Escapable,
  Failure: Error,
  Element: ~Copyable
>(
  state: consuming State,
  next: @escaping (inout State) throws(Failure) -> Element?
) -> UnfoldProducer<State, Failure, Element> {
  .init(state: state, next: next)
}

@frozen
public struct UnfoldProducer<
  State: ~Copyable & ~Escapable,
  Failure: Error,
  Element: ~Copyable
>: ~Copyable, ~Escapable {
  @usableFromInline
  internal let _next: (inout State) throws(Failure) -> Element?

  @usableFromInline
  internal var _state: State

  @inlinable
  @_lifetime(copy state)
  public init(
    state: consuming State,
    next: @escaping (inout State) throws(Failure) -> Element?
  ) {
    self._next = next
    self._state = state
  }
}

extension UnfoldProducer: Producer
where
  State: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @inlinable
  public var underestimatedCount: Int { 0 }

  @inlinable
  @discardableResult
  @_lifetime(target: copy target)
  @_lifetime(self: copy self)
  public mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Failure) -> Bool {
    var c = 0
    while !target.isFull {
      guard let next = try _next(&self._state) else { break }
      target.append(next)
      c += 1
    }
    return c > 0
  }

  @inlinable
  @_lifetime(self: copy self)
  public mutating func next() throws(Failure) -> Element? {
    try _next(&_state)
  }
}

#endif
