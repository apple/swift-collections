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

@available(SwiftCompatibilitySpan 5.0, *)
public protocol Container<Element>: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable/* & ~Escapable*/
  associatedtype Index: Comparable

  var isEmpty: Bool { get }
  var count: Int { get }

  var startIndex: Index { get }
  var endIndex: Index { get }

  func index(after index: Index) -> Index
  func formIndex(after i: inout Index)
  func distance(from start: Index, to end: Index) -> Int
  func index(_ index: Index, offsetBy n: Int) -> Index
  func formIndex(
    _ i: inout Index,
    offsetBy distance: inout Int,
    limitedBy limit: Index
  )

  // FIXME: Do we want these as standard requirements?
  func index(alignedDown index: Index) -> Index
  func index(alignedUp index: Index) -> Index

  #if compiler(>=9999) // FIXME: We can't do this yet
  subscript(index: Index) -> Element { borrow }
  #else
  @lifetime(borrow self)
  func borrowElement(at index: Index) -> Borrow<Element>
  #endif

  // See if index rounding results need to get returned somewhere
  // maximumCount: see if it has any real reason to exist yet
  @lifetime(borrow self)
  func nextSpan(after index: inout Index) -> Span<Element>

  // Try a version where nextSpan takes an index range

  // See if it makes sense to have a ~Escapable ValidatedIndex type, as a sort of non-self-driving iterator substitute
}

@available(SwiftCompatibilitySpan 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  public func index(alignedDown index: Index) -> Index { index }

  @inlinable
  public func index(alignedUp index: Index) -> Index { index }

  @inlinable
  @lifetime(borrow self)
  public func nextSpan(after index: inout Index, maximumCount: Int) -> Span<Element> {
    let original = index
    var span = nextSpan(after: &index)
    if span.count > maximumCount {
      span = span._extracting(first: maximumCount)
      // Index remains within the same span, so offseting it is expected to be quick
      index = self.index(original, offsetBy: maximumCount)
    }
    return span
  }

  @inlinable
  public subscript(index: Index) -> Element {
    @lifetime(copy self)
    unsafeAddress {
      unsafe borrowElement(at: index)._pointer
    }
  }
}


#if false // DEMO
@available(SwiftCompatibilitySpan 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  // This is just to demo the bulk iteration model
  func forEachSpan<E: Error>(_ body: (Span<Element>) throws(E) -> Void) throws(E) {
    var it = self.startIndex
    while true {
      let span = self.nextSpan(after: &it)
      if span.isEmpty { break }
      try body(span)
    }
  }

  // This is just to demo the bulk iteration model
  func forEach<E: Error>(_ body: (borrowing Element) throws(E) -> Void) throws(E) {
    var it = self.startIndex
    while true {
      let span = self.nextSpan(after: &it)
      if span.isEmpty { break }
      var i = 0
      while i < span.count {
        unsafe try body(span[unchecked: i])
        i &+= 1
      }
    }
  }

  borrowing func borrowingMap<E: Error, U>(
    _ transform: (borrowing Element) throws(E) -> U
  ) throws(E) -> [U] {
    var result: [U] = []
    result.reserveCapacity(count)
    try self.forEach { value throws(E) in result.append(try transform(value)) }
    return result
  }
}
#endif
