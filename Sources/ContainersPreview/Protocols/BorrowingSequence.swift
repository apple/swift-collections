//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
public protocol BorrowingSequence_<Element_, Failure>: ~Copyable, ~Escapable {
  associatedtype Element_: ~Copyable
  associatedtype Failure: Error

  associatedtype BorrowingIterator_:
    BorrowingIteratorProtocol_<Element_, Failure> & ~Copyable & ~Escapable

  var underestimatedCount_: Int { get }

  @_lifetime(borrow self)
  borrowing func makeBorrowingIterator_() throws(Failure) -> BorrowingIterator_

  func _customContainsEquatableElement_(
    _ element: borrowing Element_
  ) -> Bool? // FIXME(throws): Should this throw?
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence_
where
  Self: ~Copyable & ~Escapable, Element_: ~Copyable
{
  @inlinable
  public var underestimatedCount_: Int { 0 }
  
  @inlinable
  public func _customContainsEquatableElement_(_ element: borrowing Element_) -> Bool? {
    nil
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence_ where Self: Sequence {
  @inlinable
  public func _customContainsEquatableElement_(_ element: borrowing Element) -> Bool? {
    nil
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence_
where
  Self: ~Copyable & ~Escapable,
  Element_: ~Copyable
{
  /// Implementation demo of what borrowing for-in loops would need to expand into.
  @inlinable
  public func _borrowingForEach(
    _ body: (borrowing Element_) throws(Failure) -> Void // FIXME(throws): Union
  ) throws(Failure) -> Void {
    var it = try makeBorrowingIterator_()
    while true {
      let span = try it.nextSpan_()
      if span.isEmpty { break }
      var i = 0
      while i < span.count {
        try body(span[unchecked: i])
        i &+= 1
      }
    }
  }
}

#endif
