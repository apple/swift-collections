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

extension RigidArray /*where Element: Copyable*/ {
#if FIXME
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & Sequence<Element>>(
    capacity: Int,
    copying contents: C
  ) {
    self.init(capacity: capacity)
    self.append(copying: contents)
  }
#endif

#if FIXME
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & ~Copyable & ~Escapable>(
    capacity: Int? = nil,
    copying contents: borrowing C
  ) {
    self.init(capacity: capacity ?? contents.count)
    self.append(copying: contents)
  }
#endif

#if FIXME
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<C: Container<Element> & Collection<Element>>(
    capacity: Int? = nil,
    copying contents: C
  ) {
    self.init(capacity: capacity ?? contents.count)
    self.append(copying: contents)
  }
#endif
}

#if FIXME
extension RigidArray where Element: ~Copyable {
  @inlinable
  @_lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    precondition(index >= 0 && index < _count, "Index out of bounds")
    return unsafe Borrow(
      unsafeAddress: _storage.baseAddress.unsafelyUnwrapped.advanced(by: index),
      borrowing: self
    )
  }
}
#endif

#if FIXME
extension RigidArray: RandomAccessContainer where Element: ~Copyable {
}
#endif

#if FIXME
extension RigidArray where Element: ~Copyable {
  @inlinable
  @_lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Inout<Element> {
    precondition(index >= 0 && index < _count)
    return unsafe Inout(
      unsafeAddress: _storage.baseAddress.unsafelyUnwrapped.advanced(by: index),
      mutating: &self
    )
  }
}
#endif

#if FIXME
extension RigidArray: MutableContainer where Element: ~Copyable {
}
#endif

extension RigidArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @inlinable
  public mutating func reallocate<E: Error, R: ~Copyable>(
    capacity: Int,
    with body: (
      inout InputSpan<Element>,
      inout OutputSpan<Element>
    ) throws(E) -> R
  ) throws(E) -> R {
    var source = InputSpan(buffer: _storage, initializedCount: _count)
    let newStorage: UnsafeMutableBufferPointer<Element> = .allocate(
      capacity: capacity)
    var target = OutputSpan(buffer: newStorage, initializedCount: 0)
    defer {
      _ = consume source
      _storage.deallocate()
      _count = target.finalize(for: newStorage)
      _storage = newStorage
      source = .init()
      target = .init()
    }
    return try body(&source, &target)
  }
}

#if FIXME
extension RigidArray where Element: ~Copyable {
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

extension RigidArray where Element: ~Copyable {
  @_lifetime(&self)
  public mutating func popLast(_ count: Int) -> InputSpan<Element> {
    let c = Swift.min(count, self.count)
    self._count &-= c
    let span = InputSpan(
      buffer: self._storage._extracting(last: c),
      initializedCount: c)
    return _overrideLifetime(span, mutating: &self)
  }
}

extension RigidArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout InputSpan<Element>
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(last: count)
      unsafe self.append(moving: source)
      count = 0
    }
  }

  @available(SwiftStdlib 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout OutputSpan<Element>
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.append(moving: source)
      count = 0
    }
  }
}

extension RigidArray {
#if FIXME
  @inlinable
  internal mutating func _appendContainer<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C
  ) {
    let (copied, end) = unsafe _freeSpace._initializePrefix(
      copying: newElements)
    precondition(end == newElements.endIndex, "RigidArray capacity overflow")
    _count += copied
  }
#endif

#if FIXME
  /// Copies the elements of a container to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// container, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: A container whose contents to copy into the array.
  ///
  /// - Complexity: O(`newElements.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append<C: Container<Element> & ~Copyable & ~Escapable>(
    copying newElements: borrowing C
  ) {
    _appendContainer(copying: newElements)
  }
#endif

#if FIXME
  /// Copies the elements of a container to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// container, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the array.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append<
    C: Container<Element> & Sequence<Element>
  >(copying newElements: C) {
    _appendContainer(copying: newElements)
  }
#endif
}

extension RigidArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout InputSpan<Element>,
    at index: Int
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(last: count)
      unsafe self.append(moving: source)
      count = 0
    }
  }

  @available(SwiftStdlib 5.0, *)
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout OutputSpan<Element>,
    at index: Int
  ) {
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.append(moving: source)
      count = 0
    }
  }
}

extension RigidArray {
#if FIXME
  @inlinable
  internal mutating func _insertContainer<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    at index: Int,
    copying items: borrowing C,
    newCount: Int
  ) {
    precondition(index >= 0 && index <= _count, "Index out of bounds")
    precondition(newCount <= freeCapacity, "RigidArray capacity overflow")
    let target = unsafe _openGap(at: index, count: newCount)
    let (copied, end) = unsafe target._initializePrefix(copying: items)
    precondition(
      copied == newCount && end == items.endIndex,
      "Broken Container: count doesn't match contents")
    _count += newCount
  }
#endif

#if FIXME
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///    *m* is the count of `newElements`.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    _insertContainer(
      at: index, copying: newElements, newCount: newElements.count)
  }
#endif

#if FIXME
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///    *m* is the count of `newElements`.
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & Collection<Element>
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    _insertContainer(
      at: index, copying: newElements, newCount: newElements.count)
  }
#endif
}

extension RigidArray {
#if FIXME
  @inlinable
  public mutating func _replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copyingContainer newElements: borrowing C,
    newCount: Int
  ) {
    let gap = unsafe _gapForReplacement(of: subrange, withNewCount: newCount)
    let (copied, end) = unsafe gap._initializePrefix(copying: newElements)
    precondition(
      copied == newCount && end == newElements.endIndex,
      "Broken Container: count doesn't match contents")
  }
#endif

#if FIXME
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copying newElements: borrowing C
  ) {
    _replaceSubrange(
      subrange, copyingContainer: newElements, newCount: newElements.count)
  }
#endif

#if FIXME
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange<
    C: Container<Element> & Collection<Element>
  >(
    _ subrange: Range<Int>,
    copying newElements: C
  ) {
    _replaceSubrange(
      subrange, copyingContainer: newElements, newCount: newElements.count)
  }
#endif
}

#endif
#endif
