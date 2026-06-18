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
extension IterableIteratorProtocol_
where
  Self: ~Copyable & ~Escapable,
  Element_: ~Copyable
{
  @inlinable
  @_lifetime(copy self)
  public consuming func mapError<NewFailure: Error>(
    _ transform: @escaping (Failure_) -> NewFailure
  ) -> ErrorMappedIterator<Self, NewFailure> {
    ErrorMappedIterator(base: self, transform: transform)
  }

  @inlinable
  @_lifetime(copy self)
  public consuming func mapError<NewFailure: Error>(
    to error: NewFailure.Type = NewFailure.self
  ) -> ErrorMappedIterator<Self, NewFailure>
  where Failure_ == Never {
    ErrorMappedIterator(base: self, transform: { _ in
      fatalError("Unreachable")
    })
  }
}

@frozen
public struct ErrorMappedIterator<
  Base: IterableIteratorProtocol_ & ~Copyable & ~Escapable,
  Failure: Error
>: ~Copyable, ~Escapable
where Base.Element_: ~Copyable {
  @usableFromInline
  internal let _transform: (Base.Failure_) -> Failure

  @usableFromInline
  internal var _base: Base

  @inlinable
  @_lifetime(copy base)
  public init(
    base: consuming Base,
    transform: @escaping (Base.Failure_) -> Failure
  ) {
    self._base = base
    self._transform = transform
  }
}

extension ErrorMappedIterator: IterableIteratorProtocol_
where
  Base: ~Copyable & ~Escapable,
  Base.Element_: ~Copyable
{
  public typealias Element_ = Base.Element_
  public typealias Failure_ = Failure

  @inlinable
  @_lifetime(&self)
  @_lifetime(self: copy self)
  public mutating func nextSpan_(maximumCount: Int) throws(Failure_) -> Span<Element_> {
    do {
      return try _base.nextSpan_(maximumCount: maximumCount)
    } catch {
      throw _transform(error)
    }
  }

  @inlinable
  @_lifetime(self: copy self)
  public mutating func skip_(by maximumOffset: Int) throws(Failure_) -> Int {
    do {
      return try _base.skip_(by: maximumOffset)
    } catch {
      throw _transform(error)
    }
  }
}

#endif
