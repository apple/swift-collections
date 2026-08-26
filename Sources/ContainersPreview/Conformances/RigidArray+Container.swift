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
  internal mutating func _replace<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    removing subrange: Range<Int>,
    copyingContainer items: borrowing C,
    newCount: Int
  ) {
    var it = items.makeBorrowingIterator()
    self.replace(removing: subrange, addingCount: newCount) { target in
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
  @inlinable
  @inline(__always)
  public mutating func replace<
    C: Container<Element> & ~Copyable & ~Escapable
  >(
    removing subrange: Range<Int>,
    copying newElements: borrowing C
  ) {
    _replace(
      removing: subrange,
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
  @inlinable
  @inline(__always)
  public mutating func replace<
    C: Container<Element> & Collection<Element>
  >(
    removing subrange: Range<Int>,
    copying newElements: C
  ) {
    _replace(
      removing: subrange,
      copyingContainer: newElements,
      newCount: newElements.count)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray.SubrangeConsumer: Drain where Element: ~Copyable {
}

#endif
