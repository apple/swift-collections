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

// MARK: prefix(_ count:)

@available(SwiftStdlib 5.0, *)
public struct PrefixBorrowingIterator<Base: BorrowingIteratorProtocol_>: BorrowingIteratorProtocol_, ~Copyable, ~Escapable
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
    if remaining == 0 {
      return Span()
    }
    
    let c = min(maximumCount, remaining)
    let span = base.nextSpan_(maximumCount: c)
    remaining -= span.count
    if span.count == 0 {
      remaining = 0
    }
    return span
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol_ where Self: ~Copyable & ~Escapable, Element_: ~Copyable {
  @_lifetime(copy self)
  public consuming func prefix(_ count: Int) -> PrefixBorrowingIterator<Self> {
    .init(self, count: count)
  }
}

// MARK: prefix(while:)

@available(SwiftStdlib 5.0, *)
public struct PrefixWhileBorrowingIterator<Base: BorrowingIteratorProtocol_>: BorrowingIteratorProtocol_, ~Copyable, ~Escapable
  where Base: ~Copyable & ~Escapable, Base.Element_: ~Copyable
{
  public typealias Element_ = Base.Element_
  
  var base: Base
  var predicate: (borrowing Base.Element_) -> Bool
  var foundNonMatchingElement: Bool = false

  @_lifetime(copy base)
  init(_ base: consuming Base, predicate: @escaping (borrowing Base.Element_) -> Bool) {
    self.base = base
    self.predicate = predicate
  }
  
  @_lifetime(&self)
  public mutating func nextSpan_(maximumCount: Int) -> Span<Element_> {
    if foundNonMatchingElement {
      return Span()
    }
    
    let span = base.nextSpan_(maximumCount: maximumCount)
    for i in span.indices {
      if !predicate(span[i]) {
        foundNonMatchingElement = true
        return span.extracting(first: i)
      }
    }
    return span
  }
}

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol_ where Self: ~Copyable & ~Escapable, Element_: ~Copyable {
  @_lifetime(copy self)
  public consuming func prefix(
    while predicate: @escaping (borrowing Element_) -> Bool
  ) -> PrefixWhileBorrowingIterator<Self> {
    .init(self, predicate: predicate)
  }
}

#endif
