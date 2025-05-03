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

@available(SwiftStdlib 6.2, *)
public protocol MutableContainer<Element>: Container, ~Copyable, ~Escapable {
#if compiler(>=9999) // FIXME: Needs borrow accessors
  subscript(index: Index) -> Element { borrow mutate }
#else

#if compiler(>=6.2) && $InoutLifetimeDependence
  @lifetime(&self)
#else
  @lifetime(borrow self)
#endif
  @lifetime(self: copy self)
  mutating func mutateElement(at index: Index) -> Inout<Element>
#endif

#if compiler(>=6.2) && $InoutLifetimeDependence
  @lifetime(&self)
#else
  @lifetime(borrow self)
#endif
  @lifetime(self: copy self)
  mutating func nextMutableSpan(after index: inout Index) -> MutableSpan<Element>

  // FIXME: What about previousMutableSpan?

  @lifetime(self: copy self)
  mutating func swapAt(_ i: Index, _ j: Index)
}

@available(SwiftStdlib 6.2, *)
extension MutableContainer where Self: ~Copyable & ~Escapable {
#if false  // FIXME: This has flagrant exclusivity violations.
#if compiler(>=6.2) && $InoutLifetimeDependence
  @lifetime(&self)
#else
  @lifetime(borrow self)
#endif
  public mutating func nextMutableSpan(
    after index: inout Index, maximumCount: Int
  ) -> MutableSpan<Element> {
    let start = index
    do {
      let span = self.nextMutableSpan(after: &index)
      guard span.count > maximumCount else { return span }
    }
    // Index remains within the same span, so offseting it is expected to be quick
    let end = self.index(start, offsetBy: maximumCount)
    index = start
    var span = self.nextMutableSpan(after: &index)
    let extract = span.extracting(first: maximumCount) // FIXME: Oops
    index = end
    return extract
  }
#endif

  @lifetime(self: copy self)
  public mutating func withNextMutableSpan<
    E: Error, R: ~Copyable
  >(
    after index: inout Index, maximumCount: Int,
    body: (inout MutableSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    // FIXME: We don't want this to be closure-based, but MutableSpan cannot be sliced "in place".
    let start = index
    do {
      var span = self.nextMutableSpan(after: &index)
      if span.count <= maximumCount {
        return try body(&span)
      }
    }
    // Try again, but figure out what our target index is first.
    // Index remains within the same span, so offseting it is expected to be quick
    index = self.index(start, offsetBy: maximumCount)
    var i = start
    var span = self.nextMutableSpan(after: &i)
    var extract = span.extracting(first: maximumCount)
    return try body(&extract)
  }

#if compiler(>=6.2) && $InoutLifetimeDependence
  @inlinable
  public subscript(index: Index) -> Element {
    @lifetime(borrow self)
    unsafeAddress {
      unsafe borrowElement(at: index)._pointer
    }

    @lifetime(&self)
    unsafeMutableAddress {
      unsafe mutateElement(at: index)._pointer
    }
  }
#else
  @inlinable
  public subscript(index: Index) -> Element {
    @lifetime(borrow self)
    unsafeAddress {
      unsafe borrowElement(at: index)._pointer
    }

    @lifetime(borrow self)
    unsafeMutableAddress {
      unsafe mutateElement(at: index)._pointer
    }
  }
#endif
}

@available(SwiftStdlib 6.2, *)
extension MutableContainer where Self: ~Copyable & ~Escapable {
  /// Moves all elements satisfying `isSuffixElement` into a suffix of the
  /// container, returning the start position of the resulting suffix.
  ///
  /// - Complexity: O(*n*) where n is the count of the container.
  @inlinable
  @lifetime(self: copy self)
  internal mutating func _halfStablePartition<E: Error>(
    isSuffixElement: (borrowing Element) throws(E) -> Bool
  ) throws(E) -> Index {
    guard var i = try firstIndex(where: isSuffixElement)
    else { return endIndex }

    var j = index(after: i)
    while j != endIndex {
      if try !isSuffixElement(self[j]) {
        swapAt(i, j)
        formIndex(after: &i)
      }
      formIndex(after: &j)
    }
    return i
  }
}
