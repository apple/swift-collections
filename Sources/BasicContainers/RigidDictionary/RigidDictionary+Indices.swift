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

@available(SwiftStdlib 6.2, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @available(SwiftStdlib 6.4, *)
  @frozen
  @safe
  public struct Indices: ~Escapable {
    @_alwaysEmitIntoClient
    package let _it: _HTable.BucketIterator

    @_alwaysEmitIntoClient
    package let _count: Int

    @_alwaysEmitIntoClient
    @_lifetime(borrow _base)
    package init(_base: borrowing _HTable) {
      self._it = _base.makeBucketIterator()
      self._count = _base.count
    }
  }

  @available(SwiftStdlib 6.4, *)
  @inlinable
  public var indices: Indices {
    @_lifetime(borrow self)
    get {
      unsafe Indices(_base: self._keys._table)
    }
  }
}

@available(SwiftStdlib 6.4, *)
extension RigidDictionary.Indices: Iterable
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
  public var underestimatedCount: Int { _count }

  @_lifetime(borrow self)
  public func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(_it: _it)
  }
}

@available(SwiftStdlib 6.4, *)
extension RigidDictionary.Indices.BorrowingIterator: BorrowingIteratorProtocol
where Key: ~Copyable, Value: ~Copyable {
  @_lifetime(&self)
  public mutating func nextSpan(maxCount: Int) -> Span<Element> {
    guard _it.advanceToOccupied() else { return .init() }
    _current[0] = Element(_bucket: _it.currentBucket)
    _it.advanceToNextBit()
    return _current.span
  }
}
#endif
