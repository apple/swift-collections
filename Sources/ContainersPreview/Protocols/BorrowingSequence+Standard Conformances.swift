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

@available(SwiftStdlib 5.0, *)
extension Span: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = SpanIterator<Element>

  @inlinable
  public var underestimatedCount: Int { count }

  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> SpanIterator<Element> {
    SpanIterator(self)
  }
}

@available(SwiftStdlib 5.0, *)
extension MutableSpan: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = SpanIterator<Element>

  @inlinable
  public var underestimatedCount: Int { count }

  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> BorrowingIterator {
    SpanIterator(self.span)
  }
}

@available(SwiftStdlib 5.0, *)
extension OutputSpan: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = SpanIterator<Element>

  @inlinable
  public var underestimatedCount: Int { count }

  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> BorrowingIterator {
    SpanIterator(self.span)
  }
}

@available(SwiftStdlib 5.0, *)
extension InputSpan: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = SpanIterator<Element>

  @inlinable
  public var underestimatedCount: Int { count }

  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> BorrowingIterator {
    SpanIterator(self.span)
  }
}

@available(SwiftStdlib 6.2, *)
extension Array: BorrowingSequence {
  public typealias BorrowingIterator = SpanIterator<Element>

  @inlinable
  public var underestimatedCount: Int { count }
  
  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> BorrowingIterator {
    SpanIterator(self.span)
  }
}

@available(SwiftStdlib 6.2, *)
extension InlineArray: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = SpanIterator<Element>
  
  @inlinable
  public var underestimatedCount: Int { count }

  @_lifetime(borrow self)
  @inlinable
  public func makeBorrowingIterator() -> BorrowingIterator {
    SpanIterator(self.span)
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
    internal var _progress: Bool
    
    @inlinable
    internal init(_ base: Range<Bound>) {
      self._current = .init(repeating: base.lowerBound)
      self._end = base.upperBound
      self._progress = false
    }
    @inlinable
    @_lifetime(&self)
    public mutating func nextSpan(maximumCount: Int) -> Span<Bound> {
      if _progress {
        _current[0] = _current[0].advanced(by: 1)
      }
      guard _current[0] < _end else {
        _progress = false
        return .init()
      }
      _progress = true
      return _current.span
    }
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package var _borrowingUnderestimatedCount: Int {
    guard let count = Int(exactly: lowerBound.distance(to: upperBound)) else {
      return 0
    }
    return count
  }

  @inlinable
  public var underestimatedCount: Int { _borrowingUnderestimatedCount }

  @inlinable
  public func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(self)
  }
}

@available(SwiftStdlib 6.2, *)
extension ClosedRange: BorrowingSequence
where Bound: Strideable, Bound.Stride: SignedInteger
{
  public typealias Element = Bound
  
  @frozen
  public struct BorrowingIterator: BorrowingIteratorProtocol, ~Copyable {
    @usableFromInline
    internal var _current: InlineArray<1, Bound>
    
    @usableFromInline
    internal var _last: Bound
    
    @usableFromInline
    internal var _progress: Bool
    
    @inlinable
    internal init(_ base: ClosedRange<Bound>) {
      self._current = .init(repeating: base.lowerBound)
      self._last = base.upperBound
      self._progress = false
    }
    @inlinable
    @_lifetime(&self)
    public mutating func nextSpan(maximumCount: Int) -> Span<Bound> {
      if _progress {
        _current[0] = _current[0].advanced(by: 1)
      }
      guard _current[0] <= _last else {
        _progress = false
        return .init()
      }
      _progress = true
      return _current.span
    }
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package var _borrowingUnderestimatedCount: Int {
    guard let distance = Int(exactly: lowerBound.distance(to: upperBound))
    else { return 0 }
    let advanced = distance.addingReportingOverflow(1)
    guard !advanced.overflow else { return 0 }
    return advanced.partialValue
  }

  @inlinable
  public var underestimatedCount: Int { _borrowingUnderestimatedCount }
  
  @inlinable
  public func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(self)
  }
}

#endif
