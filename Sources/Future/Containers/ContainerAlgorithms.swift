//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

//MARK: - firstIndex(where:)

@available(SwiftStdlib 6.2, *)
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  internal func _containerFirstIndex<E: Error>(
    where predicate: (borrowing Element) throws(E) -> Bool
  ) throws(E) -> Index? {
    var i = self.startIndex
    while true {
      let spanStart = i
      let span = self.nextSpan(after: &i)
      if span.isEmpty { break }
      for offset in span.indices {
        if try predicate(span[offset]) {
          return self.index(spanStart, offsetBy: offset)
        }
      }
    }
    return nil
  }

  /// Returns the first index that addresses an element of the container that
  /// satisfies the given predicate.
  ///
  /// You can use the predicate to find an element of a type that doesn't
  /// conform to the `Equatable` protocol or to find an element that matches
  /// particular criteria.
  ///
  /// - Parameter predicate: A closure that takes an element as its argument
  ///   and returns a Boolean value that indicates whether the passed element
  ///   represents a match.
  /// - Returns: The index of the first element for which `predicate` returns
  ///   `true`. If no elements in the container satisfy the given predicate,
  ///   returns `nil`.
  ///
  /// - Complexity: O(*n*), where *n* is the count of the container.
  @_alwaysEmitIntoClient
  @inline(__always)
  public func firstIndex<E: Error>(
    where predicate: (borrowing Element) throws(E) -> Bool
  ) throws(E) -> Index? {
    try _containerFirstIndex(where: predicate)
  }
}

@available(SwiftStdlib 6.2, *)
extension Container where Self: Collection {
  /// Returns the first index that addresses an element of the container that
  /// satisfies the given predicate.
  ///
  /// You can use the predicate to find an element of a type that doesn't
  /// conform to the `Equatable` protocol or to find an element that matches
  /// particular criteria.
  ///
  /// - Parameter predicate: A closure that takes an element as its argument
  ///   and returns a Boolean value that indicates whether the passed element
  ///   represents a match.
  /// - Returns: The index of the first element for which `predicate` returns
  ///   `true`. If no elements in the container satisfy the given predicate,
  ///   returns `nil`.
  ///
  /// - Complexity: O(*n*), where *n* is the count of the container.
  @_alwaysEmitIntoClient
  @inline(__always)
  public func firstIndex<E: Error>(
    where predicate: (borrowing Element) throws(E) -> Bool
  ) throws(E) -> Index? {
    try _containerFirstIndex(where: predicate)
  }
}

//MARK: - firstIndex(of:)

@available(SwiftStdlib 6.2, *)
extension Container where Element: Equatable {
  @inlinable
  internal func _containerFirstIndex(of element: Element) -> Index? {
    if let result = _customIndexOfEquatableElement(element) {
      return result
    }
    return firstIndex(where: { $0 == element })
  }

  /// Returns the first index where the specified value appears in the container.
  ///
  /// After using `firstIndex(of:)` to find the position of a particular element
  /// in a container, you can use it to access the element by subscripting.
  ///
  /// - Parameter element: An element to search for in the container.
  /// - Returns: The first index where `element` is found. If `element` is not
  ///   found in the container, returns `nil`.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public func firstIndex(of element: Element) -> Index? {
    _containerFirstIndex(of: element)
  }
}

@available(SwiftStdlib 6.2, *)
extension Container where Self: Collection, Element: Equatable {
  /// Returns the first index where the specified value appears in the container.
  ///
  /// After using `firstIndex(of:)` to find the position of a particular element
  /// in a container, you can use it to access the element by subscripting.
  ///
  /// - Parameter element: An element to search for in the container.
  /// - Returns: The first index where `element` is found. If `element` is not
  ///   found in the container, returns `nil`.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public func firstIndex(of element: Element) -> Index? {
    _containerFirstIndex(of: element)
  }
}

//MARK: - lastIndex(where:)

@available(SwiftStdlib 6.2, *)
extension BidirectionalContainer where Self: ~Copyable & ~Escapable {
  @inlinable
  internal func _containerLastIndex<E: Error>(
    where predicate: (borrowing Element) throws(E) -> Bool
  ) throws(E) -> Index? {
    var i = self.endIndex
    while true {
      let span = self.previousSpan(before: &i)
      if span.isEmpty { break }
      var offset = span.count - 1
      while offset >= 0 {
        if try predicate(span[offset]) {
          return self.index(i, offsetBy: offset)
        }
        offset &-= 1
      }
    }
    return nil
  }

