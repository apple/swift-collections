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
import ContainersPreview
#endif

#if compiler(>=6.4) && UnstableHashedContainers && UnstableContainersPreview

@available(SwiftStdlib 5.0, *)
extension RigidSet: Iterable_ where Element: ~Copyable {
  public typealias Element_ = Element

  @inlinable
  public var underestimatedCount_: Int { count }
  
  @inlinable
  public func _customContainsEquatableElement_(
    _ element: borrowing Element
  ) -> Bool? {
    self.contains(element)
  }

  @inlinable
  @_lifetime(borrow self)
  public borrowing func makeIterableIterator_() -> IterableIterator_ {
    IterableIterator_(_set: self)
  }

  @frozen
  public struct IterableIterator_:
    BorrowingIteratorProtocol_,
    ~Copyable,
    ~Escapable
  {
    public typealias Element_ = Element

    @_alwaysEmitIntoClient
    internal var _baseAddress: UnsafePointer<Element_>?

    @_alwaysEmitIntoClient
    internal var _bucketIterator: _HTable.BucketIterator
  
    @_alwaysEmitIntoClient
    @_lifetime(borrow _set)
    internal init(
      _set: borrowing RigidSet<Element_>
    ) {
      self._baseAddress = .init(_set._members)
      self._bucketIterator = _set._table.makeBucketIterator()
    }

    @_alwaysEmitIntoClient
    @_lifetime(copy self)
    internal func _span(over buckets: Range<_Bucket>) -> Span<Element_> {
      let items = UnsafeBufferPointer(
        start: _baseAddress.unsafelyUnwrapped + buckets.lowerBound.offset,
        count: buckets.upperBound.offset - buckets.lowerBound.offset)
      return _overrideLifetime(Span(_unsafeElements: items), copying: self)
    }
    
    @_alwaysEmitIntoClient
    @_lifetime(&self)
    public mutating func nextSpan_(maxCount: Int) -> Span<Element_> {
      precondition(maxCount > 0, "maxCount must be positive")
      guard
        let next = _bucketIterator.nextOccupiedRegion(maxCount: maxCount)
      else {
        return .init()
      }
      return _span(over: next)
    }
  }
}

#endif
