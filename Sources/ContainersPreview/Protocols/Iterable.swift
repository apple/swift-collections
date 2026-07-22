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

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
public protocol Iterable_<Element_, Failure_>: ~Copyable, ~Escapable {
  // FIXME: None of these names should not have trailing underscores, but that
  // would clash with the stdlib's versions:
  //    error: 'BorrowingIterator' is ambiguous for type lookup in this context
  //
  // This is likely best resolved by removing these definitions as soon as they
  // appear in the stdlib.
  associatedtype Element_: ~Copyable
  associatedtype Failure_: Error = Never

  associatedtype BorrowingIterator_: BorrowingIteratorProtocol_<Element_, Failure_> & ~Copyable & ~Escapable

  var underestimatedCount_: Int { get }

  @_lifetime(borrow self)
  borrowing func makeBorrowingIterator_() -> BorrowingIterator_
  
  func _customContainsEquatableElement_(
    _ element: borrowing Element_
  ) -> Bool?
}

@available(SwiftStdlib 6.4, *)
extension Iterable_
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

@available(SwiftStdlib 6.4, *)
extension Iterable_ where Self: Sequence {
  @inlinable
  public var underestimatedCount_: Int { 0 }

  @inlinable
  public func _customContainsEquatableElement_(_ element: borrowing Element) -> Bool? {
    nil
  }
}

#endif
