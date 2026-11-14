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
  /// Appends the given element to the end of this list.
  ///
  /// This method invalidates all previously returned list indices.
  ///
  /// - Parameters:
  ///    - item: The new member to append to the end of this list.
  /// - Returns: A valid index addressing the newly inserted item.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func append(_ item: consuming Element) -> Index {
    let new = unsafe _Node.allocate(item)
    if let last = unsafe self._last {
      // Appending to non-empty list
      unsafe assert(last.pointee.next == nil)
      unsafe last.pointee.next = new
    } else {
      // First item in empty list
      unsafe assert(self._first == nil)
      unsafe self._first = new
    }
    self._version.bump()
    defer {
      unsafe self._last = new
      self._count &+= 1
    }
    return unsafe self._index(previousNode: self._last, offset: self.count)
  }

  /// Appends the elements of a given list to the end of this one by
  /// directly linking its contents, consuming it in the process.
  ///
  /// This method invalidates all previously returned list indices.
  ///
  /// - Parameters:
  ///    - items: A list to splice to the end of this list.
  /// - Returns: A valid index range addressing the newly inserted items.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func append(
    consuming other: consuming LinkedList
  ) -> Range<Index> {
    self._version.bump()
    guard !other.isEmpty else { return endIndex ..< endIndex }
    let middle = unsafe self._index(previousNode: self._last, offset: self.count)
    if let last = unsafe self._last {
      unsafe last.pointee.next = other._first
    } else {
      unsafe self._first = other._first
    }
    unsafe self._last = other._last
    self._count += other._count
    unsafe other._first = nil
    unsafe other._last = nil
    other._count = 0
    return middle ..< endIndex
  }
}
#endif
