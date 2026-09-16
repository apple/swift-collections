//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import BasicContainers
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
extension RigidArray: Container where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeBorrowingIterator(
    from start: Index, to end: Index
  ) -> BorrowingIterator {
    // FIXME: `makeBorrowingIterator` would be borrowing the temporary `span`, not self
    self.span._makeBorrowingIterator(from: start, to: end)
  }

  @_alwaysEmitIntoClient
  public func currentIndex(of iterator: inout BorrowingIterator) -> Index {
    self.span.currentIndex(of: &iterator)
  }
}

@available(SwiftStdlib 6.4, *)
extension RigidArray: BidirectionalContainer where Element: ~Copyable {}

@available(SwiftStdlib 6.4, *)
extension RigidArray: RandomAccessContainer where Element: ~Copyable {}

@available(SwiftStdlib 6.4, *)
extension RigidArray: MutableContainer where Element: ~Copyable {}

@available(SwiftStdlib 6.4, *)
extension RigidArray: DrainableContainer where Element: ~Copyable {}

@available(SwiftStdlib 6.4, *)
extension RigidArray: RangeReplaceableContainer where Element: ~Copyable {
  @available(SwiftStdlib 6.4, *)
  @inlinable
  internal mutating func _replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copyingContainer items: borrowing C,
    newCount: Int
  ) -> Range<Int> {
    var it = items.makeBorrowingIterator()
    return self.replaceSubrange(subrange, addingCount: newCount) { target in
      while !target.isFull {
        let source = it.nextSpan(maxCount: target.freeCapacity)
        precondition(
          !source.isEmpty,
          "Broken Container: count doesn't match contents")
        target._append(copying: source)
      }
      precondition(
        it.nextSpan().isEmpty,
        "Broken Container: count doesn't match contents")
    }
  }

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
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(copying:at:)`.
  ///
  /// Likewise, if you pass a zero-length container as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  ///
  /// - Complexity: O(`self.count` + `newElements.count`)
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  @discardableResult
  public mutating func replaceSubrange<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    _ subrange: Range<Int>,
    copying newElements: borrowing C
  ) -> Range<Int> {
    _replaceSubrange(
      subrange,
      copyingContainer: newElements,
      newCount: newElements.count)
  }

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
  /// inserts the elements of `newElements` at `subrange.lowerBound`. This case
  /// is more directly expressed by calling `insert(copying:at:)`.
  ///
  /// Likewise, if you pass a zero-length container as the `newElements`
  /// parameter, this method removes the elements in the given subrange
  /// without replacement. This case is more directly expressed by calling
  /// `removeSubrange`.
  ///
  /// - Parameters:
  ///   - subrange: The subrange of the array to replace. The bounds of
  ///     the range must be valid indices in the array.
  ///   - newElements: The new elements to copy into the collection.
  ///
  /// - Complexity: O(*n* + *m*), where *n* is count of this array and
  ///   *m* is the count of `newElements`.
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  @discardableResult
  public mutating func replaceSubrange<
    C: Container<Element> & Collection<Element>
  >(
    _ subrange: Range<Int>,
    copying newElements: C
  ) -> Range<Int> {
    _replaceSubrange(
      subrange,
      copyingContainer: newElements,
      newCount: newElements.count)
  }

  @_alwaysEmitIntoClient
  public mutating func _customRemoveLast() -> Element? {
    self.removeLast()
  }

  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func _customConsumeLast(_ n: Int) -> SubrangeConsumer? {
    self.consumeLast(n)
  }

  @_alwaysEmitIntoClient
  public mutating func _customRemoveLast(_ n: Int) -> Bool {
    self.removeLast(n)
    return true
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray.SubrangeConsumer: ContainerDrain where Element: ~Copyable {
}

@available(SwiftStdlib 6.4, *)
extension RigidArray where Element: ~Copyable {
  /// Creates a new rigid array of the specified capacity, populating it with
  /// all items generated by a given producer.
  ///
  /// If the capacity is exhausted before the producer reaches its end, then
  /// this triggers a runtime error.
  ///
  /// If the producer throws an error during this initializer, then all
  /// previously produced items are discarded and the initializer rethrows the
  /// error.
  ///
  /// - Parameters:
  ///    - capacity: The desired storage capacity of the new array.
  ///    - producer: A producer that generates the items to append to the new
  ///       array.
  ///
  /// - Complexity: O(`capacity`)
  @_alwaysEmitIntoClient
  public init<
    E: Error,
    P: Producer<Element, E> & ~Copyable & ~Escapable
  >(
    capacity: Int,
    from producer: consuming P
  ) throws(E)
  where P.Element: ~Copyable
  {
    self.init(capacity: capacity)
    try self.append(addingCount: capacity, from: &producer)
    try producer._expectEnd("RigidDeque capacity overflow")
  }

  /// Creates a new rigid array of the specified capacity, populating it with
  /// all items generated by a given counted producer.
  ///
  /// If the capacity is exhausted before the producer reaches its end, then
  /// this triggers a runtime error.
  ///
  /// If the producer throws an error during this initializer, then all
  /// previously produced items are discarded and the initializer rethrows the
  /// error.
  ///
  /// - Parameters:
  ///    - capacity: The desired storage capacity of the new array, or nil
  ///       to allocate exactly as much room as needed to store the new items.
  ///    - producer: A producer that generates the items to append to the new
  ///       array.
  ///
  /// - Complexity: O(`capacity`)
  @_alwaysEmitIntoClient
  public init<
    E: Error,
    P: CountedProducer<Element, E> & ~Copyable & ~Escapable
  >(
    capacity: Int? = nil,
    from producer: consuming P
  ) throws(E)
  where P.Element: ~Copyable
  {
    let c = producer.count
    let capacity = capacity ?? c
    precondition(capacity >= c, "RigidDeque capacity overflow")
    self.init(capacity: capacity)
    try self.append(addingCount: c, from: &producer)
    try producer._expectEnd("Invalid CountedProducer")
  }

}

@available(SwiftStdlib 6.4, *)
extension RigidArray /* where Element: Copyable */ {
  /// Creates a new array with the specified capacity, holding a copy
  /// of the contents of the given container.
  ///
  /// - Parameters:
  ///   - capacity: The storage capacity of the new array, or nil to allocate
  ///      just enough capacity to store the contents of the source container.
  ///   - span: The containers whose contents to copy into the new array.
  ///      The container must not contain more than `capacity` elements.
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    capacity: Int? = nil,
    copying items: borrowing C
  ) {
    self.init(capacity: capacity ?? items.count)
    self.append(copying: items)
  }

  /// Creates a new array with the specified capacity, holding a copy
  /// of the contents of the given container.
  ///
  /// - Parameters:
  ///   - capacity: The storage capacity of the new array, or nil to allocate
  ///      just enough capacity to store the contents of the source container.
  ///   - span: The containers whose contents to copy into the new array.
  ///      The container must not contain more than `capacity` elements.
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<
    C: Container<Element> & Sequence<Element>
  >(
    capacity: Int? = nil,
    copying items: __shared C
  ) {
    self.init(capacity: capacity ?? items.count)
    self.append(copying: items)
  }

  /// Creates a new array with the specified capacity, holding a copy
  /// of the contents of the given container.
  ///
  /// - Parameters:
  ///   - capacity: The storage capacity of the new array, or nil to allocate
  ///      just enough capacity to store the contents of the source container.
  ///   - span: The containers whose contents to copy into the new array.
  ///      The container must not contain more than `capacity` elements.
  @_alwaysEmitIntoClient
  @inline(__always)
  public init<
    C: Container<Element> & Collection<Element>
  >(
    capacity: Int? = nil,
    copying items: __shared C
  ) {
    self.init(capacity: capacity ?? items.count)
    self.append(copying: items)
  }
}

#endif
