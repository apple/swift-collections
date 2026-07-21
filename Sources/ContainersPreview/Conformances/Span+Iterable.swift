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

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension Span: Iterable_ where Element: ~Copyable {
  public typealias Element_ = Element

  @inlinable
  public var underestimatedCount_: Int { count }

  @inlinable
  @_lifetime(borrow self)
  public func makeBorrowingIterator_() -> BorrowingIterator_ {
    BorrowingIterator_(self)
  }
}

@available(SwiftStdlib 5.0, *)
extension Span where Element: ~Copyable {
  /// A borrowing iterator that provides access to the elements of a single
  /// span through a `BorrowingIteratorProtocol` interface.
  @available(SwiftStdlib 6.4, *)
  public struct BorrowingIterator_:
    BorrowingIteratorProtocol_, ~Copyable, ~Escapable
  {
    public typealias Element_ = Element

    @usableFromInline
    package var _span: Span<Element_>
    @usableFromInline
    package var _start: Int
    @usableFromInline
    package var _count: Int

    @_lifetime(copy elements)
    public init(_ elements: Span<Element_>) {
      _span = elements
      _start = 0
      _count = elements.count
    }

    @_lifetime(copy elements)
    public init(_ elements: Span<Element_>, from start: Int, to end: Int) {
      precondition(start >= 0 && start <= elements.count, "Index out of bounds")
      precondition(end >= 0 && end <= elements.count, "Index out of bounds")
      precondition(start <= end, "start index must be less than or equal to end index")
      _span = elements
      _start = start
      _count = end &- start
    }

    @_alwaysEmitIntoClient
    @_lifetime(&self)
    @_lifetime(self: copy self)
    @_transparent
    public mutating func nextSpan_(maxCount: Int) -> Span<Element_> {
      let c = Swift.min(maxCount, _count)
      defer {
        _start &+= c
        _count &-= c
      }
      return _span.extracting(droppingFirst: _start).extracting(first: c)
    }

    @_alwaysEmitIntoClient
    @_lifetime(self: copy self)
    public mutating func skip_(by offset: Int) -> Int {
      let c = Swift.min(offset, _count)
      defer {
        _start &+= c
        _count &-= c
      }
      return c
    }
  }
}
#endif
