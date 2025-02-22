//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import Span
#endif

extension Deque: RandomAccessContainer {
  public typealias BorrowingIterator = RigidDeque<Element>.BorrowingIterator

  @inlinable
  public func startBorrowingIteration() -> BorrowingIterator {
    self.startBorrowingIteration(from: 0)
  }

  @inlinable
  public func startBorrowingIteration(from start: Int) -> BorrowingIterator {
    // FIXME: This is unacceptably unsafe. We want to access `_storage.value`
    // FIXME: as if it was a structural part of `self`, but there is no way
    // FIXME: to express this in Swift.
    BorrowingIterator(
      _unsafeSegments: _storage.value._handle.segments(),
      startOffset: start,
      owner: self)
  }

  @inlinable
  public func index(at position: borrowing BorrowingIterator) -> Int {
    precondition(_read { $0.segments().isIdentical(to: position._segments) })
    return position._offset
  }

  @inlinable
  public func formIndex(
    _ index: inout Index, offsetBy distance: inout Index.Stride, limitedBy limit: Index
  ) {
    // Note: Range checks are deferred until element access.
    index.advance(by: &distance, limitedBy: limit)
  }
}
