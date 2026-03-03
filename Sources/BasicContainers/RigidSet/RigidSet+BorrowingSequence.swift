//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import ContainersPreview
#endif

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension RigidSet: BorrowingSequence where Element: ~Copyable {
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @inlinable
  public func _customContainsEquatableElement(
    _ element: borrowing Element
  ) -> Bool? {
    self.contains(element)
  }

  @inlinable
  @_lifetime(borrow self)
  public borrowing func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(_set: self)
  }

  @frozen
  public struct BorrowingIterator:
    BorrowingIteratorProtocol,
    ~Copyable,
    ~Escapable
  {
    @_alwaysEmitIntoClient
    internal var _baseAddress: UnsafePointer<Element>?

    @_alwaysEmitIntoClient
    internal var _bucketIterator: _HTable.BucketIterator
  
    @_alwaysEmitIntoClient
    @_lifetime(borrow _set)
    internal init(
      _set: borrowing RigidSet<Element>
    ) {
      self._baseAddress = .init(_set._members)
      self._bucketIterator = _set._table.makeBucketIterator()
    }

    @_alwaysEmitIntoClient
    @_lifetime(copy self)
    internal func _span(over buckets: Range<_Bucket>) -> Span<Element> {
      let items = UnsafeBufferPointer(
        start: _baseAddress.unsafelyUnwrapped + buckets.lowerBound.offset,
        count: buckets.upperBound.offset - buckets.lowerBound.offset)
      return _overrideLifetime(Span(_unsafeElements: items), copying: self)
    }
    
    @_alwaysEmitIntoClient
    @_lifetime(copy self)
    public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
      precondition(maximumCount > 0, "maximumCount must be positive")
      guard
        let next = _bucketIterator.nextOccupiedRegion(maximumCount: maximumCount)
      else {
        return .init()
      }
      return _span(over: next)
    }
  }
}

#endif
