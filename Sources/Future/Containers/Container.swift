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

#if false // FIXME: Revive
public protocol BorrowingIteratorProtocol: ~Escapable {
  associatedtype Element: ~Copyable

  @lifetime(self)
  mutating func nextChunk(maximumCount: Int) -> Span<Element>
}

public protocol Container: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable

  associatedtype BorrowingIterator: BorrowingIteratorProtocol, ~Escapable
  where BorrowingIterator.Element == Element

  borrowing func startBorrowingIteration() -> BorrowingIterator
  borrowing func startBorrowingIteration(from start: Index) -> BorrowingIterator

  associatedtype Index: Comparable

  var isEmpty: Bool { get }
  var count: Int { get }

  var startIndex: Index { get }
  var endIndex: Index { get }

  // FIXME: Replace `@_borrowed` with proper `read`/`modify` accessor requirements
  // FIXME: (Or rather, accessors with proper projection semantics.)
  @_borrowed subscript(index: Index) -> Element { get }

  func index(after index: Index) -> Index
  func formIndex(after i: inout Index)

  func index(at position: borrowing BorrowingIterator) -> Index

  func distance(from start: Index, to end: Index) -> Int

  func index(_ index: Index, offsetBy n: Int) -> Index

  func formIndex(
    _ i: inout Index, offsetBy distance: inout Int, limitedBy limit: Index
  )
}

public protocol BidirectionalContainer: Container, ~Copyable, ~Escapable {
  override associatedtype Element: ~Copyable

  func index(before i: Index) -> Index
  func formIndex(before i: inout Index)

  @_nonoverride func index(_ i: Index, offsetBy distance: Int) -> Index
  @_nonoverride func formIndex(
    _ i: inout Index, offsetBy distance: inout Int, limitedBy limit: Index
  )
}

public protocol RandomAccessContainer: BidirectionalContainer, ~Copyable, ~Escapable {
  override associatedtype Element: ~Copyable
}

extension Strideable {
  @inlinable
  public mutating func advance(by distance: inout Stride, limitedBy limit: Self) {
    if distance >= 0 {
      guard limit >= self else {
        self = self.advanced(by: distance)
        distance = 0
        return
      }
      let d = Swift.min(distance, self.distance(to: limit))
      self = self.advanced(by: d)
      distance -= d
    } else {
      guard limit <= self else {
        self = self.advanced(by: distance)
        distance = 0
        return
      }
      let d = Swift.max(distance, self.distance(to: limit))
      self = self.advanced(by: d)
      distance -= d
    }
  }
}

extension RandomAccessContainer where Index: Strideable, Index.Stride == Int, Self: ~Copyable {
  @inlinable
  public func index(after index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: 1)
  }

  @inlinable
  public func index(before index: Index) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: -1)
  }

  @inlinable
  public func formIndex(after index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: 1)
  }

  @inlinable
  public func formIndex(before index: inout Index) {
    // Note: Range checks are deferred until element access.
    index = index.advanced(by: -1)
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    // Note: Range checks are deferred until element access.
    start.distance(to: end)
  }

  @inlinable
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    // Note: Range checks are deferred until element access.
    index.advanced(by: n)
  }

  @inlinable
  public func formIndex(
    _ index: inout Index, offsetBy distance: inout Index.Stride, limitedBy limit: Index
  ) {
    // Note: Range checks are deferred until element access.
    index.advance(by: &distance, limitedBy: limit)
  }
}
#endif

#if false // TODO
public protocol Muterator: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable

  @lifetime(self)
  mutating func nextChunk(maximumCount: Int) -> MutableSpan<Element>
}

public protocol MutableContainer: Container, ~Copyable, ~Escapable {
  associatedtype MutatingIterationState: ~Copyable, ~Escapable

  mutating func startMutatingIteration() -> MutatingIterationState

  // FIXME: Replace `@_borrowed` with proper `read`/`modify` accessor requirements
  @_borrowed subscript(index: Index) -> Element { get set }

}
#endif
