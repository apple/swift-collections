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
  /// Inserts a new element into the array at the specified position.
  ///
  /// If the array does not have sufficient capacity to hold any more elements,
  /// then this reallocates storage to extend its capacity.
  ///
  /// The new element is inserted before the element currently at the specified
  /// index. If you pass the array's `endIndex` as the `index` parameter, then
  /// the new element is appended to the container.
  ///
  /// All existing elements at or following the specified position are moved to
  /// make room for the new item.
  ///
  /// - Parameter item: The new element to insert into the array.
  /// - Parameter i: The position at which to insert the new element.
  ///   `index` must be a valid index in the array.
  ///
  /// - Complexity: O(`self.count`)
  @inlinable
  public mutating func insert(_ item: consuming Element, at index: Int) {
    precondition(index >= 0 && index <= count)
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(1)
    _storage.insert(item, at: index)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  @inlinable
  public mutating func insert<Result: ~Copyable>(
    count: Int,
    at index: Int,
    initializingWith body: (inout OutputSpan<Element>) -> Result
  ) -> Result {
    // FIXME: This does not allow `body` to throw, to prevent having to move the tail twice. Is that okay?
    _ensureFreeCapacity(count)
    return _storage.insert(count: count, at: index, initializingWith: body)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Moves the elements of a fully initialized buffer into this array,
  /// starting at the specified position, and leaving the buffer
  /// uninitialized.
  ///
  /// If the array does not have sufficient capacity to hold all elements,
  /// then this reallocates storage to extend its capacity.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(items.count)
    _storage.insert(moving: items, at: index)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout InputSpan<Element>,
    at index: Int
  ) {
    _ensureFreeCapacity(items.count)
    _storage.insert(moving: &items, at: index)
  }
#endif

  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout OutputSpan<Element>,
    at index: Int
  ) {
    _ensureFreeCapacity(items.count)
    _storage.insert(moving: &items, at: index)
  }

  /// Inserts the elements of a given array into the given position in this
  /// array by moving them between the containers. On return, the input array
  /// becomes empty, but it is not destroyed, and it preserves its original
  /// storage capacity.
  ///
  /// If the array does not have sufficient capacity to hold all elements,
  /// then this reallocates storage to extend its capacity.
  ///
  /// - Parameters
  ///    - items: An array whose contents to move into `self`.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    moving items: inout RigidArray<Element>,
    at index: Int
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(items.count)
    _storage.insert(moving: &items, at: index)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Inserts the elements of a given array into the given position in this
  /// array by consuming the source container.
  ///
  /// If the array does not have sufficient capacity to hold all elements,
  /// then this reallocates storage to extend its capacity.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
  ///
  /// - Complexity: O(`self.count` + `items.count`)
  @_alwaysEmitIntoClient
  public mutating func insert(
    consuming items: consuming RigidArray<Element>,
    at index: Int
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(items.count)
    _storage.insert(consuming: items, at: index)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueArray {
  /// Copyies the elements of a fully initialized buffer pointer into this
  /// array at the specified position.
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
  ///    - newElements: The new elements to insert into the array. The buffer
  ///       must be fully initialized.
  ///    - index: The position at which to insert the new elements. It must be
  ///       a valid index of the array.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  public mutating func insert(
    copying newElements: UnsafeBufferPointer<Element>, at index: Int
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count)
    unsafe _storage.insert(copying: newElements, at: index)
  }

  /// Copyies the elements of a fully initialized buffer pointer into this
  /// array at the specified position.
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
  ///    - newElements: The new elements to insert into the array. The buffer
  ///       must be fully initialized.
  ///    - index: The position at which to insert the new elements. It must be
  ///       a valid index of the array.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  public mutating func insert(
    copying newElements: UnsafeMutableBufferPointer<Element>,
    at index: Int
  ) {
    unsafe self.insert(copying: UnsafeBufferPointer(newElements), at: index)
  }

  /// Copies the elements of a span into this array at the specified position.
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
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  public mutating func insert(
    copying newElements: Span<Element>, at index: Int
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    _ensureFreeCapacity(newElements.count)
    _storage.insert(copying: newElements, at: index)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
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
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    let c = newElements.count
    _ensureFreeCapacity(c)
    _storage._insertContainer(at: index, copying: newElements, newCount: c)
  }
#endif

  /// Copies the elements of a collection into this array at the specified
  /// position.
  ///
  /// The new elements are inserted before the element currently at the
  /// specified index. If you pass the array’s `endIndex` as the `index`
  /// parameter, then the new elements are appended to the end of the array.
  ///
  /// All existing elements at or following the specified position are moved
  /// to make room for the new item.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: The new elements to insert into the array.
  ///    - index: The position at which to insert the new elements. It must be
  ///        a valid index of the array.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @inlinable
  public mutating func insert(
    copying newElements: some Collection<Element>, at index: Int
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    let newCount = newElements.count
    _ensureFreeCapacity(newCount)
    _storage._insertCollection(
      at: index, copying: newElements, newCount: newCount)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
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
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func insert<
    C: Container<Element> & Collection<Element>
  >(
    copying newElements: borrowing C, at index: Int
  ) {
    // FIXME: Avoid moving the subsequent elements twice.
    let c = newElements.count
    _ensureFreeCapacity(c)
    _storage._insertContainer(at: index, copying: newElements, newCount: c)
  }
#endif
}

#endif
