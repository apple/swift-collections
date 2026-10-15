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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.3)

#if compiler(>=6.4) && UnstableContainersPreview

//MARK: - Protocol conformances

@available(SwiftStdlib 5.0, *)
extension TemporaryArray: Iterable_ where Element: ~Copyable {
  public typealias IterableIterator_ = SpanIterator<Element>

  @_alwaysEmitIntoClient
  @inline(__always)
  public var underestimatedCount_: Int { count }

  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(borrow self)
  public func makeIterableIterator_() -> IterableIterator_ {
    SpanIterator(self.span)
  }
}

@available(SwiftStdlib 5.0, *)
extension TemporaryArray: Container where Element: ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension TemporaryArray: BidirectionalContainer where Element: ~Copyable {}

@available(SwiftStdlib 5.0, *)
extension TemporaryArray: RandomAccessContainer where Element: ~Copyable {}

#endif // compiler(>=6.4) && UnstableContainersPreview

//MARK: - Count

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// A Boolean value indicating whether the array is empty.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public var isEmpty: Bool { _count == 0 }

  /// The number of elements in the array.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @inline(__always)
  public var count: Int { _count }
}

//MARK: - Indices

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// A position in the array: an integer offset from the start.
  public typealias Index = Int

  @_alwaysEmitIntoClient
  @inline(__always)
  public var startIndex: Int { 0 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public var endIndex: Int { _count }

  @_alwaysEmitIntoClient
  @inline(__always)
  public var indices: Range<Int> { unsafe Range(uncheckedBounds: (0, _count)) }

  @_alwaysEmitIntoClient
  @_transparent
  internal func _checkItemIndex(_ index: Int) {
    precondition(
      UInt(bitPattern: index) < UInt(bitPattern: _count),
      "Index out of bounds")
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func _checkValidIndex(_ index: Int) {
    precondition(
      UInt(bitPattern: index) <= UInt(bitPattern: _count),
      "Index out of bounds")
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal func _checkValidBounds(_ subrange: Range<Int>) {
    precondition(
      subrange.lowerBound >= 0 && subrange.upperBound <= _count,
      "Index range out of bounds")
  }
}

//MARK: - Index navigation

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(after index: Int) -> Int { index + 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(before index: Int) -> Int { index - 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(after index: inout Int) { index += 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(before index: inout Int) { index -= 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(_ index: Int, offsetBy n: Int) -> Int { index + n }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func distance(from start: Int, to end: Int) -> Int { end - start }

  @_alwaysEmitIntoClient
  public func formIndex(
    _ index: inout Int, offsetBy n: inout Int, limitedBy limit: Int
  ) {
    index._advance(by: &n, limitedBy: limit)
  }
}

//MARK: - Element access

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inline(__always)
  internal func _ptr(to index: Int) -> UnsafePointer<Element> {
    _checkItemIndex(index)
    let p = unsafe _storage.baseAddress.unsafelyUnwrapped.advanced(by: index)
    return unsafe UnsafePointer(p)
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  internal mutating func _mutablePtr(
    to index: Int
  ) -> UnsafeMutablePointer<Element> {
    _checkItemIndex(index)
    return unsafe _storage.baseAddress.unsafelyUnwrapped.advanced(by: index)
  }

  /// Accesses the element at the specified position.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public subscript(position: Int) -> Element {
    @inline(__always)
    unsafeAddress {
      unsafe _ptr(to: position)
    }
    @inline(__always)
    unsafeMutableAddress {
      unsafe _mutablePtr(to: position)
    }
  }

  /// Exchanges the values at the specified indices of the array.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func swapAt(_ i: Int, _ j: Int) {
    _checkItemIndex(i)
    _checkItemIndex(j)
    unsafe _items.swapAt(i, j)
  }
}

//MARK: - Bulk access

@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: ~Copyable {
  /// Return a span over the contiguous storage chunk starting at `index`, of at
  /// most `maximumCount` items, advancing `index` past it.
  ///
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Int, maximumCount: Int
  ) -> Span<Element> {
    _checkValidIndex(index)
    precondition(maximumCount > 0, "maximumCount must be positive")
    let start = index
    index = start &+ Swift.min(maximumCount, _count &- start)
    return _span(in: Range(uncheckedBounds: (start, index)))
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextMutableSpan(
    after index: inout Int, maximumCount: Int
  ) -> MutableSpan<Element> {
    _checkValidIndex(index)
    precondition(maximumCount > 0, "maximumCount must be positive")
    let start = index
    index = start &+ Swift.min(maximumCount, _count &- start)
    return _mutableSpan(in: Range(uncheckedBounds: (start, index)))
  }

  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func previousSpan(
    before index: inout Int, maximumCount: Int
  ) -> Span<Element> {
    _checkValidIndex(index)
    precondition(maximumCount > 0, "maximumCount must be positive")
    let start = index
    index = start &- Swift.min(maximumCount, start)
    return _span(in: Range(uncheckedBounds: (index, start)))
  }
}

#endif
