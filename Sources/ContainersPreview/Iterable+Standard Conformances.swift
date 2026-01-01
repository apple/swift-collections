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
extension Span: Iterable where Element: ~Copyable {
  // FIXME: This simple definition cannot also be a backward (or bidirectional)
  // iterator, nor a random-access iterator. If we want to go in that direction,
  // we'll need to rather introduce a type more like `RigidArray.BorrowIterator`.
  public typealias BorrowIterator = Self
 
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_lifetime(copy self)
  @inlinable
  public func startBorrowIteration() -> Span<Element> {
    self
  }
}

@available(SwiftStdlib 5.0, *)
extension MutableSpan: Iterable where Element: ~Copyable {
  public typealias BorrowIterator = Span<Element>.BorrowIterator
 
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_lifetime(borrow self)
  @inlinable
  public func startBorrowIteration() -> Span<Element> {
    self.span
  }
}

@available(SwiftStdlib 5.0, *)
extension OutputSpan: Iterable where Element: ~Copyable {
  public typealias BorrowIterator = Span<Element>.BorrowIterator
 
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_lifetime(borrow self)
  @inlinable
  public func startBorrowIteration() -> Span<Element> {
    self.span
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan: Iterable where Element: ~Copyable {
  public typealias BorrowIterator = Span<Element>.BorrowIterator
 
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_lifetime(borrow self)
  @inlinable
  public func startBorrowIteration() -> Span<Element> {
    self.span
  }
}

@available(SwiftStdlib 6.2, *)
extension Array: Iterable {
  public typealias BorrowIterator = Span<Element>.BorrowIterator
 
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_lifetime(borrow self)
  @inlinable
  public func startBorrowIteration() -> Span<Element> {
    self.span
  }
}


#endif
