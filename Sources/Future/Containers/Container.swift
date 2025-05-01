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

  #if compiler(>=9999) // FIXME: We can't do this yet
  subscript(index: Index) -> Element { borrow }
  #else
  @lifetime(borrow self)
  func borrowElement(at index: Index) -> Borrow<Element>
  #endif

  /// Return a span over the container's storage that begins with the element at the given index,
  /// and extends to the end of the contiguous storage chunk that contains it. On return, the index
  /// is updated to address the next item following the end of the returned span.
  ///
  /// This method can be used to efficiently process the items of a container in bulk, by
  /// directly iterating over its piecewise contiguous pieces of storage:
  ///
  ///     var index = items.startIndex
  ///     while true {
  ///       let span = items.nextSpan(after: &index)
  ///       if span.isEmpty { break }
  ///       // Process items in `span`
  ///     }
  ///
  /// Note: The spans returned by this method are not guaranteed to be disjunct. Some containers
  /// may use the same storage chunk (or parts of a storage chunk) multiple times, to repeat their
  /// contents.
  ///
  /// Note: Repeated invocations of `nextSpan` on the same container and index are not guaranteed
  /// to return identical results. (This is particularly the case with containers that can store
  /// contents in their "inline" representation. Such containers may not always have
  /// a unique address in memory; the locations of the spans exposed by this method may vary
  /// between different borrows of the same container.)
  ///
  /// - Parameter index: A valid index in the container, including the end index. On return, this
  ///     index is advanced by the count of the resulting span, to simplify iteration.
  /// - Returns: A span over contiguous storage that starts at the given index. If the input index
  ///     is the end index, then this returns an empty span. Otherwise the result is non-empty,
  ///     with its first element matching the element at the input index.
  @lifetime(borrow self)
  func nextSpan(after index: inout Index) -> Span<Element>

  // FIXME: Try a version where nextSpan takes an index range

  // FIXME: See if it makes sense to have a ~Escapable ValidatedIndex type, as a sort of non-self-driving iterator substitute

  // *** Requirements with default implementations ***

  // FIXME: Do we want these as standard requirements this time?
  func index(alignedDown index: Index) -> Index
  func index(alignedUp index: Index) -> Index

  func _customIndexOfEquatableElement(_ element: borrowing Element) -> Index??
  func _customLastIndexOfEquatableElement(_ element: borrowing Element) -> Index??
}

@available(SwiftCompatibilitySpan 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  public func _defaultIndex(_ i: Index, advancedBy distance: Int) -> Index {
    precondition(
      distance >= 0,
      "Only BidirectionalContainers can be advanced by a negative amount")

    var i = index(alignedDown: i)
    var distance = distance

    // FIXME: This implementation can be wasteful for contiguous containers,
    // as iterating over spans will overshoot the target immediately.
    // Reintroducing `nextSpan(after:maximumCount:)` would help avoid
    // having to use a second loop to refine the result, but it would
    // complicate conformances.

    // Skip forward until we find the span that contains our target.
    while distance > 0 {
      var j = i
      let span = self.nextSpan(after: &j)
      precondition(
        !span.isEmpty,
        "Can't advance index beyond the end of the container")
      guard span.count <= distance else { break }
      i = j
      distance &-= span.count
    }
    // Step through to find the precise target.
    while distance > 0 {
      self.formIndex(after: &i)
      distance &-= 1
    }
    return i
  }

  @inlinable
  public func _defaultDistance(from start: Index, to end: Index) -> Int {
    var start = index(alignedDown: start)
    let end = index(alignedDown: end)
    if start > end {
      return -_defaultDistance(from: end, to: start)
    }
    var count = 0
    while start != end {
      count = count + 1
      formIndex(after: &start)
    }
    return count
  }

  @inlinable
  public func _defaultFormIndex(
    _ i: inout Index,
    advancedBy distance: inout Int,
    limitedBy limit: Index
  ) {
    precondition(
      distance >= 0,
      "Only BidirectionalContainers can be advanced by a negative amount")

    i = index(alignedDown: i)
    let limit = index(alignedDown: limit)

    // Skip forward until we find the span that contains our target.
    while distance > 0 {
      var j = i
      let span = self.nextSpan(after: &j)
      precondition(
        !span.isEmpty,
        "Can't advance index beyond the end of the container")
      guard span.count <= distance, j < limit else {
        break
      }
      i = j
      distance &-= span.count
    }
    // Step through to find the precise target.
    while distance != 0 {
      if i == limit {
        return
      }
      formIndex(after: &i)
      distance &-= 1
    }
  }
}

@available(SwiftCompatibilitySpan 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  public var isEmpty: Bool {
    return startIndex == endIndex
  }

  @inlinable
  public func formIndex(after i: inout Index) {
    i = self.index(after: i)
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    _defaultDistance(from: start, to: end)
  }

  @inlinable
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    _defaultIndex(index, advancedBy: n)
  }

  @inlinable
  public func formIndex(
    _ i: inout Index,
    offsetBy distance: inout Int,
    limitedBy limit: Index
  ) {
    _defaultFormIndex(&i, advancedBy: &distance, limitedBy: limit)
  }

  @inlinable
  public func index(alignedDown index: Index) -> Index { index }

  @inlinable
  public func index(alignedUp index: Index) -> Index { index }

  @inlinable
  public func _customIndexOfEquatableElement(_ element: borrowing Element) -> Index?? { nil }

  @inlinable
  public func _customLastIndexOfEquatableElement(_ element: borrowing Element) -> Index?? { nil }
}

@available(SwiftCompatibilitySpan 5.0, *)
extension Container where Self: Sequence {
  @inlinable
  public var underestimatedCount: Int { count }
}

@available(SwiftCompatibilitySpan 5.0, *)
extension Container where Self: Collection {
  // Resolve ambiguities between default implementations between Collection
  // and Container.

  @inlinable
  public var underestimatedCount: Int { count }

  @inlinable
  public var isEmpty: Bool {
    return startIndex == endIndex
  }

  @inlinable
  public func formIndex(after i: inout Index) {
    i = self.index(after: i)
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    _defaultDistance(from: start, to: end)
  }

  @inlinable
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    _defaultIndex(index, advancedBy: n)
  }

  @inlinable
  public func _customIndexOfEquatableElement(_ element: borrowing Element) -> Index?? { nil }

  @inlinable
  public func _customLastIndexOfEquatableElement(_ element: borrowing Element) -> Index?? { nil }
}

@available(SwiftCompatibilitySpan 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  public subscript(index: Index) -> Element {
    // This stopgap definition is standing in for the eventual subscript requirement with a
    // borrowing accessor.
    @lifetime(copy self)
    unsafeAddress {
      unsafe borrowElement(at: index)._pointer
    }
  }
}

@available(SwiftCompatibilitySpan 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
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
