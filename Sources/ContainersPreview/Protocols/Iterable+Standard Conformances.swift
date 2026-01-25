//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension Span: BorrowingSequence where Element: ~Copyable {
  // FIXME: This simple definition cannot also be a backward (or bidirectional)
  // iterator, nor a random-access iterator. If we want to go in that direction,
  // we'll need to rather introduce a type more like `RigidArray.BorrowingIterator`.
  public typealias BorrowingIterator = Self
 
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_lifetime(copy self)
  @inlinable
  public func makeBorrowingIterator() -> Span<Element> {
    self
  }
}

@available(SwiftStdlib 5.0, *)
extension MutableSpan: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = Span<Element>.BorrowingIterator
 
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> Span<Element> {
    self.span
  }
}

@available(SwiftStdlib 5.0, *)
extension OutputSpan: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = Span<Element>.BorrowingIterator
 
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> Span<Element> {
    self.span
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = Span<Element>.BorrowingIterator
 
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> Span<Element> {
    self.span
  }
}

@available(SwiftStdlib 6.2, *)
extension Array: BorrowingSequence {
  public typealias BorrowingIterator = Span<Element>.BorrowingIterator
 
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> Span<Element> {
    self.span
  }
}


#endif
