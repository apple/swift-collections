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
  /// Extract the members in a given subrange into a standalone list,
  /// de-linking them from this one.
  ///
  /// This method invalidates all previously returned list indices.
  ///
  /// - Parameter subrange: The subrange of members to extract into a new list.
  ///     On return, this is set to the empty subrange addressing the location
  ///     of the removed items in `self`.
  /// - Returns: A new list composed of the members of the subrange.
  /// - Complexity: O(1)
  @_alwaysEmitIntoClient
  public mutating func extract(
    _ subrange: inout Range<Index> 
  ) -> LinkedList {
    // FIXME: We want this to return a tuple of (Index, LinkedList), but we can't do that.
    defer {
      var i = subrange.lowerBound
      i._version = self._version
      subrange = i ..< i
    }

    precondition(
      _isValid(subrange.lowerBound) && _isValid(subrange.upperBound),
      "Invalid subrange")
    switch (subrange.lowerBound._offset == 0, subrange.upperBound._offset == count) {
    case (false, false):
      break
    case (false, true):
      return extract(from: subrange.lowerBound)
    case (true, false):
      return extract(upTo: subrange.upperBound)
    case (true, true):
      return exchange(&self, with: LinkedList())
    }

    _version.bump()
    guard !subrange.isEmpty else {
      return LinkedList()
    }

    let lower = unsafe subrange.lowerBound._previousNode.unsafelyUnwrapped
    let last = unsafe subrange.upperBound._previousNode.unsafelyUnwrapped

    let tail = unsafe exchange(&last.pointee.next, with: nil)
    let first = unsafe exchange(&lower.pointee.next, with: tail)

    let c = subrange.upperBound._offset &- subrange.lowerBound._offset
    self._count &-= c

    return unsafe LinkedList(_first: first, last: last, count: c)
  }

  @_alwaysEmitIntoClient
  public mutating func extract(
    upTo index: Index
  ) -> LinkedList {
    precondition(_isValid(index), "Invalid index")
    _version.bump()
    guard let last = unsafe index._previousNode else { // index == startIndex
      return LinkedList()
    }
    guard unsafe last != self._last else { // index == endIndex
      return exchange(&self, with: Self())
    }
    self._count &-= index._offset

    let first = unsafe exchange(&self._first, with: exchange(&last.pointee.next, with: nil))

    return unsafe LinkedList(_first: first, last: last, count: index._offset)
  }

  @_alwaysEmitIntoClient
  public mutating func extract(
    from index: Index
  ) -> LinkedList {
    precondition(_isValid(index), "Invalid index")
    _version.bump()
    guard let last = unsafe index._previousNode else { // index == startIndex
      return exchange(&self, with: Self())
    }
    guard unsafe last != self._last else { // index == endIndex
      return LinkedList()
    }

    defer {
      self._count = index._offset
    }

    return unsafe LinkedList(
      _first: exchange(&last.pointee.next, with: nil),
      last: exchange(&self._last, with: last),
      count: self.count &- index._offset)
  }
}
#endif
