//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
public protocol Container<Element>: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable /*& ~Escapable*/
  associatedtype BorrowIterator: BorrowIteratorProtocol<Element> & ~Copyable & ~Escapable
  
  var isEmpty: Bool { get }
  var count: Int { get }

  @_lifetime(borrow self)
  borrowing func startBorrowIteration() -> BorrowIterator
}

@available(SwiftStdlib 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  /// Implementation demo of what borrowing for-in loops would need to expand into.
  @inlinable
  public func _borrowingForEach<E: Error>(
    _ body: (borrowing Element) throws(E) -> Void
  ) throws(E) -> Void {
    var it = startBorrowIteration()
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
extension Container where Self: ~Copyable & ~Escapable {
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
    var it = startBorrowIteration()
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
