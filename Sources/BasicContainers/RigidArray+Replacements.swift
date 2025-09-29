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
extension RigidArray where Element: ~Copyable {
  /// Replaces the specified range of elements by a given count of new items,
  /// using a callback to directly initialize array storage by populating
  /// an output span.
  ///
  /// This method has the effect of removing the specified range of elements
  /// from the array and inserting room for the new elements starting at the
  /// same location. The number of new elements need not match the number
  /// of elements being removed.
  ///
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
    let target = _gapForReplacement(of: subrange, withNewCount: newCount)
    var span = OutputSpan(buffer: target, initializedCount: 0)
    defer {
      let c = span.finalize(for: target)
      precondition(c == newCount, "Inserted fewer items than promised")
      span = OutputSpan()
    }
    return body(&span)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  /// Replaces the specified range of elements by moving the elements of a
  /// fully initialized buffer into their place. On return, the buffer is left
  /// in an uninitialized state.
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
  ///   - newElements: A fully initialized buffer whose contents to move into
  ///     the array.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @_alwaysEmitIntoClient
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    moving newElements: UnsafeMutableBufferPointer<Element>,
  ) {
    replaceSubrange(subrange, newCount: newElements.count) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        count = unsafe buffer._moveInitializePrefix(from: newElements)
      }
    }
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(last: count)
      unsafe self.replaceSubrange(subrange, moving: source)
      count = 0
    }
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.replaceSubrange(subrange, moving: source)
      count = 0
    }
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
  /// If the capacity of the array isn't sufficient to accommodate the new
  /// elements, then this method triggers a runtime error.
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
    unsafe newElements._unsafeEdit { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe self.replaceSubrange(subrange, moving: source)
      count = 0
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Replaces the specified range of elements by moving the elements of a
  /// given array into their place, consuming it in the process.
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
    // FIXME: Remove this in favor of a generic algorithm over consumable containers
    replaceSubrange(subrange, moving: &newElements)
  }
#endif
}

@available(SwiftStdlib 5.0, *)
extension RigidArray {
  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
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
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    replaceSubrange(subrange, newCount: newElements.count) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        count = unsafe buffer._initializePrefix(copying: newElements)
      }
    }
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given buffer pointer, which must be fully initialized.
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
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.replaceSubrange(
      subrange,
      copying: UnsafeBufferPointer(newElements))
  }

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given span.
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
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: Span<Element>
  ) {
    unsafe newElements.withUnsafeBufferPointer { buffer in
      unsafe self.replaceSubrange(subrange, copying: buffer)
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  internal mutating func _replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copyingContainer newElements: borrowing C,
    newCount: Int
  ) {
    self.replaceSubrange(subrange, newCount: newCount) { target in
      target.withUnsafeMutableBufferPointer { buffer, count in
        count = newElements._copyContents(intoPrefixOf: buffer)
        precondition(
          count == newCount,
          "Broken Container: count doesn't match contents")
      }
    }
  }
#endif

  @inlinable
  internal mutating func _replaceSubrange(
    _ subrange: Range<Int>,
    copyingCollection newElements: __owned some Collection<Element>,
    newCount: Int
  ) {
    self.replaceSubrange(subrange, newCount: newCount) { target in
      target.withUnsafeMutableBufferPointer { dst, dstCount in
        let done: Void? = newElements.withContiguousStorageIfAvailable { src in
          let i = unsafe dst._initializePrefix(copying: src)
          precondition(
            i == newCount,
            "Broken Collection: count doesn't match contents")
          dstCount = i
        }
        if done != nil { return }

        var (it, copied) = unsafe newElements._copyContents(initializing: dst)
        dstCount = copied
        precondition(
          it.next() == nil && copied == newCount,
          "Broken Collection: count doesn't match contents")
      }
    }

  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
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

  /// Replaces the specified subrange of elements by copying the elements of
  /// the given collection.
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
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  @inline(__always)
  public mutating func replaceSubrange(
    _ subrange: Range<Int>,
    copying newElements: __owned some Collection<Element>
  ) {
    _replaceSubrange(
      subrange, copyingCollection: newElements, newCount: newElements.count)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
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
