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

@available(SwiftStdlib 5.0, *)
public protocol Iterable_<Element_, Failure_>: ~Copyable, ~Escapable {
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

@available(SwiftStdlib 5.0, *)
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

@available(SwiftStdlib 5.0, *)
extension Iterable_ where Self: Sequence {
  @inlinable
  public var underestimatedCount_: Int { 0 }

  @inlinable
  public func _customContainsEquatableElement_(_ element: borrowing Element) -> Bool? {
    nil
  }
}

#endif
