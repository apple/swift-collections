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

@available(SwiftStdlib 6.2, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @frozen
  public struct Indices: ~Escapable {
    @_alwaysEmitIntoClient
    package let _base: Ref<_HTable>

    @_alwaysEmitIntoClient
    @_lifetime(borrow _base)
    package init(_base: borrowing @_addressable _HTable) {
      self._base = Ref(_base)
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
extension RigidDictionary.Indices: BorrowingSequence_
where Key: ~Copyable, Value: ~Copyable
{
  public typealias Element = RigidDictionary.Index
  public typealias Element_ = Element

  @frozen
  public struct BorrowingIterator_: ~Escapable {
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
  public var underestimatedCount_: Int { self._base.value.count }

  @_lifetime(borrow self) // FIXME: Should be @_lifetime(copy self)
  public func makeBorrowingIterator_() -> BorrowingIterator_ {
    let bit = self._base.value.makeBucketIterator()
    // FIXME: This override really should not be necessary. Check if the real `struct Borrow` fixes it.
    let override = _overrideLifetime(bit, copying: self)
    return BorrowingIterator_(_it: override)
  }
}

@available(SwiftStdlib 6.2, *)
extension RigidDictionary.Indices.BorrowingIterator_: BorrowingIteratorProtocol_
where Key: ~Copyable, Value: ~Copyable {
  public typealias Element_ = Element

  @_lifetime(&self)
  public mutating func nextSpan_(maximumCount: Int) -> Span<Element> {
    guard _it.advanceToOccupied() else { return .init() }
    _current[0] = Element(_bucket: _it.currentBucket)
    _it.advanceToNextBit()
    return _current.span
  }
}
#endif
