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
public protocol BorrowingIteratorProtocol: ~Escapable {
  associatedtype Element: ~Copyable

  @lifetime(copy self)
  mutating func nextChunk(maximumCount: Int) -> Span<Element>
}

@available(SwiftStdlib 6.2, *) // For Span
public protocol Container: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable

  associatedtype BorrowingIterator: BorrowingIteratorProtocol, ~Escapable
  where BorrowingIterator.Element == Element

  @lifetime(copy self)
  borrowing func startBorrowingIteration() -> BorrowingIterator
  
  @lifetime(copy self)
  borrowing func startBorrowingIteration(from start: Index) -> BorrowingIterator

  associatedtype Index: Comparable

  var isEmpty: Bool { get }
  var count: Int { get }

  var startIndex: Index { get }
  var endIndex: Index { get }
  
  /// This is a temporary stand-in for the subscript requirement that we actually want:
  ///
  ///     subscript(index: Index) -> Element { borrow }
  @lifetime(copy self)
  func borrowElement(at index: Index) -> Borrow<Element>
  
  func index(after index: Index) -> Index
  func formIndex(after i: inout Index)

  func index(at position: borrowing BorrowingIterator) -> Index

  func distance(from start: Index, to end: Index) -> Int

  func index(_ index: Index, offsetBy n: Int) -> Index

  func formIndex(
    _ i: inout Index, offsetBy distance: inout Int, limitedBy limit: Index
  )
}

@available(SwiftStdlib 6.2, *)
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  public subscript(index: Index) -> Element {
    unsafeAddress {
      unsafe borrowElement(at: index)._pointer
    }
  }
}

