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

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @frozen
  public struct Indices: ~Escapable {
    @_alwaysEmitIntoClient
    package let _base: Borrow<_HTable>
    
    @_alwaysEmitIntoClient
    @_lifetime(borrow _base)
    package init(_base: borrowing @_addressable _HTable) {
      self._base = Borrow(_base)
    }
  }

  @inlinable
  public var indices: Indices {
    @_lifetime(borrow self)
    get {
      Indices(_base: self._keys._table)
    }
  }
}

@available(SwiftStdlib 6.2, *)
extension RigidDictionary.Indices: BorrowingSequence
where Key: ~Copyable, Value: ~Copyable
{
  public typealias Element = RigidDictionary.Index
  
  @frozen
  public struct BorrowingIterator: ~Escapable {
    public typealias Element = RigidDictionary.Index

    @usableFromInline
    package var _it: _HTable.BucketIterator
    
    @usableFromInline
    package var _current: InlineArray<1, Element>
    
    @inlinable
    @_lifetime(copy _it)
    package init(_it: consuming _HTable.BucketIterator) {
      self._it = _it
      self._current = InlineArray { target in
        target.append(Element(_bucket: _HTable.Bucket(offset: 0)))
      }
    }
  }

  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(self._base.value.count)
  }
  
  @_lifetime(copy self)
  public func makeBorrowingIterator() -> BorrowingIterator {
    let bit = self._base.value.makeBucketIterator()
    // FIXME: This override really should not be necessary. Check if the real `struct Borrow` fixes it.
    let override = _overrideLifetime(bit, copying: self)
    return BorrowingIterator(_it: override)
  }
}

@available(SwiftStdlib 6.2, *)
extension RigidDictionary.Indices.BorrowingIterator: BorrowingIteratorProtocol
where Key: ~Copyable, Value: ~Copyable {
  @_lifetime(&self)
  public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
    guard _it.advanceToOccupied() else { return .init() }
    _current[0] = Element(_bucket: _it.currentBucket)
    _it.advanceToNextBit()
    return _current.span
  }
}
#endif
