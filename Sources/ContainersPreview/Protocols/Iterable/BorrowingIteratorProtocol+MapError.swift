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

@available(SwiftStdlib 6.4, *)
extension BorrowingIteratorProtocol
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @inlinable
  @_lifetime(copy self)
  public consuming func mapError<NewFailure: Error>(
    _ transform: @escaping (Failure) -> NewFailure
  ) -> ErrorMappedIterator<Self, NewFailure> {
    ErrorMappedIterator(base: self, transform: transform)
  }

  @inlinable
  @_lifetime(copy self)
  public consuming func mapError<NewFailure: Error>(
    to error: NewFailure.Type = NewFailure.self
  ) -> ErrorMappedIterator<Self, NewFailure>
  where Failure == Never {
    ErrorMappedIterator(base: self, transform: { _ in
      fatalError("Unreachable")
    })
  }
}

@available(SwiftStdlib 6.4, *)
@frozen
public struct ErrorMappedIterator<
  Base: BorrowingIteratorProtocol & ~Copyable & ~Escapable,
  Failure: Error
>: ~Copyable, ~Escapable
where Base.Element: ~Copyable {
  @usableFromInline
  internal let _transform: (Base.Failure) -> Failure

  @usableFromInline
  internal var _base: Base

  @inlinable
  @_lifetime(copy base)
  public init(
    base: consuming Base,
    transform: @escaping (Base.Failure) -> Failure
  ) {
    self._base = base
    self._transform = transform
  }
}

@available(SwiftStdlib 6.4, *)
extension ErrorMappedIterator: BorrowingIteratorProtocol
where
  Base: ~Copyable & ~Escapable,
  Base.Element: ~Copyable
{
  public typealias Element = Base.Element
  public typealias Failure = Failure

  @inlinable
  @_lifetime(&self)
  @_lifetime(self: copy self)
  public mutating func nextSpan(maxCount: Int) throws(Failure) -> Span<Element> {
    do {
      return try _base.nextSpan(maxCount: maxCount)
    } catch {
      throw _transform(error)
    }
  }

  @inlinable
  @_lifetime(self: copy self)
  public mutating func skip(by maximumOffset: Int) throws(Failure) -> Int {
    do {
      return try _base.skip(by: maximumOffset)
    } catch {
      throw _transform(error)
    }
  }
}

#endif
