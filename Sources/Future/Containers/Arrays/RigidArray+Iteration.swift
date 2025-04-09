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

@available(SwiftStdlib 6.2, *) // For Span
extension RigidArray: RandomAccessContainer where Element: ~Copyable {
  @safe
  public struct BorrowingIterator: BorrowingIteratorProtocol, ~Escapable {
    @usableFromInline
    internal let _items: UnsafeBufferPointer<Element>
    
    @usableFromInline
    internal var _offset: Int
    
    @inlinable
    @lifetime(borrow array)
    internal init(for array: borrowing RigidArray, startOffset: Int) {
      unsafe self._items = UnsafeBufferPointer(array._items)
      self._offset = startOffset
    }
    
    @inlinable
    internal var _span: Span<Element> {
      @lifetime(copy self)
      get {
        unsafe Span(_unsafeElements: _items)
      }
    }

    @lifetime(copy self)
    public mutating func nextChunk(
      maximumCount: Int
    ) -> Span<Element> {
      let end = unsafe _offset + Swift.min(maximumCount, _items.count - _offset)
      defer { _offset = end }
      return unsafe _span._extracting(Range(uncheckedBounds: (_offset, end)))
    }
  }
  
  @lifetime(borrow self)
  public func startBorrowingIteration() -> BorrowingIterator {
    BorrowingIterator(for: self, startOffset: 0)
  }
  
  @lifetime(borrow self)
  public func startBorrowingIteration(from start: Int) -> BorrowingIterator {
    BorrowingIterator(for: self, startOffset: start)
  }
  
  @inlinable
  public func index(at position: borrowing BorrowingIterator) -> Int {
    precondition(unsafe position._items === UnsafeBufferPointer(self._items))
    return position._offset
  }
}
