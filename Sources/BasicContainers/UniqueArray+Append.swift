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

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Adds an element to the end of the array.
  ///
  /// If the array does not have sufficient capacity to hold any more elements,
  /// then this reallocates the array's storage to grow its capacity.
  ///
  /// - Parameter item: The element to append to the collection.
  ///
  /// - Complexity: O(1) when amortized over many invocations on the same array
  @inlinable
  public mutating func append(_ item: consuming Element) {
    _ensureFreeCapacity(1)
    _storage.append(item)
  }
}

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public mutating func append<E: Error, Result: ~Copyable>(
    count: Int,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    _ensureFreeCapacity(count)
    return try _storage.append(count: count, initializingWith: body)
  }
}

@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Moves the elements of a buffer to the end of this array, leaving the
  /// buffer uninitialized.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// buffer, then this reallocates the array's storage to grow its capacity.
  ///
  /// - Parameters
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
  ///
  /// - Complexity: O(`items.count`) when amortized over many invocations on
  ///     the same array
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    _ensureFreeCapacity(items.count)
    _storage.append(moving: items)
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout InputSpan<Element>
  ) {
    _ensureFreeCapacity(items.count)
    _storage.append(moving: &items)
  }
#endif

  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout OutputSpan<Element>
  ) {
    _ensureFreeCapacity(items.count)
    _storage.append(moving: &items)
  }

  /// Appends the elements of a given array to the end of this array by moving
  /// them between the containers. On return, the input array becomes empty, but
  /// it is not destroyed, and it preserves its original storage capacity.
  ///
  /// If the target array does not have sufficient capacity to hold all items
  /// in the source array, then this automatically grows the target array's
  /// capacity.
  ///
  /// - Parameters
  ///    - items: An array whose items to move to the end of this array.
  ///
  /// - Complexity: O(`items.count`) when amortized over many invocations on
  ///     the same array
  @_alwaysEmitIntoClient
  public mutating func append(
    moving items: inout RigidArray<Element>
  ) {
    // FIXME: Remove this in favor of a generic algorithm over range-replaceable containers
    _ensureFreeCapacity(items.count)
    _storage.append(moving: &items)
  }
}

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SpanAvailability 1.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Appends the elements of a given container to the end of this array by
  /// consuming the source container.
  ///
  /// If the target array does not have sufficient capacity to hold all items
  /// in the source array, then this triggers a runtime error.
  ///
  /// - Parameters
  ///    - items: An array whose items to move to the end of this array.
  ///
  /// - Complexity: O(`items.count`)
  @_alwaysEmitIntoClient
  public mutating func append(
    consuming items: consuming RigidArray<Element>
  ) {
    // FIXME: Remove this in favor of a generic algorithm over consumable containers
    var items = items
    self.append(moving: &items)
  }
}
#endif

@available(SpanAvailability 1.0, *)
extension UniqueArray {
  /// Copies the elements of a buffer to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the array.
  ///
  /// - Complexity: O(`newElements.count`) when amortized over many
  ///     invocations on the same array.
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeBufferPointer<Element>
  ) {
    _ensureFreeCapacity(newElements.count)
    unsafe _storage.append(copying: newElements)
  }

  /// Copies the elements of a buffer to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: A fully initialized buffer whose contents to copy into
  ///       the array.
  ///
  /// - Complexity: O(`newElements.count`) when amortized over many
  ///     invocations on the same array.
  @_alwaysEmitIntoClient
  public mutating func append(
    copying newElements: UnsafeMutableBufferPointer<Element>
  ) {
    unsafe self.append(copying: UnsafeBufferPointer(newElements))
  }

  /// Copies the elements of a span to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity.
  ///
  /// - Parameters
  ///    - newElements: A span whose contents to copy into the array.
  ///
  /// - Complexity: O(`newElements.count`) when amortized over many
  ///     invocations on the same array.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: Span<Element>) {
    _ensureFreeCapacity(newElements.count)
    _storage.append(copying: newElements)
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
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
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append<
    Source: Container<Element> & ~Copyable & ~Escapable
  >(
    copying newElements: borrowing Source
  ) {
    _ensureFreeCapacity(newElements.count)
    _storage._append(copyingContainer: newElements)
  }

#endif

  /// Copies the elements of a sequence to the end of this array.
  ///
  /// If the array does not have sufficient capacity to hold enough elements,
  /// then this reallocates the array's storage to extend its capacity. This
  /// reallocation can happen multiple times.
  ///
  /// - Parameters
  ///    - newElements: The new elements to copy into the array.
  ///
  /// - Complexity: O(*m*), where *m* is the length of `newElements`, when
  ///     amortized over many invocations over the same array.
  @_alwaysEmitIntoClient
  public mutating func append(copying newElements: some Sequence<Element>) {
    let done: Void? = newElements.withContiguousStorageIfAvailable { buffer in
      _ensureFreeCapacity(buffer.count)
      unsafe _storage.append(copying: buffer)
      return
    }
    if done != nil { return }

    _ensureFreeCapacity(newElements.underestimatedCount)
    var it = _storage._append(prefixOf: newElements)
    while let item = it.next() {
      _ensureFreeCapacity(1)
      _storage.append(item)
    }
  }
  
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
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
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func append<
    Source: Container<Element> & Sequence<Element>
  >(copying newElements: Source) {
    _ensureFreeCapacity(newElements.count)
    _storage._append(copyingContainer: newElements)
  }
#endif

}

#endif