  /// Returns the index of the last element in the container that matches the
  /// given predicate.
  ///
  /// You can use the predicate to find an element of a type that doesn't
  /// conform to the `Equatable` protocol or to find an element that matches
  /// particular criteria.
  ///
  /// - Parameter predicate: A closure that takes an element as its argument
  ///   and returns a Boolean value that indicates whether the passed element
  ///   represents a match.
  /// - Returns: The index of the last element in the container that matches
  ///   `predicate`, or `nil` if no elements match.
  ///
  /// - Complexity: O(*n*), where *n* is the count of the container.
  @_alwaysEmitIntoClient
  @inline(__always)
  public func lastIndex<E: Error>(
    where predicate: (borrowing Element) throws(E) -> Bool
  ) throws(E) -> Index? {
    try _containerLastIndex(where: predicate)
  }
}

@available(SwiftStdlib 6.2, *)
extension BidirectionalContainer where Self: BidirectionalCollection {
  /// Returns the first index that addresses an element of the container that
  /// satisfies the given predicate.
  ///
  /// You can use the predicate to find an element of a type that doesn't
  /// conform to the `Equatable` protocol or to find an element that matches
  /// particular criteria.
  ///
  /// - Parameter predicate: A closure that takes an element as its argument
  ///   and returns a Boolean value that indicates whether the passed element
  ///   represents a match.
  /// - Returns: The index of the first element for which `predicate` returns
  ///   `true`. If no elements in the container satisfy the given predicate,
  ///   returns `nil`.
  ///
  /// - Complexity: O(*n*), where *n* is the count of the container.
  @_alwaysEmitIntoClient
  @inline(__always)
  public func lastIndex<E: Error>(
    where predicate: (borrowing Element) throws(E) -> Bool
  ) throws(E) -> Index? {
    try _containerLastIndex(where: predicate)
  }
}

//MARK: - lastIndex(of:)

@available(SwiftStdlib 6.2, *)
extension BidirectionalContainer where Element: Equatable {
  @inlinable
  internal func _containerLastIndex(of element: Element) -> Index? {
    if let result = _customLastIndexOfEquatableElement(element) {
      return result
    }
    return self._containerLastIndex(where: { $0 == element })
  }

  /// Returns the first index where the specified value appears in the container.
  ///
  /// After using `firstIndex(of:)` to find the position of a particular element
  /// in a container, you can use it to access the element by subscripting.
  ///
  /// - Parameter element: An element to search for in the container.
  /// - Returns: The first index where `element` is found. If `element` is not
  ///   found in the container, returns `nil`.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public func lastIndex(of element: Element) -> Index? {
    _containerLastIndex(of: element)
  }
}

@available(SwiftStdlib 6.2, *)
extension BidirectionalContainer where Self: BidirectionalCollection, Element: Equatable {
  /// Returns the first index where the specified value appears in the container.
  ///
  /// After using `firstIndex(of:)` to find the position of a particular element
  /// in a container, you can use it to access the element by subscripting.
  ///
  /// - Parameter element: An element to search for in the container.
  /// - Returns: The first index where `element` is found. If `element` is not
  ///   found in the container, returns `nil`.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public func lastIndex(of element: Element) -> Index? {
    _containerLastIndex(of: element)
  }
}

//MARK: - elementsEqual(_:,by:)

@available(SwiftStdlib 6.2, *)
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  internal func _spanwiseZip<Other: Container & ~Copyable & ~Escapable, State: ~Copyable, E: Error>(
    state: inout State,
    with other: borrowing Other,
    by process: (inout State, Span<Element>, Span<Other.Element>) throws(E) -> Bool
  ) throws(E) -> (Index, Other.Index) {
    var i = self.startIndex // End index of the current span in `self`
    var j = other.startIndex // End index of the current span in `other`
    var a: Span<Element> = .empty
    var b: Span<Other.Element> = .empty
    var pi = i // Start index of the original span we're currently processing in `self`
    var pj = j // Start index of the original span we're currently processing in `other`
    var ca = 0 // Count of the original span we're currently processing in `self`
    var cb = 0 // Count of the original span we're currently processing in `other`
  loop:
    while true {
      if a.isEmpty {
        pi = i
        a = self.nextSpan(after: &i)
        ca = a.count
      }
      if b.isEmpty {
        pj = j
        b = other.nextSpan(after: &j)
        cb = b.count
      }
      if a.isEmpty || b.isEmpty {
        return (
          (a.isEmpty ? i : self.index(pi, offsetBy: ca - a.count)),
          (b.isEmpty ? j : other.index(pj, offsetBy: cb - b.count)))
      }

      let c = Swift.min(a.count, b.count)
      guard try process(&state, a._extracting(first: c), b._extracting(first: c)) else {
        return (
          (c == a.count ? i : self.index(pi, offsetBy: c)),
          (c == b.count ? j : other.index(pj, offsetBy: c)))
      }
      a = a._extracting(droppingFirst: c)
      b = b._extracting(droppingFirst: c)
    }
  }

  @inlinable
  internal func _containerElementsEqual<E: Error, Other: Container & ~Copyable & ~Escapable>(
    _ other: borrowing Other,
    by areEquivalent: (borrowing Element, borrowing Other.Element) throws(E) -> Bool
  ) throws(E) -> Bool {
    var result = true
    let (i, j) = try _spanwiseZip(state: &result, with: other) { state, a, b throws(E) in
      assert(a.count == b.count)
      for i in a.indices {
        guard try areEquivalent(a[i], b[i]) else {
          state = false
          return false
        }
      }
      return true
    }
    return result && i == self.endIndex && j == other.endIndex
  }

  /// Returns a Boolean value indicating whether this container and another
  /// container contain equivalent elements in the same order, using the given
  /// predicate as the equivalence test.
  ///
  /// The predicate must form an *equivalence relation* over the elements. That
  /// is, for any elements `a`, `b`, and `c`, the following conditions must
  /// hold:
  ///
  /// - `areEquivalent(a, a)` is always `true`. (Reflexivity)
  /// - `areEquivalent(a, b)` implies `areEquivalent(b, a)`. (Symmetry)
  /// - If `areEquivalent(a, b)` and `areEquivalent(b, c)` are both `true`, then
  ///   `areEquivalent(a, c)` is also `true`. (Transitivity)
  ///
  /// - Parameters:
  ///   - other: A container to compare to this container.
  ///   - areEquivalent: A predicate that returns `true` if its two arguments
  ///     are equivalent; otherwise, `false`.
  /// - Returns: `true` if this container and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the count of the smaller of the input containers.
  @_alwaysEmitIntoClient
  public func elementsEqual<E: Error, Other: Container & ~Copyable & ~Escapable>(
    _ other: borrowing Other,
    by areEquivalent: (borrowing Element, borrowing Other.Element) throws(E) -> Bool
  ) throws(E) -> Bool {
    try _containerElementsEqual(other, by: areEquivalent)
  }
}

