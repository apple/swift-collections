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

/// A borrowing iterator that provides access to the elements of a single
/// span through a `BorrowingIteratorProtocol` interface.
@available(SwiftStdlib 5.0, *)
public struct SpanIterator<Element_>: BorrowingIteratorProtocol_, ~Copyable, ~Escapable
  where Element_: ~Copyable
{
  @usableFromInline
  internal var _span: Span<Element_>
  @usableFromInline
  internal var _start: Int
  @usableFromInline
  internal var _count: Int
  
  @_lifetime(copy elements)
  public init(_ elements: Span<Element_>) {
    _span = elements
    _start = 0
    _count = elements.count
  }
  
  @_alwaysEmitIntoClient
  @_lifetime(&self)
  @_lifetime(self: copy self)
  @_transparent
  public mutating func nextSpan_(maximumCount: Int) -> Span<Element_> {
    let c = Swift.min(maximumCount, _count)
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

#endif
