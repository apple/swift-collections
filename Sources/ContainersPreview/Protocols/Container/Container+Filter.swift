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
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 6.4, *)
extension Container where Self: ~Copyable /*& ~Escapable*/, Element: ~Copyable {
  @_lifetime(borrow self)
  public func _filter(
    _ isIncluded: @escaping (borrowing Element) -> Bool
  ) -> ContainerFilter<Self> {
    ContainerFilter(_base: self, isIncluded: isIncluded)
  }
}

@available(SwiftStdlib 6.4, *)
extension ContainerIterator where Base.Element: ~Copyable {
  @_lifetime(copy self)
  public func filter(
    _ isIncluded: @escaping (borrowing Element_) -> Bool
  ) -> ContainerFilter<Base> {
    ContainerFilter(_base: _base, index: _position, isIncluded: isIncluded)
  }
}

@available(SwiftStdlib 6.4, *)
public struct ContainerFilter<
  Base: Container & ~Copyable/* FIXME & ~Escapable */
>: ~Copyable, ~Escapable
where Base.Element: ~Copyable
{
  public typealias Element = Base.Element

  @_alwaysEmitIntoClient
  public let _isIncluded: (borrowing Element) -> Bool

  @_alwaysEmitIntoClient
  public let _base: Borrow<Base> // FIXME: This does not allow escapable Bases

  @_alwaysEmitIntoClient
  public var _position: Base.Index

  @_alwaysEmitIntoClient
  public var _remainder: Span<Element>

  @inlinable
  @_lifetime(copy _base)
  internal init(
    _base: Borrow<Base>,
    index: Base.Index,
    isIncluded: @escaping (borrowing Element) -> Bool
  ) {
    self._isIncluded = isIncluded
    self._base = _base
    self._position = index
    self._remainder = .init()
  }

  @inlinable
  @_lifetime(borrow _base)
  internal init(
    _base: borrowing Base,
    isIncluded: @escaping (borrowing Element) -> Bool
  ) {
    self._isIncluded = isIncluded
    self._base = Borrow(_base)
    self._position = _base.startIndex
    self._remainder = .init()
  }
}

// FIXME: Sendable

@available(SwiftStdlib 6.4, *)
extension ContainerFilter: BorrowingIteratorProtocol where Element: ~Copyable {
  @_lifetime(copy self)
  public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
    precondition(maximumCount > 0)
    while true {
      // Drop filtered out items from prefix of _remainder
      var i = 0
      while i < _remainder.count, !_isIncluded(_remainder[unchecked: i]) {
        i &+= 1
      }
      _remainder = _remainder.extracting(droppingFirst: i)
      // Return maximal
      if !_remainder.isEmpty {
        let c = Swift.min(_remainder.count, maximumCount)
        i = 1
        while i < c, _isIncluded(_remainder[unchecked: i]) {
          i &+= 1
        }
        return _remainder._trim(first: i)
      }
      _remainder = _base.value.nextSpan(after: &_position)
      if _remainder.isEmpty { return .init() }
    }
  }
}

#endif