@available(SwiftStdlib 6.2, *)
extension Container where Self: Sequence {
  /// Returns a Boolean value indicating whether this container and another
  /// container contain equivalent elements in the same order, using the given
  /// predicate as the equivalence test.
  ///
  /// The predicate must form an *equivalence relation* over the elements. That
  /// is, for any elements `a`, `b`, and `c`, the following conditions must
  /// hold:
  ///
  /// - `areEquivalent(a, a)` is always `true`. (Reflexivity)
  /// - `areEquivalent(a, b)` implies `areEquivalent(b, a)`. (Symmetry)
  /// - If `areEquivalent(a, b)` and `areEquivalent(b, c)` are both `true`, then
  ///   `areEquivalent(a, c)` is also `true`. (Transitivity)
  ///
  /// - Parameters:
  ///   - other: A container to compare to this container.
  ///   - areEquivalent: A predicate that returns `true` if its two arguments
  ///     are equivalent; otherwise, `false`.
  /// - Returns: `true` if this container and `other` contain equivalent items,
  ///   using `areEquivalent` as the equivalence test; otherwise, `false.`
  ///
  /// - Complexity: O(*m*), where *m* is the count of the smaller of the input containers.
  @_alwaysEmitIntoClient
  public func elementsEqual<Other: Container<Element> & Sequence<Element>, E: Error>(
    _ other: Other,
    by areEquivalent: (borrowing Element, borrowing Element) throws(E) -> Bool
  ) throws(E) -> Bool {
    try _containerElementsEqual(other, by: areEquivalent)
  }
}
//MARK: - elementsEqual(_:)


@available(SwiftStdlib 6.2, *)
extension Container where Self: ~Copyable & ~Escapable, Element: Equatable {
  /// Returns a Boolean value indicating whether this container and another
  /// container contain the same elements in the same order.
  ///
  /// - Parameter other: A container whose contents to compare to this container.
  /// - Returns: `true` if this container and `other` contain the same elements
  ///   in the same order.
  ///
  /// - Complexity: O(*m*), where *m* is the count of the smaller of the input containers.
  @_alwaysEmitIntoClient
  @inline(__always)
  public func elementsEqual<Other: Container<Element> & ~Copyable & ~Escapable>(
    _ other: borrowing Other
  ) -> Bool {
    self._containerElementsEqual(other, by: { $0 == $1 })
  }
}

@available(SwiftStdlib 6.2, *)
extension Container where Self: Sequence, Element: Equatable {
  /// Returns a Boolean value indicating whether this container and another
  /// container contain the same elements in the same order.
  ///
  /// - Parameter other: A container whose contents to compare to this container.
  /// - Returns: `true` if this container and `other` contain the same elements
  ///   in the same order.
  ///
  /// - Complexity: O(*m*), where *m* is the count of the smaller of the input containers.
  @_alwaysEmitIntoClient
  @inline(__always)
  public func elementsEqual<Other: Sequence<Element> & Container<Element>>(
    _ other: Other
  ) -> Bool {
    self._containerElementsEqual(other, by: { $0 == $1 })
  }
}
