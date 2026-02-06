//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Append a given number of items to the end of this array by populating
  /// an output span.
  ///
  /// If the array does not have sufficient capacity to hold the requested
  /// number of new elements, then this reallocates the array's storage to
  /// grow its capacity, using a geometric growth rate.
  ///
  /// - Parameters
  ///    - count: The number of items to append to the array.
  ///    - initializer: A callback that gets called exactly once to directly
  ///       populate newly reserved storage within the array. The function
  ///       is allowed to initialize fewer than `count` items. The array is
  ///       appended however many items the callback adds to the output span
  ///       before it returns (or before it throws an error).
  ///
  /// - Complexity: O(`count`)
  @available(*, deprecated, renamed: "append(addingCount:initializingWith:)")
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append<E: Error, Result: ~Copyable>(
    count: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    var result: Result? = nil
    try append(addingCount: count) { target throws(E) in
      result = try initializer(&target)
    }
    return result.take()!
  }
  
  /// Inserts a given number of new items into this array at the specified
  /// position, using a callback to directly initialize array storage by
  /// populating an output span.
  ///
  /// All existing elements at or following the specified position are moved to
  /// make room for the new items.
  ///
  /// If the array does not have sufficient capacity to hold the new elements,
  /// then this reallocates storage to extend its capacity, using a geometric
  /// growth rate.
  ///
  /// - Parameters:
  ///    - count: The number of items to insert into the array.
  ///    - index: The position at which to insert the new items.
  ///       `index` must be a valid index in the array.
  ///    - body: A callback that gets called exactly once to directly
  ///       populate newly reserved storage within the array. The function
  ///       is called with an empty output span of capacity matching the
  ///       supplied count, and it must fully populate it before returning.
  ///
  /// - Complexity: O(`self.count` + `count`)
  @available(*, deprecated, renamed: "insert(addingCount:at:initializingWith:)")
  @inlinable
  public mutating func insert<Result: ~Copyable>(
    count: Int,
    at index: Int,
    initializingWith body: (inout OutputSpan<Element>) -> Result
  ) -> Result {
    var result: Result? = nil
    self.insert(addingCount: count, at: index) { target in
      result = body(&target)
    }
    return result!
  }

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
  ///   - body: A callback that gets called exactly once to directly
  ///      populate newly reserved storage within the array. The function
  ///      is called with an empty output span of capacity `newCount`,
  ///      and it must fully populate it before returning.
  ///
  /// - Complexity: O(`self.count` + `newCount`)
  @available(*, deprecated, renamed: "replace(removing:addingCount:initializingWith:)")
  @inlinable
  public mutating func replaceSubrange<Result: ~Copyable>(
    _ subrange: Range<Int>,
    newCount: Int,
    initializingWith body: (inout OutputSpan<Element>) -> Result
  ) -> Result {
    var result: Result? = nil
    self.replace(removing: subrange, addingCount: newCount) { target in
      result = body(&target)
    }
    return result!
  }

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
  @available(*, deprecated, renamed: "replace(removing:moving:)")
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving newElements: UnsafeMutableBufferPointer<Element>,
  ) {
    self.replace(removing: subrange, moving: newElements)
  }
  
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
  @available(*, deprecated, renamed: "replace(removing:moving:)")
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving items: inout OutputSpan<Element>
  ) {
    self.replace(removing: subrange, moving: &items)
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
  @available(*, deprecated, renamed: "replace(removing:moving:)")
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving newElements: inout RigidArray<Element>,
  ) {
    self.replace(removing: subrange, moving: &newElements)
  }
  
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
  @available(*, deprecated, renamed: "replace(removing:consuming:)")
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    consuming newElements: consuming RigidArray<Element>,
  ) {
    self.replace(removing: subrange, consuming: newElements)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray {
  /// Copy the contents of this array into a newly allocated unique array
  /// instance with just enough capacity to hold all its elements.
  ///
  /// - Complexity: O(`count`)
  @available(*, deprecated, renamed: "clone()")
  @inlinable
  public func copy() -> Self {
    self.clone()
  }
  
  /// Copy the contents of this array into a newly allocated unique array
  /// instance with the specified capacity.
  ///
  /// - Parameter capacity: The desired capacity of the resulting unique array.
  ///    `capacity` must be greater than or equal to `count`.
  ///
  /// - Complexity: O(`count`)
  @available(*, deprecated, renamed: "clone(capacity:)")
  @inlinable
  public func copy(capacity: Int) -> Self {
    clone(capacity: capacity)
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
  @available(*, deprecated, renamed: "replace(removing:copying:)")
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    self.replace(removing: subrange, copying: newElements)
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
  @available(*, deprecated, renamed: "replace(removing:copying:)")
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    self.replace(removing: subrange, copying: newElements)
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
  @available(*, deprecated, renamed: "replace(removing:copying:)")
  @inlinable
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: Span<Element>
  ) {
    self.replace(removing: subrange, copying: newElements)
  }
  
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
  @available(*, deprecated, renamed: "replace(removing:copying:)")
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: __owned some Collection<Element>
  ) {
    self.replace(removing: subrange, copying: newElements)
  }
}

#endif
