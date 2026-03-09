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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

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
extension BorrowingSequence where Self: ~Copyable & ~Escapable {
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
extension BorrowingSequence where Self: ~Copyable & ~Escapable {
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

@available(SwiftStdlib 5.0, *)
extension BorrowingSequence where Self: ~Copyable & ~Escapable {
  @inlinable
  public func borrowingReduce<Result: ~Copyable, E: Error>(
    into initial: consuming Result,
    _ update: (inout Result, borrowing Self.Element) throws(E) -> ()
  ) throws(E) -> Result {
    var result = initial
    try self._borrowingForEach { item throws(E) in
      try update(&result, item)
    }
    return result
  }

  @inlinable
  public func borrowingReduce<Result: ~Copyable, E: Error>(
    _ initial: consuming Result,
    _ next: (consuming Result, borrowing Self.Element) throws(E) -> Result
  ) throws(E) -> Result {
    var result = initial
#if false // FIXME: missing reinitialization of closure capture 'result' after consume
    try self._borrowingForEach { item throws(E) in
      result = try next(result, item)
    }
#else
    var it = makeBorrowingIterator()
    while true {
      let span = it.nextSpan()
      if span.isEmpty { break }
      var i = 0
      while i < span.count {
        result = try next(result, span[unchecked: i])
        i &+= 1
      }
    }
#endif
    return result
  }

}

#endif
