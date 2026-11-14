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
  /// Prepends the given element to the start of this list.
  ///
  /// This method invalidates all previously returned list indices.
  ///
  /// - Parameters:
  ///    - item: The new member to prepend to this list.
  /// - Returns: A valid index addressing the newly inserted item.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func prepend(_ item: consuming Element) -> Index {
    let new = unsafe _Node.allocate(item, next: self._first)
    unsafe self._first = new
    unsafe assert((new.pointee.next == nil) == (self._last == nil))
    if unsafe self._last == nil {
      unsafe self._last = new
    }
    self._count &+= 1
    self._version.bump()
    return self.startIndex
  }

  /// Prepends the elements of a given list to the start of this one by
  /// directly linking its contents, consuming it in the process.
  ///
  /// This method invalidates all previously returned list indices.
  ///
  /// - Parameters:
  ///    - items: A list to splice to the start of this list.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func prepend(
    consuming other: consuming LinkedList
  ) -> Range<Index> {
    self._version.bump()
    guard !other.isEmpty else { return startIndex ..< startIndex }

    unsafe other._last.unsafelyUnwrapped.pointee.next = self._first
    unsafe self._first = other._first
    if unsafe self._last == nil {
      unsafe self._last = other._last
    }
    self._count += other._count
    let middle = unsafe self._index(previousNode: other._last, offset: other.count)
    unsafe other._first = nil
    unsafe other._last = nil
    other._count = 0
    return startIndex ..< middle
  }

}
#endif
