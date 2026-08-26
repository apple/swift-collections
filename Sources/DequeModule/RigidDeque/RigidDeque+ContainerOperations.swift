//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
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

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(after index: Int) -> Int { index + 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(before index: Int) -> Int { index - 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(after index: inout Int) { index += 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(before index: inout Int) { index -= 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(_ index: Int, offsetBy n: Int) -> Int {
    index + n
  }

  @_alwaysEmitIntoClient
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    index._advance(by: &n, limitedBy: limit)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Span<Element> {
    _checkValidIndex(index)
    let segment = self._handle.nextSegment(after: index)
    index &+= segment.count
    return _overrideLifetime(Span(_unsafeElements: segment), borrowing: self)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> Span<Element> {
    _checkValidIndex(index)
    _checkValidIndex(limit)
    precondition(maxCount > 0, "maxCount must be positive")
    let segment = self._handle.nextSegment(
      after: &index, maxCount: maxCount, limitedBy: limit)
    return _overrideLifetime(Span(_unsafeElements: segment), borrowing: self)
  }

  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int
  ) -> MutableSpan<Element> {
    _checkValidIndex(index)
    let segment = self._handle.nextSegment(after: index)
    index &+= segment.count
    return _overrideLifetime(
      MutableSpan(_unsafeElements: .init(mutating: segment)),
      mutating: &self)
  }

  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> MutableSpan<Element> {
    _checkValidIndex(index)
    _checkValidIndex(limit)
    precondition(maxCount > 0, "maxCount must be positive")
    let segment = self._handle.nextSegment(
      after: &index, maxCount: maxCount, limitedBy: limit)
    return _overrideLifetime(
      MutableSpan(_unsafeElements: .init(mutating: segment)),
      mutating: &self)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(before index: Index) -> (index: Index, distance: Int) {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    let r = self._handle.spanBoundary(before: index)
    return (r.offset, r.distance)
  }

  @_alwaysEmitIntoClient
  public func spanBoundary(
    before index: Index, maxDistance: Int, limitedBy limit: Index
  ) -> (index: Index, distance: Int) {
    precondition(index >= 0 && index <= count, "Index out of bounds")
    precondition(limit >= 0 && limit <= count, "Index out of bounds")
    precondition(maxDistance > 0, "maxDistance must be positive")
    let r = self._handle.spanBoundary(before: index, maxDistance: maxDistance, limitedBy: limit)
    return (r.offset, r.distance)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(before index: inout Int, maxCount: Int) -> Span<Element> {
    // FIXME: Remove this in favor of the BidirectionalContainer algorithm.
    _checkValidIndex(index)
    precondition(maxCount > 0, "maxCount must be positive")
    let segment = self._handle
      .previousSegment(before: index)
      ._extracting(last: maxCount)
    index &-= segment.count
    return _overrideLifetime(Span(_unsafeElements: segment), borrowing: self)
  }
}

#endif
