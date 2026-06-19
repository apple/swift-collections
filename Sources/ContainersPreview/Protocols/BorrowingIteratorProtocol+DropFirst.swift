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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

// MARK: dropFirst(_ count:)

@available(SwiftStdlib 5.0, *)
public struct DropFirstBorrowingIterator<Base: BorrowingIteratorProtocol_>: BorrowingIteratorProtocol_, ~Copyable, ~Escapable
  where Base: ~Copyable & ~Escapable, Base.Element_: ~Copyable
{
  public typealias Element_ = Base.Element_
  
  var base: Base
  var remaining: Int

  @_lifetime(copy base)
  init(_ base: consuming Base, count: Int) {
    self.base = base
    self.remaining = count
  }
  
  @_lifetime(&self)
  public mutating func nextSpan_(maximumCount: Int) -> Span<Element_> {
    if remaining > 0 {
      _ = base.skip_(by: remaining)
      remaining = 0
    }
    return base.nextSpan_(maximumCount: maximumCount)
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol_ where Self: ~Copyable & ~Escapable, Element_: ~Copyable {
  @_lifetime(copy self)
  public consuming func dropFirst(_ count: Int = 1) -> DropFirstBorrowingIterator<Self> {
    .init(self, count: count)
  }
}

// MARK: dropFirst(while:)

@available(SwiftStdlib 5.0, *)
public struct DropFirstWhileBorrowingIterator<Base: BorrowingIteratorProtocol_>: BorrowingIteratorProtocol_, ~Copyable, ~Escapable
  where Base: ~Copyable & ~Escapable, Base.Element_: ~Copyable
{
  public typealias Element_ = Base.Element_
  
  var base: Base
  var predicate: (borrowing Base.Element_) -> Bool
  var hasDroppedPrefix: Bool = false

  @_lifetime(copy base)
  init(_ base: consuming Base, predicate: @escaping (borrowing Base.Element_) -> Bool) {
    self.base = base
    self.predicate = predicate
  }
  
  @_lifetime(&self)
  public mutating func nextSpan_(maximumCount: Int) -> Span<Element_> {
    if !hasDroppedPrefix {
      hasDroppedPrefix = true
      while true {
        let span = base.nextSpan_(maximumCount: maximumCount)
        if span.isEmpty { return span }
        
        var i = 0
        while i < span.count {
          if !predicate(span[unchecked: i]) {
            return span.extracting(droppingFirst: i)
          }
          i &+= 1
        }
      }
    }
    
    return base.nextSpan_(maximumCount: maximumCount)
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol_ where Self: ~Copyable & ~Escapable, Element_: ~Copyable {
  @_lifetime(copy self)
  public consuming func dropFirst(
    while predicate: @escaping (borrowing Element_) -> Bool
  ) -> DropFirstWhileBorrowingIterator<Self> {
    .init(self, predicate: predicate)
  }
}

#endif
