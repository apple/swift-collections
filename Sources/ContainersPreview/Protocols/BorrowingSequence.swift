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
public protocol BorrowingSequence<Element>: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable
  associatedtype BorrowingIterator: BorrowingIteratorProtocol<Element> & ~Copyable & ~Escapable
  
  var underestimatedCount: Int { get }

  @_lifetime(borrow self)
  borrowing func makeBorrowingIterator() -> BorrowingIterator
  
  func _customContainsEquatableElement(
    _ element: borrowing Element
  ) -> Bool?
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence
where
  Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @inlinable
  public var underestimatedCount: Int { 0 }
  
  @inlinable
  public func _customContainsEquatableElement(_ element: borrowing Element) -> Bool? {
    nil
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence where Self: Sequence {
  @inlinable
  public func _customContainsEquatableElement(_ element: borrowing Element) -> Bool? {
    nil
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  /// Implementation demo of what borrowing for-in loops would need to expand into.
  @inlinable
  public func _borrowingForEach<E: Error>(
    _ body: (borrowing Element) throws(E) -> Void
  ) throws(E) -> Void {
    var it = makeBorrowingIterator()
    while true {
      let span = it.nextSpan()
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
