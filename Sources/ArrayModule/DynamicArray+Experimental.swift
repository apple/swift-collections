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


#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2) && (compiler(>=6.3) || !os(Windows)) // FIXME: [2025-08-17] Windows has no 6.2 snapshot with OutputSpan
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

#if FIXME
extension DynamicArray /*where Element: Copyable*/ {
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & ~Copyable & ~Escapable>(
    capacity: Int? = nil,
    copying contents: borrowing C
  ) {
    self.init(consuming: RigidArray(capacity: capacity, copying: contents))
  }

  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & Sequence<Element>>(
    capacity: Int? = nil,
    copying contents: C
  ) {
    self.init(consuming: RigidArray(capacity: capacity, copying: contents))
  }
}
#endif

#if FIXME
extension DynamicArray where Element: ~Copyable {
  @inlinable
  @inline(__always)
  @_lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    _storage.borrowElement(at: index)
  }
}
#endif

#if FIXME
extension DynamicArray: RandomAccessContainer where Element: ~Copyable {}
#endif

#if FIXME
extension DynamicArray where Element: ~Copyable {
  @inlinable
  @_lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Inout<Element> {
    _storage.mutateElement(at: index)
  }
}
#endif

extension DynamicArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @inlinable
  @_transparent
  internal mutating func _edit<R: ~Copyable>(
    freeCapacity: Int,
    inPlaceMutation: (inout OutputSpan<Element>) -> R,
    reallocatingMutation: (inout InputSpan<Element>, inout OutputSpan<Element>) -> R
  ) -> R {
    if _storage.freeCapacity >= freeCapacity {
      return edit(inPlaceMutation)
    }
    let newCapacity = _grow(freeCapacity: freeCapacity)
    return _storage.reallocate(capacity: newCapacity, with: reallocatingMutation)
  }
}

#if FIXME
extension DynamicArray where Element: ~Copyable {
  /// Removes all the elements that satisfy the given predicate.
  ///
  /// Use this method to remove every element in a container that meets
  /// particular criteria. The order of the remaining elements is preserved.
  ///
  /// - Parameter shouldBeRemoved: A closure that takes an element of the
  ///   sequence as its argument and returns a Boolean value indicating
  ///   whether the element should be removed from the array.
  ///
  /// - Complexity: O(`count`)
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public mutating func removeAll<E: Error>(
    where shouldBeRemoved: (borrowing Element) throws(E) -> Bool
  ) throws(E) {
    // FIXME: Remove this in favor of a standard algorithm.
    let suffixStart = try _halfStablePartition(isSuffixElement: shouldBeRemoved)
    removeSubrange(suffixStart...)
  }
}
#endif

extension DynamicArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout InputSpan<Element>
  ) {
    _ensureFreeCapacity(items.count)
    _storage.append(moving: &items)
  }

  @available(SwiftStdlib 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout OutputSpan<Element>
  ) {
    _ensureFreeCapacity(items.count)
    _storage.append(moving: &items)
  }
}

extension DynamicArray {
#if FIXME
  public mutating func _appendContainer<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C
  ) {
    var i = newElements.startIndex
    while true {
      let span = newElements.span(after: &i)
      if span.isEmpty { break }
      self.append(copying: span)
    }
  }
#endif

#if FIXME
  /// Copies the elements of a container to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: A container whose contents to copy into the array.
  ///
  /// - Complexity: O(`newElements.count`), when amortized over many invocations
  ///    over the same array.
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public mutating func append<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C
  ) {
    _appendContainer(copying: newElements)
  }
#endif

#if FIXME
  /// Copies the elements of a container to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: A container whose contents to copy into the array.
  ///
  /// - Complexity: O(`newElements.count`), when amortized over many invocations
  ///    over the same array.
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public mutating func append<
    C: Container<Element> & Sequence<Element>
  >(
    copying newElements: borrowing C
  ) {
    _appendContainer(copying: newElements)
  }
#endif
}

#if FIXME
extension DynamicArray {
  @available(SwiftStdlib 6.2, *)
  @inlinable
  internal mutating func _insertContainer<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    let newCount = newElements.count
    _ensureFreeCapacity(newCount)
    _storage._insertContainer(
      at: index, copying: newElements, newCount: newCount)
  }

  /// Copies the elements of a container into this array at the specified
  /// position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the array’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the array.
  ///
  /// All existing elements at or following the specified position are moved to
  /// make room for the new item.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///    *m* is the count of `newElements`.
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    _insertContainer(copying: newElements, at: index)
  }

  /// Copies the elements of a container into this array at the specified
  /// position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the array’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the array.
  ///
  /// All existing elements at or following the specified position are moved to
  /// make room for the new item.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///    *m* is the count of `newElements`.
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & Collection<Element>
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    _insertContainer(copying: newElements, at: index)
  }

}
#endif

#if FIXME
extension DynamicArray {
  @available(SwiftStdlib 6.2, *)
  @inlinable
  public mutating func _replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copyingContainer newElements: borrowing C
  ) {
    // FIXME: Avoiding moving the subsequent elements twice.
    let c = newElements.count
    _ensureFreeCapacity(c)
    _storage._replaceSubrange(
      subrange, copyingContainer: newElements, newCount: c)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length container as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///   *m* is the count of `newElements`.
  @available(SwiftStdlib 6.2, *)
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copying newElements: borrowing C
  ) {
    _replaceSubrange(subrange, copyingContainer: newElements)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length container as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///   *m* is the count of `newElements`.
  @available(SwiftStdlib 6.2, *)
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange<
    C: Container<Element> & Collection<Element>
  >(
    _ subrange: Range<Int>,
    copying newElements: borrowing C
  ) {
    _replaceSubrange(subrange, copyingContainer: newElements)
  }
}
#endif

#endif
#endif
