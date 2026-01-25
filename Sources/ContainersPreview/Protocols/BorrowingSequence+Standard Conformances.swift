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

@available(SwiftStdlib 6.2, *)
extension Range: BorrowingSequence
where Bound: Strideable, Bound.Stride: SignedInteger
{
  public typealias Element = Bound

  @frozen
  public struct BorrowingIterator: BorrowingIteratorProtocol, ~Copyable {
    @usableFromInline
    internal var _current: InlineArray<1, Bound>
    
    @usableFromInline
    internal var _end: Bound

    @usableFromInline
    internal var _first: Bool

    @inlinable
    internal init(_ base: Range<Bound>) {
      self._current = .init(repeating: base.lowerBound)
      self._end = base.upperBound
      self._first = true
    }
    @inlinable
    @_lifetime(&self)
    public mutating func nextSpan(maximumCount: Int) -> Span<Bound> {
      guard _current[0] < _end else { return .init() }
      if _first {
        _first = false
      } else {
        _current[0] = _current[0].advanced(by: 1)
      }
      return _current.span
    }
  }

  @inlinable
  public var estimatedCount: EstimatedCount {
    if let count = Int(exactly: lowerBound.distance(to: upperBound)) {
      return .exactly(count)
    }
    return .unknown
  }

  public func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(self)
  }


  
}

#endif
