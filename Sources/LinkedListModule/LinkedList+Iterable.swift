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

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension LinkedList: Iterable where Element: ~Copyable {
  public typealias Failure = Never

  @frozen
  public struct BorrowingIterator: BorrowingIteratorProtocol, ~Copyable, ~Escapable {
    @_alwaysEmitIntoClient
    public let _base: Ref<LinkedList>

    @_alwaysEmitIntoClient
    public let _end: LinkedList.Index

    @_alwaysEmitIntoClient
    package var _index: LinkedList.Index

    @_alwaysEmitIntoClient
    @inline(always)
    @_lifetime(copy _base)
    package init(
      _base: Ref<LinkedList>,
      from start: LinkedList.Index,
      to end: LinkedList.Index
    ) {
      self._base = _base
      self._end = end
      self._index = start
    }
  }

  /// A value less than or equal to the number of elements in the sequence,
  /// calculated nondestructively.
  @_alwaysEmitIntoClient
  @inline(always)
  public var underestimatedCount: Int { self.count }

  /// Returns a borrowing iterator over the elements of this sequence.
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(
      _base: Ref(self),
      from: self.startIndex,
      to: self.endIndex)
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(
    from start: Index, to end: Index
  ) -> BorrowingIterator {
    precondition(_isValid(start) && _isValid(end), "Invalid index")
    return BorrowingIterator(_base: Ref(self), from: start, to: end)
  }

  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: inout BorrowingIterator) -> Index {
    iterator._index
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList.BorrowingIterator: BorrowingIteratorProtocol
where Element: ~Copyable
{
  public typealias Failure = Never

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextSpan(maxCount: Int) -> Span<Element> {
    _base.value.nextSpan(
      after: &self._index,
      maxCount: maxCount,
      limitedBy: self._end)
  }

  @_alwaysEmitIntoClient
  public mutating func skip(by n: inout Int) {
    _base.value.formIndex(
      &self._index,
      offsetBy: &n,
      limitedBy: self._end)
  }

  @_alwaysEmitIntoClient
  @inline(always)
  public mutating func skip(by n: Int) -> Int {
    var n = n
    self.skip(by: &n)
    return n
  }
}

#endif
