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

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Replaces the specified range of elements by a given count of new items,
  /// using a callback to directly initialize array storage by populating
  /// an output span.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting room for the new elements starting at the
  /// same location. The number of new elements need not match the number
  /// of elements being removed.
  ///
  /// If the array does not have sufficient capacity to perform the replacement,
  /// then this reallocates storage to extend its capacity, using a geometric
  /// growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, then
  /// this method is equivalent to calling
  /// `insert(count: newCount, initializingWith: body)`.
  ///
  /// Likewise, if you pass a zero for `newCount`, then this method
  /// removes the elements in the given subrange without any replacement.
  /// Calling `removeSubrange(subrange)` is preferred in this case.
  ///
  /// - Parameters
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///      the range must be valid indices in the array.
  ///   - newCount: the number of items to replace the old subrange.
  ///   - body: A callback that gets called precisely once to directly
  ///      populate newly reserved storage within the array. The function
  ///      is called with an empty output span of capacity `newCount`,
  ///      and it must fully populate it before returning.
  ///
  /// - Complexity: O(`self.count` + `newCount`)
  @inlinable
  public mutating func replaceSubrange<Result: ~Copyable>(
    _ subrange: Range<Int>,
    newCount: Int,
    initializingWith body: (inout OutputSpan<Element>) -> Result
  ) -> Result {
    // FIXME: Should we allow throwing (and a partially filled output span)?
    // FIXME: Should we have a version of this with two closures, to allow custom-consuming the old items?
    // replaceSubrange(5..<10, newCount: 3, consumingWith: {...}, initializingWith: {...})
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(newCount - subrange.count)
    return _storage.replaceSubrange(
      subrange, newCount: newCount, initializingWith: body)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Replaces the specified range of elements by moving the elements of a
  /// fully initialized buffer into their place. On return, the buffer is left
  /// in an uninitialized state.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the array does not have sufficient capacity to perform the replacement,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: A fully initialized buffer whose contents to move into
  ///     the array.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving newElements: UnsafeMutableBufferPointer<Element>,
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count - subrange.count)
    _storage.replaceSubrange(subrange, moving: newElements)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Replaces the specified range of elements by moving the contents of an
  /// input span into their place. On return, the span is left empty.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the array does not have sufficient capacity to perform the replacement,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(moving:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - items: An input span whose contents are to be moved into the array.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving items: inout InputSpan<Element>
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(items.count - subrange.count)
    _storage.replaceSubrange(subrange, moving: &items)
  }
#endif

  /// Replaces the specified range of elements by moving the contents of an
  /// output span into their place. On return, the span is left empty.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the array does not have sufficient capacity to perform the replacement,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(moving:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - items: An output span whose contents are to be moved into the array.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving items: inout OutputSpan<Element>
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(items.count - subrange.count)
    _storage.replaceSubrange(subrange, moving: &items)
  }

  /// Replaces the specified range of elements by moving the elements of a
  /// another array into their place.  On return, the source array
  /// becomes empty, but it is not destroyed, and it preserves its original
  /// storage capacity.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: An array whose contents to move into `self`.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving newElements: inout RigidArray<Element>,
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count - subrange.count)
    _storage.replaceSubrange(subrange, moving: &newElements)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Replaces the specified range of elements by moving the elements of a
  /// given array into their place, consuming it in the process.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same
  /// location. The number of new elements need not match the number of elements
  /// being removed.
  ///
  /// If the array does not have sufficient capacity to perform the replacement,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. Calling the `removeSubrange(_:)` method instead is
  /// preferred in this case.
  ///
  /// - Parameters
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: An array whose contents to move into `self`.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    consuming newElements: consuming RigidArray<Element>,
  ) {
    replaceSubrange(subrange, moving: &newElements)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray {
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If the capacity of the array isn't sufficient to perform the replacement,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
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
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count)
    unsafe _storage.replaceSubrange(subrange, copying: newElements)
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If the capacity of the array isn't sufficient to perform the replacement,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length buffer as the `newElements`
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
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.replaceSubrange(
      subrange, copying: UnsafeBufferPointer(newElements))
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given span.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If the capacity of the array isn't sufficient to perform the replacement,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length span as the `newElements`
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
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: Span<Element>
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count)
    _storage.replaceSubrange(subrange, copying: newElements)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If the capacity of the array isn't sufficient to perform the replacement,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
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
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copying newElements: borrowing C
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    let c = newElements.count
    _ensureFreeCapacity(c - subrange.count)
    _storage._replaceSubrange(
      subrange, copyingContainer: newElements, newCount: c)
  }
#endif

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given collection.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If the capacity of the array isn't sufficient to perform the replacement,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
  ///
  /// If you pass a zero-length range as the `subrange` parameter, this method
  /// inserts the elements of `newElements` at `subrange.lowerBound`. Calling
  /// the `insert(copying:at:)` method instead is preferred in this case.
  ///
  /// Likewise, if you pass a zero-length collection as the `newElements`
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
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: __owned some Collection<Element>
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    let c = newElements.count
    _ensureFreeCapacity(c)
    _storage._replaceSubrange(
      subrange, copyingCollection: newElements, newCount: c)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given container.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting the new elements starting at the same location.
  /// The number of new elements need not match the number of elements being
  /// removed.
  ///
  /// If the capacity of the array isn't sufficient to perform the replacement,
  /// then this reallocates the array's storage to extend its capacity, using a
  /// geometric growth rate.
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
    copying newElements: borrowing C
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    let c = newElements.count
    _ensureFreeCapacity(c - subrange.count)
    _storage._replaceSubrange(
      subrange, copyingContainer: newElements, newCount: c)
  }
#endif
}
#endif
