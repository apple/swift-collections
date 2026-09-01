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

#if compiler(>=6.4) && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension RigidSet: Iterable where Element: ~Copyable {
  @inlinable
  public var underestimatedCount: Int { count }
  
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

  @_alwaysEmitIntoClient
  package borrowing func _validateIterator(
    _ iterator: borrowing BorrowingIterator
  ) -> Bool {
    iterator._baseAddress == UnsafePointer(self._members)
    && iterator._bucketIterator._words == UnsafePointer(self._table._bitmap)
  }

  @frozen
  public struct BorrowingIterator:
    BorrowingIteratorProtocol,
    ~Copyable,
    ~Escapable
  {
    @_alwaysEmitIntoClient
    package var _baseAddress: UnsafePointer<Element>?

    @_alwaysEmitIntoClient
    package var _bucketIterator: _HTable.BucketIterator

    @_alwaysEmitIntoClient
    package var _endBucket: _Bucket

    @_alwaysEmitIntoClient
    @_lifetime(borrow _set)
    package init(
      _set: borrowing RigidSet<Element>
    ) {
      self._baseAddress = .init(_set._members)
      self._bucketIterator = _set._table.makeBucketIterator()
      self._endBucket = self._bucketIterator._endBucket
      _bucketIterator.advanceToOccupied()
    }

    @_alwaysEmitIntoClient
    @_lifetime(borrow _set)
    package init(
      _set: borrowing RigidSet<Element>,
      from start: Index,
      to end: Index
    ) {
      self._baseAddress = .init(_set._members)
      self._bucketIterator = _set._table.makeBucketIterator(from: start._bucket)
      self._endBucket = end._bucket
      _bucketIterator.advanceToOccupied()
    }

    @_alwaysEmitIntoClient
    @_lifetime(copy self)
    internal func _span(from start: _Bucket, to end: _Bucket) -> Span<Element> {
      let items = UnsafeBufferPointer(
        start: _baseAddress.unsafelyUnwrapped + start.offset,
        count: end.offset - start.offset)
      return _overrideLifetime(Span(_unsafeElements: items), copying: self)
    }
    
    @_alwaysEmitIntoClient
    @_lifetime(&self)
    public mutating func nextSpan(maxCount: Int = .max) -> Span<Element> {
      precondition(maxCount > 0, "maxCount must be positive")
      let start = _bucketIterator.currentBucket
      if start >= _endBucket {
        return .init()
      }
      assert(_bucketIterator.isOccupied)
      _bucketIterator.advanceToUnoccupied(maxCount: maxCount)
      var end = _bucketIterator.currentBucket
      _bucketIterator.advanceToOccupied()
      if _endBucket < end {
        end = _endBucket
        _bucketIterator.advanceToEnd()
      }
      return _span(from: start, to: end)
    }
  }
}

#endif
