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

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable {
  /// Inserts the given element into this list at the specified index.
  ///
  /// This method invalidates all previously returned list indices.
  ///
  /// - Parameters:
  ///    - item: The new member to insert into this list.
  ///    - index: A valid index at which to insert the new element.
  /// - Returns: A valid index addressing the newly inserted item.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func insert(_ item: consuming Element, at index: Index) -> Index {
    precondition(_isValid(index), "Invalid index")
    let node = unsafe _Node.allocate(item)
    if let previous = unsafe index._previousNode {
      unsafe node.pointee.next = previous.pointee.next
      unsafe previous.pointee.next = node
    } else {
      unsafe node.pointee.next = _first
      unsafe _first = node
    }
    if unsafe node.pointee.next == nil {
      unsafe self._last = node
    }
    self._count &+= 1
    self._version.bump()
    return unsafe self._index(
      previousNode: index._previousNode,
      offset: index._offset)
  }

  /// Inserts the given list into this one at the specified index by
  /// directly linking its contents, consuming the source list in the process.
  ///
  /// This method invalidates all previously returned list indices.
  ///
  /// - Parameters:
  ///    - items: A list to splice into this list.
  ///    - index: A valid index at which to insert the contents.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func insert(
    consuming other: consuming LinkedList,
    at index: Index
  ) -> Range<Index> {
    precondition(_isValid(index), "Invalid index")
    self._version.bump()

    guard !other.isEmpty else {
      let i = unsafe self._index(
        previousNode: index._previousNode, offset: index._offset)
      return i ..< i
    }

    let tail: UnsafeMutablePointer<_Node>?
    if let prev = unsafe index._previousNode {
      unsafe tail = exchange(&prev.pointee.next, with: other._first)
    } else {
      unsafe tail = exchange(&self._first, with: other._first)
    }

    let last = unsafe other._last.unsafelyUnwrapped // `other` isn't empty
    unsafe last.pointee.next = tail

    if unsafe tail == nil {
      unsafe self._last = last
    }

    self._count += other._count

    let lower = unsafe self._index(
      previousNode: index._previousNode, offset: index._offset)
    let upper = unsafe self._index(
      previousNode: last, offset: index._offset &+ other.count)

    unsafe other._first = nil
    unsafe other._last = nil
    other._count = 0

    return lower ..< upper
  }
}
#endif
